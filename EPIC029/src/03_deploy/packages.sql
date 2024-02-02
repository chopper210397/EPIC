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

--EPIC029 - Paquetes de transacciones del cliente

spool ./src/03_deploy/packages/packages_loop.sql;

prompt var codunicoclimask varchar2(17);

begin
  for target_pointer in (select distinct codunicocli, codunicocli as codunicoclimask,periodo as codmes from tmp_topsolicitante_alerta )
  loop
	dbms_output.put_line('define codunicocli = '''||target_pointer.codunicocli||''';');
    dbms_output.put_line('exec :codunicoclimask := '''||target_pointer.codunicoclimask||''';');
    dbms_output.put_line('define codmes = '''||target_pointer.codmes||''';');
    dbms_output.put_line('@@./src/03_deploy/packages/packages_trx.sql;');
  end loop;
  
end;
/

spool off;

@@./src/03_deploy/packages/packages_loop.sql;

spool off

quit;