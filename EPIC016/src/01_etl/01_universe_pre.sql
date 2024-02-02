@&1 --PARAMETRO DE CREDENCIALES

SET ECHO ON
WHENEVER SQLERROR EXIT SQL.SQLCODE
ALTER SESSION DISABLE PARALLEL QUERY;

TRUNCATE TABLE TMP_CONOCMCDO_UNIPREV01;
INSERT INTO TMP_CONOCMCDO_UNIPREV01
SELECT
   DISTINCT TO_NUMBER(TO_CHAR(ADD_MONTHS(SYSDATE, -1), 'YYYYMM')) AS NUMPERIODO,
   A.CODCLAVECIC,
   CASE
      WHEN C.TIPPER = 'E' THEN 'PJ'
      ELSE
         CASE WHEN B.CODNIT IS NULL 
         THEN 'PN_SN'
         ELSE 'PN_CN' END END AS TIPPER
FROM T23377.SCORECLIENTECUMP A
INNER JOIN ODS_V.MD_CLIENTEG94 C ON A.CODCLAVECIC = C.CODCLAVECIC
LEFT JOIN ODS_V.MD_RELACIONIDCNIT B ON A.CODCLAVECIC = B.CODCLAVECIC
WHERE UPPER(A.NIVEL_RIESGO) LIKE 'ALTO';

TRUNCATE TABLE TMP_CONOCMCDO_UNIPREV02;
INSERT INTO TMP_CONOCMCDO_UNIPREV02
SELECT
   DISTINCT NUMPERIODO,
   CODCLAVECIC,
   TIPPER,
--          CASE
--              WHEN UPPER(TIPPER) LIKE'%PN_SN%' THEN 'PN_SN'
--              WHEN UPPER(TIPPER) LIKE'%PN_CN%' THEN 'PN_CN'
--              WHEN UPPER(TIPPER) LIKE'%PJ%' THEN 'PJ'
--              ELSE NULL
--          END
   TIPPER AS TIPPER_AGRUP
FROM TMP_CONOCMCDO_UNIPREV01;

TRUNCATE TABLE TMP_CONOCMCDO_UNIPREV03;
INSERT INTO TMP_CONOCMCDO_UNIPREV03 WITH TMP AS (
   SELECT A.* FROM TMP_CONOCMCDO_UNIPREV02 A 
   INNER JOIN ODS_V.MD_CLIENTEG94 B ON (A.CODCLAVECIC=B.CODCLAVECIC AND B.FLGREGELIMINADO='N')
)
   SELECT
      DISTINCT NUMPERIODO,
      CODCLAVECIC,
      TIPPER_AGRUP
   FROM TMP;
QUIT;