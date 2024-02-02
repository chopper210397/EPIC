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

spool .\data\production\01_raw.csv;
PROMPT PERIODO|CODCLAVECIC|TIPPER|FLGARCHIVONEGATIVO|MTODOLARIZADO|PAISRIESGO_MONTO|CTD_BENEFICIARIO|CTDEVAL|INDICE_CONCENTRADOR|RATIO;

--tablon de escenario de agentes
select
periodo||'|'||
codclavecic||'|'||
tipper||'|'||
flgarchivonegativo||'|'||
mtodolarizado||'|'||
paisriesgo_monto||'|'||
ctd_beneficiario||'|'||
ctdeval||'|'||
indice_concentrador||'|'||
ratio
from tmp_hb_data;

spool off;
quit;