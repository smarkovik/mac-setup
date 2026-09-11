---
name: architecture-review
description: Review a design or codebase for architecture issues - coupling, data ownership, failure modes at scale. Use when asked to review architecture, evaluate a design, or assess whether a structural change is sound.
---

# Architecture review

Work in this order; do not skip to recommendations before the first three.

## 1. Data flow and ownership
- For each piece of shared state: who writes it, who reads it, and what
  breaks if that changed.
- Flag state with more than one writer as a specific risk, not a style note.

## 2. Coupling
- Name which modules change together today, and whether that coupling is
  deliberate (a real invariant) or accidental (nobody separated them).
- Accidental coupling across a boundary meant to be independent is a
  finding; the same coupling within a single module usually is not.

## 3. Failure modes
- What happens under 10x load, a downstream outage, a partial write, a
  process restart mid-operation.
- A design that only has a happy path documented is incomplete, not fine.

## 4. Recommendation
- Give one recommendation, not a survey. If there's a real trade-off, say
  which side you'd take and why.
- Prefer the existing, already-understood pattern in this codebase over a
  new abstraction unless the existing one is demonstrably the problem.
- Do not propose a rewrite when a smaller structural fix solves the actual
  problem.

State load-bearing assumptions explicitly rather than silently picking one.
