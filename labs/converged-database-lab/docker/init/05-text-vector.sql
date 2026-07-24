ALTER SESSION SET CONTAINER = FREEPDB1;
ALTER SESSION SET CURRENT_SCHEMA = lab_user;

-- Oracle Text index on ticket SUBJECTS: keyword search in the same
-- engine/transaction. SYNC (ON COMMIT): the index syncs inside the committing
-- transaction, so a committed row is immediately findable via CONTAINS —
-- transactional read-after-write search (module 02 proves this). The 26ai Free
-- default for CREATE SEARCH INDEX is MAINTENANCE AUTO with deferred background
-- sync (ctx_user_indexes showed IDX_SYNC_TYPE = MANUAL), under which a probe
-- row was NOT visible to CONTAINS immediately after COMMIT.
--
-- MERGE RECONCILIATION (modules 02 + 03 together on main): this index lives on
-- SUBJECT here, not BODY. Module 03's Hybrid Vector Index owns body text search
-- (an HVI's text component is the same indextype as a SEARCH index — two cannot
-- share a column, ORA-29879), and the HVI's text component does NOT sync on
-- commit (verified empirically 2026-07-24: a committed probe row was not
-- CONTAINS-findable through the HVI). Module 02's read-after-write proof
-- therefore probes the subject column on main; the article/02 BRANCH keeps the
-- body form that the published article's snippets byte-match.
CREATE SEARCH INDEX ticket_text_idx ON support_tickets (subject)
  PARAMETERS ('SYNC (ON COMMIT)');

-- Vector index. IVF (NEIGHBOR PARTITIONS) — works within Free-tier memory without
-- carving VECTOR_MEMORY_SIZE; module 03 demonstrates HNSW + memory sizing.
CREATE VECTOR INDEX ticket_vec_idx ON support_tickets (embedding)
  ORGANIZATION NEIGHBOR PARTITIONS
  DISTANCE COSINE;
