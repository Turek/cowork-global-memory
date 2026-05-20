---
name: memory-wire
description: Inject the global-memory pointer block into every per-project CLAUDE.md under a root directory. Wraps the bundled inject-memory-pointer.sh script. Idempotent — re-runs skip files that already have the marker.
argument-hint: "[root-dir]"
---

The user wants to wire global-memory awareness into per-project
`CLAUDE.md` files by running the bundled injector script.

## 1. Determine the root

**If the user passed an argument**, use it verbatim. Skip steps below.

User argument:

```
$ARGUMENTS
```

**If no argument was passed**, resolve the root automatically — do not
fall back to the script's hardcoded default without trying this first:

### In Cowork

Your session context (the system prompt) contains the mapping between
the user's real macOS filesystem paths and the sandbox mount paths.
It looks like:

```
/Users/<name>/Documents/Claude/<folder> → /sessions/.../mnt/<folder>/
```

Find the entry whose sandbox path is the currently selected workspace
(i.e. the folder the user has open, not `outputs` or `uploads`).
Use the **left side** (the real macOS path) as the root.

If the system prompt lists more than one mounted folder, pick the one
that is not `outputs`, `uploads`, or the global-memory plugin folder
itself.

If you cannot determine the path with confidence, ask the user:
"What is the full path to the project directory?" — never silently
default to `~/Documents/Claude`.

### In Claude Code

Run `pwd` via the Bash tool. Use the result as the root.

## 2. Run the script

Once the root is resolved, execute:

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/inject-memory-pointer.sh "<resolved-root>"
```

Always pass the resolved root as an explicit argument. Never run the
script without an argument (doing so triggers the hardcoded default,
which is almost never what the user wants).

The script is idempotent — files that already contain the
`<!-- global-memory-pointer -->` marker are skipped.

## 3. Report output

Show the script's stdout verbatim. It lists each file created or
injected, plus a summary.

If the script reports `Root not found`, the resolved path was wrong.
Tell the user which path was used and ask them to confirm the correct
one.

## 4. Confirm

Reply with one line:

`Created: N. Injected: M. Skipped: K.`

Nothing else.
