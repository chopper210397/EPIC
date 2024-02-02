--PARAMETRO DE CREDENCIALES
@&1 

SET ECHO ON
WHENEVER SQLERROR EXIT SQL.SQLCODE
ALTER SESSION DISABLE PARALLEL QUERY;

TRUNCATE TABLE TMP_CONOCMCDO_UNIVTRX;
INSERT INTO TMP_CONOCMCDO_UNIVTRX
--CREATE TABLE TMP_CONOCMCDO_UNIVTRX AS
  WITH TMP AS
  (
    SELECT CODCLAVECIC_SOL,CODOPECTA_SOL,CODCLAVECIC_BEN,CODOPECTA_BEN,FECDIA,HORTRANSACCION,CODMONEDA, MTOTRANSACCION,MTO_DOLARIZADO,TIPO_TRANSACCION,CANAL,CODPAISORIGEN
    FROM TMP_CONOCMCDO_TRX_AGENTE --AGENTE
    UNION
    SELECT CODCLAVECIC_SOL,CODOPECTA_SOL,CODCLAVECIC_BEN,CODOPECTA_BEN,FECDIA,HORTRANSACCION,CODMONEDA, MTOTRANSACCION,MTO_DOLARIZADO,TIPO_TRANSACCION,CANAL,CODPAISORIGEN
    FROM TMP_CONOCMCDO_TRX_VENTANILLA --VENTANILLA
    UNION
    SELECT CODCLAVECIC_SOL,CODOPECTA_SOL,CODCLAVECIC_BEN,CODOPECTA_BEN,FECDIA,HORTRANSACCION,CODMONEDA, MTOTRANSACCION,MTO_DOLARIZADO,TIPO_TRANSACCION,CANAL,CODPAISORIGEN
    FROM TMP_CONOCMCDO_TRX_REMITTANCE --TRANSFERENCIAS DEL EXTERIOR (REMESAS)
    UNION
    SELECT CODCLAVECIC_SOL,CODOPECTA_SOL,CODCLAVECIC_BEN,CODOPECTA_BEN,FECDIA,HORTRANSACCION,CODMONEDA, MTOTRANSACCION,MTO_DOLARIZADO,TIPO_TRANSACCION,CANAL,CODPAISORIGEN
    FROM TMP_CONOCMCDO_TRX_CAJERO --CAJERO
    UNION
    SELECT CODCLAVECIC_SOL,CODOPECTA_SOL,CODCLAVECIC_BEN,CODOPECTA_BEN,FECDIA,HORTRANSACCION,CODMONEDA, MTOTRANSACCION,MTO_DOLARIZADO,TIPO_TRANSACCION,CANAL,CODPAISORIGEN
    FROM TMP_CONOCMCDO_TRX_BANCAMOVIL --BANCA MOVIL
    UNION
    SELECT CODCLAVECIC_SOL,CODOPECTA_SOL,CODCLAVECIC_BEN,CODOPECTA_BEN,FECDIA,HORTRANSACCION,CODMONEDA, MTOTRANSACCION,MTO_DOLARIZADO,TIPO_TRANSACCION,CANAL,CODPAISORIGEN
    FROM TMP_CONOCMCDO_TRX_TELCRE --TELECREDITO
    UNION
    SELECT CODCLAVECIC_SOL,CODOPECTA_SOL,CODCLAVECIC_BEN,CODOPECTA_BEN,FECDIA,HORTRANSACCION,CODMONEDA, MTOTRANSACCION,MTO_DOLARIZADO,TIPO_TRANSACCION,CANAL,CODPAISORIGEN
    FROM TMP_CONOCMCDO_TRX_HM --HOMEBANKING
    UNION
    SELECT CODCLAVECIC_SOL,CODOPECTA_SOL,CODCLAVECIC_BEN,CODOPECTA_BEN,FECDIA,HORTRANSACCION,CODMONEDA, MTOTRANSACCION,MTO_DOLARIZADO,TIPO_TRANSACCION,CANAL,CODPAISORIGEN
    FROM TMP_CONOCMCDO_TRX_GGTT --GGTT
  )--FILTRO LISTA BLANCA
  SELECT *
  FROM TMP
  WHERE CODCLAVECIC_BEN NOT IN (SELECT CODCLAVECIC FROM S55632.LISTABLANCA_CUMP);

quit;