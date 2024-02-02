@&1

SET ECHO ON
WHENEVER SQLERROR EXIT SQL.SQLCODE
ALTER SESSION DISABLE PARALLEL QUERY;

VAR INTERVALO_1 NUMBER
EXEC :INTERVALO_1 := TO_NUMBER(&2);
VAR INTERVALO_2 NUMBER
EXEC :INTERVALO_2 := TO_NUMBER(&3);

SELECT :INTERVALO_1, :INTERVALO_2 FROM DUAL;

--***************************************************BANCA MOVIL***********************************************************
--ACORTAMOS EL PERIODO DE LA TABLA Y EXTRAEMOS LOS CODCLAVECIC BENEFICIARIOS
--CREATE TABLE TMP_INGCLIEBCACEI_BANCAMOVIL_BEN TABLESPACE D_AML_99 AS
TRUNCATE TABLE TMP_INGCLIEBCACEI_BANCAMOVIL_BEN;
INSERT INTO TMP_INGCLIEBCACEI_BANCAMOVIL_BEN
SELECT
	a.CODCLAVEOPECTAORIGEN,a.CODCLAVEOPECTADESTINO,a.FECTRANSACCION AS FECDIA,a.hortransaccion,
	a.codmonedatransaccion as CODMONEDA,a.mtotransaccion,a.tiptransaccionbcamovil,
	B.CODCLAVECIC AS CODCLAVECIC_BEN,B.CODOPECTA AS CODOPECTA_BEN,B.TIPBANCA AS TIPBANCA_BEN
FROM
	S61751.tmp_movbcamovil_i a
	inner join TMP_INGCLIEBCACEI_UNIVCTASCLIE B ON A.CODCLAVEOPECTADESTINO=B.CODCLAVEOPECTA
WHERE
	a.FECTRANSACCION BETWEEN TRUNC(ADD_MONTHS(SYSDATE,:INTERVALO_1),'MM') AND TRUNC(LAST_DAY(ADD_MONTHS(SYSDATE,:INTERVALO_2))) AND
	a.TIPTRANSACCIONBCAMOVIL='2' AND
	a.FLGTRANSACCIONVALIDA='S'
UNION ALL
SELECT
	a.CODCLAVEOPECTAORIGEN,a.CODCLAVEOPECTADESTINO,a.FECTRANSACCION AS FECDIA,a.hortransaccion,
	a.codmonedatransaccion as CODMONEDA,a.mtotransaccion,a.tiptransaccionbcamovil,
	B.CODCLAVECIC AS CODCLAVECIC_BEN,B.CODOPECTA AS CODOPECTA_BEN,B.TIPBANCA AS TIPBANCA_BEN
FROM
	S61751.tmp_movbcamovil_p a
	inner join TMP_INGCLIEBCACEI_UNIVCTASCLIE B ON A.CODCLAVEOPECTADESTINO=B.CODCLAVEOPECTA
WHERE
	a.FECTRANSACCION BETWEEN TRUNC(ADD_MONTHS(SYSDATE,:INTERVALO_1),'MM') AND TRUNC(LAST_DAY(ADD_MONTHS(SYSDATE,:INTERVALO_2))) AND
	a.TIPTRANSACCIONBCAMOVIL='2' AND
	a.FLGTRANSACCIONVALIDA='S';

--EXTRAEMOS LA INFO DE LOS SOLICITANTES
--CREATE TABLE TMP_INGCLIEBCACEI_TRX_BANCAMOVIL TABLESPACE D_AML_99 AS
TRUNCATE TABLE TMP_INGCLIEBCACEI_TRX_BANCAMOVIL;
INSERT INTO TMP_INGCLIEBCACEI_TRX_BANCAMOVIL
       WITH TMP_BANCAMOVIL_SOL AS
       (
      	SELECT
            	A.*,B.CODCLAVECIC AS CODCLAVECIC_SOL, B.CODOPECTA AS CODOPECTA_SOL
      	FROM
             TMP_INGCLIEBCACEI_BANCAMOVIL_BEN A
      		   LEFT JOIN
                       ODS_V.MD_CUENTA B ON A.CODCLAVEOPECTAORIGEN=B.CODCLAVEOPECTA
       )
       SELECT DISTINCT
                      A.CODCLAVECIC_SOL,A.CODOPECTA_SOL,A.CODCLAVECIC_BEN,A.CODOPECTA_BEN,A.TIPBANCA_BEN,A.fecdia,
                      A.hortransaccion, A.codmoneda, A.mtotransaccion,A.mtotransaccion * tc.MtoCambioAlDolar as MTO_DOLARIZADO,
                      d.DESTIPTRANSACCIONBCAMOVIL as TIPO_TRANSACCION, 'BANCA MOVIL' as CANAL,' ' CODPAISORIGEN, '0'FLG_ZAR
    	 FROM
            TMP_BANCAMOVIL_SOL A
    			  left join
                      ods_v.hd_tipocambiosaldodiario tc on A.FECDIA = tc.FecTipCambio and A.CODMONEDA = tc.CodMoneda
    			  left join
                      ods_v.mm_destiptransaccionbcamovil d on A.tiptransaccionbcamovil = d.tiptransaccionbcamovil
    	 WHERE
             A.CODCLAVECIC_BEN<>0 AND
		         A.CODCLAVECIC_SOL<>A.CODCLAVECIC_BEN;
COMMIT;
quit;