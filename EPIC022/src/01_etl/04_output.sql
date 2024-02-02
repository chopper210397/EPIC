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
PROMPT PERIODO|CODCLAVECIC|ANTIGUEDADCLI|MTO_TOTAL_CASH|CTD_TOTAL_CASH|MTO_TOTAL|CTDCHQGEN|MTO_CHQGEN|MTO_TOTAL_CASH_ZAED|CTD_CASH_ZAED|EDAD|TIPBANCA|DESTIPBANCA|CODPAISNACIONALIDAD|NOMBREPAIS|FLGNACIONALIDAD|CTDAGENTES|FLGAGENTE|FLGCHQGEN|PORC_CHQGEN|CTD_DIAS_DEBAJOLAVA;

select
periodo||'|'||
codclavecic||'|'||
antiguedadcli||'|'||
mto_total_cash||'|'||
ctd_total_cash||'|'||
mto_total||'|'||
ctdchqgen||'|'||
mto_chqgen||'|'||
mto_total_cash_zaed||'|'||
ctd_cash_zaed||'|'||
edad||'|'||
tipbanca||'|'||
trim(destipbanca)||'|'||
codpaisnacionalidad||'|'||
nombrepais||'|'||
flgnacionalidad||'|'||
ctdagentes||'|'||
flgagente||'|'||
flgchqgen||'|'||
porc_chqgen||'|'||
ctd_dias_debajolava
from tmp_clinuevo_ctddias_debajolava;

spool off;
quit;