ALTER SESSION SET CONTAINER = FREEPDB1;
ALTER SESSION SET CURRENT_SCHEMA = lab_user;

-- Hybrid Vector Index on the ticket body: one domain index unifying Oracle Text
-- (keyword) and a vector index (semantic) over the same column, queried via
-- DBMS_HYBRID_VECTOR.SEARCH with RRF/score fusion (module 03, 04-hybrid-search.sql).
-- Leaf-3-specific: the foundational model + body_vec + IVF live in 08 (on main);
-- this HVI is the article-3 hybrid-search showcase and stays on this branch.
--
-- COLLISION NOTE — RESOLVED ON MAIN: a CONTEXT/SEARCH text index and the HVI's
-- internal text component are the SAME indextype, so two cannot sit on the same
-- column (ORA-29879). On main, 05-text-vector.sql creates ticket_text_idx on
-- SUBJECT (SYNC ON COMMIT, for module 02's transactional read-after-write
-- proof) and this HVI owns BODY text search (module 03's hybrid proof) —
-- different columns, no collision, so the branch-era ticket_text_idx drop is
-- gone. The HVI's text component does NOT sync on commit (verified 2026-07-24),
-- which is why module 02's proof cannot ride on the HVI.
--
-- VECTOR_IDXTYPE IVF keeps the HVI's vector component off the Vector Pool
-- (Free-safe); MEMORY 256M caps the Oracle Text build memory modestly. Builds in
-- a few minutes over the 10,000-ticket corpus on the Free container.
DECLARE
BEGIN
  EXECUTE IMMEDIATE 'DROP INDEX tickets_hvi';
EXCEPTION WHEN OTHERS THEN NULL; /* absent — first run */
END;
/
CREATE HYBRID VECTOR INDEX tickets_hvi ON support_tickets(body)
  PARAMETERS('MODEL MINILM_L12 VECTOR_IDXTYPE IVF MEMORY 256M');
