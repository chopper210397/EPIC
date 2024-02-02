--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

set echo off;
set feedback off;
set head off;
set lin 256;
set trimspool on;
set wrap off;
set pages 0;
set term off;
set serveroutput on;

alter session disable parallel query;
alter session set nls_numeric_characters='.,';

--epic020 - paquetes de transacciones del cliente
spool ./src/03_deploy/packages/packages_loop.sql;

prompt var codclavecic number;

begin
  for target_pointer in (select distinct codclavecic, codunicocli from tmp_egbcacei_alertas )
  loop
	  dbms_output.put_line('DEFINE CODUNICOCLI = '''||target_pointer.codunicocli||''';');
    dbms_output.put_line('EXEC :CODCLAVECIC := '''||target_pointer.codclavecic||'''; ');
    dbms_output.put_line('@@./src/03_deploy/packages/packages_trx.sql');
  end loop;

end;
/

spool off;

@@./src/03_deploy/packages/packages_loop.sql;

/*
--EPIC020 - Paquetes de EECC del cliente
-- NOTA: Se comentó en coordinación con Antony debido a que no se necesita esta ejecución (Atte. Cristian Cabrera)
spool ./src/03_deploy/packages/packages_loop.sql;

prompt var codclavecic number;

begin
  for target_pointer in (select distinct codclavecic, codunicocli from tmp_clinuevo_alertas_1 )
  loop
	  DBMS_OUTPUT.PUT_LINE('DEFINE codunicocli = '''||TARGET_POINTER.codunicocli||''';');
    DBMS_OUTPUT.PUT_LINE('EXEC :codclavecic := '''||TARGET_POINTER.codclavecic||'''; ');
    DBMS_OUTPUT.PUT_LINE('@@./Deploy/Paquetes/PAQUETES_EECC_CSV.sql;');
  end loop;

end;
/

spool off;

@@./src/03_deploy/packages/packages_loop.sql;
*/

spool off;
quit;