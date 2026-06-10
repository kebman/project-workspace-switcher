# Project Workspace Switcher

Small Zsh helper for switching between named project workspaces and repo/path slots.

Useful when you work with:

- several Git worktrees;
- several related repositories;
- several parallel branches or task stacks;
- terminal sessions that should each stay attached to a different context.

The tool is generic. Your private project names and paths live in your local config file.

## Core commands

Show active workspace:

```bash
pws
```

List configured workspaces:

```bash
pws ls
```

Select a workspace:

```bash
pws main
pws feature-a
```

Navigate to a repo/path slot in the active workspace:

```bash
pcd api
pcd web
pcd docs
```

Navigate and show Git status:

```bash
pg api
pg web
pg docs
```

Show Git status for all configured repo/path slots in the active workspace:

```bash
pag
```

## Interactive picking

If `fzf` is installed, you can select workspaces and repo/path slots interactively:

```bash
pws pick
pcd pick
pg pick
```

`fzf` is optional. Without it, use the normal commands:

```bash
pws ls
pws feature-a
pcd web
pg web
```

## Configuration

The default config path is:

```text
~/.config/project-workspace-switcher/config.zsh
```

Example config:

```zsh
typeset -g PWS_DEFAULT_WORKSPACE="main"

typeset -ga PWS_WORKSPACES=(
  main
  feature-a
)

typeset -ga PWS_REPOS=(
  api
  web
  docs
)

typeset -gA PWS_PATHS=(
  [main:api]="$HOME/projects/my-api"
  [main:web]="$HOME/projects/my-web"
  [main:docs]="$HOME/projects/my-docs"

  [feature-a:api]="$HOME/projects/workspaces/feature-a/api"
  [feature-a:web]="$HOME/projects/workspaces/feature-a/web"
  [feature-a:docs]="$HOME/projects/workspaces/feature-a/docs"
)
```

See:

```text
examples/three-repo-workspaces.config.zsh
examples/single-repo-worktrees.config.zsh
docs/design.md
```

## Examples

- Multi-repo workspace example: `examples/three-repo-workspaces.config.zsh`
- Single-repo worktree example: `examples/single-repo-worktrees.config.zsh`

## Public-safe examples

Examples use placeholders such as `my-app`, `my-api`, `feature-a` and `~/projects/my-app`. They should not contain real private project names, repository names or paths.

## Validation

Run the repo-local smoke test:

```bash
tools/smoke-test.sh
```

## Install

Source the engine from `~/.zshrc`:

```zsh
source "$HOME/projects/project-workspace-switcher/zsh/project-workspace-switcher.zsh"
```

Reload Zsh:

```bash
source ~/.zshrc
```

## Ergonomic aliases

The core commands are intentionally generic. Add your own aliases in your private config.

Example:

```zsh
alias api='pcd api'
alias web='pcd web'
alias docs='pcd docs'

alias apig='pg api'
alias webg='pg web'
alias docsg='pg docs'

alias allg='pag'
```

You can also preserve old muscle memory:

```zsh
alias oldselector='pws'
alias oldrepo='pcd web'
alias oldrepog='pg web'
```

## Git worktree note

This tool does not create Git worktrees. It only helps you switch between paths you have already configured.

Create worktrees with Git first, then add their paths to your config.

## License

MIT. See [LICENSE](LICENSE).
