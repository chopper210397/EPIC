--parametro de credenciales
@&1

alter session disable parallel query;

set echo off
set feedback off
set head off
set lin 9999
set trimspool on
set wrap off
set pages 0
set term off

SPOOL '.\data\production\01_raw.csv';

PROMPT CODMES|CODCLAVECIC|MTO_ESTIMADOR|CTDEVAL|CTD_INGRESO|MTO_INGRESO|FLG_PERFIL_DEPOSITOS_3DS;

select
codmes||'|'||
codclavecic||'|'||
replace(trim(to_char(mto_estimador,'99999999999999999990d00')),',','.')||'|'||
ctdeval||'|'||
ctd_ingreso||'|'||
replace(trim(to_char(mto_ingreso,'99999999999999999990d00')),',','.')||'|'||
flg_perfil_depositos_3ds
from tmp_esting_tablon;

spool off;

quit;