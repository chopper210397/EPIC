--PARAMETRO DE CREDENCIALES
@&1

SET ECHO ON
WHENEVER SQLERROR EXIT SQL.SQLCODE
ALTER SESSION DISABLE PARALLEL QUERY;

--Tabla EPIC016
--CREATE TABLE EPIC016 TABLESPACE D_AML_99 AS
TRUNCATE TABLE EPIC016;
INSERT INTO EPIC016
SELECT
    SYSDATE                                     AS FECGENERACION,
    38                                          AS IDORIGEN,
    A.CODUNICOCLI,
    'EPIC016'                                   AS ESCENARIO,
    'EPIC016 - ESCENARIO POR CONOC. DE MERCADO' AS DESESCENARIO,
    'ULTIMO MES'                                AS PERIODO,
    ROUND(A.MTO_INGRESOS,2)                     AS TRIGGERING,
    'La alerta correspondiente al periodo ' || A.PERIODO ||
    ' es generada porque el cliente tiene un score de riesgo PLAFT alto, además recibió $'||A.MTO_INGRESOS||
    ' ingresos en cuentas y donde el '||A.POR_CASH*100|| '% fue en efectivo cash. Adicionalmente, el cliente'||
    CASE
        WHEN A.FLG_PERFIL_3DESVT_TRX=1 THEN
            ' sale de su perfil transaccional de ingresos comparado con los 06 últimos meses previos y'
    END ||
    CASE
        WHEN A.FLG_AN=1 THEN
            ' fue reportado por AN'
    END ||
    CASE
        WHEN A.FLG_LSB_NP=1 THEN
            ' o LSB o NP.'
    END AS COMENTARIO
FROM TMP_CONOCMCDO_ALERTAS A;

GRANT SELECT ON EPIC016 TO ROL_VISTASDWHGSTCUM;

--TABLA EPIC016 - DOCUMENTOS
TRUNCATE TABLE EPIC016_DOC;
INSERT INTO EPIC016_DOC
--CREATE TABLE EPIC016_DOC TABLESPACE D_AML_99 AS
SELECT DISTINCT '\\PFILEP11\LAVADOACTIVOS\99_PROCESOS_BI\0_SAPYCWEB\DOCUMENTOS\' AS RUTA,
        '99999999_MODEM_EPIC016_TRXS_' || CODUNICOCLI || '.CSV'          AS NBRDOCUMENTO,
        CODUNICOCLI,
        SYSDATE                                                          AS FECREGISTRO,
        ' '                                                              AS NUMCASO,
        0                                                                AS IDANALISTA
FROM EPIC016
UNION ALL
SELECT DISTINCT '\\PFILEP11\LAVADOACTIVOS\99_PROCESOS_BI\0_SAPYCWEB\DOCUMENTOS\' AS RUTA,
        '99999999_MODEM_EPIC016_EECC_' || CODUNICOCLI || '.CSV'          AS NBRDOCUMENTO,
        CODUNICOCLI,
        SYSDATE                                                          AS FECREGISTRO,
        ' '                                                              AS NUMCASO,
        0                                                                AS IDANALISTA
FROM EPIC016;

GRANT SELECT ON EPIC016_DOC TO ROL_VISTASDWHGSTCUM;

SPOOL OFF

QUIT;