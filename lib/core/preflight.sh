#!/usr/bin/env bash
# lib/core/preflight.sh

source "$LIB_DIR/core/errors.sh"
source "$LIB_DIR/docker.sh"

preflight_mode_review() {
  local status=0
  print_section "Preflight — genpy review"

  require_command "curl" "curl is required to communicate with the AI provider."

  # Clean working tree — create_checkpoint also verifies this, but
  # it's better to fail here with a clear message before creating the branch.
  local git_dirty
  git_dirty=$(git status --porcelain 2>/dev/null || true)
  if [[ -n "$git_dirty" ]]; then
    print_error "Working tree has uncommitted changes. Commit or stash them first."
    status=1
  fi

  # Ollama accessible
  local ollama_host="${OLLAMA_HOST:-http://localhost:11434}"
  if ! curl -s --max-time 3 "${ollama_host}/api/tags" &>/dev/null; then
    print_error "Ollama is not responding at ${ollama_host}. Verify that it is running."
    status=1
  fi

  return "$status"
}

preflight_mode_create() {
    local status=0
    echo -e "\n🔍 Running preflight checks..."

    # 1. Validate essential commands (Invariant P2)
    require_command "docker" "Install Docker Desktop to continue."
    require_command "git" "Git is required for version control."

    # 2. Docker daemon health (reuses lib/docker.sh)
    if ! check_docker_daemon; then
        status=1
    fi

    # 3. Disk space (>500MB) to avoid rsync failures
    local free_kb
    free_kb=$(df -k . | awk 'NR==2 {print $4}')
    if [[ $free_kb -lt 512000 ]]; then
        print_warning "Low disk space (<500MB). The build may fail."
    fi

    # 4. Write permissions in the current directory
    if [[ ! -w "." ]]; then
        print_error "You do not have write permissions in this directory."
        status=1
    fi

    return $status
}
