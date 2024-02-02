--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

--tabla sobre escenario de no clientes
drop table tmp_clinuevo_salida_modelo;

commit;
quit;