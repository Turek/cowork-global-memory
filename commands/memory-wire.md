---
description: Inject the global-memory pointer block into per-project CLAUDE.md files under a given umbrella. Auto-creates CLAUDE.md at the umbrella root if missing; append-only for direct subdirectories.
argument-hint: "[root-dir]"
---

Invoke the `memory-wire` skill from the `global-memory` plugin with
the user's argument. Pass it through verbatim:

$ARGUMENTS
