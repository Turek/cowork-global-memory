#!/usr/bin/env bash
# Append a session-close entry to today's daily note in Basic Memory.
# Called by Claude Code's Stop hook after every session ends.
# Creates today's daily file if it does not exist. Idempotent on the
# timestamp — two closes in the same minute produce two entries.
#
# Basic Memory stores notes as plain markdown files on disk. This script
# writes directly to disk so it works without the MCP server running.
#
# Configure BASIC_MEMORY_HOME in your shell profile if your vault lives
# somewhere other than ~/Documents/Claude/Memory:
#   export BASIC_MEMORY_HOME=/path/to/your/memory

set -euo pipefail

MEMORY_HOME="${BASIC_MEMORY_HOME:-$HOME/Documents/Claude/Memory}"
TODAY=$(date +%Y-%m-%d)
NOW=$(date +%H:%M)
DAILY_DIR="$MEMORY_HOME/daily"
DAILY_FILE="$DAILY_DIR/$TODAY.md"

mkdir -p "$DAILY_DIR"

# Read hook context from stdin — best-effort, do not fail if absent.
CONTEXT=""
if IFS= read -r -t 2 CONTEXT 2>/dev/null; then
  :
fi

# Extract session_id from JSON context if python3 is available.
SESSION_ID=""
if [[ -n "$CONTEXT" ]] && command -v python3 &>/dev/null; then
  SESSION_ID=$(python3 -c "
import sys, json
try:
    d = json.loads(sys.stdin.read())
    print(d.get('session_id', ''))
except Exception:
    print('')
" <<< "$CONTEXT" 2>/dev/null || true)
fi

SESSION_LABEL="${SESSION_ID:+session $SESSION_ID}"
SESSION_LABEL="${SESSION_LABEL:-session}"

# Create daily file with frontmatter if it does not exist yet.
if [[ ! -f "$DAILY_FILE" ]]; then
  cat > "$DAILY_FILE" <<EOF
---
title: $TODAY
type: daily
permalink: daily/$TODAY
tags: [daily]
---

# $TODAY
EOF
fi

# Append the session-close marker.
cat >> "$DAILY_FILE" <<EOF

## Session closed — $NOW

Claude Code $SESSION_LABEL ended. If anything worth keeping happened this
session, capture it before context is lost:

  /remember <fact>

EOF
