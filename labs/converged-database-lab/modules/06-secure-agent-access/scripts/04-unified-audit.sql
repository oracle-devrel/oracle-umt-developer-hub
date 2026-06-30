-- Module 06 · Proof 4 — One unified audit trail over every model
-- ----------------------------------------------------------------------------
-- When someone asks "why did this row enter the context window?", the answer is a
-- single, kernel-managed audit trail — the same table-scoped policy that governs
-- every other query, not three log formats across a polyglot agent stack. The
-- AGENT_ACCESS_POL policy (docker/init/09) audits SELECT on CUSTOMERS; LAB_USER
-- holds AUDIT_VIEWER so it can read the trail it generates.

-- The audit control is active in the kernel (deterministic).
SELECT 'ASSERT:unified_audit_policy_enabled:' ||
       CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END AS assertion
FROM   audit_unified_enabled_policies
WHERE  policy_name = 'AGENT_ACCESS_POL';

-- The trail attributes each retrieval to the acting database user and object.
-- (Unified audit buffers writes, so counts from the current session may lag; this
--  is illustrative — the enabled-policy assertion above is the deterministic proof.)
SELECT dbusername, action_name, object_name, COUNT(*) AS accesses
FROM   unified_audit_trail
WHERE  unified_audit_policies = 'AGENT_ACCESS_POL'
GROUP  BY dbusername, action_name, object_name
ORDER  BY 1, 2;
