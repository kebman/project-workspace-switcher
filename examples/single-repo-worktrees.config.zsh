# Example config for one repository with several Git worktrees.
#
# Copy this file to:
#   ~/.config/project-workspace-switcher/config.zsh
#
# Then edit workspace names, slot names and paths for your own machine.

typeset -g PWS_DEFAULT_WORKSPACE="main"

typeset -ga PWS_WORKSPACES=(
  main
  feature-a
  bugfix-b
)

typeset -ga PWS_REPOS=(
  app
)

typeset -gA PWS_WORKSPACE_LABELS=(
  [main]="Main checkout"
  [feature-a]="Feature A worktree"
  [bugfix-b]="Bugfix B worktree"
)

typeset -gA PWS_REPO_LABELS=(
  [app]="Application"
)

typeset -gA PWS_PATHS=(
  [main:app]="$HOME/projects/my-app"
  [feature-a:app]="$HOME/projects/worktrees/my-app-feature-a"
  [bugfix-b:app]="$HOME/projects/worktrees/my-app-bugfix-b"
)

# Optional ergonomic aliases. Change freely.
alias app='pcd app'
alias appg='pg app'
alias allg='pag'
