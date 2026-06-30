-- Module 06 · Proof 2 — A least-privilege document front end (JSON Duality View)
-- ----------------------------------------------------------------------------
-- The agent does not read base tables; it reads CUSTOMER_SUPPORT_DV, a JSON
-- Relational Duality View defined in the database (docker/init/09). The view is
-- the contract:
--   * 'email' is never projected            -> sensitive data the agent cannot see
--   * no WITH INSERT/UPDATE/DELETE anywhere  -> the document is read-only
--   * it sits on CUSTOMERS                   -> it INHERITS the same row-security
--                                               predicate proved in Proof 1
-- Least privilege "defined, verified, enforced, and audited in the database" —
-- not reconstructed in every app or agent tool.

BEGIN lab_user.agent_ctx_pkg.set_user_scope('vip'); END;
/

-- (a) The sensitive field is absent from every projected document.
SELECT 'ASSERT:duality_excludes_email:' ||
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS assertion
FROM   lab_user.customer_support_dv
WHERE  JSON_EXISTS(data, '$.email');

-- (b) A write through the read-only document front end is rejected by the engine
--     (ORA-42690). assert_dv_readonly attempts the UPDATE and confirms the refusal.
SELECT 'ASSERT:duality_read_only:' || lab_user.assert_dv_readonly AS assertion FROM dual;

-- A sample document the agent actually sees: fullName, segment, nested tickets — no email.
SELECT JSON_SERIALIZE(data PRETTY) AS support_document
FROM   lab_user.customer_support_dv
ORDER  BY JSON_VALUE(data, '$._id' RETURNING NUMBER)
FETCH  FIRST 1 ROW ONLY;

-- The plan: reading the document assembles it from base tables AND carries the
-- same row-security predicate the agent can never see or remove.
EXPLAIN PLAN FOR SELECT data FROM lab_user.customer_support_dv;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, NULL, 'TYPICAL'));
