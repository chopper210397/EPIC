--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode

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

--EPIC028 - Paquetes de transacciones del cliente
spool ./src/03_deploy/packages/packages_loop.sql;
PROMPT var codclavecic number;

begin
  for target_pointer in (select distinct codclavecic, codunicocli,codmes_operacion as codmes from tmp_yape_alertas )
  loop
	dbms_output.put_line('define codunicocli = '''||target_pointer.codunicocli||''';');
    dbms_output.put_line('define codmes = '''||target_pointer.codmes||''';');
    dbms_output.put_line('exec :codclavecic := '''||target_pointer.codclavecic||''';');
    dbms_output.put_line('@@./src/03_deploy/packages/packages_trx.sql;');
  end loop;
end;
/
spool off;

@@./src/03_deploy/packages/packages_loop.sql;

spool off;

@@./src/03_deploy/packages/packages_loop.sql;

spool off

quit;

