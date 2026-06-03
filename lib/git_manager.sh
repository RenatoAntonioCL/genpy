#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# GenPy — lib/git_manager.sh (v1.0.0-alpha)
#
# Git repository management for the generated project.
# Git is always initialized — the question is only about the remote.
#
# Returns the user's choice in GIT_MODE (local | private | public)
# so that wizard.sh can show it on the summary card before building.
# =============================================================================

source "${LIB_DIR:?}/utils.sh"

# Global variable that wizard.sh reads for the pre-confirmation summary
GIT_MODE="local"

# -----------------------------------------------------------------------------
# _get_github_token
#
# Searches for a GitHub token in: GITHUB_TOKEN, GH_TOKEN, or the `gh` CLI.
# Prints the token if found; returns 1 if none is available.
# -----------------------------------------------------------------------------
_get_github_token() {
  [[ -n "${GITHUB_TOKEN:-}" ]] && { printf '%s' "$GITHUB_TOKEN"; return 0; }
  [[ -n "${GH_TOKEN:-}" ]]     && { printf '%s' "$GH_TOKEN";     return 0; }
  if command -v gh &>/dev/null; then
    local token
    token=$(gh auth token 2>/dev/null) && [[ -n "$token" ]] && { printf '%s' "$token"; return 0; }
  fi
  return 1
}

# -----------------------------------------------------------------------------
# _create_github_repo
#
# Creates a repository on GitHub via REST API.
#
# Arguments:
#   $1 — token:        Personal Access Token with 'repo' permissions
#   $2 — repo_name:    name of the repository to create
#   $3 — private_flag: "true" or "false"
#
# Prints the SSH URL of the created repository; returns 1 on error.
# -----------------------------------------------------------------------------
_create_github_repo() {
  local token="$1"
  local repo_name="$2"
  local private_flag="$3"

  local json_body
  json_body=$(printf '{"name":"%s","private":%s,"auto_init":false}' \
    "$repo_name" "$private_flag")

  local tmpfile http_code body
  tmpfile=$(mktemp)
  # The token header is passed via stdin (-H @-), not as an argument, so that
  # it does NOT appear in the process list (ps). The POST body is passed via -d.
  http_code=$(printf 'Authorization: token %s\n' "$token" \
    | curl -s -o "$tmpfile" -w "%{http_code}" \
    -X POST \
    -H @- \
    -H "Accept: application/vnd.github.v3+json" \
    -H "Content-Type: application/json" \
    -d "$json_body" \
    https://api.github.com/user/repos 2>/dev/null)
  body=$(cat "$tmpfile")
  rm -f "$tmpfile"

  if [[ "$http_code" == "201" ]]; then
    if command -v jq &>/dev/null; then
      printf '%s' "$body" | jq -r '.ssh_url'
    else
      printf '%s' "$body" | grep -o '"ssh_url":"[^"]*"' | cut -d'"' -f4
    fi
    return 0
  else
    local err_msg="HTTP $http_code"
    if command -v jq &>/dev/null; then
      local api_msg
      api_msg=$(printf '%s' "$body" | jq -r '.message // empty' 2>/dev/null)
      [[ -n "$api_msg" ]] && err_msg="$api_msg"
    fi
    print_error "GitHub API: $err_msg"
    return 1
  fi
}

# -----------------------------------------------------------------------------
# _push_to_remote
#
# Connects the remote and pushes. Shows retry instructions on failure.
# -----------------------------------------------------------------------------
_push_to_remote() {
  local repo_url="$1"
  local visibility="$2"

  git remote add origin "$repo_url"
  git branch -M main

  echo -e "  📤 Pushing to $visibility repository..."
  if git push -u origin main -q; then
    print_success "Code pushed to $visibility repository: $repo_url"
  else
    print_error "Push failed. Verify your SSH keys or access token."
    echo -e "  ${DIM}To retry: git push -u origin main${NC}"
  fi
}

# -----------------------------------------------------------------------------
# setup_git_repository
#
# Runs the full git flow in the already-created project directory.
# For private/public mode it tries to create the repo on GitHub via API
# (reading GITHUB_TOKEN / GH_TOKEN / gh CLI). If no token is available
# it asks the user; if they prefer to skip it, falls back to the manual URL flow.
#
# Arguments:
#   $1 — target_dir:    absolute path to the project directory
#   $2 — project_name:  name of the project
# -----------------------------------------------------------------------------
setup_git_repository() {
  local target_dir="$1"
  local project_name="$2"

  print_section "Initializing Repository"

  cd "$target_dir" || {
    print_error "Could not access directory: $target_dir"
    return 1
  }

  git init -b main -q

  cat > .gitignore <<'EOF'
# Dependencies
node_modules/
vendor/

# Builds and compiled output
dist/
target/
*.exe

# Environment variables — never commit to the repository
.env
.env.local
.env.*.local

# Python virtual environments
env/
venv/

# macOS
.DS_Store

# Logs
*.log

# GenPy — internal working files
.genpy_*
EOF

  git add .

  if git diff --cached --quiet; then
    print_warning "No changes to commit — empty directory"
    return 0
  fi

  git commit -m "feat: initial project scaffold — $project_name (GenPy v1.0.0-alpha)" -q
  print_success "Repository initialized on branch main"

  # ── Remote mode ───────────────────────────────────────────────────────────
  [[ "$GIT_MODE" != "private" && "$GIT_MODE" != "public" ]] && return 0

  local visibility private_flag
  if [[ "$GIT_MODE" == "private" ]]; then
    visibility="PRIVATE"
    private_flag="true"
  else
    visibility="PUBLIC"
    private_flag="false"
  fi

  echo ""

  # ── Try to create the repository automatically via API ─────────────────────
  if ! command -v curl &>/dev/null; then
    print_warning "curl is not installed — automatic creation skipped."
    _fallback_manual_remote "$visibility"
    return 0
  fi

  local token=""
  token=$(_get_github_token 2>/dev/null) || true

  if [[ -z "$token" ]]; then
    echo -e "  ${DIM}GITHUB_TOKEN not found. Enter your Personal Access Token${NC}"
    echo -e "  ${DIM}('repo' permissions required — leave blank to enter URL manually):${NC}"
    IFS= read -rsp "  >>> " token
    echo ""
  fi

  if [[ -z "$token" ]]; then
    _fallback_manual_remote "$visibility"
    return 0
  fi

  echo -e "  🌐 Creating $visibility repository on GitHub..."
  local repo_url
  if repo_url=$(_create_github_repo "$token" "$project_name" "$private_flag"); then
    _push_to_remote "$repo_url" "$visibility"
  else
    print_warning "Automatic creation failed — enter the URL manually."
    _fallback_manual_remote "$visibility"
  fi
}

# -----------------------------------------------------------------------------
# _fallback_manual_remote  (internal)
# -----------------------------------------------------------------------------
_fallback_manual_remote() {
  local visibility="$1"
  echo ""
  echo -e "  ${DIM}Enter the remote repository URL:${NC}"
  echo -e "  ${DIM}(e.g.: git@github.com:user/repo.git)${NC}"
  read -rp "  >>> " repo_url

  if [[ -z "$repo_url" ]]; then
    print_warning "Empty URL — push skipped. You can connect it manually:"
    echo -e "  ${DIM}git remote add origin <url>${NC}"
    echo -e "  ${DIM}git push -u origin main${NC}"
    return 0
  fi

  _push_to_remote "$repo_url" "$visibility"
}

# =============================================================================
# AI review checkpoint — steps [2] and [10] of the genpy review flow
# (ARCHITECTURE.md §5.4)
#
# Output globals:
#   CHECKPOINT_BRANCH           — review branch created (genpy/review/<ts>)
#   CHECKPOINT_ORIGINAL_BRANCH  — branch that was current before the checkpoint
# =============================================================================

CHECKPOINT_BRANCH=""
CHECKPOINT_ORIGINAL_BRANCH=""

# -----------------------------------------------------------------------------
# create_checkpoint
#
# Creates a review branch from the current branch and switches to it.
# The branch acts as a safe return point: if the AI review fails or
# the user rejects it, rollback_to_checkpoint returns the project to
# the previous state without touching any live files.
#
# Arguments:
#   $1 — project_dir:    absolute path to the project repository
#   $2 — branch_prefix:  branch prefix (default: genpy/review)
#
# Sets: CHECKPOINT_BRANCH, CHECKPOINT_ORIGINAL_BRANCH
# Returns: 0=ok, 1=error
# -----------------------------------------------------------------------------
create_checkpoint() {
  local project_dir="$1"
  local branch_prefix="${2:-genpy/review}"

  # ── Validations ───────────────────────────────────────────────────────────

  if [[ ! -d "$project_dir" ]]; then
    echo "Error: directory not found: $project_dir" >&2
    return 1
  fi

  if ! git -C "$project_dir" rev-parse --git-dir &>/dev/null 2>&1; then
    echo "Error: not a git repository: $project_dir" >&2
    return 1
  fi

  if ! git -C "$project_dir" rev-parse --verify HEAD &>/dev/null 2>&1; then
    echo "Error: repository has no commits — make at least one commit first." >&2
    return 1
  fi

  local original_branch
  original_branch=$(git -C "$project_dir" branch --show-current 2>/dev/null)
  if [[ -z "$original_branch" ]]; then
    echo "Error: HEAD is in detached state — switch to a branch before creating the checkpoint." >&2
    return 1
  fi

  if ! git -C "$project_dir" diff --quiet HEAD 2>/dev/null; then
    echo "Error: working tree has uncommitted changes — commit or stash them first." >&2
    return 1
  fi

  # ── Create review branch ──────────────────────────────────────────────────

  local timestamp review_branch
  timestamp=$(date +%Y%m%d_%H%M%S)
  review_branch="${branch_prefix}/${timestamp}"

  if ! git -C "$project_dir" checkout -b "$review_branch" -q 2>/dev/null; then
    echo "Error: could not create branch '${review_branch}'." >&2
    return 1
  fi

  CHECKPOINT_BRANCH="$review_branch"
  CHECKPOINT_ORIGINAL_BRANCH="$original_branch"

  print_success "Checkpoint: branch '${review_branch}' created from '${original_branch}'"
  return 0
}

# -----------------------------------------------------------------------------
# rollback_to_checkpoint
#
# Returns to the original branch and deletes the review branch.
# Safe even if the review branch has uncommitted changes:
# uses -D (force delete) because the original tree remains intact at HEAD.
#
# Arguments:
#   $1 — project_dir: absolute path to the project repository
#
# Requires: CHECKPOINT_BRANCH and CHECKPOINT_ORIGINAL_BRANCH (set by create_checkpoint)
# Returns: 0=ok, 1=error
# -----------------------------------------------------------------------------
rollback_to_checkpoint() {
  local project_dir="$1"

  if [[ ! -d "$project_dir" ]]; then
    echo "Error: directory not found: $project_dir" >&2
    return 1
  fi

  if [[ -z "${CHECKPOINT_BRANCH:-}" ]]; then
    echo "Error: CHECKPOINT_BRANCH not set — call create_checkpoint first." >&2
    return 1
  fi

  if [[ -z "${CHECKPOINT_ORIGINAL_BRANCH:-}" ]]; then
    echo "Error: CHECKPOINT_ORIGINAL_BRANCH not set." >&2
    return 1
  fi

  # ── Return to the original branch ────────────────────────────────────────

  if ! git -C "$project_dir" checkout "$CHECKPOINT_ORIGINAL_BRANCH" -q 2>/dev/null; then
    echo "Error: could not switch back to branch '${CHECKPOINT_ORIGINAL_BRANCH}'." >&2
    return 1
  fi

  # ── Delete review branch (force — may have uncommitted work) ─────────────

  local deleted_branch="$CHECKPOINT_BRANCH"
  local original_branch="$CHECKPOINT_ORIGINAL_BRANCH"
  if git -C "$project_dir" show-ref --verify --quiet \
      "refs/heads/${CHECKPOINT_BRANCH}" 2>/dev/null; then
    git -C "$project_dir" branch -D "$CHECKPOINT_BRANCH" -q 2>/dev/null || true
  fi

  CHECKPOINT_BRANCH=""
  CHECKPOINT_ORIGINAL_BRANCH=""

  print_success "Rollback: back on '${original_branch}', branch '${deleted_branch}' deleted"
  return 0
}
