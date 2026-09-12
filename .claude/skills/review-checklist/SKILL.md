---
name: review-checklist
description: Review a diff, PR, or set of code changes for correctness bugs, security issues, and unjustified complexity before it merges. Use whenever asked to review code, look at a PR, check whether a change is safe to merge, or asked "does this look right" about a diff - even without the word "review".
---

# Code review

For every finding:

- **State the concrete failure scenario** - specific inputs/state that
  produce a wrong output, crash, or security issue. Not "this could be a
  problem," the actual scenario.
- **Mark it blocking or not, explicitly.** A style preference is never
  blocking. A correctness bug, a security issue, or an untested behavior
  change is.
- **Stay in the diff's blast radius.** Don't flag pre-existing code the
  change didn't touch, unless this change made it unreachable or broke it.
- **Fewer, verified findings beat an exhaustive list of maybes.** If you're
  not sure something is a real bug, say that instead of presenting a guess
  as fact.

Order findings most-severe first. If there's nothing blocking, say so
plainly - don't manufacture nitpicks to look thorough.
