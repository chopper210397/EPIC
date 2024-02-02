--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;
alter session set nls_numeric_characters='.,';

--tablon de escenario de compra venta moneda extranjera
set echo off;
set feedback off;
set head off;
set lin 9999;
set trimspool on;
set wrap off;
set pages 0;
set term off;

spool .\data\production\01_raw.csv;
PROMPT PERIODO|CODCLAVECIC|EDAD|TIPPER|CODPROFESION|DESCODPROFESION|CATPROFESION|FECAPERTURA|ANTIGUEDAD|TIPCLI|CODSUBSEGMENTO|DESSUBSEGMENTO|CODSEGMENTO|DESSEGMENTO|FLGNOCLIENTE|CODACTECONOMICA|DESACTECONOMICA|FLG_ACTECO_NODEF|FLGNP|CTDNP|FLGLSB|CTDLSB|FLGARCHIVONEGATIVO|DESTIPMOTIVONEGATIVO|FLGNPLSBAN|CTD_AN_NP_LSB|CTDEVAL|CTD_ORDENATES_DISTINTOS|MTO_TOTAL|MTO_COMPRA|MTO_VENTA|CTD_TOTAL|CTD_COMPRA|CTD_VENTA|MTO_ZAED|CTD_ZAED|CTD_DIAS|MTO_DEPOSITOS|FLG_PERFIL_DEPOSITOS_3DS|CTD_TRX_LIM;

select
periodo||'|'||
codclavecic||'|'||
edad||'|'||
tipper||'|'||
codprofesion||'|'||
descodprofesion||'|'||
catprofesion||'|'||
fecapertura||'|'||
antiguedad||'|'||
tipcli||'|'||
codsubsegmento||'|'||
dessubsegmento||'|'||
codsegmento||'|'||
dessegmento||'|'||
flgnocliente||'|'||
codacteconomica||'|'||
desacteconomica||'|'||
flg_acteco_nodef||'|'||
flgnp||'|'||
ctdnp||'|'||
flglsb||'|'||
ctdlsb||'|'||
flgarchivonegativo||'|'||
destipmotivonegativo||'|'||
flgnplsban||'|'||
ctd_an_np_lsb||'|'||
ctdeval||'|'||
ctd_ordenates_distintos||'|'||
mto_total||'|'||
mto_compra||'|'||
mto_venta||'|'||
ctd_total||'|'||
ctd_compra||'|'||
ctd_venta||'|'||
mto_zaed||'|'||
ctd_zaed||'|'||
ctd_dias||'|'||
mto_depositos||'|'||
flg_perfil_depositos_3ds||'|'||
ctd_trx_lim
from tmp_cvme_tablon;

spool off;
quit;