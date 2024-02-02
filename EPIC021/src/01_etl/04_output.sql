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

PROMPT PERIODO|CODAGENTEVIABCP|CODCLAVECIC|CODCLAVEOPECTAAGENTE|MTO_CASH_DEPO|CTD_CASH_DEPO|MTO_CASH_RET|CTD_CASH_RET|CTD_TRXS_SINCTAAGENTE|FECAPERTURA|ANTIGUEDAD|CODACTECONOMICA|DESACTECONOMICA|FLG_ACTECO_NODEF|FLG_PERFIL_CASH_DEPO_3DS|CTD_TRXSFUERAHORARIO|PROM_DEPODIARIOS|CTD_DIASDEPO|PROM_RETDIARIOS|CTD_DIASRET|CODSUCAGE|CODDEPARTAMENTO|DESCODDEPARTAMENTO|TIPO_ZONA|CTD_AN_NP_LSB|MTO_AN_NP_LSB|CTDEVAL|CTD_EVALS_PROP;

select
periodo||'|'||
codagenteviabcp||'|'||
codclavecic||'|'||
codclaveopectaagente||'|'||
mto_cash_depo||'|'||
ctd_cash_depo||'|'||
mto_cash_ret||'|'||
ctd_cash_ret||'|'||
ctd_trxs_sinctaagente||'|'||
fecapertura||'|'||
antiguedad||'|'||
codacteconomica||'|'||
desacteconomica||'|'||
flg_acteco_nodef||'|'||
flg_perfil_cash_depo_3ds||'|'||
ctd_trxsfuerahorario||'|'||
prom_depodiarios||'|'||
ctd_diasdepo||'|'||
prom_retdiarios||'|'||
ctd_diasret||'|'||
codsucage||'|'||
coddepartamento||'|'||
descoddepartamento||'|'||
tipo_zona||'|'||
ctd_an_np_lsb||'|'||
mto_an_np_lsb||'|'||
ctdeval||'|'||
ctd_evals_prop
from tmp_escagente_tablon;

spool off
quit;