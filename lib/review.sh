#!/usr/bin/env bash
set -euo pipefail

[[ -n "${_GENPY_REVIEW_LOADED:-}" ]] && return 0
_GENPY_REVIEW_LOADED=1

# =============================================================================
# GenPy — lib/review.sh (v1.0.0-alpha)
#
# genpy review orchestrator — 10-step flow (ARCHITECTURE.md §5.4).
#
# Usage:
#   genpy review FILE [SELECTOR] [OPTIONS]
#
# SELECTOR (one of):
#   --lines N-M              Line range
#   --function NAME          Top-level function
#   --class NAME             Top-level class
#   --method CLASS.METHOD    Method inside a class
#
# OPTIONS:
#   --goal TEXT              Review goal (default: generic)
#   --provider ollama|api    AI provider (default: ollama)
#   --model NAME             Force a specific model (equivalent to GENPY_MODEL)
#
# Environment variables for testing / CI:
#   GENPY_REVIEW_NON_INTERACTIVE=1   Auto-accepts the diff at step [9]
#   GUARDIAN_NON_INTERACTIVE=1       Auto-aborts on guardian failure (see guardians.sh)
# =============================================================================

# ─── Public API ───────────────────────────────────────────────────────────────

genpy_review() {
  local target_file=""
  local selector_mode=""
  local selector_target=""
  local goal="Improve code quality, readability and robustness"
  local provider="${GENPY_PROVIDER:-ollama}"

  # ── Argument parsing ────────────────────────────────────────────────────────
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --lines|--function|--class|--method)
        selector_mode="$1"; shift
        if [[ $# -eq 0 ]]; then
          echo "Error: missing argument for $selector_mode" >&2
          _review_usage; return 1
        fi
        selector_target="$1"; shift
        ;;
      --goal)
        shift
        if [[ $# -eq 0 ]]; then
          echo "Error: missing goal text" >&2
          return 1
        fi
        goal="$1"; shift
        ;;
      --provider)
        shift
        if [[ $# -eq 0 ]]; then
          echo "Error: missing provider name" >&2
          return 1
        fi
        provider="$1"; shift
        ;;
      --model)
        shift
        if [[ $# -eq 0 ]]; then
          echo "Error: missing model name" >&2
          return 1
        fi
        export GENPY_MODEL="$1"; shift
        ;;
      -*)
        echo "Error: unknown option: $1" >&2
        _review_usage; return 1
        ;;
      *)
        if [[ -z "$target_file" ]]; then
          target_file="$1"; shift
        else
          echo "Error: unexpected argument: $1" >&2
          _review_usage; return 1
        fi
        ;;
    esac
  done

  if [[ -z "$target_file" ]]; then
    _review_usage; return 1
  fi

  # Resolve absolute path of the file
  target_file="$(_review_abspath "$target_file")" || return 1

  if [[ ! -f "$target_file" ]]; then
    echo "Error: file not found: $target_file" >&2
    return 1
  fi

  # No selector: review the full file
  if [[ -z "$selector_mode" ]]; then
    selector_mode="--lines"
    selector_target="1-$(awk 'END {print NR}' "$target_file")"
  fi

  # ── Load modules ────────────────────────────────────────────────────────────
  source "${LIB_DIR:?}/core/errors.sh"
  source "${LIB_DIR}/utils.sh"
  source "${LIB_DIR}/resolver.sh"
  source "${LIB_DIR}/assembler.sh"
  source "${LIB_DIR}/guardians.sh"
  source "${LIB_DIR}/git_manager.sh"
  # preflight.sh only if the function is not already defined (allows mock in tests)
  if ! declare -f preflight_mode_review &>/dev/null; then
    source "${LIB_DIR}/core/preflight.sh"
  fi

  # Load provider only if ai_complete is not already defined (allows injection
  # of mock in tests by pre-sourcing ollama_mock.sh before calling genpy_review)
  if ! declare -f ai_complete &>/dev/null; then
    case "$provider" in
      ollama) source "${LIB_DIR}/providers/ollama.sh" ;;
      api)    source "${LIB_DIR}/providers/api.sh" ;;
      *)
        echo "Error: unknown provider: '$provider'. Valid: ollama, api" >&2
        return 1
        ;;
    esac
  fi

  # Detect strategy
  local strategy_file
  strategy_file=$(_review_detect_strategy "$target_file") || return 1

  # Project dir = git root
  local project_dir
  project_dir=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "Error: no git repository found at or above $(dirname "$target_file")" >&2
    return 1
  }

  # ── [0] Preflight ───────────────────────────────────────────────────────────
  preflight_mode_review || return 1

  # ── Setup temp dir ──────────────────────────────────────────────────────────
  local tmpdir
  tmpdir=$(mktemp -d)
  export GENPY_CLEANUP_DIR="$tmpdir"

  local context_file="$tmpdir/context.txt"
  local focal_chunk_file="$tmpdir/focal_chunk.tmp"
  local prompt_file="$tmpdir/prompt.txt"
  local ai_output_file="$tmpdir/ai_output.tmp"
  local reassembled_file="$tmpdir/reassembled.tmp"
  local diff_file="$tmpdir/review.diff"

  # ── [1] Load strategy ───────────────────────────────────────────────────────
  print_section "AI Review — $(basename "$target_file")"
  # shellcheck source=/dev/null
  source "$strategy_file"

  # ── [2] Git checkpoint ──────────────────────────────────────────────────────
  create_checkpoint "$project_dir" || return 1

  # ── [3] Resolve range ───────────────────────────────────────────────────────
  resolve_range "$selector_mode" "$selector_target" "$target_file" || {
    rollback_to_checkpoint "$project_dir"
    return 1
  }
  print_info "Fragment: lines ${RESOLVE_START}–${RESOLVE_END} of $(basename "$target_file")"

  # Extract the focal chunk
  sed -n "${RESOLVE_START},${RESOLVE_END}p" "$target_file" > "$focal_chunk_file"

  # ── [4] Build context ───────────────────────────────────────────────────────
  build_review_context "$target_file" "$strategy_file" > "$context_file"

  # ── [5] Assemble prompt ─────────────────────────────────────────────────────
  assemble_prompt "$context_file" "$focal_chunk_file" "$goal" > "$prompt_file"

  # ── [6–7] AI + Guardians loop ───────────────────────────────────────────────
  local retries_done=0
  while true; do
    show_progress "Sending fragment to model"

    local ai_rc=0
    ai_complete "$prompt_file" "$ai_output_file" || ai_rc=$?
    printf '\r\033[K'  # clear the progress line

    case "$ai_rc" in
      0) ;;
      3)
        rollback_to_checkpoint "$project_dir"
        print_error "Timeout waiting for model response (${OLLAMA_TIMEOUT:-120}s)."
        return 1
        ;;
      *)
        rollback_to_checkpoint "$project_dir"
        print_error "Provider failed (rc=${ai_rc}). Is Ollama running?"
        return 1
        ;;
    esac

    local grd_rc=0
    run_guardians \
      "$ai_output_file" "$focal_chunk_file" "$strategy_file" "$retries_done" \
      || grd_rc=$?

    case "$grd_rc" in
      0) break ;;
      2)
        retries_done=$(( retries_done + 1 ))
        continue
        ;;
      *)
        rollback_to_checkpoint "$project_dir"
        print_warning "Review aborted."
        return 1
        ;;
    esac
  done

  # ── [8] Reassembly + full syntax validation ──────────────────────────────────
  reassemble_file \
    "$target_file" "$ai_output_file" "$RESOLVE_START" "$RESOLVE_END" \
    > "$reassembled_file"

  if declare -f validate_syntax &>/dev/null; then
    if ! validate_syntax "$reassembled_file" 2>/dev/null; then
      print_warning "The reassembled file has syntax errors."
      if [[ "${GENPY_REVIEW_NON_INTERACTIVE:-0}" != "1" && -t 0 ]]; then
        printf '  [A]bort  [E]dit manually → '
        local syn_choice; IFS= read -r syn_choice
        syn_choice="${syn_choice^^}"
        if [[ "$syn_choice" == "E" ]]; then
          "${EDITOR:-vi}" "$reassembled_file"
        else
          rollback_to_checkpoint "$project_dir"
          return 1
        fi
      else
        rollback_to_checkpoint "$project_dir"
        return 1
      fi
    fi
  fi

  # ── [9] Visual diff + confirmation ──────────────────────────────────────────
  diff -u "$target_file" "$reassembled_file" > "$diff_file" || true

  if [[ ! -s "$diff_file" ]]; then
    print_warning "The model introduced no changes to the fragment."
    rollback_to_checkpoint "$project_dir"
    return 0
  fi

  printf '\n'
  if [[ "${GENPY_REVIEW_NON_INTERACTIVE:-0}" != "1" && -t 1 ]] \
     && command -v less &>/dev/null; then
    diff --color=always -u "$target_file" "$reassembled_file" | less -R || true
  else
    cat "$diff_file"
  fi

  local final_choice="A"
  if [[ "${GENPY_REVIEW_NON_INTERACTIVE:-0}" != "1" && -t 0 ]]; then
    printf '\n  [A]ccept changes  [R]eject  [E]dit → '
    IFS= read -r final_choice
    final_choice="${final_choice^^}"
  fi

  # ── [10] Apply or revert ─────────────────────────────────────────────────────
  case "$final_choice" in
    A|"")
      _review_apply "$project_dir" "$target_file" "$reassembled_file"
      ;;
    E)
      "${EDITOR:-vi}" "$reassembled_file"
      _review_apply "$project_dir" "$target_file" "$reassembled_file"
      ;;
    *)
      rollback_to_checkpoint "$project_dir"
      print_warning "Review rejected. Original state restored."
      ;;
  esac
}

# ─── Internals ────────────────────────────────────────────────────────────────

_review_apply() {
  local project_dir="$1" target_file="$2" reassembled_file="$3"

  cp "$reassembled_file" "$target_file"

  local relative_file="${target_file#${project_dir}/}"
  git -C "$project_dir" add "$relative_file"
  git -C "$project_dir" commit -q \
    -m "chore(genpy): review applied to ${relative_file}"

  print_success "Changes applied and committed to '${CHECKPOINT_BRANCH}'."
  print_info   "To integrate: git checkout <base-branch> && git merge ${CHECKPOINT_BRANCH}"
}

# Detects the strategy from blueprint.toml or the file extension
_review_detect_strategy() {
  local file="$1"
  local lib_dir="${LIB_DIR:?}"

  # 1. Try to read language from the project's blueprint.toml
  local toml=".genpy/blueprint.toml"
  if [[ -f "$toml" ]]; then
    local lang
    lang=$(grep -E '^language[[:space:]]*=' "$toml" 2>/dev/null | head -1 \
      | sed 's/.*=[[:space:]]*//' | tr -d '"'"'" | tr -d '[:space:]') || true
    if [[ -n "$lang" ]]; then
      local strategy="${lib_dir}/review_strategies/${lang}.sh"
      if [[ -f "$strategy" ]]; then
        echo "$strategy"; return 0
      fi
    fi
  fi

  # 2. Fallback: file extension
  local ext="${file##*.}"
  local strategy
  case "$ext" in
    py)            strategy="${lib_dir}/review_strategies/python.sh" ;;
    go)            strategy="${lib_dir}/review_strategies/go.sh" ;;
    js|ts|jsx|tsx) strategy="${lib_dir}/review_strategies/javascript.sh" ;;
    *)
      echo "Error: could not detect language for '${file}'" >&2
      echo "  Use a blueprint.toml with [meta] language = <language>" >&2
      return 1
      ;;
  esac

  if [[ ! -f "$strategy" ]]; then
    echo "Error: strategy not found: $strategy" >&2
    return 1
  fi

  echo "$strategy"
}

# Resolves absolute path portably (same logic as bin/genpy _resolve_path)
_review_abspath() {
  local target="$1"
  if command -v realpath &>/dev/null; then
    realpath "$target"
  elif readlink -f "$target" &>/dev/null 2>&1; then
    readlink -f "$target"
  else
    local dir file
    dir="$(cd "$(dirname "$target")" && pwd)"
    file="$(basename "$target")"
    echo "${dir}/${file}"
  fi
}

_review_usage() {
  cat >&2 <<'EOF'
Usage: genpy review FILE [SELECTOR] [OPTIONS]

SELECTOR (one of):
  --lines N-M              Line range (e.g.: 10-50)
  --function NAME          Top-level function
  --class NAME             Top-level class
  --method CLASS.METHOD    Method inside a class

OPTIONS:
  --goal TEXT              Review goal
  --provider ollama|api    AI provider (default: ollama)
  --model NAME             Force specific model

Examples:
  genpy review app.py --function create_user
  genpy review main.py --lines 10-50 --goal "Improve error handling"
  genpy review models.py --class UserModel
EOF
}
