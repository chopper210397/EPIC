--PARAMETRO DE CREDENCIALES
@&1 

SET ECHO ON
WHENEVER SQLERROR EXIT SQL.SQLCODE
ALTER SESSION DISABLE PARALLEL QUERY;

VAR INTERVALO_1 NUMBER
EXEC :INTERVALO_1 := TO_NUMBER(&2);
VAR INTERVALO_2 NUMBER
EXEC :INTERVALO_2 := TO_NUMBER(&3);

SELECT :INTERVALO_1, :INTERVALO_2 FROM DUAL;

--***************************************************VENTANILLA-EFECTIVO***********************************************************
--ACORTAMOS EL PERIODO DE LA TABLA
TRUNCATE TABLE TMP_CONOCMCDO_MOVCASH_SOL;
INSERT INTO TMP_CONOCMCDO_MOVCASH_SOL
--CREATE TABLE TMP_CONOCMCDO_MOVCASH_SOL AS
WITH TMP AS (
     SELECT A.CODUNICOCLISOLICITANTE,
     A.CODCLAVEOPECTADESTINO,
     A.FECDIA,
     A.CODMONEDATRANSACCION AS CODMONEDA,
     CASE WHEN A.MTOTRANSACCIONCTA <> 0 THEN A.MTOTRANSACCIONCTA ELSE A.MTOTRANSACCION END AS MTOTRANSACCION 
     FROM T00985.QRY_EFECTPARTICIPE A 
     WHERE A.FECDIA BETWEEN TRUNC(ADD_MONTHS(SYSDATE, :INTERVALO_1), 'MM') AND TRUNC(LAST_DAY(ADD_MONTHS(SYSDATE, :INTERVALO_2))) 
     AND A.CODTRANSACCIONVENTANILLA IN (60, 62, 63, 159, 186, 187, 188)
)
     SELECT
          B.CODCLAVECIC          AS CODCLAVECIC_SOL,
          A.CODCLAVEOPECTADESTINO,
          A.FECDIA,
          A.CODMONEDA,
          A.MTOTRANSACCION
     FROM TMP A
     LEFT JOIN ODS_V.MD_CLIENTE B ON A.CODUNICOCLISOLICITANTE=B.CODUNICOCLI;

--CODCLAVECIC BENEFICIARIO
TRUNCATE TABLE TMP_CONOCMCDO_MOVCASH_BEN;
INSERT INTO TMP_CONOCMCDO_MOVCASH_BEN
--CREATE TABLE TMP_CONOCMCDO_MOVCASH_BEN AS
     SELECT
          A.*,
          B.CODCLAVECIC AS CODCLAVECIC_BEN
     FROM
          TMP_CONOCMCDO_MOVCASH_SOL A
          LEFT JOIN ODS_V.MD_CUENTA B ON A.CODCLAVEOPECTADESTINO=B.CODCLAVEOPECTA
     WHERE
          B.CODCLAVECIC IN (
               SELECT
                    DISTINCT CODCLAVECIC
               FROM TMP_CONOCMCDO_UNIVCLIE
          );

--TABLA FINAL (FILTRANDO CODCLAVECIC <> 0
TRUNCATE TABLE TMP_CONOCMCDO_MOVCASH;
INSERT INTO TMP_CONOCMCDO_MOVCASH
--CREATE TABLE TMP_CONOCMCDO_MOVCASH AS
     SELECT
          DISTINCT A.CODCLAVECIC_SOL,
          A.CODCLAVECIC_BEN,
          A.FECDIA,
          A.CODMONEDA,
          A.MTOTRANSACCION,
          A.MTOTRANSACCION * TC.MTOCAMBIOALDOLAR AS MTO_DOLARIZADO
     FROM
          TMP_CONOCMCDO_MOVCASH_BEN      A
          LEFT JOIN ODS_V.HD_TIPOCAMBIOSALDODIARIO TC
          ON A.FECDIA = TC.FECTIPCAMBIO
          AND A.CODMONEDA = TC.CODMONEDA
     WHERE
          A.CODCLAVECIC_BEN<>0
          AND A.CODCLAVECIC_SOL<>A.CODCLAVECIC_BEN;

QUIT;