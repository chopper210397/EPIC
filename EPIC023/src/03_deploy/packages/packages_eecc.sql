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

spool \\PFILEP11\LAVADOACTIVOS\99_PROCESOS_BI\0_SAPYCWEB\DOCUMENTOS\&&codmes._99999999_MODEM_EPIC023_EECC_&&CODUNICOCLI..CSV;
PROMPT CODCLAVECIC|CODUNICOCLI|NOMBRE|CODCLAVEOPECTA|CODOPECTA|CUENTACOMERCIAL|FECDIA|HORTRANSACCION|DESOPETRANSACCIONSAVINGDETALLE|GRUPO|DESCANAL|NBRSUCAGE|CODMONEDA|MTOTRANSACCION|TIPCARGOABONO|MTODOLARIZADO;

select
	codclavecic||'|'||
	codunicocli||'|'||
	nombre||'|'||
	codclaveopecta||'|'||
	codopecta||'|'||
	cuentacomercial||'|'||
	fecdia||'|'||
	hortransaccion||'|'||
	desopetransaccionsavingdetalle||'|'||
	grupo||'|'||
	descanal||'|'||
	nbrsucage||'|'||
	codmoneda||'|'||
	mtotransaccion||'|'||
	tipcargoabono||'|'||
	mtodolarizado
from tmp_cvme_eecc_alertas
where codclavecic = :codclavecic;

spool off;