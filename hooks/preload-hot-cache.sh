#!/usr/bin/env bash
# Pre-load the global-memory hot cache into session context.
# Reads ~/Documents/Claude/Memory/CLAUDE.md (permalink "claude") and prints
# it so Claude sees the user's people, acronyms, and active projects on
# session start without having to call basic-memory MCP first.

set -euo pipefail

MEMORY_HOME="${BASIC_MEMORY_HOME:-$HOME/Documents/Claude/Memory}"
HOT_CACHE="$MEMORY_HOME/CLAUDE.md"

if [[ ! -f "$HOT_CACHE" ]]; then
  cat <<EOF
# global-memory: hot cache not found

Memory store at "$MEMORY_HOME" is empty or missing CLAUDE.md.
Suggest running /memory-bootstrap to seed it.
EOF
  exit 0
fi

cat <<EOF
# global-memory hot cache (auto-loaded)

The following is the user's global memory hot cache. Treat the people,
acronyms, nicknames, and active projects below as known context for this
session. For anything not covered here, call mcp__basic-memory__read_note
with permalink "glossary", "people/<slug>", or "projects/<slug>".

---

EOF

cat "$HOT_CACHE"
