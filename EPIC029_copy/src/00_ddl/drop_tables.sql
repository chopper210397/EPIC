--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

drop table tmp_topsolicitante_trx;
drop table tmp_topsolicitante_previa;
drop table tmp_topsolicitante_spool;
drop table tmp_topsolicitante_output;
drop table tmp_topsolicitante_filtrado;
drop table tmp_topsolicitante_alerta;
drop table tmp_trx_epic029;

commit;
quit;