# Example config for Project Workspace Switcher.
#
# Copy this file to:
#   ~/.config/project-workspace-switcher/config.zsh
#
# Then edit workspace names, repo names and paths for your own machine.

typeset -g PWS_DEFAULT_WORKSPACE="main"

typeset -ga PWS_WORKSPACES=(
  main
  feature-a
  feature-b
)

typeset -ga PWS_REPOS=(
  api
  web
  docs
)

typeset -gA PWS_WORKSPACE_LABELS=(
  [main]="Stable main checkouts"
  [feature-a]="Feature A worktrees"
  [feature-b]="Feature B worktrees"
)

typeset -gA PWS_REPO_LABELS=(
  [api]="API / backend"
  [web]="Web frontend"
  [docs]="Documentation"
)

typeset -gA PWS_PATHS=(
  [main:api]="$HOME/projects/my-api"
  [main:web]="$HOME/projects/my-web"
  [main:docs]="$HOME/projects/my-docs"

  [feature-a:api]="$HOME/projects/workspaces/feature-a/api"
  [feature-a:web]="$HOME/projects/workspaces/feature-a/web"
  [feature-a:docs]="$HOME/projects/workspaces/feature-a/docs"

  [feature-b:api]="$HOME/projects/workspaces/feature-b/api"
  [feature-b:web]="$HOME/projects/workspaces/feature-b/web"
  [feature-b:docs]="$HOME/projects/workspaces/feature-b/docs"
)

# Optional ergonomic aliases. Change freely.
alias api='pcd api'
alias web='pcd web'
alias docs='pcd docs'

alias apig='pg api'
alias webg='pg web'
alias docsg='pg docs'

alias allg='pag'
