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

## Daily journal

Each session of substantial work, append to today's daily note
(`daily/<YYYY-MM-DD>`):

- What happened.
- What was learned.
- Decisions made.

If today's note does not exist, create it. If it exists, read, append,
write back.

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
