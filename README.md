# global-memory

Cross-project workplace memory for Claude Cowork and Claude Code.
Plain markdown on disk, indexed and served by the
[Basic Memory](https://github.com/basicmachines-co/basic-memory) MCP
server, accessed by a forked `memory-management` skill so the same
memory works from any selected workspace folder.

This is a fork of `productivity:memory-management` that swaps direct
file I/O for MCP calls. Same data model, same files on disk,
client-agnostic access.

## What's inside

| Component | Purpose |
|-----------|---------|
| `skills/memory-management/SKILL.md` | Auto-triggered skill. Decodes shorthand, looks up via Basic Memory MCP, writes new facts. |
| `skills/memory-bootstrap/SKILL.md` | `/memory-bootstrap` — interview-style first-time setup that seeds the memory store with people, projects, acronyms, and preferences. |
| `skills/remember/SKILL.md` | `/remember <fact>` — explicit verb to push a fact into memory. Classifies and routes to the right destination. |
| `skills/memory-wire/SKILL.md` | `/memory-wire [root-dir]` — runs the injector script to append the global-memory pointer block to every per-project `CLAUDE.md`. Idempotent. |
| `hooks/hooks.json` + `hooks/preload-hot-cache.sh` | SessionStart hook. Auto-loads `CLAUDE.md` (hot cache) into session context so memory feels automatic. |
| `scripts/inject-memory-pointer.sh` | Adds a "global memory exists" pointer block to every per-project `CLAUDE.md` under `~/Documents/Claude/Project*/`. Idempotent. |
| `.mcp.json` | Registers the `basic-memory` MCP server, pointed at the `memory` project. |
| `.claude-plugin/plugin.json` | Plugin manifest. |
| `.claude-plugin/marketplace.json` | Marketplace manifest for `claude plugins` / `/plugin` install. |

## Prerequisites

1. Install Basic Memory:

   ```bash
   brew tap basicmachines-co/basic-memory
   brew install basic-memory
   ```

2. Create the Memory directory and register a Basic Memory project
   named `memory` pointing at it:

   ```bash
   mkdir -p ~/Documents/Claude/Memory
   basic-memory project add memory ~/Documents/Claude/Memory --default
   ```

   Verify with `basic-memory status` — it should report the project
   without errors.

The directory does not need to be populated yet. `/memory-bootstrap`
handles seeding on first use.

## Install

### From the marketplace (recommended)

In Claude Code or Cowork:

```
/plugin marketplace add Turek/cowork-global-memory
/plugin install global-memory@cowork-global-memory
```

### From a `.plugin` file (Cowork)

Build:

```bash
cd ~/Documents/Claude/global-memory
zip -r /tmp/global-memory.plugin . -x "*.DS_Store" -x ".git/*"
```

Drag `/tmp/global-memory.plugin` into Cowork.

### From local source

```bash
claude plugins add ~/Documents/Claude/global-memory
```

## First-time use

After install, in a fresh Cowork or Claude Code session:

```
/memory-bootstrap
```

The skill asks for: name and role, frequent contacts (up to ~10),
active projects (up to ~8), daily acronyms / shorthand, and
communication preferences. It then writes the seed notes to the right
permalinks (`claude`, `glossary`, `preferences`, `people/<slug>`,
`projects/<slug>`, `index`, today's `daily/<date>`).

Subsequent sessions auto-load the hot cache via the SessionStart hook,
so Claude knows your people, acronyms, and active projects without
needing to be told.

## Day-to-day use

- **Auto-decoding** — just talk normally.
  "Ask todd to do the PSR for oracle" → Claude looks up `todd`, `PSR`,
  `oracle` via the hot cache and full glossary before acting.
- **Explicit push** — `/remember <fact>`.
  E.g. `/remember Jane Smith is the new platform lead, prefers Slack DMs`.
  The skill classifies the fact, picks the right permalink, writes it.
- **First-time setup** — `/memory-bootstrap`.
- **Wire per-project CLAUDE.md files** — `/memory-wire [root-dir]`.
  Runs the bundled injector script to append the global-memory pointer
  block to every `CLAUDE.md` under `~/Documents/Claude/Project*/` (or
  a custom root). Idempotent.

## Lookup chain

For any non-trivial request:

1. `mcp__basic-memory__read_note("claude")` — hot cache
2. `mcp__basic-memory__read_note("glossary")` — full decoder ring
3. `mcp__basic-memory__read_note("people/<slug>")` /
   `read_note("projects/<slug>")` — deep context
4. `mcp__basic-memory__search_notes("<term>")` — fuzzy
5. Ask the user, then `mcp__basic-memory__write_note(...)`

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
The structure is created on demand — `/memory-bootstrap` and
`/remember` write to the right paths and Basic Memory creates files
and subfolders as needed.

## Configuration

`.mcp.json` launches the MCP server with `basic-memory mcp --project
memory`. To use a different project name, edit `.mcp.json`:

```json
{
  "mcpServers": {
    "basic-memory": {
      "command": "/bin/bash",
      "args": ["-lc", "basic-memory mcp --project YOUR_PROJECT_NAME"]
    }
  }
}
```

If Cowork or Claude Code can't find `basic-memory`, replace the inline
command with its absolute path. Find it with `which basic-memory`
(typically `/opt/homebrew/bin/basic-memory` on Apple Silicon, or
`/usr/local/bin/basic-memory` on Intel).

The SessionStart hook (`preload-hot-cache.sh`) reads
`$HOME/Documents/Claude/Memory/CLAUDE.md` directly off disk. If your
memory home is elsewhere, set `BASIC_MEMORY_HOME` in your shell
environment so the hook resolves the right path:

```bash
export BASIC_MEMORY_HOME=/path/to/your/memory
```

## Wiring into per-project `CLAUDE.md`

Easiest: run `/memory-wire` from any Cowork or Claude Code session.
The skill wraps the bundled injector script and reports which files
got the pointer and which were skipped. Pass a custom root if your
projects live outside `~/Documents/Claude/`:

```
/memory-wire /custom/projects/root
```

The underlying script is at
`scripts/inject-memory-pointer.sh` and can also be run directly from
the shell:

```bash
~/Documents/Claude/global-memory/scripts/inject-memory-pointer.sh
```

Either way it's idempotent — re-runs skip files that already contain
the marker.

## Wiring into Claude Code's `~/.claude/CLAUDE.md`

For Claude Code users, add the snippet below to your global
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

## Coexistence with `productivity:memory-management`

The upstream skill writes the same files via direct Read/Write/Edit.
If both skills are active and Cowork's workspace is set to
`~/Documents/Claude/Memory/`, both code paths reach the same data. For
cross-project work, this skill is the one Claude uses — the upstream
skill cannot see files outside the selected folder.

## Roadmap

See `TODO.md` for items deferred to v0.3+ (dashboard HTML and
scheduled consolidation). Both build only after 3+ months of real
usage to justify the effort.

## Versioning

Semver. Current: `0.2.3`.

## License

MIT.
