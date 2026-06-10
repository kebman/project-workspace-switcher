# Design

Project Workspace Switcher separates a small generic engine from user-local configuration.

The engine lives in `zsh/project-workspace-switcher.zsh`. It provides command behaviour, validation, workspace selection and path lookup. User-specific names, labels and paths live outside the engine in a config file, usually `~/.config/project-workspace-switcher/config.zsh`. This keeps the reusable code public-safe while letting each user model their own projects privately.

## Generic Commands

The core commands are deliberately short and neutral:

- `pws` selects or prints the active workspace.
- `pcd` changes directory to a repo/path slot in the active workspace.
- `pg` changes directory to a slot and runs `git status`.
- `pag` runs `git status` across every configured slot in the active workspace.

These names describe generic actions instead of any specific project. They are suitable for a shared tool because they do not encode a user's organisation, repository names, branch names or local filesystem layout.

## User Aliases

Aliases are intentionally left to user config. A user can add aliases such as `alias app='pcd app'` or `alias allg='pag'`, but the engine does not ship project-specific shortcuts.

This keeps the shared tool stable and avoids publishing private naming habits. It also lets different users choose aliases that fit their own shell workflow without changing the engine.

## Session-Local Selection

Workspace selection is per terminal session. When `pws feature-a` runs, it updates the `PWS_ACTIVE` shell variable in that shell process. Other terminal tabs or windows keep their own active workspace.

This is useful when separate terminals need to stay attached to different task contexts at the same time.

## Optional Picker

Interactive picker commands use `fzf` when it is available, but the core engine remains non-interactive and scriptable. `pws pick`, `pcd pick` and `pg pick` improve terminal ergonomics without making `fzf` a required dependency.

## Git Worktrees

This tool does not create Git worktrees. Git already owns worktree creation, removal and metadata. Project Workspace Switcher only switches between paths that already exist and are listed in config.

Create or remove worktrees with Git, then update `PWS_PATHS` so the switcher knows where each workspace and repo/path slot lives.

## Supported Layouts

The same data model supports both common layouts:

- Multi-repo workspaces, where one workspace contains several related repositories such as `api`, `web` and `docs`.
- Single-repo multi-worktree setups, where one repo/path slot such as `app` points to different worktree directories for `main`, `feature-a` and `bugfix-b`.

The engine treats both layouts as workspace names crossed with repo/path slots. It does not need to know whether each path is a separate repository, a Git worktree, or another useful directory.

## Data Model

User config defines these shell variables:

- `PWS_WORKSPACES`: ordered workspace names, for example `main`, `feature-a`, `bugfix-b`.
- `PWS_REPOS`: ordered repo/path slot names, for example `api`, `web`, `docs` or just `app`.
- `PWS_PATHS`: associative array keyed by `workspace:repo`, with each value pointing to the local directory for that pair.
- Optional `PWS_WORKSPACE_LABELS`: human-readable labels for workspaces.
- Optional `PWS_REPO_LABELS`: human-readable labels for repo/path slots.

Example key shape:

```zsh
typeset -gA PWS_PATHS=(
  [main:app]="$HOME/projects/my-app"
  [feature-a:app]="$HOME/projects/worktrees/my-app-feature-a"
)
```

## Public-Safe Examples

Examples must avoid real private project names, real repository names, personal usernames and concrete private paths. Use neutral placeholders such as `my-app`, `my-api`, `my-web`, `my-docs`, `feature-a`, `bugfix-b`, `~/projects/my-app` and `~/projects/worktrees/my-app-feature-a`.

## Smoke Test

The repo-local smoke test validates engine syntax, example config syntax and basic workspace selection behaviour. It does not validate real filesystem path existence, because example paths are placeholders by design.
