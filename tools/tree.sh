#!/usr/bin/env bash
# scripts/show-doc-tree.sh - Tree w/ sizes for documentation printouts (depth + archive-* ignores)

set -euo pipefail

# Defaults suited for printing docs trees
readonly DEFAULT_IGNORE_DIRS=(".git" "node_modules" "queries" "run-logs" "dev-logs")
readonly ALWAYS_IGNORE_GLOB='archive*'   # always ignored unless --include-archives
readonly DEFAULT_DEPTH=99                 # effectively unlimited unless overridden

# Some terminals/fonts render Unicode box-drawing "│" poorly (or it disappears in copy/paste).
# Use ASCII '|' for reliable output.
readonly VERT="|"

readonly BOLD=$(tput bold 2>/dev/null || echo "")
readonly RESET=$(tput sgr0 2>/dev/null || echo "")

usage() {
  cat << EOF
Usage: $0 [OPTIONS] [DIRECTORY]

Show directory tree with file/folder sizes, tailored for documentation printouts.

OPTIONS:
  -d, --depth N           Max directory recursion depth (1,2,3,...) [default: unlimited]
  -i, --ignore DIR        Ignore directory name (repeatable)
  --no-defaults           Don't ignore default directories (.git, node_modules)
  --include-archives      Do NOT ignore archive* directories
  -h, --help              Show this help

EXAMPLES:
  $0 documentation
  $0 -d 3 documentation
  $0 -d 4 -i dist -i build documentation
  $0 --no-defaults --include-archives -d 2 documentation

Default ignored directories: ${DEFAULT_IGNORE_DIRS[*]}
Always ignored (unless --include-archives): ${ALWAYS_IGNORE_GLOB}
EOF
}

# ---------- helpers ----------

format_size() {
  local size="$1"
  if command -v numfmt >/dev/null 2>&1; then
    numfmt --to=iec --suffix=B "$size" 2>/dev/null || echo "${size}B"
  else
    if ((size >= 1073741824)); then
      awk "BEGIN{printf \"%.1fGB\n\", $size/1073741824}"
    elif ((size >= 1048576)); then
      awk "BEGIN{printf \"%.1fMB\n\", $size/1048576}"
    elif ((size >= 1024)); then
      awk "BEGIN{printf \"%.1fKB\n\", $size/1024}"
    else
      printf "%dB\n" "$size"
    fi
  fi
}

get_dir_size() {
  local dir="$1"
  timeout 5s du -sb "$dir" 2>/dev/null | awk '{print $1}' || echo "0"
}

get_file_size() {
  local file="$1"
  if [[ -r "$file" ]]; then
    stat --format="%s" "$file" 2>/dev/null || stat -f "%z" "$file" 2>/dev/null || echo "0"
  else
    echo "0"
  fi
}

validate_directory() {
  local dir="$1"
  [[ -d "$dir" ]] || { printf 'Error: "%s" is not a directory\n' "$dir" >&2; return 1; }
  [[ -r "$dir" ]] || { printf 'Error: Cannot read directory "%s"\n' "$dir" >&2; return 1; }
}

# ---------- argument parsing ----------

parse_args() {
  local start_dir="."
  local depth="$DEFAULT_DEPTH"
  local use_defaults=true
  local include_archives=false
  local ignore_dirs=()

  # start with defaults (can be cleared by --no-defaults)
  ignore_dirs=("${DEFAULT_IGNORE_DIRS[@]}")

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -d|--depth)
        [[ -n "${2:-}" ]] || { echo "Error: --depth requires a number" >&2; exit 1; }
        [[ "$2" =~ ^[0-9]+$ ]] || { echo "Error: --depth must be an integer" >&2; exit 1; }
        depth="$2"
        shift 2
        ;;
      -i|--ignore)
        [[ -n "${2:-}" ]] || { echo "Error: --ignore requires a directory name" >&2; exit 1; }
        ignore_dirs+=("$2")
        shift 2
        ;;
      --no-defaults)
        use_defaults=false
        ignore_dirs=()
        shift
        ;;
      --include-archives)
        include_archives=true
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      -*)
        echo "Error: Unknown option $1" >&2
        usage >&2
        exit 1
        ;;
      *)
        start_dir="$1"
        shift
        ;;
    esac
  done

  # Build ignore regex from explicit dir names
  local ignore_regex="^$"  # match nothing by default
  if [[ ${#ignore_dirs[@]} -gt 0 ]]; then
    local IFS="|"
    ignore_regex="^(${ignore_dirs[*]})$"
  fi

  printf '%s\n%s\n%s\n%s\n' "$start_dir" "$depth" "$ignore_regex" "$include_archives"
}

# ---------- tree logic ----------

# Return 0 if should skip, 1 otherwise
should_skip_dir() {
  local base="$1"
  local ignore_regex="$2"
  local include_archives="$3"

  # archive-* handling
  if [[ "$include_archives" != "true" ]]; then
    [[ "$base" == $ALWAYS_IGNORE_GLOB ]] && return 0
  fi

  # explicit ignore list (exact-name match via regex)
  if [[ -n "$ignore_regex" && "$ignore_regex" != "^$" ]] && [[ "$base" =~ $ignore_regex ]]; then
    return 0
  fi

  return 1
}

build_items_array() {
  local dir="$1"
  local ignore_regex="$2"
  local include_archives="$3"
  local -n items_ref=$4

  items_ref=()
  while IFS= read -r -d '' item; do
    local base
    base=$(basename "$item")
    if [[ -d "$item" ]]; then
      if should_skip_dir "$base" "$ignore_regex" "$include_archives"; then
        continue
      fi
    fi
    items_ref+=("$item")
  done < <(find "$dir" -mindepth 1 -maxdepth 1 -print0 2>/dev/null | sort -z)
}

tree_draw() {
  local dir="$1"
  local prefix="$2"
  local ignore_regex="$3"
  local include_archives="$4"
  local depth_left="$5"

  # depth_left: how many more directory levels to traverse
  # If 0, we still list files/dirs at this level but do not recurse into subdirs.
  local items=()
  build_items_array "$dir" "$ignore_regex" "$include_archives" items

  local total=${#items[@]}
  local i
  for i in "${!items[@]}"; do
    local item="${items[$i]}"
    local base
    base=$(basename "$item")

    local is_last=$((i == total - 1))
    local treechar="├──"
    [[ $is_last -eq 1 ]] && treechar="└──"

    if [[ -d "$item" ]]; then
      local size size_fmt
      size=$(get_dir_size "$item")
      size_fmt=$(format_size "$size")

      printf '%s%s %s%s/%s (%s)\n' \
        "$prefix" "$treechar" "$BOLD" "$base" "$RESET" "$size_fmt"

      if (( depth_left > 0 )); then
        local newprefix
        if [[ $is_last -eq 1 ]]; then
	  newprefix="${prefix}    "
        else
	  newprefix="${prefix}│   "
        fi
        tree_draw "$item" "$newprefix" "$ignore_regex" "$include_archives" $((depth_left - 1))
      fi
    else
      local size size_fmt
      size=$(get_file_size "$item")
      size_fmt=$(format_size "$size")

      printf '%s%s %s (%s)\n' \
        "$prefix" "$treechar" "$base" "$size_fmt"
    fi
  done
}

error_handler() {
  local line_no=$1
  printf 'Error occurred on line %d\n' "$line_no" >&2
  exit 1
}
trap 'error_handler $LINENO' ERR

main() {
  local start_dir depth ignore_regex include_archives
  {
    read -r start_dir
    read -r depth
    read -r ignore_regex
    read -r include_archives
  } < <(parse_args "$@")

  validate_directory "$start_dir" || exit 1

  # Print ignore summary to stderr (doesn't pollute printout if you redirect stdout)
  if [[ "$include_archives" != "true" ]]; then
    echo "Ignoring directories matching: ${ALWAYS_IGNORE_GLOB}" >&2
  fi
  if [[ "$ignore_regex" != "^$" ]]; then
    echo "Ignoring directories (exact names): ${ignore_regex}" >&2
  fi
  echo >&2

  printf 'Directory tree for: %s\n' "$(realpath "$start_dir" 2>/dev/null || echo "$start_dir")"
  echo

  # depth=1 means: show root entries, no recursion into subdirs
  local depth_left
  if (( depth <= 0 )); then
    depth_left=0
  else
    depth_left=$((depth - 1))
  fi

  tree_draw "$start_dir" "" "$ignore_regex" "$include_archives" "$depth_left"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
