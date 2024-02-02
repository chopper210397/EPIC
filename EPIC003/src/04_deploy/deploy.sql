--PARAMETRO DE CREDENCIALES
@&1

SET ECHO ON
WHENEVER SQLERROR EXIT SQL.SQLCODE
ALTER SESSION DISABLE PARALLEL QUERY;

-- ============================ TABLA DE ALERTAS ============================

TRUNCATE TABLE TMP_EPIC003_ALERTAS;
INSERT INTO TMP_EPIC003_ALERTAS
--CREATE TABLE TMP_EPIC003_ALERTAS TABLESPACE D_AML_99 AS
SELECT
    PERIODO,
    A.CODCLAVECIC,
    CODUNICOCLI,
    MTO_TRANSF,
    CTD_OPE,
    FLG_PAIS,
    FLG_PROF,
    FLG_PEP,
    FLG_PERFIL,
    CTDEVAL
FROM TMP_EPIC003_OUTPUTMODEL A
LEFT JOIN ODS_V.MD_CLIENTEG94 B ON A.CODCLAVECIC=B.CODCLAVECIC
WHERE OUTLIER=-1;


--Tabla EPIC003
--CREATE TABLE EPIC003 TABLESPACE D_AML_99 AS
TRUNCATE TABLE EPIC003;
INSERT INTO EPIC003
SELECT
    SYSDATE                                     AS FECGENERACION,
    38                                          AS IDORIGEN,
    CODUNICOCLI                                 AS CODUNICOCLI,
    'EPIC003'                                   AS ESCENARIO,
    'EPIC003 - Transferencia al exterior - PPNN' AS DESESCENARIO,
    'ULTIMO MES'                                AS PERIODO,
    ROUND(MTO_TRANSF,2)                         AS TRIGGERING,
    'La alerta correspondiente al periodo ' || A.PERIODO ||
    ' es generada porque el cliente realizo transferencias al exterior por  '||MTO_TRANSF|| ' correspondiente a '||CTD_OPE||' transaccion(es) '||
    CASE
        WHEN FLG_PAIS=1 THEN
            'si tuvo por lo menos una operacion hacia un pais de riesgo (o sin informacion disponible). Adicionalmente, el cliente '
        else 
            'no tuvo una operacion hacia un pais de riesgo. Adicionalmente, el cliente '
    END ||
    CASE WHEN FLG_PROF=1 THEN
            'cuenta con una profesion considerada de riesgo y '
        else 
            'no cuenta con una profesion considerada de riesgo y '
    END ||
    CASE WHEN FLG_PEP=1 THEN
            'si es PEP. Por ultimo, '
        else 
            'no es PEP. Por ultimo, '
    END ||
    CASE WHEN FLG_PERFIL=1 THEN
            'sale de su perfil transaccional de transferencias al exterior comparado con los ultimos 6 meses previos y cuenta con '||CTDEVAL||' evaluaciones PLAFT previas.'
        else 
            'no sale de su perfil transaccional de transferencias al exterior comparado con los ultimos 6 meses previos y cuenta con '||CTDEVAL||' evaluaciones PLAFT previas.'
    END AS COMENTARIO
FROM TMP_EPIC003_ALERTAS A;


GRANT SELECT ON EPIC003 TO ROL_VISTASDWHGSTCUM;

--TABLA EPIC003 - DOCUMENTOS
TRUNCATE TABLE EPIC003_DOC;
INSERT INTO EPIC003_DOC
--CREATE TABLE EPIC003_DOC TABLESPACE D_AML_99 AS
SELECT DISTINCT '\\PFILEP11\LAVADOACTIVOS\99_PROCESOS_BI\0_SAPYCWEB\DOCUMENTOS\' AS RUTA,
        '99999999_MODEM_EPIC003_TRXS_' || CODUNICOCLI || '.CSV'          AS NBRDOCUMENTO,
        CODUNICOCLI,
        SYSDATE                                                          AS FECREGISTRO,
        ' '                                                              AS NUMCASO,
        0                                                                AS IDANALISTA
FROM EPIC003;

GRANT SELECT ON EPIC003_DOC TO ROL_VISTASDWHGSTCUM;

SPOOL OFF

QUIT;