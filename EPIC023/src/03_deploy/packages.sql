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

alter session set nls_numeric_characters='.,';

--epic023 - paquetes de transacciones del cliente
spool ./src/03_deploy/packages/packages_loop.sql;
PROMPT var codclavecic number;

begin
  for target_pointer in (select distinct codclavecic, codunicocli, periodo as codmes from tmp_cvme_alertas )
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
/*
--epic023 - paquetes de eecc del cliente

spool ./deploy/paquetes/paquetes_loop.sql;

prompt var codclavecic number;

begin
  for target_pointer in (select distinct codclavecic, codunicocli, periodo as codmes from tmp_cvme_alertas )
  loop
	  dbms_output.put_line('define codunicocli = '''||target_pointer.codunicocli||''';');
    dbms_output.put_line('define codmes = '''||target_pointer.codmes||''';');
    dbms_output.put_line('exec :codclavecic := '''||target_pointer.codclavecic||'''; ');
    dbms_output.put_line('@@./src/03_deploy/packages/packages_eecc.sql;');
  end loop;

end;
/
*/
spool off;
@@./src/03_deploy/packages/packages_loop.sql;

spool off;
quit;