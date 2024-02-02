ALTER SESSION DISABLE PARALLEL QUERY;

SET ECHO OFF
SET FEEDBACK OFF
SET HEAD OFF
SET LIN 256
SET TRIMSPOOL ON
SET WRAP OFF
SET PAGES 0
SET TERM OFF
set colsep ','

SPOOL \\PFILEP11\LAVADOACTIVOS\99_PROCESOS_BI\0_SAPYCWEB\DOCUMENTOS\99999999_MODEM_EPIC017_EECC_&&CODUNICOCLI..CSV;

PROMPT CODCLAVECIC,CODUNICOCLI,NOMBRE,CODCLAVEOPECTA,CODOPECTA,CUENTACOMERCIAL,FECDIA,HORTRANSACCION,DESOPETRANSACCIONSAVINGDETALLE,GRUPO,DESCANAL,NBRSUCAGE,CODMONEDA,MTOTRANSACCION,TIPCARGOABONO,MTODOLARIZADO;

SELECT
	CODCLAVECIC||','||
	CODUNICOCLI||','||
	NOMBRE||','||
	CODCLAVEOPECTA||','||
	CODOPECTA||','||
	CUENTACOMERCIAL||','||
	FECDIA||','||
	HORTRANSACCION||','||
	DESOPETRANSACCIONSAVINGDETALLE||','||
	GRUPO||','||
	DESCANAL||','||
	NBRSUCAGE||','||
	CODMONEDA||','||
	MTOTRANSACCION||','||
	TIPCARGOABONO||','||
	MTODOLARIZADO
FROM TMP_ESCPEP_EECC_ALERTAS
WHERE CODCLAVECIC = :CODCLAVECIC;

SPOOL OFF;