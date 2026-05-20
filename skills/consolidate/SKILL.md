---
name: consolidate
description: >
  Scan daily notes for facts that belong in permanent notes (people,
  projects, decisions, glossary) and promote them. Leaves daily entries
  intact — marks promoted bullets with (→ promoted). Run when the daily
  folder accumulates enough entries to be worth processing.
argument-hint: "[days=30]"
user-invocable: true
---

# Consolidate — promote daily facts to permanent notes

Moves facts from the ephemeral daily journal into the right permanent
notes so the store stays searchable as it grows.

## 1. Determine the scan window

Default: 30 days. If the user passed a number, use that instead.

```
$ARGUMENTS
```

## 2. Collect unprocessed daily notes

For each date in the window, call `mcp__basic-memory__read_note` with
`daily/<YYYY-MM-DD>`. Collect notes whose entries do NOT already end
with `(→ promoted)` — those are already processed.

If every note in the window is fully processed, tell the user and stop.

## 3. Extract promotable facts

For each unprocessed daily note, scan each bullet or paragraph for:

- **Person facts** — anything that describes a person's role, preference,
  contact detail, or decision. Match against known `people/<slug>` notes.
- **Project facts** — status updates, decisions, commands, or learnings
  about a known project. Match against `projects/<slug>` notes.
- **Glossary additions** — new acronyms, nicknames, or codenames.
- **Standalone decisions** — architectural or workflow choices that should
  be an ADR in `decisions/`.

To check what people and project notes exist, call
`mcp__basic-memory__search_notes` with the entity name if uncertain.

Facts that are already captured elsewhere, too vague to be useful, or
purely ephemeral (e.g. "ran tests today") should be skipped.

## 4. Present the promotion plan

Before writing anything, list every proposed promotion:

```
From: daily/YYYY-MM-DD — "<bullet text>"
To:   <destination permalink>
Why:  <one-line reason>
```

Ask the user: "Apply all, apply some (list numbers), or cancel?"

Wait for the response before proceeding.

## 5. Apply approved promotions

For each approved item:

1. Read the destination note (`mcp__basic-memory__read_note`).
2. If it does not exist yet, create a stub with correct frontmatter.
3. Append the fact under a `## History` section (create the section if
   absent) with the source date: `- YYYY-MM-DD: <fact>`.
4. Write the updated note back (`mcp__basic-memory__write_note` with
   `overwrite: true`).
5. Edit the source daily note to append `(→ promoted to <permalink>)`
   to the promoted bullet. Use `mcp__basic-memory__edit_note` with
   `operation: find_replace`.

## 6. Report

Print one line per promoted fact:

`promoted: "<short fact>" → <permalink>`

Then a totals line:

`Promoted: N. Skipped: M.`

Nothing else.
