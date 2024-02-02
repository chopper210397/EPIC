--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

--tabla sobre escenario de cv me
drop table tmp_cvme_salida_modelo;

commit;
quit;