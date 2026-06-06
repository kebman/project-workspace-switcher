# Project Workspace Switcher
#
# Generic Zsh helper for switching between configured workspaces and repo/path slots.
#
# Core commands:
#   pws             show active workspace
#   pws ls          list configured workspaces
#   pws <name>      select workspace
#   pcd <repo>      cd to repo/path in active workspace
#   pg <repo>       cd to repo/path + git status
#   pag             git status for all repos/paths in active workspace
#
# Config:
#   Define PWS_WORKSPACES, PWS_REPOS and PWS_PATHS before sourcing this file,
#   or set PWS_CONFIG_FILE to a config file path.

typeset -g PWS_CONFIG_FILE="${PWS_CONFIG_FILE:-$HOME/.config/project-workspace-switcher/config.zsh}"
typeset -g PWS_DEFAULT_WORKSPACE="${PWS_DEFAULT_WORKSPACE:-main}"
typeset -g PWS_ACTIVE="${PWS_ACTIVE:-$PWS_DEFAULT_WORKSPACE}"

typeset -ga PWS_WORKSPACES
typeset -ga PWS_REPOS
typeset -gA PWS_WORKSPACE_LABELS
typeset -gA PWS_REPO_LABELS
typeset -gA PWS_PATHS

unfunction pws pcd pg pag 2>/dev/null

_pws_load_config() {
  if [[ -f "$PWS_CONFIG_FILE" ]]; then
    source "$PWS_CONFIG_FILE"
  fi

  PWS_ACTIVE="${PWS_ACTIVE:-$PWS_DEFAULT_WORKSPACE}"
}

_pws_has_item() {
  local needle="$1"
  shift

  local item
  for item in "$@"; do
    [[ "$item" == "$needle" ]] && return 0
  done

  return 1
}

_pws_require_config() {
  if (( ${#PWS_WORKSPACES[@]} == 0 )); then
    print -u2 -- "No workspaces configured. Define PWS_WORKSPACES in your config."
    return 1
  fi

  if (( ${#PWS_REPOS[@]} == 0 )); then
    print -u2 -- "No repo/path slots configured. Define PWS_REPOS in your config."
    return 1
  fi
}

_pws_workspace_exists() {
  _pws_has_item "$1" "${PWS_WORKSPACES[@]}"
}

_pws_repo_exists() {
  _pws_has_item "$1" "${PWS_REPOS[@]}"
}

_pws_workspace_label() {
  local workspace="$1"
  print -r -- "${PWS_WORKSPACE_LABELS[$workspace]:-$workspace}"
}

_pws_repo_label() {
  local repo="$1"
  print -r -- "${PWS_REPO_LABELS[$repo]:-$repo}"
}

_pws_path_key() {
  local workspace="$1"
  local repo="$2"
  print -r -- "${workspace}:${repo}"
}

_pws_repo_dir() {
  local workspace="$1"
  local repo="$2"
  local key

  key=$(_pws_path_key "$workspace" "$repo")
  print -r -- "${PWS_PATHS[$key]}"
}

_pws_print_current() {
  _pws_require_config || return 1

  if ! _pws_workspace_exists "$PWS_ACTIVE"; then
    print -u2 -- "Active workspace is not configured: $PWS_ACTIVE"
    return 1
  fi

  local repo repo_dir label
  print -r -- "Active workspace: $PWS_ACTIVE ($(_pws_workspace_label "$PWS_ACTIVE"))"

  for repo in "${PWS_REPOS[@]}"; do
    repo_dir=$(_pws_repo_dir "$PWS_ACTIVE" "$repo")
    label=$(_pws_repo_label "$repo")
    print -r -- "  $repo  $label  $repo_dir"
  done
}

_pws_print_list() {
  _pws_require_config || return 1

  local workspace marker
  print -r -- "Available workspaces:"

  for workspace in "${PWS_WORKSPACES[@]}"; do
    marker=" "
    [[ "$workspace" == "$PWS_ACTIVE" ]] && marker="*"
    print -r -- " $marker $workspace  $(_pws_workspace_label "$workspace")"
  done

  print
  print -r -- "Active workspace: $PWS_ACTIVE"
}

pws() {
  _pws_load_config
  _pws_require_config || return 1

  if [[ $# -eq 0 ]]; then
    _pws_print_current
    return
  fi

  case "$1" in
    ls|--list|-l)
      _pws_print_list
      return
      ;;
    help|--help|-h)
      print -r -- "Usage:"
      print -r -- "  pws              show active workspace"
      print -r -- "  pws ls           list configured workspaces"
      print -r -- "  pws <workspace>  select workspace"
      print -r -- "  pcd <repo>       cd to repo/path in active workspace"
      print -r -- "  pg <repo>        cd to repo/path + git status"
      print -r -- "  pag              git status for all repos/paths in active workspace"
      return
      ;;
  esac

  if ! _pws_workspace_exists "$1"; then
    print -u2 -- "Unknown workspace: $1"
    print -u2 -- "Run: pws ls"
    return 1
  fi

  typeset -g PWS_ACTIVE="$1"
  _pws_print_current
}

pcd() {
  _pws_load_config
  _pws_require_config || return 1

  local repo="$1"
  local repo_dir

  if [[ -z "$repo" ]]; then
    print -u2 -- "Usage: pcd <repo>"
    return 1
  fi

  if ! _pws_workspace_exists "$PWS_ACTIVE"; then
    print -u2 -- "Active workspace is not configured: $PWS_ACTIVE"
    return 1
  fi

  if ! _pws_repo_exists "$repo"; then
    print -u2 -- "Unknown repo/path slot: $repo"
    print -u2 -- "Configured slots: ${PWS_REPOS[*]}"
    return 1
  fi

  repo_dir=$(_pws_repo_dir "$PWS_ACTIVE" "$repo")

  if [[ -z "$repo_dir" ]]; then
    print -u2 -- "No path configured for workspace/repo: $PWS_ACTIVE / $repo"
    return 1
  fi

  if [[ ! -d "$repo_dir" ]]; then
    print -u2 -- "Missing directory: $repo_dir"
    return 1
  fi

  builtin cd "$repo_dir"
}

pg() {
  local repo="$1"
  local branch

  if [[ -z "$repo" ]]; then
    print -u2 -- "Usage: pg <repo>"
    return 1
  fi

  pcd "$repo" || return 1

  branch=$(command git branch --show-current 2>/dev/null)

  if [[ -n "$branch" ]]; then
    print -P "%~(${branch})"
  else
    print -P "%~"
  fi

  command git status
}

pag() {
  _pws_load_config
  _pws_require_config || return 1

  if ! _pws_workspace_exists "$PWS_ACTIVE"; then
    print -u2 -- "Active workspace is not configured: $PWS_ACTIVE"
    return 1
  fi

  local repo repo_dir branch label

  print -r -- "Active workspace: $PWS_ACTIVE ($(_pws_workspace_label "$PWS_ACTIVE"))"

  for repo in "${PWS_REPOS[@]}"; do
    repo_dir=$(_pws_repo_dir "$PWS_ACTIVE" "$repo")
    label=$(_pws_repo_label "$repo")

    print
    print -r -- "$repo  $label"
    print -r -- "$repo_dir"

    if [[ -z "$repo_dir" ]]; then
      print -r -- "No path configured."
      continue
    fi

    if [[ ! -d "$repo_dir" ]]; then
      print -r -- "Missing directory."
      continue
    fi

    branch=$(command git -C "$repo_dir" branch --show-current 2>/dev/null)

    if [[ -n "$branch" ]]; then
      print -r -- "branch: $branch"
    fi

    command git -C "$repo_dir" status
  done
}

_pws_load_config
