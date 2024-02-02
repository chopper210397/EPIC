alter session disable parallel query;

set echo off
set feedback off
set head off
set lin 9999
set trimspool on
set wrap off
set pages 0
set term off
set colsep '|'

spool \\Pfilep11\lavadoactivos\99_Procesos_BI\0_SapycWeb\PAQUETES_ADHOC\&&codmes._99999999_MODEM_EPIC023_TRXS_&&CODUNICOCLI..CSV;
PROMPT NUMREGISTRO|FECDIA|HORINITRANSACCION|HORFINTRANSACCION|CODSUCAGE|CODSESION|CODTRANSACCIONVENTANILLA|DESTRANSACCIONVENTANILLA|FLGTRANSACCIONAPROBADA|TIPROLTRANSACCION|CODMONEDA|MTOTRANSACCION|MTODOLARIZADO|CODOPECTA|CODOPECTADESTINO|CODCLAVECIC_SOLICITANTE|CODUNICOCLISOLICITANTE|NOMBRESOLICITANTE|CODCLAVECIC_ORDENANTE|CODUNICOCLIORDENANTE|NOMBREORDENANTE;

select 
	numregistro||'|'||
	fecdia||'|'||
	horinitransaccion||'|'||
	horfintransaccion||'|'||
	codsucage||'|'||
	codsesion||'|'||
	codtransaccionventanilla||'|'||
	destransaccionventanilla||'|'||
	flgtransaccionaprobada||'|'||
	tiproltransaccion||'|'||
	codmoneda||'|'||
	replace(trim(to_char(mtotransaccion,'99999999999999999990d00')),'|','.')||'|'||
	replace(trim(to_char(mtodolarizado,'99999999999999999990d00')),'|','.')||'|'||	
	codopecta||'|'||
	codopectadestino||'|'||
	codclavecic_solicitante||'|'||
	codunicoclisolicitante||'|'||
	nombresolicitante||'|'||
	codclavecic_ordenante||'|'||
	codunicocliordenante||'|'||
	nombreordenante
from tmp_trx_epic023
where codclavecic_solicitante = :codclavecic ;

spool off;