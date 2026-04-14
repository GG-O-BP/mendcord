---
description: Run gleam format --check, gleam check, and gleam test. Report only failures.
argument-hint: (no arguments)
allowed-tools: Bash(gleam format:*), Bash(gleam check:*), Bash(gleam test:*)
---

Run the full quality gate and report **only failures**:

1. `gleam format --check` — fail if any file needs formatting.
2. `gleam check` — fail on type errors or warnings.
3. `gleam test` — fail on test failures.

If all three pass, respond with a single line: `✅ all checks passed`.

If any step fails, print:
- which step failed,
- the trimmed error output (no full stack traces unless asked),
- the fix in one sentence.

Do not modify any file. Do not run `gleam format` (without `--check`) — only the user or the PostToolUse hook should mutate files.
