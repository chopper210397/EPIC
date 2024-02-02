--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

alter session set nls_numeric_characters='.,';

set echo off;
set feedback off;
set head off;
set lin 9999;
set trimspool on;
set wrap off;
set pages 0;
set term off;

spool .\data\production\01_raw.csv
PROMPT PERIODO|CODCLAVECIC|MTO_OPEPOS|CTD_OPEPOS|MTO_OPEATM|CTD_OPEATM|FLG_PAISRIESGO|FLG_ECUADOR;

select
periodo||'|'||
codclavecic||'|'||
mto_opepos||'|'||
ctd_opepos||'|'||
mto_opeatm||'|'||
ctd_opeatm||'|'||
flg_paisriesgo||'|'||
flg_ecuador
from tmp_retatmext_tablon_final;

spool off;
quit;