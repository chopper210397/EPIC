alter session disable parallel query;

set echo off;
set feedback off;
set head off;
set lin 9999;
set trimspool on;
set wrap off;
set pages 0;
set term off;

spool \\pfilep11\lavadoactivos\99_procesos_bi\0_sapycweb\paquetes_adhoc\&&codmes._999999999_modem_epic024_pn_trxs_&&codunicocli..csv;
PROMPT PERIODO,CODCLAVECIC,CODSUCAGE,CODCLAVECICORDENANTE,CODUNICOCLIORDENANTE,NOMBREORDENANTE,CODOPECTAORDENANTE,BANCOEMISOR,NBRPAISORIGEN,FECDIA,HORTRANSACCION,CODMONEDA,MTOTRANSACCION,MTODOLARIZADO,MTO_CONOTROSPROXIMOS,CODPRODUCTO,DESCODPRODUCTO,CODCLAVECICBENEFICIARIO,CODUNICOCLIBENEFICIARIO,NOMBREBENEFICIARIO,CODOPECTABENEFICIARIO;

select
	periodo||'|'||
	codclavecic||'|'||
	codsucage||'|'||
	codclavecicordenante||'|'||
	codunicocliordenante||'|'||
	nombreordenante||'|'||
	codopectaordenante||'|'||
	bancoemisor||'|'||
	nbrpaisorigen||'|'||
	fecdia||'|'||
	hortransaccion||'|'||
	codmoneda||'|'||
	replace(trim(to_char(mtotransaccion,'99999999999999999990d00')),'|','.')||'|'||
	replace(trim(to_char(mtodolarizado,'99999999999999999990d00')),'|','.')||'|'||
	replace(trim(to_char(mto_conotrosproximos,'99999999999999999990d00')),'|','.')||'|'||
	codproducto||'|'||
	descodproducto||'|'||
	codclavecicbeneficiario||'|'||
	codunicoclibeneficiario||'|'||
	nombrebeneficiario||'|'||
	codopectabeneficiario
from tmp_trx_epic024_pn
where codclavecicbeneficiario = :codclavecic;

spool off;