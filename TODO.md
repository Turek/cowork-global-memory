# TODO

Items deferred to v0.3+. Build only after enough real usage to justify
the effort — premature builds against thin data are wasted work.

## Dashboard HTML

Single-file HTML board view of the memory store: recent notes, current
hot cache contents, today's daily journal, and quick links to people /
projects.

- Crib pattern from `productivity:memory-management/skills/dashboard.html`.
- Read notes via Basic Memory MCP (or directly off disk if the
  dashboard is rendered server-side / by a one-shot script).
- Build only after **3+ months** of usage — the dashboard is only
  useful when there is enough volume to scan, otherwise it duplicates
  what `/remember` and `read_note("claude")` already provide.

## Scheduled consolidation

Weekly cron / scheduled-task that folds `daily/<YYYY-MM-DD>` entries
into topical files (people, projects, decisions) so the daily folder
does not become an unsearchable junk drawer.

- Detect entries that reference a known person/project and propose
  promoting the bullet into that note's history section.
- Leave the daily entry intact (audit trail) but mark it consolidated.
- Build only after **3+ months** of accumulated daily notes — without
  volume there is nothing to consolidate.
