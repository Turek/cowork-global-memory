#!/usr/bin/env bash
# Inject the global-memory pointer block into per-project CLAUDE.md
# files under ~/Documents/Claude/Project*/. Idempotent — files that
# already contain the marker are skipped.
#
# Usage:
#   ./scripts/inject-memory-pointer.sh           # default root
#   ./scripts/inject-memory-pointer.sh /custom   # custom root

set -euo pipefail

ROOT="${1:-$HOME/Documents/Claude}"
MARKER="<!-- global-memory-pointer -->"

if [[ ! -d "$ROOT" ]]; then
  echo "Root not found: $ROOT" >&2
  exit 1
fi

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

injected=0
skipped=0
created=0

while IFS= read -r -d '' file; do
  if grep -qF "$MARKER" "$file"; then
    skipped=$((skipped + 1))
    continue
  fi
  printf '\n%s\n' "$BLOCK" >> "$file"
  injected=$((injected + 1))
  echo "injected: $file"
done < <(find "$ROOT" -maxdepth 3 -type f -name 'CLAUDE.md' -path "$ROOT/Project*/*" -print0)

echo
echo "Done. Injected: $injected. Skipped (already had marker): $skipped."

if [[ $injected -eq 0 && $skipped -eq 0 ]]; then
  echo "No CLAUDE.md found under $ROOT/Project*/. Nothing to do."
fi
