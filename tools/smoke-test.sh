#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
ENGINE="$REPO_ROOT/zsh/project-workspace-switcher.zsh"
THREE_REPO_CONFIG="$REPO_ROOT/examples/three-repo-workspaces.config.zsh"
SINGLE_REPO_CONFIG="$REPO_ROOT/examples/single-repo-worktrees.config.zsh"

section() {
  printf '\n== %s ==\n' "$1"
}

require_zsh() {
  section "Checking dependencies"

  if ! command -v zsh >/dev/null 2>&1; then
    printf 'zsh is required but was not found on PATH.\n' >&2
    exit 1
  fi

  printf 'zsh found: %s\n' "$(command -v zsh)"
}

syntax_check() {
  section "Checking Zsh syntax"

  zsh -n "$ENGINE"
  zsh -n "$THREE_REPO_CONFIG"
  zsh -n "$SINGLE_REPO_CONFIG"

  printf 'Syntax checks passed.\n'
}

run_workspace_smoke() {
  local label="$1"
  local config_file="$2"
  local workspace="$3"

  section "Smoke test: $label"

  PWS_CONFIG_FILE="$config_file" PWS_EXPECTED_WORKSPACE="$workspace" PWS_REPO_ROOT="$REPO_ROOT" zsh -f <<'EOF'
source "$PWS_REPO_ROOT/zsh/project-workspace-switcher.zsh" || exit 1

pws ls >/dev/null || exit 1
pws "$PWS_EXPECTED_WORKSPACE" >/dev/null || exit 1

current_output="$(pws)" || exit 1
if [[ "$current_output" != *"Active workspace: $PWS_EXPECTED_WORKSPACE "* ]]; then
  print -u2 -- "Expected active workspace not found in pws output."
  print -u2 -- "$current_output"
  exit 1
fi

if pws unknown-workspace >/dev/null 2>&1; then
  print -u2 -- "Unknown workspace unexpectedly succeeded."
  exit 1
fi
EOF

  printf 'Workspace selection checks passed.\n'
}

main() {
  cd "$REPO_ROOT"

  require_zsh
  syntax_check
  run_workspace_smoke "multi-repo workspace example" "$THREE_REPO_CONFIG" "feature-a"
  run_workspace_smoke "single-repo worktree example" "$SINGLE_REPO_CONFIG" "bugfix-b"

  section "Result"
  printf 'Smoke tests passed.\n'
}

main "$@"
