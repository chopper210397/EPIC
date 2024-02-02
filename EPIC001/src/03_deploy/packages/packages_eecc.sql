alter session disable parallel query;

spool \\PFILEP11\LAVADOACTIVOS\99_PROCESOS_BI\0_SAPYCWEB\DOCUMENTOS\&&CODMES._99999999_MODEM_EPIC001_EECC_&&CODUNICOCLI..CSV;
PROMPT CODCLAVECIC,CODUNICOCLI,NOMBRE,CODCLAVEOPECTA,CODOPECTA,CUENTACOMERCIAL,FECDIA,HORTRANSACCION,DESOPETRANSACCIONSAVINGDETALLE,GRUPO,DESCANAL,NBRSUCAGE,CODMONEDA,MTOTRANSACCION,TIPCARGOABONO,MTODOLARIZADO;

select
	codclavecic||','||
	codunicocli||','||
	nombre||','||
	codclaveopecta||','||
	codopecta||','||
	cuentacomercial||','||
	fecdia||','||
	hortransaccion||','||
	desopetransaccionsavingdetalle||','||
	grupo||','||
	descanal||','||
	nbrsucage||','||
	codmoneda||','||
	mtotransaccion||','||
	tipcargoabono||','||
	mtodolarizado
from tmp_retatmext_eecc_alertas
where codclavecic = :codclavecic;

spool off;