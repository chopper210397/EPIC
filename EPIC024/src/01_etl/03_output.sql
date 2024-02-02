--parametro de credenciales
@&1

alter session disable parallel query;

set echo off;
set feedback off;
set head off;
set lin 9999;
set trimspool on;
set wrap off;
set pages 0;
set term off;

spool .\data\production\01_raw.csv;
PROMPT PERIODO|CODCLAVECIC|EDAD|TIPPER|ANTIGUEDAD|CODACTECONOMICA|DESACTECONOMICA|FLG_ACTECO_NODEF|FLGNP|CTDNP|FLGLSB|CTDLSB|FLGARCHIVONEGATIVO|DESTIPMOTIVONEGATIVO|CTD_NP_LSB|CTDEVAL|CODSUBSEGMENTO|DESSUBSEGMENTO|CODSEGMENTO|DESSEGMENTO|TIPDIR|CODUBIGEO|CODDISTRITO|DESCODDISTRITO|CODPROVINCIA|DESCODPROVINCIA|CODDEPARTAMENTO|DESCODDEPARTAMENTO|CODPAISNACIONALIDAD|DESCODPAISNACIONALIDAD|FLGNACIONALIDAD|MTO_INGRESOS_MES|CTD_INGRESOS_MES|MEDIA_INGRESOS|DESV_INGRESOS|FLG_PERFIL_INGRESOS_3DS|MAX_CTDMTOSREDONDOS|SUM_MTOSREDONDOS|CTDMAXIMA|MTO_MAXIMOSREPETIDOS|MTOMAXDEMAXREPETIDOS|MTO_CONOTROSPROXIMOS|CTD_CONOTROSPROXIMOS;

select
periodo||'|'||
codclavecic||'|'||
case when coalesce(edad,0)<0 then 0 else coalesce(edad,0) end||'|'||
tipper||'|'||
case when coalesce(antiguedad,0)<0 then 0 else coalesce(antiguedad,0) end||'|'||
codacteconomica||'|'||
desacteconomica||'|'||
flg_acteco_nodef||'|'||
flgnp||'|'||
coalesce(ctdnp,0)||'|'||
flglsb||'|'||
coalesce(ctdlsb,0)||'|'||
flgarchivonegativo||'|'||
destipmotivonegativo||'|'||
coalesce(ctd_np_lsb,0)||'|'||
coalesce(ctdeval,0)||'|'||
codsubsegmento||'|'||
dessubsegmento||'|'||
codsegmento||'|'||
dessegmento||'|'||
tipdir||'|'||
codubigeo||'|'||
coddistrito||'|'||
descoddistrito||'|'||
codprovincia||'|'||
descodprovincia||'|'||
coddepartamento||'|'||
descoddepartamento||'|'||
codpaisnacionalidad||'|'||
descodpaisnacionalidad||'|'||
coalesce(flgnacionalidad,0)||'|'||
replace(trim(to_char(mto_ingresos_mes,'99999999999999999990d00')),',','.')||'|'||
ctd_ingresos_mes||'|'||
replace(trim(to_char(media_ingresos,'99999999999999999990d00')),',','.')||'|'||
replace(trim(to_char(desv_ingresos,'99999999999999999990d00')),',','.')||'|'||
flg_perfil_ingresos_3ds||'|'||
max_ctdmtosredondos||'|'||
replace(trim(to_char(sum_mtosredondos,'99999999999999999990d00')),',','.')||'|'||
ctdmaxima||'|'||
replace(trim(to_char(mto_maximosrepetidos,'99999999999999999990d00')),',','.')||'|'||
replace(trim(to_char(mtomaxdemaxrepetidos,'99999999999999999990d00')),',','.')||'|'||
replace(trim(to_char(mto_conotrosproximos,'99999999999999999990d00')),',','.')||'|'||
ctd_conotrosproximos
from tmp_ingrestrc_mtosyctdsproximos_tablon;

spool off;
quit;