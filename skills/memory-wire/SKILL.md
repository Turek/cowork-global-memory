---
name: memory-wire
description: Inject the global-memory pointer block into every per-project CLAUDE.md under a root directory. Wraps the bundled inject-memory-pointer.sh script. Idempotent — re-runs skip files that already have the marker.
argument-hint: "[root-dir]"
---

The user wants to wire global-memory awareness into per-project
`CLAUDE.md` files by running the bundled injector script.

## 1. Determine the root

If the user passed an argument, use it as the root directory.
Otherwise the script defaults to `~/Documents/Claude`, which scans
`~/Documents/Claude/Project*/CLAUDE.md` files.

User argument:

```
$ARGUMENTS
```

## 2. Run the script

Execute via the Bash tool:

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/inject-memory-pointer.sh $ARGUMENTS
```

If no argument was passed, run it without the trailing argument so the
script uses its own default.

The script is idempotent — files that already contain the
`<!-- global-memory-pointer -->` marker are skipped.

## 3. Report output

Show the script's stdout verbatim. It lists each file that was
created or had the pointer injected, plus a final summary with counts
of created vs injected vs skipped files.

If the script reports `No Project*/ directories found under <root>`,
suggest re-running with a custom root:

```
/memory-wire /path/to/projects-parent
```

## 4. Confirm

Reply with one line summarising the script's totals:

`Created: N. Injected: M. Skipped: K.`

Nothing else.
