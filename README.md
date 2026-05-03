# global-memory

Cross-project workplace memory for Cowork. Plain markdown on disk,
indexed and served by the Basic Memory MCP server, used by a forked
`memory-management` skill so the same memory works from any selected
workspace folder.

This is a fork of the upstream `productivity:memory-management` skill
that swaps direct file I/O for MCP calls. Same data model, same files
on disk, but accessible regardless of which folder Cowork has mounted.

## What's inside

- `skills/memory-management/SKILL.md` — the forked skill. Triggers on
  memory-related requests and uses Basic Memory MCP tools instead of
  Read/Write/Edit.
- `.mcp.json` — registers the `basic-memory` MCP server, pointed at
  `$HOME/Documents/Claude/Memory/` by default.
- `.claude-plugin/plugin.json` — Cowork plugin manifest.

## Prerequisites

1. A populated memory directory at `~/Documents/Claude/Memory/`. Minimum
   contents: `CLAUDE.md` (permalink `claude`), `glossary.md`,
   `preferences.md`. Folders for `people/`, `projects/`, `decisions/`,
   `daily/`, `context/` are conventional.
2. Basic Memory installed:

   ```bash
   brew tap basicmachines-co/basic-memory
   brew install basic-memory
   ```

## Install

### Option 1 — From GitHub (recommended)

In Claude Code or Cowork:

```
/plugin marketplace add Turek/cowork-global-memory
/plugin install global-memory@cowork-global-memory
```

### Option 2 — `.plugin` file

Drag the built `global-memory.plugin` file into Cowork. Confirm install
when prompted.

### Option 3 — From local source

Clone this repo somewhere stable, then in Cowork:

```bash
claude plugins add /path/to/global-memory
```

Or build a `.plugin` from source:

```bash
cd global-memory
zip -r /tmp/global-memory.plugin . -x "*.DS_Store" -x ".git/*"
```

Then drag `/tmp/global-memory.plugin` into Cowork.

## Configuration

`.mcp.json` expands `$HOME` at launch via `bash -lc`, so the default
memory home is `~/Documents/Claude/Memory/` for any user. To change it,
edit `.mcp.json`:

```json
{
  "mcpServers": {
    "basic-memory": {
      "command": "/bin/bash",
      "args": [
        "-lc",
        "BASIC_MEMORY_HOME=\"$HOME/your/path\" basic-memory mcp"
      ]
    }
  }
}
```

If Cowork cannot find `basic-memory`, replace the inline command with
its absolute path. Find it with `which basic-memory` after install
(typically `/opt/homebrew/bin/basic-memory` on Apple Silicon, or
`/usr/local/bin/basic-memory` on Intel).

## How it works

The skill auto-triggers on memory-relevant requests — references to
people, terms, projects, "remember this", "what does X mean".

Lookup order:

1. `read_note("claude")` — hot cache, top ~30 people / acronyms /
   active projects.
2. `read_note("glossary")` — full decoder ring.
3. `read_note("people/<slug>")` or `read_note("projects/<slug>")` for
   deep context.
4. `search_notes("<term>")` for fuzzy matches.
5. Ask the user, then `write_note(...)`.

New facts are routed to the right destination:

- Acronyms / nicknames / codenames → `glossary`.
- Person → `people/<slug>`.
- Project → `projects/<slug>`.
- Decision → `decisions/<YYYY-MM-DD>-<slug>`.
- Preference → `preferences`.
- Daily journal → `daily/<YYYY-MM-DD>`.

If an item becomes part of active work or is used frequently, it gets
promoted to the `claude` hot cache.

## Memory directory layout

```
~/Documents/Claude/Memory/
├── CLAUDE.md            # permalink: claude — hot cache
├── INDEX.md             # store map
├── glossary.md          # full decoder ring
├── preferences.md       # comms and code preferences
├── people/              # one file per person
├── projects/            # one file per project
├── context/             # company, teams, stack
├── decisions/           # ADR-style notes (YYYY-MM-DD-slug.md)
└── daily/               # journal (YYYY-MM-DD.md)
```

All files use YAML frontmatter so Basic Memory indexes them correctly.

## Claude Code users — wiring it into `~/.claude/CLAUDE.md`

The plugin works in Cowork out of the box because Cowork loads plugin
hooks and MCP servers automatically. For the Claude Code CLI / desktop
app, install the plugin the same way (`claude plugins add
/path/to/global-memory`) and then add the snippet below to your global
`~/.claude/CLAUDE.md` so every session knows the memory store exists
and how to reach it:

```markdown
## Global memory (basic-memory MCP)

A cross-project memory store is available via the `basic-memory` MCP
server, installed by the `global-memory` plugin. The hot cache is
pre-loaded at session start. For anything not in the hot cache:

- `mcp__basic-memory__read_note` — permalinks: `claude` (hot cache),
  `glossary`, `preferences`, `people/<slug>`, `projects/<slug>`,
  `decisions/<YYYY-MM-DD>-<slug>`, `daily/<YYYY-MM-DD>`.
- `mcp__basic-memory__search_notes` — fuzzy search across all notes.
- `mcp__basic-memory__write_note` — add or update a note.

Use `/remember <fact>` to push a new fact in. Use `/memory-bootstrap`
to seed an empty store.
```

For per-repo `CLAUDE.md` files (one per project), run
`scripts/inject-memory-pointer.sh` to append a shorter pointer block to
every `~/Documents/Claude/Project*/CLAUDE.md` in one pass. The script
is idempotent — re-running skips files that already contain the marker.

## Coexistence with `productivity:memory-management`

The upstream skill writes the same files via direct Read/Write/Edit.
If both skills are active and Cowork's workspace is set to
`~/Documents/Claude/Memory/`, both code paths reach the same data.
For cross-project work, this skill is the one Claude uses — the
upstream skill cannot see files outside the selected folder.

## Versioning

Semver. Current: `0.2.0`.

## License

MIT.
