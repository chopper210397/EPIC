--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

--tabla sobre escenario de retiros en el exterior
drop table tmp_retatmext_salida_modelo;

commit;
quit;