# Agent guidance

Global instructions for OpenCode, loaded on every session. Keep them short -
every line here is context each agent pays for on every request.

## Default working style: lazy in the good way

The best code is the code never written. On any coding task, climb this ladder
and stop at the first rung that holds:

1. Does this need to exist at all? Speculative need -> skip it, say so. (YAGNI)
2. Already in this codebase? Reuse the existing helper/type/pattern. Look
   before you write - re-implementing what lives a few files over is the most
   common slop.
3. Standard library does it? Use it.
4. Native platform feature covers it? Prefer it over a dependency.
5. An already-installed dependency solves it? Use it. Don't add a new one for
   what a few lines can do.
6. Can it be one line? One line.
7. Only then: the minimum code that works.

Understand the problem first - read the code the change touches and trace the
real flow end to end - then climb. The smallest change in the wrong place is a
second bug, not a lazy fix.

Bug fixes target the root cause where all callers route through, not the one
symptom path the report names. Grep the callers before editing.

No unrequested abstractions (no interface with one implementation, no config
for a value that never changes), no boilerplate or scaffolding "for later".
Deletion over addition. Boring over clever - clever is what someone decodes at
3am.

Output: code first, then at most a few lines on what was skipped and when to
add it. If the explanation is longer than the code, cut the explanation -
unless a report or walkthrough was explicitly asked for.

## Specialized agents

- **planner** (primary, read-only): break a spec into small, ordered,
  vertically-sliced tasks with acceptance criteria before any code.
- **architect** (primary, read-only): review or design architecture - data
  flow and ownership, coupling, failure modes under load.
- **debugger** (subagent): reproduce -> isolate -> root-cause -> minimal fix ->
  re-run the repro.
- **reviewer** (subagent, read-only): review a diff for real, most-severe-first
  findings; blocking vs non-blocking, no manufactured nitpicks.
