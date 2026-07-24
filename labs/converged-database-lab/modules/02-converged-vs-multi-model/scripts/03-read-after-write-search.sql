DELETE /* Module 02 proof 3: transactional read-after-write text search.

   A row INSERTed and COMMITted is immediately findable through the Oracle
   Text search index (CONTAINS) — no refresh interval, no change-stream lag,
   no separate search process. The lab's ticket_text_idx is created with
   PARAMETERS ('SYNC (ON COMMIT)') (docker/init/05-text-vector.sql): the index
   syncs inside the committing transaction, so search visibility arrives WITH
   the commit, not eventually after it.

   MAIN-BRANCH RECONCILIATION: on main the SYNC(ON COMMIT) search index lives
   on SUBJECT (module 03's Hybrid Vector Index owns body text search, and the
   HVI's text component does not sync on commit — verified 2026-07-24), so
   this proof carries its marker token in the subject and probes
   CONTAINS(subject, ...). The article/02 branch keeps the body-marker form
   that the published article's snippets byte-match; the property proven —
   search visibility inside the committing transaction — is identical.

   COMMIT WARNING: this script intentionally COMMITs — a documented exception
   to the rollback contract (see the module README). Read-after-write through
   a text index can only be demonstrated across a real commit boundary.
   Explicit cleanup restores the domain: the probe ticket is deleted and the
   delete is committed. The script is also reseed-safe — ticket_id is
   identity-generated and nothing assumes a fixed id; the probe row is
   addressed only by its unique subject and marker token.

   This first statement is an idempotence guard: remove any probe rows left by
   a previously interrupted run (committed together with the INSERT below). */
FROM support_tickets WHERE subject LIKE 'm02 rw-search probe%';

INSERT INTO support_tickets (customer_id, subject, body, status)
VALUES (1, 'm02 rw-search probe zzqxw9347',
        'read-after-write search probe (marker token in subject)', 'open');

COMMIT;

SELECT /* the committed row is findable by CONTAINS immediately — same call
          stack, same second, no sync window */
       'ASSERT:contains-finds-committed-write:' ||
       CASE WHEN COUNT(*) = 1 THEN 'PASS' ELSE 'FAIL' END
FROM support_tickets WHERE CONTAINS(subject, 'zzqxw9347') > 0;

DELETE /* explicit cleanup: remove the probe ticket */
FROM support_tickets WHERE subject LIKE 'm02 rw-search probe%';

COMMIT;

SELECT /* and the committed delete is just as immediately invisible to
          search — read-after-write holds in both directions */
       'ASSERT:contains-after-cleanup:' ||
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM support_tickets WHERE CONTAINS(subject, 'zzqxw9347') > 0;

SELECT /* domain restored: no probe rows survive in the base table either */
       'ASSERT:probe-rows-gone:' ||
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM support_tickets WHERE subject LIKE 'm02 rw-search probe%';
