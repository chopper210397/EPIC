--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

--tabla salida gremio
drop table tmp_grm_salida_modelo;

commit;
quit;