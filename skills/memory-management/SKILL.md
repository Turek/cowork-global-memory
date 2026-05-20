---
name: memory-management
description: Cross-project workplace memory backed by Basic Memory MCP. Decodes shorthand, acronyms, nicknames, and project codenames so Claude understands requests like a colleague would. Use when the user mentions a person, term, or project Claude does not know, says "remember this" or "X means Y", asks "who is X" or "what does X mean", or starts any non-trivial task that benefits from prior context.
user-invocable: false
---

# Memory management (Basic Memory backed)

Cross-project memory that works in every Cowork session regardless of
which folder is currently selected. Storage is plain markdown on disk.
Access is via the `basic-memory` MCP server.

## The goal

Decode shorthand into understanding. Without memory, "ask todd to do the
PSR for oracle" is meaningless. With memory, Claude knows todd is Todd
Martinez, PSR is Pipeline Status Report, oracle is the Oracle Systems
deal.

## Architecture

Two-tier system. Hot cache for fast lookup, full notes for depth.

| Permalink | Purpose |
|-----------|---------|
| `claude` | Hot cache. Top ~30 people, common acronyms, active projects. Read first. |
| `glossary` | Full decoder ring — every term, nickname, codename. |
| `preferences` | Communication and code preferences. |
| `index` | Map of the memory store. |
| `people/<slug>` | One file per person. |
| `projects/<slug>` | One file per project. |
| `context/<topic>` | Company, teams, stack. |
| `decisions/<YYYY-MM-DD>-<slug>` | ADR-style notes. |
| `daily/<YYYY-MM-DD>` | Append-only journal, one per day. |

## Lookup flow

For any non-trivial request, decode shorthand before acting:

1. Call `mcp__basic-memory__read_note` with permalink `claude`. Covers
   roughly 90% of decoding.
2. If a term wasn't in the hot cache, call `mcp__basic-memory__read_note`
   with permalink `glossary`.
3. If deeper context is needed (drafting a message to someone, planning
   work on a project), call `mcp__basic-memory__read_note` with
   `people/<slug>` or `projects/<slug>`.
4. If still unknown, call `mcp__basic-memory__search_notes` with the
   term as a fuzzy search.
5. If genuinely unknown after all of the above, ask the user, then
   write the answer to memory.

Example:

```
User: "ask todd to do the PSR for oracle"

Step 1 — read_note("claude"):
  todd → Todd Martinez ✓
  PSR  → Pipeline Status Report ✓
  oracle → not in hot cache

Step 2 — read_note("glossary"):
  oracle → Oracle Systems deal ($2.3M) ✓

Step 3 — drafting the message, need Todd's preferences:
  read_note("people/todd-martinez")
```

## Adding memory

When the user says "remember this", "X means Y", or volunteers a fact
worth keeping:

1. Identify the destination:
   - Acronym, term, nickname, codename → `glossary`.
   - Person → `people/<slug>` (create or update).
   - Project → `projects/<slug>` (create or update).
   - Decision → `decisions/<YYYY-MM-DD>-<slug>` (always new).
   - Preference → `preferences`.
   - Ad-hoc and dated → today's `daily/<YYYY-MM-DD>`.

2. For an update, call `mcp__basic-memory__read_note` to get current
   content. For a new note, skip this.

3. Build new content with YAML frontmatter and a body. Frontmatter is
   required for Basic Memory to index correctly.

4. Call `mcp__basic-memory__write_note` with the new content.

5. Promotion: if the item is used frequently or part of active work,
   also update the `claude` note to add it to the hot cache.

## Session lifecycle

### Session start

When a session begins and the hot cache is loaded, check whether the
previous session left a `## Session closed` entry in the most recent
daily note without a subsequent summary. If it did, mention it briefly:
"Last session ended without a written summary — anything worth capturing?"

Do not make this intrusive. One sentence is enough. Skip if today's
daily note does not exist yet.

### Session end (before the user leaves)

When the user says goodbye, thanks, done, or similar closing signals,
before responding:

1. Call `mcp__basic-memory__read_note` with `daily/<YYYY-MM-DD>` for
   today. Create it if absent.
2. Append a `## Session summary — HH:MM` section with:
   - What was accomplished (bullet list, keep tight).
   - Any decisions made.
   - Any facts that should be promoted to hot cache or deep storage.
3. Write the updated note back.
4. If any items warrant promotion (active project, frequent person, new
   decision), write those notes too.
5. Confirm to the user in one line: "Session summary written to
   `daily/<YYYY-MM-DD>`."

**This step is mandatory on every session that involved non-trivial
work.** The Stop hook writes a `## Session closed` marker automatically,
but it carries no content. The summary above is Claude's responsibility.

### Daily journal

Append to today's daily note (`daily/<YYYY-MM-DD>`) whenever:

- A significant decision is made.
- A new fact is learned that doesn't fit a specific destination yet.
- The session is ending (see above).

If today's note does not exist, create it with frontmatter:

```yaml
---
title: YYYY-MM-DD
type: daily
permalink: daily/YYYY-MM-DD
tags: [daily]
---
```

## File format

Every note must include YAML frontmatter:

```yaml
---
title: Display title
type: note
permalink: short/identifier
tags: [tag, tag]
---
```

For daily notes, set `type: daily`.

## Conventions

- Permalinks: lowercase, hyphens. `people/jane-smith`,
  `projects/project-phoenix`, `decisions/2026-05-03-auth-rewrite`.
- Capture nicknames and alternate names in `glossary` and in the
  person's file.
- Capture codenames in `glossary` and the project's file.
- Keep `claude` (hot cache) under ~100 lines.

## What goes where

| Type | Hot cache (`claude`) | Full storage |
|------|---------------------|--------------|
| Person | Top ~30 frequent | `glossary` + `people/<slug>` |
| Acronym | ~30 most common | `glossary` (complete) |
| Project | Active only | `glossary` + `projects/<slug>` |
| Nickname | If person is top 30 | `glossary` (all) |
| Company context | Quick reference | `context/<topic>` |
| Preferences | All | `preferences` |
| Decisions | — | `decisions/<date>-<slug>` |
| Daily entries | — | `daily/<date>` |

## Promotion / demotion

Promote to `claude` when:

- An item is used frequently.
- It is part of active work.

Demote (remove from `claude`, keep in deep storage) when:

- A project completes.
- A person is no longer a frequent contact.
- A term is rarely used.

This keeps the hot cache fresh.

## Bootstrapping a new memory store

If `read_note("claude")` fails or returns empty, the memory store is
not yet populated. Tell the user, offer to seed it, and ask:

- Their name, role, current focus.
- Names and roles of frequent contacts.
- Active projects.
- Acronyms and shorthand they use daily.

Then write to `claude`, `glossary`, `preferences`, and as many
`people/<slug>` / `projects/<slug>` files as needed.
