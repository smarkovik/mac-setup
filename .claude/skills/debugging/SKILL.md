---
name: debugging
description: Debug a failing test, crash, exception, or behavior that doesn't match expectations. Use whenever the user pastes an error message or stack trace, says something is broken or acting up, or asks why an output is wrong - even without explicitly asking to "debug" or "fix" it. Always reproduce before proposing a fix.
---

# Debugging

Fixed order. Do not propose a fix before step 1 is done.

## 1. Reproduce
Run it yourself and see the actual failure before touching anything. If you
cannot reproduce it, say exactly what's missing (input, env, state) rather
than guessing at a fix.

## 2. Isolate
Narrow to the smallest input or state that still fails. Cut everything not
needed to trigger it.

## 3. Root-cause
Explain *why* it fails, not just where the symptom shows up. "It passes
after this change" is not a diagnosis - you need the mechanism.

## 4. Fix minimally
The smallest change that addresses the root cause. Not a drive-by refactor
of the surrounding code, even if it's tempting.

## 5. Verify
Re-run the original repro and show it passing. A fix without a demonstrated
re-run is not done.

## Flakes
"Flaky" is not a diagnosis either. Before calling something environmental:
reproduce the failure at least once yourself, or show concrete evidence
(fails on a clean checkout too, or against code this change didn't touch).
