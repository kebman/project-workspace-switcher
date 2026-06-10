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

run_command_smoke() {
  local tmp_dir
  local config_file

  section "Smoke test: command behaviour"

  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' RETURN
  config_file="$tmp_dir/config.zsh"

  mkdir -p "$tmp_dir/main/api" "$tmp_dir/main/web" "$tmp_dir/feature-a/api" "$tmp_dir/feature-a/web"
  git -C "$tmp_dir/main/api" init -q
  git -C "$tmp_dir/main/web" init -q

  {
    printf 'typeset -g PWS_DEFAULT_WORKSPACE="main"\n'
    printf 'typeset -ga PWS_WORKSPACES=(main feature-a)\n'
    printf 'typeset -ga PWS_REPOS=(api web)\n'
    printf 'typeset -gA PWS_WORKSPACE_LABELS=([main]="Stable main checkouts" [feature-a]="Feature A worktrees")\n'
    printf 'typeset -gA PWS_REPO_LABELS=([api]="API / backend" [web]="Web frontend")\n'
    printf 'typeset -gA PWS_PATHS=(\n'
    printf '  [main:api]="%s/main/api"\n' "$tmp_dir"
    printf '  [main:web]="%s/main/web"\n' "$tmp_dir"
    printf '  [feature-a:api]="%s/feature-a/api"\n' "$tmp_dir"
    printf '  [feature-a:web]="%s/feature-a/web"\n' "$tmp_dir"
    printf ')\n'
  } >"$config_file"

  PWS_CONFIG_FILE="$config_file" PWS_TMP_DIR="$tmp_dir" PWS_REPO_ROOT="$REPO_ROOT" zsh -f <<'EOF'
source "$PWS_REPO_ROOT/zsh/project-workspace-switcher.zsh" || exit 1

help_output="$(pws help)" || exit 1
for expected in \
  "pws pick         interactively select workspace with fzf" \
  "pcd pick         interactively cd to repo/path with fzf" \
  "pg pick          interactively cd + git status with fzf"; do
  if [[ "$help_output" != *"$expected"* ]]; then
    print -u2 -- "Expected help line not found: $expected"
    exit 1
  fi
done

pws feature-a >/dev/null || exit 1
pws main >/dev/null || exit 1
pcd api || exit 1
if [[ "$PWD" != "$PWS_TMP_DIR/main/api" ]]; then
  print -u2 -- "pcd did not change to the expected directory."
  exit 1
fi

pg web >/dev/null || exit 1
pag >/dev/null || exit 1

PWS_FZF_BIN="__pws_missing_fzf__"
for command_line in "pws pick" "pcd pick" "pg pick"; do
  if output="$(eval "$command_line" 2>&1)"; then
    print -u2 -- "$command_line unexpectedly succeeded without fzf."
    exit 1
  fi

  if [[ "$output" != *"fzf is not installed"* ]]; then
    print -u2 -- "$command_line did not report missing fzf."
    print -u2 -- "$output"
    exit 1
  fi
done
EOF

  rm -rf "$tmp_dir"
  printf 'Command behaviour checks passed.\n'
  trap - RETURN
}

main() {
  cd "$REPO_ROOT"

  require_zsh
  syntax_check
  run_workspace_smoke "multi-repo workspace example" "$THREE_REPO_CONFIG" "feature-a"
  run_workspace_smoke "single-repo worktree example" "$SINGLE_REPO_CONFIG" "bugfix-b"
  run_command_smoke

  section "Result"
  printf 'Smoke tests passed.\n'
}

main "$@"
