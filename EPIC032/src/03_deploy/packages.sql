--PARAMETRO DE CREDENCIALES
@&1

SET ECHO ON
WHENEVER SQLERROR EXIT SQL.SQLCODE
ALTER SESSION DISABLE PARALLEL QUERY;

SET ECHO OFF;
SET FEEDBACK OFF;
SET HEAD OFF;
SET LIN 9999;
SET TRIMSPOOL ON;
SET WRAP OFF;
SET PAGES 0;
SET TERM OFF;
SET SERVEROUTPUT ON;

ALTER session disable parallel query;
alter session set NLS_NUMERIC_CHARACTERS='.,';

-- Paquetes Historico del gremio

SPOOL ./src/03_deploy/packages/packages_loop.sql;

PROMPT VAR CODCLAVECIC char(13);

BEGIN
  FOR TARGET_POINTER IN (select distinct  a.codunicocli_limpio as codclavecic, a.codunicocli_limpio, 
                          periodo as codmes from tmp_epic032_alertas a)
                            
  LOOP
	  DBMS_OUTPUT.PUT_LINE('DEFINE codunicocli_limpio = '''||TARGET_POINTER.codunicocli_limpio||''';');
    DBMS_OUTPUT.PUT_LINE('EXEC :CODCLAVECIC := '''||TARGET_POINTER.CODCLAVECIC||''';');
    DBMS_OUTPUT.PUT_LINE('DEFINE codmes = '''||TARGET_POINTER.codmes||''';');
    DBMS_OUTPUT.PUT_LINE('@@./src/03_deploy/packages/packages_trx.sql;');
  END LOOP;
END;
/

SPOOL OFF;

@@./src/03_deploy/packages/packages_loop.sql;

SPOOL OFF

quit;