--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

set echo off
set feedback off
set head off
set lin 256
set trimspool on
set wrap off
set pages 0
set term off
set colsep ','

spool .\data\production\01_raw.csv;

prompt numperiodo,codclavecic,mto_egresos,mto_ext,pctje_ext,ctd_dias_debajolava02,flg_perfil_3desvt,flg_ros_rel,flg_rel_extranj,flg_lsb_np_ben,flg_an_ben,flg_rel_pep;

select
	numperiodo||','||
	codclavecic||','||
	replace(trim(to_char(mto_egresos,'99999999999999999990d00')),',','.')||','||
	replace(trim(to_char(mto_ext,'99999999999999999990d00')),',','.')||','||
	replace(trim(to_char(pctje_ext,'99999999999999999990d00')),',','.')||','||
	ctd_dias_debajolava02||','||
	flg_perfil_3desvt||','||
	flg_ros_rel||','||
	flg_rel_extranj||','||
	flg_lsb_np_ben||','||
	flg_an_ben||','||
	flg_rel_pep
from tmp_egbcacei_cliemes_egretot10;

spool off;
quit;