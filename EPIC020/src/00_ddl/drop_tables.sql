--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

drop table tmp_egbcacei_outputmodel;

commit;
quit;