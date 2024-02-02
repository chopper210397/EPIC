--PARAMETRO DE CREDENCIALES
@&1

SET ECHO ON
WHENEVER SQLERROR EXIT SQL.SQLCODE
ALTER SESSION DISABLE PARALLEL QUERY;

--TABLA EPIC017

--DROP TABLE EPIC017;
--CREATE TABLE EPIC017 TABLESPACE D_AML_99 AS
TRUNCATE TABLE EPIC017;
INSERT INTO EPIC017
SELECT
      SYSDATE AS FECGENERACION, 38 AS IDORIGEN, A.CODUNICOCLI, 'EPIC017' AS ESCENARIO,
      'EPIC017 - ESCENARIO DE PEPS' AS DESESCENARIO, 'ULTIMO MES' AS PERIODO,
      CASE
        WHEN n_cluster IN (2,5) THEN ROUND(a.MTO_AL_TTEE+a.MTO_DEL_TTEE,2)
        WHEN n_cluster IN (3) THEN ROUND(a.MTO_TOTAL,2)
        WHEN n_cluster IN (4) THEN ROUND(a.MTO_TOTAL+a.MTO_TIB+a.MTO_EGRESO,2)
      END AS TRIGGERING,
      CASE
        WHEN n_cluster IN (2,5) THEN
        'La alerta correspondiente al periodo '||a.PERIODO||' es generada porque el PEP tiene un monto significativo acumulado mensual de transacciones al /del exterior por $'||ROUND(a.MTO_AL_TTEE+a.MTO_DEL_TTEE,2)||', el cual corresponde a $'||ROUND(a.MTO_AL_TTEE,2)||' y $'||ROUND(a.MTO_DEL_TTEE,2)||' de transacciones al exterior y transacciones del exterior respectivamente.'
        WHEN n_cluster IN (3) THEN
        'La alerta correspondiente al periodo '||a.PERIODO||' es generada porque el PEP tiene un monto mensual acumulado de $'||ROUND(a.MTO_TOTAL,2)||' que sale de su perfil transaccional. Es decir, excede a su promedio de INgresos totales de los 6 meses anteriores $'||b.MEDIA_ING||' más 3 veces la desviación estándar '||b.DESV_ING||'.'
        WHEN n_cluster IN (4) THEN
        'La alerta correspondiente al periodo '||a.PERIODO||' es generada porque el PEP tiene un movimiento total acumulado mensual significativo de $'||ROUND(a.MTO_TOTAL+a.MTO_TIB+a.MTO_EGRESO,2)||' que corresponden a $'||ROUND(a.MTO_TOTAL+a.MTO_TIB,2)||' de monto de INgreso  y/o $'||ROUND(a.MTO_EGRESO,2)||' de monto de egreso. Adicionalmente, el PEP ha tenido '||a.ctdevals||' evaluaciones previas, '||a.ctdnp||' noticias periodísticas y '||a.ctdlsb||' levantamientos de secreto bancario. '||CASE WHEN a.FLGARCHIVONEGATIVO=1 and a.FLG_INGR_TER_AN=0 THEN 'Por último, se encuentra registrado en AN.' WHEN a.FLGARCHIVONEGATIVO=0 and a.FLG_INGR_TER_AN=1 THEN 'Por último, también ha recibido depósitos de personas registradas en AN en el mes que se genera la alerta.' WHEN a.FLGARCHIVONEGATIVO=1 and a.FLG_INGR_TER_AN=1 THEN 'Por último, se encuentra registrado en AN y también ha recibido depósitos de personas registradas en AN en el mes que se genera la alerta.' END 
      END AS COMENTARIO
FROM TMP_ESCPEP_ALERTAS A
LEFT JOIN TMP_ESCPEP_PERFI3 B ON (A.PERIODO=B.NUMPERIODO AND A.CODCLAVECIC=B.CODCLAVECIC);


GRANT SELECT ON EPIC017 TO ROL_VISTASDWHGSTCUM;

--TABLA EPIC017 - DOCUMENTOS

--DROP TABLE EPIC017_DOC;
--CREATE TABLE EPIC017_DOC TABLESPACE D_AML_99 AS
TRUNCATE TABLE EPIC017_DOC;
INSERT INTO EPIC017_DOC
SELECT DISTINCT
      '\\Pfilep11\lavadoactivos\99_Procesos_BI\0_SapycWeb\PAQUETES_ADHOC\' AS RUTA,
      '99999999_MODEM_EPIC017_TRXS_' || CODUNICOCLI || '.CSV' AS NBRDOCUMENTO,
      CODUNICOCLI,
      SYSDATE AS FECREGISTRO,
      ' ' AS NUMCASO,
      0 AS IDANALISTA
FROM EPIC017
UNION ALL
SELECT DISTINCT
      '\\Pfilep11\lavadoactivos\99_Procesos_BI\0_SapycWeb\PAQUETES_ADHOC\' AS RUTA,
      '99999999_MODEM_EPIC017_EECC_' || CODUNICOCLI || '.CSV' AS NBRDOCUMENTO,
      CODUNICOCLI,
      SYSDATE AS FECREGISTRO,
      ' ' AS NUMCASO,
      0 AS IDANALISTA
FROM EPIC017;

GRANT SELECT ON EPIC017_DOC TO ROL_VISTASDWHGSTCUM;

--SEGUIMIENTO DE VARIABLES
SPOOL OFF
QUIT;