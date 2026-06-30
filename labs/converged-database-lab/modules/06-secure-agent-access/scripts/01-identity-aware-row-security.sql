-- Module 06 · Proof 1 — Identity-aware row security (the agent acts AS the user)
-- ----------------------------------------------------------------------------
-- An AI agent that reaches data through one over-privileged service account is a
-- confused deputy: a user with no direct access can extract anything the agent can
-- reach, just by asking. The converged engine moves the boundary BELOW the agent.
-- The agent enters an identity-propagating context ("agent mode"); the engine's
-- row-level security (VPD) is then deny-by-default and scoped to exactly the
-- acting user's entitlement. The policy is installed at init (docker/init/09);
-- here we prove its behavior as LAB_USER — the same un-privileged path the agent uses.
--
-- The headline artifact is the EXPLAIN PLAN: the security predicate is INJECTED BY
-- THE ENGINE into the access path. No prompt, no app filter, no agent-built SQL can
-- remove it. Authorization lives where the agent cannot reach it.

-- (a) Enter the agent path with NO propagated identity -> deny by default.
BEGIN lab_user.agent_ctx_pkg.set_agent_mode; END;
/
SELECT 'ASSERT:rls_deny_by_default:' ||
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS assertion
FROM   lab_user.customers;

-- (b) Propagate a standard-tier user's identity -> the engine returns only their rows.
BEGIN lab_user.agent_ctx_pkg.set_user_scope('standard'); END;
/
SELECT 'ASSERT:rls_scope_standard_151_one_segment:' ||
       CASE WHEN COUNT(*) = 151 AND COUNT(DISTINCT segment) = 1 THEN 'PASS' ELSE 'FAIL' END AS assertion
FROM   lab_user.customers;

-- (c) SAME query, a vip-tier identity -> the governed result changes accordingly.
BEGIN lab_user.agent_ctx_pkg.set_user_scope('vip'); END;
/
SELECT 'ASSERT:rls_scope_vip_11:' ||
       CASE WHEN COUNT(*) = 11 THEN 'PASS' ELSE 'FAIL' END AS assertion
FROM   lab_user.customers;

-- The proof you can read in the plan: the engine injects the row-security predicate.
EXPLAIN PLAN FOR SELECT customer_id, full_name, segment FROM lab_user.customers;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, NULL, 'TYPICAL'));
