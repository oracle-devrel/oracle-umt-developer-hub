# Module 06 — Secure Agent Access

Companion to the article **"How Do You Secure AI Agent Data Access? Put Authorization Back in the Engine."**

An AI agent that reads enterprise data is only as constrained as the connection it reads
through. When authorization lives in application code, the RAG pipeline, or the prompt, a
prompt-injected agent can rewrite it. This module proves the structural alternative: move the
access decision **below the agent**, into the engine, where neither the model nor an attacker
speaking through it can reach it — one enforcement domain across rows, documents, and vectors.

The privileged setup lives in [`docker/init/09-agent-security.sql`](../../docker/init/09-agent-security.sql)
(runs as SYS at boot): an identity-propagating application context, a mode-gated Virtual Private
Database (VPD) row-security policy on `CUSTOMERS`, a least-privilege read-only duality view, and a
unified audit policy. The scripts below run **as the unprivileged application user** — the same
path the agent uses — which is why the row-security predicate shows up in the query plans (VPD is
bypassed for SYS).

## Proofs

| # | Script | Proves | Assertions |
|---|--------|--------|-----------|
| 1 | [`01-identity-aware-row-security.sql`](scripts/01-identity-aware-row-security.sql) | The agent acts AS the user: deny-by-default with no identity (0 rows), scoped to exactly the user's rows once identity is propagated (151 / 11). The `EXPLAIN PLAN` shows the engine **injecting** the security predicate (plan `2008213504`). | 3 |
| 2 | [`02-least-privilege-duality.sql`](scripts/02-least-privilege-duality.sql) | The duality view excludes `email` (the agent can't see undeclared fields) and is read-only (`ORA-42690` on write). Reading it **inherits** the same VPD predicate (plan `2586717113`). | 2 |
| 3 | [`03-governed-hybrid-retrieval.sql`](scripts/03-governed-hybrid-retrieval.sql) | Hybrid vector + relational retrieval (the RAG path) returns only authorized rows because the join is filtered **before** ranking — vector ranking, relational join, and row security in one plan (`4006954426`). | 1 |
| 4 | [`04-unified-audit.sql`](scripts/04-unified-audit.sql) | One kernel-managed audit trail attributes every retrieval to the acting user, governed by the same table-scoped policy as every other query. | 1 |

Seven assertions total. Every one runs against Oracle AI Database 26ai Free.

## What this does NOT prove

Honest scoping, mirrored from the article:

- It shrinks the **private-data** leg of the lethal trifecta — not the untrusted-content or
  external-communication legs. Taint tracking and egress controls remain an agent-layer job.
- It is **containment, not prevention** of prompt injection: it caps what a fooled agent can
  reach to exactly what the human behind it could reach anyway.
- The full OAuth on-behalf-of identity path (Oracle **Deep Data Security**, 26ai) and **SQL
  Firewall** enforcement are described and cited in the article but not asserted in the free
  container; the enforcement half (VPD, contexts, duality, audit) runs here.

## Run

```bash
docker compose up -d --build oracle        # from labs/converged-database-lab
python validator/run.py                    # runs every module; prints ASSERT results
```
