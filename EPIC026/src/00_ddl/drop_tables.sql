--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

--tabla sobre escenario de no clientes
drop table tmp_hb_salidamodelo;

commit;
quit;