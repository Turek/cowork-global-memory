---
name: reflect
description: >
  Read the past N days of daily notes, identify patterns in corrections
  and missing context, and propose concrete updates to preferences.md.
  Writes proposals to decisions/ — nothing is applied until the user
  reviews and runs /remember. Use weekly or whenever memory feels stale.
argument-hint: "[days=7]"
user-invocable: true
---

# Reflect — memory review and preference proposals

Reads recent daily notes to surface patterns worth encoding as permanent
preferences. Does not apply any changes — proposals only.

## 1. Determine the lookback window

Default: 7 days. If the user passed a number as an argument, use that.

```
$ARGUMENTS
```

## 2. Read daily notes

Call `mcp__basic-memory__read_note` for each date in the window:
`daily/<YYYY-MM-DD>`. Start from today and work backwards.

Skip dates where the note does not exist (not an error). Collect all
content that was found.

If no daily notes exist at all, tell the user and stop.

## 3. Identify patterns

Scan the collected content for:

- **Corrections** — the user corrected Claude's output. What was wrong?
  Is there a rule that would prevent it?
- **Repeated lookups** — the same term, person, or project appeared
  across multiple sessions without being in the hot cache. Should it be
  promoted?
- **Missing context** — Claude had to ask for something the user expected
  it to know. Should that be in preferences or deep storage?
- **Outdated entries** — hot cache or project notes that no longer reflect
  reality (completed projects, changed roles, obsolete terms).

Group findings by type. Discard one-off events — only patterns that
appear two or more times are worth encoding.

## 4. Draft proposals

For each pattern, produce a concrete proposal in one of these forms:

- **Add to preferences.md** — a new rule or convention to encode.
- **Promote to hot cache** — a term or person used frequently enough to
  belong in `claude`.
- **Demote from hot cache** — a stale entry that should move to deep
  storage only.
- **Update a deep-storage note** — a correction to a person or project
  note that is now out of date.

Write proposals as a numbered list. Each proposal must state:
1. What to change.
2. Which note/section to change it in (`permalink`).
3. Why — the pattern it addresses.

## 5. Write the proposal note

Call `mcp__basic-memory__write_note` to create:

```yaml
---
title: Reflection — YYYY-MM-DD
type: decision
permalink: decisions/YYYY-MM-DD-reflection
tags: [reflection, preferences, review]
---
```

Body: the numbered proposal list from step 4, plus a header showing the
lookback window and how many daily notes were read.

## 6. Report to the user

Print a compact summary:

- Date range reviewed.
- Number of daily notes read.
- Number of proposals written.
- The permalink of the proposal note.
- One line: "Review at `decisions/YYYY-MM-DD-reflection` and apply with
  `/remember` for each item you want to keep."

Nothing else. Do not apply any changes automatically.
