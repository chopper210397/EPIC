--parametro de credenciales
@&1

set echo on
set echo off;
set feedback off;
set head off;
set lin 256;
set trimspool on;
set wrap off;
set pages 0;
set term off;
set serveroutput on;

whenever sqlerror exit sql.sqlcode
alter session disable parallel query;
alter session set nls_numeric_characters='.,';

--epic021 - paquetes de transacciones del cliente

spool ./src/03_deploy/packages/packages_loop.sql;
PROMPT VAR codclavecic NUMBER;

begin
  for target_pointer in (select distinct codclavecic, codunicocli, codagenteviabcp, periodo as codmes from tmp_escagente_alertas)
  loop
	dbms_output.put_line('define codunicocli = '''||target_pointer.codunicocli||''';');
  dbms_output.put_line('define codmes = '''||target_pointer.codmes||''';');
  dbms_output.put_line('exec :codclavecic := '''||target_pointer.codclavecic||''';');
	dbms_output.put_line('define codagenteviabcp = '''||target_pointer.codagenteviabcp||''';');
  dbms_output.put_line('@@./src/03_deploy/packages/packages_trx.sql;');
  end loop;
end;
/
spool off;
@@./src/03_deploy/packages/packages_loop.sql;
/*
--epic021 - paquetes de eecc del cliente

spool ./src/03_deploy/packages/packages_loop.sql;
prompt var codclavecic number;

begin
  for target_pointer in (select distinct codclavecic, codunicocli, periodo as codmes from tmp_escagente_alertas)
  loop
	  dbms_output.put_line('define codunicocli = '''||target_pointer.codunicocli||''';');
    dbms_output.put_line('define codmes = '''||target_pointer.codmes||''';');
    dbms_output.put_line('exec :codclavecic := '''||target_pointer.codclavecic||'''; ');
    dbms_output.put_line('@@./src/03_deploy/packages/packages_eecc.sql;');
  end loop;
end;
/
spool off;
@@./src/03_deploy/packages/packages_loop.sql;
*/
spool off;
quit;