---
name: production-debugging
description: Use when diagnosing a live or staging incident from logs, errors, or user reports.
---

# Production debugging

1. Capture the symptom, timeframe, and blast radius (who/what is affected).
2. Gather evidence: error messages, request ids, recent deploys, related config.
3. Form 1–3 falsifiable hypotheses; test the cheapest first.
4. Prefer read-only investigation until a fix is confirmed.
5. Document root cause, fix, and follow-up monitoring.
