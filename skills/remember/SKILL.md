---
name: remember
description: Push a fact into global memory (people, projects, acronyms, decisions, preferences, daily journal). Routes to the right destination via Basic Memory MCP.
argument-hint: <fact to remember>
---

The user wants to commit a fact to global memory. The fact is:

$ARGUMENTS

Follow this exact procedure. Do not skip steps.

## 1. Classify the fact

Pick exactly one destination. If the fact spans more than one, pick the
primary one and cross-reference from there.

| Kind of fact | Destination permalink |
|--------------|----------------------|
| Acronym, nickname, codename, shorthand term | `glossary` |
| Person (new or update) | `people/<slug>` |
| Project (new or update) | `projects/<slug>` |
| Decision / ADR | `decisions/<YYYY-MM-DD>-<slug>` |
| Communication or code preference | `preferences` |
| Dated, ad-hoc, journal-style | `daily/<YYYY-MM-DD>` |

If the fact is a person/project/term that the user references frequently
or is part of active work, also plan to update `claude` (hot cache).

## 2. Read existing content (skip for brand-new notes)

For updates, call `mcp__basic-memory__read_note` with the chosen
permalink so you can merge instead of overwrite.

For glossary, people/<slug>, projects/<slug>, preferences, claude — these
are long-lived and almost always exist. Always read first.

For decisions/<date>-<slug> and daily/<date>, treat as new unless you
already wrote to today's daily this session.

## 3. Build the new content

Required YAML frontmatter:

```yaml
---
title: <human title>
type: note
permalink: <permalink>
tags: [tag, tag]
---
```

For daily notes use `type: daily`.

Append the new fact as a bullet or short paragraph under an appropriate
heading. Keep formatting consistent with the existing file.

## 4. Write

Call `mcp__basic-memory__write_note` with the merged content and the
chosen permalink.

## 5. Promote to hot cache (when warranted)

If the new fact is one of:

- a person the user contacts frequently,
- an acronym or codename in current rotation,
- a currently-active project,

then also `read_note("claude")`, add the entry under the right section,
and `write_note("claude", ...)`. Keep `claude` under ~100 lines — demote
stale items to `glossary` or the relevant deep-storage file if needed to
make room.

## 6. Confirm to the user

Reply with:

- one line stating where it was written (permalink),
- one line stating whether it was also promoted to the hot cache,
- nothing else.

Example: `Wrote to people/jane-smith. Promoted to hot cache.`

If the fact was ambiguous (e.g. could be person OR project), state your
classification choice in one short line so the user can correct you.
