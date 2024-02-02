--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

create table tmp_egbcacei_outputmodel
(
numperiodo number,
codclavecic number,
mto_egresos number,
mto_ext number,
pctje_ext number,
ctd_dias_debajolava02 number,
flg_perfil_3desvt number,
flg_ros_rel number,
flg_rel_extranj number,
flg_an_ben number,
flg_rel_pep number ,
flg_lsb_np_ben number,
cluster_kmeans number
)tablespace d_aml_99;
commit;
quit;