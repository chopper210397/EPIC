@&1

SET ECHO ON
WHENEVER SQLERROR EXIT SQL.SQLCODE
ALTER SESSION DISABLE PARALLEL QUERY;

TRUNCATE TABLE EPIC019;
INSERT INTO EPIC019
SELECT DISTINCT
	SYSDATE AS FECGENERACION, 38 AS IDORIGEN, A.CODIGO_CLIENTE, 'EPIC019' AS ESCENARIO, 'SOL o BEN TOP dólares' AS DESESCENARIO, 'ULTIMO MES' AS PERIODO, TOTAL AS TRIGGERING,
	'La alerta pertenece al periodo ' || A.PERIODO || ', el cliente ' || A.NBRCLIENTE || ' con codunicocli ' || A.CODIGO_CLIENTE  || ', ' ||
		'ingresó a través de ventanilla $' || A.SOLICITANTE || ', y recibió como beneficiario $' || A.BENEFICIARIO || ', ' ||
		CASE WHEN A.FLGZAED = 1 THEN 'si' ELSE 'no' END || ' pertenece a zona ZAED, ' ||
		'pertenece al segmento comercial: ' || A.SEGMENTO || ', con profesión ' || A.PROFESION || ' y ' ||
		CASE WHEN A.FLGFFNN = 1 THEN 'si' ELSE 'no' END || ' tiene FFNN.' AS COMENTARIO
FROM TMP_BASETOP_DOLAR_OUTPUT A;

TRUNCATE TABLE TMP_EPIC019 ;
INSERT INTO TMP_EPIC019
SELECT A.CODUNICOCLI,B.CODCLAVECIC FROM EPIC019 A
INNER JOIN ODS_V.MD_CLIENTEG94 B ON A.CODUNICOCLI=B.CODUNICOCLI;

COMMIT;
SPOOL OFF
QUIT;