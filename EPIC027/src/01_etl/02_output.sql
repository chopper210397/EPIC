--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;
alter session set nls_numeric_characters='.,';

--tablon de escenario de agentes
set echo off;
set feedback off;
set head off;
set lin 9999;
set trimspool on;
set wrap off;
set pages 0;
set term off;

spool .\data\production\01_raw.csv;
PROMPT CODMES|CODCLAVECIC|VARIACIO_1M_TOTAL_DEUDA|RATIO_NO_TOTAL_SF_HAB;

select
codmes||'|'||
codclavecic||'|'||
variacio_1m_total_deuda||'|'||
ratio_no_total_sf_hab
from tmp_grm_universo_comercial;

spool off;
quit;