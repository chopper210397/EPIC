--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

--tabla sobre fuera de perfil en gremios
drop table tmp_ingcashbcacei_outputmodel;

commit;
quit;