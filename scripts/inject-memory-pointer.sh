#!/usr/bin/env bash
# Inject the global-memory pointer block into per-project CLAUDE.md
# files. Auto-creates CLAUDE.md when missing. Idempotent — files that
# already contain the marker are skipped. Bash 3.2 compatible (macOS).
#
# Behaviour: the passed root is the project umbrella. The script
# creates CLAUDE.md in the root if missing and appends the pointer
# block when not yet present. For direct subdirectories the script is
# append-only — it adds the pointer to existing CLAUDE.md files but
# never creates new ones. Hidden and noise directories (.git,
# node_modules, .vscode, etc.) are skipped.
#
# Usage:
#   ./scripts/inject-memory-pointer.sh                 # default root
#   ./scripts/inject-memory-pointer.sh ~/Projects/Foo  # custom root
#
# Default root: ~/Documents/Claude.

set -euo pipefail

ROOT="${1:-$HOME/Documents/Claude}"
MARKER="<!-- global-memory-pointer -->"

if [[ ! -d "$ROOT" ]]; then
  echo "Root not found: $ROOT" >&2
  exit 1
fi

ROOT="$(cd "$ROOT" && pwd -P)"

# Noise directories never treated as project roots.
SKIP_NAMES='^(\.|node_modules$|venv$|\.venv$|__pycache__$|dist$|build$|target$|out$|\.next$|\.cache$|\.idea$|\.vscode$|\.DS_Store$)'

read -r -d '' BLOCK <<'EOF' || true
<!-- global-memory-pointer -->
## Global memory

This machine has a cross-project memory store served by the
`basic-memory` MCP server (plugin: `global-memory`). When you encounter
a person, acronym, codename, project shortname, or "remember this"
request, do not assume — call the MCP first:

- `mcp__basic-memory__read_note` with permalink `claude` (hot cache)
- then `glossary`, `people/<slug>`, or `projects/<slug>` for depth
- `mcp__basic-memory__search_notes` for fuzzy matches
- `mcp__basic-memory__write_note` to record new facts

The hot cache is auto-loaded at session start when this plugin is
installed. Treat it as authoritative for who/what is being referenced.
<!-- /global-memory-pointer -->
EOF

created=0
injected=0
skipped=0

# Process a single directory.
# $1 = directory, $2 = "create" to allow file creation, anything else
# means append-only (skip if CLAUDE.md does not exist).
process_dir() {
  local dir="$1"
  local mode="$2"
  local file="$dir/CLAUDE.md"
  if [[ -f "$file" ]]; then
    if grep -qF "$MARKER" "$file"; then
      skipped=$((skipped + 1))
      return
    fi
    printf '\n%s\n' "$BLOCK" >> "$file"
    injected=$((injected + 1))
    echo "injected: $file"
  elif [[ "$mode" == "create" ]]; then
    printf '%s\n' "$BLOCK" > "$file"
    created=$((created + 1))
    echo "created:  $file"
  fi
}

# Root: create CLAUDE.md if missing.
process_dir "$ROOT" "create"

# Direct subdirectories: append-only (never create).
while IFS= read -r -d '' dir; do
  name="$(basename "$dir")"
  if [[ "$name" =~ $SKIP_NAMES ]]; then
    continue
  fi
  process_dir "$dir" "append-only"
done < <(find "$ROOT" -mindepth 1 -maxdepth 1 -type d -print0)

echo
echo "Done. Created: $created. Injected: $injected. Skipped (already had marker): $skipped."
