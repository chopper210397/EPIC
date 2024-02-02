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

PROMPT NUMPERIODO|CODCLAVECIC|MTO_INGRESO|NUM_INGRESO|ANTIGUEDADCLIENTE|MTO_CTAS_RECIENTES|POR_CASH|FLG_PERFIL|FLG_AN_LSB_NP|FLG_ACT_ECO|CTD_DIAS_DEBAJOLAVA02|PORC_CASH_MESANTERIOR|FLG_REL_AN_LSB_NP|FLG_ACTECO_PLAFT|FLG_MARCASENSIBLE_PLAFT;

select
	numperiodo||'|'||
	codclavecic||'|'||
	mto_ingreso||'|'||
	num_ingreso||'|'||
	antiguedadcliente||'|'||
	mto_ctas_recientes||'|'||
	por_cash||'|'||
	flg_perfil||'|'||
	flg_an_lsb_np||'|'||
	flg_act_eco||'|'||
	ctd_dias_debajolava02||'|'||
	porc_cash_mesanterior||'|'||
	flg_rel_an_lsb_np||'|'||
	flg_acteco_plaft||'|'||
	flg_marcasensible_plaft
from tmp_ingcashbcacei_final;

spool off
quit;