-- 09-agent-security.sql — Secure Agent Access (Module 06) setup. Runs as SYS in FREEPDB1.
--
-- Installs the in-engine controls a SELECT-time AI agent inherits when it reads
-- enterprise data through the converged engine:
--   1) an application context that carries the acting user's identity — the
--      "identity propagation" path an agent connects through;
--   2) a mode-gated Virtual Private Database (row-level security) policy on
--      CUSTOMERS — non-agent sessions (operators, ETL, the other lab modules)
--      are unaffected; agent-mode sessions are DENY-BY-DEFAULT and scoped to
--      exactly the propagated identity;
--   3) a least-privilege JSON Relational Duality View — no email, read-only;
--   4) a unified audit policy over the governed table; and
--   5) a helper that proves the read-only view rejects writes from a SELECT.
--
-- These are SYS-level objects, so they live in init (not in the LAB_USER module
-- scripts the validator runs). The module asserts their behavior as LAB_USER.

ALTER SESSION SET CONTAINER = FREEPDB1;

-- ---- idempotent teardown (safe re-apply) ----
BEGIN DBMS_RLS.DROP_POLICY('LAB_USER','CUSTOMERS','AGENT_ROW_SECURITY'); EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP VIEW lab_user.customer_support_dv'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'NOAUDIT POLICY agent_access_pol'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP AUDIT POLICY agent_access_pol'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

ALTER SESSION SET CURRENT_SCHEMA = lab_user;

-- ---- 1) identity-propagation context + its trusted setter package ----
-- The context can ONLY be set by this package (CREATE CONTEXT ... USING). That is
-- the point: a prompt cannot forge an identity; only the trusted connection path can.
CREATE OR REPLACE PACKAGE lab_user.agent_ctx_pkg AS
  PROCEDURE set_agent_mode;                          -- enter the agent path, no identity yet
  PROCEDURE set_user_scope(p_segment IN VARCHAR2);   -- propagate the acting user's entitlement
  PROCEDURE clear_scope;
END;
/
CREATE OR REPLACE PACKAGE BODY lab_user.agent_ctx_pkg AS
  PROCEDURE set_agent_mode IS
  BEGIN
    DBMS_SESSION.SET_CONTEXT('agent_scope','mode','agent');
    DBMS_SESSION.CLEAR_CONTEXT('agent_scope', NULL, 'allowed_segment');
  END;
  PROCEDURE set_user_scope(p_segment IN VARCHAR2) IS
  BEGIN
    DBMS_SESSION.SET_CONTEXT('agent_scope','mode','agent');
    DBMS_SESSION.SET_CONTEXT('agent_scope','allowed_segment', p_segment);
  END;
  PROCEDURE clear_scope IS
  BEGIN
    DBMS_SESSION.CLEAR_CONTEXT('agent_scope');
  END;
END;
/
CREATE OR REPLACE CONTEXT agent_scope USING lab_user.agent_ctx_pkg;

-- ---- 2) mode-gated row-level security: the engine enforces least privilege ----
CREATE OR REPLACE FUNCTION lab_user.agent_row_filter(p_schema VARCHAR2, p_obj VARCHAR2)
  RETURN VARCHAR2 AS
  v_seg VARCHAR2(100);
BEGIN
  -- Non-agent sessions are unaffected (operators, ETL, the other lab modules).
  IF NVL(SYS_CONTEXT('agent_scope','mode'),'x') <> 'agent' THEN
    RETURN '1=1';
  END IF;
  -- Agent path: deny-by-default until an identity is propagated.
  v_seg := SYS_CONTEXT('agent_scope','allowed_segment');
  IF v_seg IS NULL THEN
    RETURN '1=0';
  END IF;
  -- Identity propagated: the engine returns exactly the acting user's rows.
  RETURN 'segment = SYS_CONTEXT(''agent_scope'',''allowed_segment'')';
END;
/
BEGIN
  DBMS_RLS.ADD_POLICY(
    object_schema   => 'LAB_USER', object_name => 'CUSTOMERS',
    policy_name     => 'AGENT_ROW_SECURITY',
    function_schema => 'LAB_USER', policy_function => 'AGENT_ROW_FILTER',
    statement_types => 'SELECT');
END;
/

-- ---- 3) least-privilege document front end: no email, read-only ----
-- A support-triage agent reads customer documents through THIS view. 'email' is
-- never projected, and the absence of WITH INSERT/UPDATE/DELETE makes the whole
-- view read-only — excessive agency is contained by the contract, not the prompt.
CREATE OR REPLACE JSON RELATIONAL DUALITY VIEW lab_user.customer_support_dv AS
SELECT JSON {
  '_id'      : c.customer_id,
  'fullName' : c.full_name,
  'segment'  : c.segment,
  'tickets'  : [ SELECT JSON {
                   'ticketId' : t.ticket_id,
                   'subject'  : t.subject,
                   'status'   : t.status }
                 FROM support_tickets t
                 WHERE t.customer_id = c.customer_id ]
} FROM customers c;

-- ---- 4) helper: prove the read-only view rejects writes (callable from SELECT) ----
CREATE OR REPLACE FUNCTION lab_user.assert_dv_readonly RETURN VARCHAR2 AS
  PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
  EXECUTE IMMEDIATE q'[UPDATE lab_user.customer_support_dv c
                          SET c.data = json_transform(c.data, SET '$.segment' = 'premium')
                        WHERE ROWNUM = 1]';
  ROLLBACK;
  RETURN 'FAIL';                         -- a read-only duality view must never accept the write
EXCEPTION WHEN OTHERS THEN
  ROLLBACK;
  RETURN CASE WHEN SQLCODE = -42690 THEN 'PASS' ELSE 'FAIL' END;  -- ORA-42690: view is read-only
END;
/

-- ---- 5) one unified audit trail over the governed table ----
CREATE AUDIT POLICY agent_access_pol ACTIONS SELECT ON lab_user.customers;
AUDIT POLICY agent_access_pol;
GRANT AUDIT_VIEWER TO lab_user;            -- so the module can read the trail it generates
