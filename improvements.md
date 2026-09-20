# AI setup — improvements

Findings from a review of the OpenCode AI setup (2026-09-20), tracked to a
decision. Workflow: **finding → Q&A → route forward**. Nothing here is acted on
until its Decision line is filled.

Status: `open` (needs Q&A) · `decided` (route chosen, not yet done) ·
`done` · `wontfix`.

## Investigation notes (verified)

- **Global AGENTS.md loads.** OpenCode auto-loads `~/.config/opencode/AGENTS.md`
  first, on every session, across all projects — confirmed in the docs. Our
  symlinked `config/opencode/AGENTS.md` is therefore active. (So the earlier
  "may be inert" worry is resolved; it works.)
- **OpenCode has Agent Skills.** Correcting an earlier claim: OpenCode now
  supports skills (opencode.ai/docs/skills), a real routing option for some
  capabilities alongside agents + AGENTS.md.
- **Stage 0 confirmed:** `ollama list` is empty — no models pulled yet.
- **No container runtime** in the Brewfile (needed by the github MCP).

Sources: OpenCode docs — Instructions (opencode.ai/v2/docs/instructions/),
Rules (opencode.ai/docs/rules/), Skills (opencode.ai/docs/skills/).

## Findings

### F1 — Context window probably defaults to ~4k on the new tiers
- **Severity:** high · **Status:** open · **Basis:** inferred (can't confirm at Stage 0)
- The old models were tagged `:30b-32k`; the new `local-code` tiers pull raw
  `hf.co` GGUFs with no Modelfile and no `num_ctx`, and ollama defaults to 4096.
  The provider `options` in opencode.json don't set context either. For coding
  that's a silent, painful truncation and a regression from the old setup.
- **Options:** (a) set `num_ctx` in `local-code` via a Modelfile at create time;
  (b) set context in the opencode provider `options`; (c) accept 4k.
- **Decision:** _pending Q&A_

### F2 — No top-level default model
- **Severity:** medium · **Status:** open · **Basis:** verified
- Only the 4 named agents set a model; OpenCode's default "build" agent has
  none, so everyday use needs a manual pick or errors out.
- **Options:** (a) add top-level `"model": "ollama/qwen3-coder:big"`;
  (b) pick a lighter default (`:mid`); (c) leave it, always use named agents.
- **Decision:** _pending Q&A_

### F3 — Stage 0: no models pulled, setup inert
- **Severity:** state (not a defect) · **Status:** open · **Basis:** verified
- Every agent points at `ollama/qwen3-coder:*` which isn't pulled. Nothing works
  until `local-code pull`.
- **Options:** (a) pull one tier now (which?); (b) stay at Stage 0 by design.
- **Decision:** _pending Q&A_

### F4 — github MCP can't run as configured
- **Severity:** medium · **Status:** open · **Basis:** verified
- It shells out to `docker run`, but there's no container runtime in the
  Brewfile and it needs `GITHUB_PERSONAL_ACCESS_TOKEN`. Currently `enabled:false`,
  so harmless until someone flips it, then it fails confusingly.
- **Options:** (a) add a runtime (colima/orbstack/docker) to the Brewfile +
  document the PAT; (b) remove the MCP block; (c) keep disabled, document the
  prereqs in a comment.
- **Decision:** _pending Q&A_

### F5 — "Tiers" are one model at three quants
- **Severity:** low / clarity · **Status:** open · **Basis:** verified
- `small/mid/big` are IQ4/Q5/Q6 of the *same* Qwen3-Coder-30B weights, and
  planner/architect/reviewer all run `big` — so they're capability-identical;
  only prompt + permissions differ. The README frames big-vs-mid as a quality
  lever, which overstates it.
- **Options:** (a) soften the README wording; (b) actually differentiate (e.g.
  a genuinely different model for one role); (c) leave as-is.
- **Decision:** _pending Q&A_

### F6 — AGENTS.md is global (applies to every project)
- **Severity:** decision · **Status:** open · **Basis:** verified
- The "laziest solution that works" ethos now applies to all OpenCode sessions
  everywhere, not just this repo.
- **Options:** (a) keep it global (intended); (b) move to a project-level
  AGENTS.md so it only applies where wanted; (c) split — thin global + fuller
  per-project.
- **Decision:** _pending Q&A_

### F7 — Relative-path + symlink-dir resolution is fragile
- **Severity:** low · **Status:** open · **Basis:** verified (broke once already)
- Prompts/AGENTS.md resolve via `{file:./...}` against the symlink dir; it
  already caused the "prompts not found" failure. Correct now, but a recurring
  shape.
- **Options:** (a) accept (documented now); (b) switch to absolute paths;
  (c) symlink the whole `~/.config/opencode` dir instead of per-file.
- **Decision:** _pending Q&A_

### F8 — No escape hatch to a stronger model
- **Severity:** decision · **Status:** open · **Basis:** inferred
- A quantized local 30B has a real capability ceiling vs. frontier cloud models
  on hard reasoning / large context. Nothing is configured as a fallback.
- **Options:** (a) add one cloud provider (key via `auth.json`, never committed)
  as an opt-in "when local isn't enough"; (b) stay strictly local by principle.
- **Decision:** _pending Q&A_

### F9 — Model version drift
- **Severity:** low · **Status:** open · **Basis:** verified
- `local-code` pulls moving tags (`:Q6_K`), not digests, so "the same setup"
  changes as upstream re-uploads.
- **Options:** (a) pin digests; (b) accept drift (fine for personal use).
- **Decision:** _pending Q&A_

### F10 — Reconsider OpenCode Agent Skills
- **Severity:** option · **Status:** open · **Basis:** verified (feature exists)
- Now that OpenCode has skills, some capabilities could be skills rather than
  agents/AGENTS.md.
- **Options:** (a) leave the agents/AGENTS.md model as-is; (b) port some
  capabilities to OpenCode skills; (c) hybrid.
- **Decision:** _pending Q&A_
