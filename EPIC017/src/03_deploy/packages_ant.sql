--PARAMETRO DE CREDENCIALES
@&1

SET ECHO ON
WHENEVER SQLERROR EXIT SQL.SQLCODE
ALTER SESSION DISABLE PARALLEL QUERY;

alter session set NLS_NUMERIC_CHARACTERS='.,';

--EPIC017 - Paquetes de transacciones del cliente

SPOOL ./src/03_deploy/packages/packages_loop.sql;

PROMPT VAR codclavecic NUMBER;

BEGIN
  FOR TARGET_POINTER IN (SELECT DISTINCT codclavecic, codunicocli FROM TMP_ESCPEP_ALERTAS )
  LOOP
	DBMS_OUTPUT.PUT_LINE('DEFINE codunicocli = '''||TARGET_POINTER.codunicocli||''';');
    DBMS_OUTPUT.PUT_LINE('EXEC :codclavecic := '''||TARGET_POINTER.codclavecic||'''; ');
    DBMS_OUTPUT.PUT_LINE('@@./src/03_deploy/packages/packages_trx.sql;');
  END LOOP;
END;
/

SPOOL OFF;

@@./src/03_deploy/packages/packages_loop.sql;

SPOOL OFF;

@@./src/03_deploy/packages/packages_loop.sql;

SPOOL OFF
quit;