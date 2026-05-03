---
name: memory-bootstrap
description: Seed the global memory store on a fresh machine — asks the user about themselves, contacts, projects, and shorthand, then writes the foundational notes via Basic Memory MCP.
---

The user is bootstrapping global memory on a fresh machine. Your job is
to interview them and write the seed notes.

## 1. Check first

Call `mcp__basic-memory__read_note` with permalink `claude`.

- If it returns content, the store is already seeded. Stop and tell the
  user — offer to extend it instead of overwriting.
- If it errors or is empty, proceed.

## 2. Interview

Ask the user, in this order, in **one** message containing all questions
(not one-by-one). Group them clearly so they can answer in a single
reply:

1. **About you** — full name, role / job title, the company or context
   you work in, current focus (one or two lines).
2. **Frequent contacts** — up to 10 people you talk to most. For each:
   first name or nickname → full name, role, anything notable (manager,
   direct report, key client, etc.).
3. **Active projects** — up to 8. For each: short name / codename →
   full name, one-line description, status if relevant.
4. **Daily acronyms / shorthand** — up to 20. Acronym → expansion.
5. **Communication preferences** — anything Claude should always do or
   never do (tone, formats, no-emojis, etc.). Optional.

Tell them they can answer with "skip" for any section.

## 3. Wait for the answer

Do not write anything until they reply.

## 4. Write the seed files

Use `mcp__basic-memory__write_note` for each. Required frontmatter on
every file:

```yaml
---
title: <title>
type: note
permalink: <permalink>
tags: [tag, tag]
---
```

### `claude` (hot cache, permalink `claude`)

Sections: `## About me`, `## People`, `## Projects`, `## Acronyms`.
Keep under ~100 lines. Most-referenced items only.

### `glossary` (permalink `glossary`)

Full decoder ring. Every acronym, nickname, codename the user
mentioned, plus a short blurb each.

### `preferences` (permalink `preferences`)

Capture everything they said about how Claude should behave. If they
skipped the question, write a stub note (`type: note`, body: "No
preferences captured yet.") so the file exists for `/remember` to
update later.

### `people/<slug>` — one per contact

Slug = lowercase, hyphenated, full name. Frontmatter must include
`tags: [person]`. Body sections: `## Role`, `## Notes`, plus
`## Aliases` listing any nicknames.

### `projects/<slug>` — one per project

Slug = lowercase, hyphenated. `tags: [project]`. Body sections:
`## Description`, `## Status`, `## Codenames` if any.

### `index` (permalink `index`)

Short map of the store: list each top-level note and folder created
above with one-line descriptions. This becomes the user-facing TOC.

### `daily/<YYYY-MM-DD>` for today

Use today's actual date. `type: daily`. One bullet: "Bootstrapped
global memory."

## 5. Confirm

Reply with a compact summary:

- count of people, projects, acronyms written,
- list of permalinks created,
- one line: "Hot cache, glossary, preferences, and seed people/projects
  written. Use /remember to add more."

Nothing else. No celebration. No next-steps tutorial.
