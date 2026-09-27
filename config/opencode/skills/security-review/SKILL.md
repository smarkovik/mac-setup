---
name: security-review
description: Use when auditing a change or surface for security defects before ship.
---

# Security review

1. Identify trust boundaries (user input, auth, admin, webhooks, file/IO).
2. Check authz on every mutating path; verify tenant isolation if multi-tenant.
3. Hunt for injection, SSRF, path traversal, and secret leakage in logs/errors.
4. Rate each finding high/medium/low with a concrete remediation.
5. Do not expand into a full rewrite unless asked.
