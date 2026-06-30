-- Module 06 · Proof 3 — Governed hybrid retrieval (vector + relational + RLS, one plan)
-- ----------------------------------------------------------------------------
-- The RAG leak: most systems enforce access control in the application layer and
-- post-filter what the vector store already returned — too late, the model has
-- seen it. On the converged engine the vector search is just part of the query,
-- so it inherits the same row-security as everything else. A support agent does a
-- semantic ticket search; because it runs AS a vip-scoped user, the JOIN to
-- CUSTOMERS is filtered by VPD and the agent can only retrieve tickets for
-- customers it is entitled to see. Security is applied BEFORE rows reach the model.

BEGIN lab_user.agent_ctx_pkg.set_user_scope('vip'); END;
/

-- Semantic search over ticket bodies, embedded in-database by the same ONNX model
-- that embedded them — but governed: every returned row belongs to the vip segment.
SELECT 'ASSERT:hybrid_retrieval_only_authorized_rows:' ||
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS assertion
FROM ( SELECT c.segment
       FROM   lab_user.support_tickets t
       JOIN   lab_user.customers c ON c.customer_id = t.customer_id
       ORDER  BY VECTOR_DISTANCE(t.body_vec,
                   VECTOR_EMBEDDING(MINILM_L12 USING 'cannot reset my password' AS data), COSINE)
       FETCH  FIRST 5 ROWS ONLY )
WHERE segment <> 'vip';

-- The retrieved set the agent gets back (ticket id, segment, cosine distance).
SELECT t.ticket_id, c.segment,
       ROUND(VECTOR_DISTANCE(t.body_vec,
             VECTOR_EMBEDDING(MINILM_L12 USING 'cannot reset my password' AS data), COSINE), 4) AS dist
FROM   lab_user.support_tickets t
JOIN   lab_user.customers c ON c.customer_id = t.customer_id
ORDER  BY dist
FETCH  FIRST 5 ROWS ONLY;

-- One plan: vector ranking (SORT ORDER BY STOPKEY) + relational HASH JOIN +
-- the row-security predicate on CUSTOMERS, costed together by one optimizer.
EXPLAIN PLAN FOR
SELECT t.ticket_id, c.segment,
       VECTOR_DISTANCE(t.body_vec,
             VECTOR_EMBEDDING(MINILM_L12 USING 'cannot reset my password' AS data), COSINE) AS dist
FROM   lab_user.support_tickets t
JOIN   lab_user.customers c ON c.customer_id = t.customer_id
ORDER  BY dist
FETCH  FIRST 5 ROWS ONLY;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, NULL, 'TYPICAL'));
