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
--set colsep '|'

SPOOL \\Pfilep11\lavadoactivos\99_Procesos_BI\0_SapycWeb\PAQUETES_ADHOC\99999999_MODEM_EPIC016_EECC_&&codunicocli..csv;

PROMPT CODCLAVECIC,CODUNICOCLI,NOMBRE,CODCLAVEOPECTA,CODOPECTA,CUENTACOMERCIAL,FECDIA,HORTRANSACCION,DESOPETRANSACCIONSAVINGDETALLE,GRUPO,DESCANAL,NBRSUCAGE,CODMONEDA,MTOTRANSACCION,TIPCARGOABONO,MTODOLARIZADO;

SELECT
    CODCLAVECIC||','||
    CODUNICOCLI||','||
	REPLACE(TRIM(NOMBRE),',','')||','||
    CODCLAVEOPECTA||','||
    CODOPECTA||','||
    CUENTACOMERCIAL||','||
    FECDIA||','||
    HORTRANSACCION||','||
	REPLACE(TRIM(DESOPETRANSACCIONSAVINGDETALLE),',','')||','||
    GRUPO||','||
    DESCANAL||','||
    NBRSUCAGE||','||
    CODMONEDA||','||
	REPLACE(TRIM(TO_CHAR(MTOTRANSACCION,'99999999999999999990D00')),',','.')||','||
    TIPCARGOABONO||','||
	REPLACE(TRIM(TO_CHAR(MTODOLARIZADO,'99999999999999999990D00')),',','.')
FROM TMP_CONOCMCDO_EECC_ALERTAS
where codclavecic = :codclavecic;

SPOOL OFF;