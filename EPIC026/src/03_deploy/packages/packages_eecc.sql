spool \\pfilep11\lavadoactivos\99_procesos_bi\0_sapycweb\documentos\&&codmes._99999999_modem_epic026_eecc_&&codunicocli..csv;
PROMPT CODCLAVECIC,CODUNICOCLI,NOMBRE,CODCLAVEOPECTA,CODOPECTA,CUENTACOMERCIAL,FECDIA,HORTRANSACCION,DESOPETRANSACCIONSAVINGDETALLE,GRUPO,DESCANAL,NBRSUCAGE,CODMONEDA,MTOTRANSACCION,TIPCARGOABONO,MTODOLARIZADO;

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
from tmp_hb_eecc_alertas
where codclavecic = :codclavecic;

spool off;