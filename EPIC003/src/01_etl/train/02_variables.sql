
---VARIABLES FLG_PEP SEGEMENTO---
DROP TABLE TMP_TTEE_SEGMENTO;
CREATE TABLE TMP_TTEE_SEGMENTO TABLESPACE D_AML_99 AS
SELECT A.*,B.FLGPEP AS FLG_PEP, B.DESSEGMENTO AS SEGMENTO
FROM TMP_TTEE_UNIVERSO A
LEFT JOIN (SELECT DISTINCT CODCLAVECIC, FLGPEP, DESSEGMENTO FROM TMP_TTEE_FINAL) B ON A.CODCLAVECIC = B.CODCLAVECIC;

---VARIABLE FLG_PROF----
DROP TABLE TMP_TTEE_PROFESION;
CREATE TABLE  TMP_TTEE_PROFESION TABLESPACE D_AML_99 AS
SELECT A.*,
CASE WHEN TRIM(C.DESCODPROFESION) LIKE ('%TEC%') OR C.DESCODPROFESION IS NULL OR TRIM(B.CODPROFESION) IN ('130','142','146','150','151','152','153','174','207','410','613','618','701','705','706','707','710','804','806','807','810','850','999') THEN 1
ELSE 0 END FLG_PROF
FROM TMP_TTEE_SEGMENTO A
LEFT JOIN ODS_V.MM_PERSONANATURAL B ON A.CODCLAVECIC=B.CODCLAVECIC
LEFT JOIN ODS_V.MM_DESCODIGOPROFESION C ON TRIM(B.CODPROFESION)=TRIM(C.CODPROFESION);

--VARIABLE CTDEVAL(SAPYC)-------
DROP TABLE TMP_TTEE_SAPYC;
CREATE TABLE TMP_TTEE_SAPYC TABLESPACE D_AML_99 AS
SELECT A.*
FROM (
   SELECT A.IDCASO, CASE WHEN INSTR(A.CODUNICOCLI,'GR') > 0 THEN C.CODCLAVECIC ELSE D.CODCLAVECIC END AS CODCLAVECIC, A.IDRESULTADO AS IDRESULTADOEVAL, A.FECFINEVAL AS FECFINEVAL, B.IDRESULTADOSUPERVISOR
     FROM S85645.SAPY_DMEVALUACION A
     LEFT JOIN S85645.SAPY_DMINVESTIGACION B ON A.IDCASO = B.IDCASO
     LEFT JOIN ODS_V.MD_EMPLEADOG94 C ON TRIM(SUBSTR(A.CODUNICOCLI,INSTR(A.CODUNICOCLI,'GR')+2,6)) = TRIM(C.CODMATRICULA)
     LEFT JOIN ODS_V.MD_CLIENTEG94 D ON TRIM(A.CODUNICOCLI) = TRIM(D.CODUNICOCLI)
) A;

DROP TABLE TMP_TTEE_EVALS;
CREATE TABLE TMP_TTEE_EVALS TABLESPACE D_AML_99 AS
WITH TMP_TTEE_EVALS_AUX AS
(
  SELECT A.PERIODO,A.CODCLAVECIC, SUM(CASE WHEN B.FECFINEVAL < TO_DATE(TO_CHAR(A.PERIODO||'01'),'YYYYMMDD') THEN 1 ELSE 0 END) AS CTDEVAL
  FROM TMP_TTEE_UNIVERSO A
  LEFT JOIN TMP_TTEE_SAPYC B ON A.CODCLAVECIC = B.CODCLAVECIC
  WHERE IDRESULTADOEVAL <> 7
  GROUP BY A.PERIODO,A.CODCLAVECIC
)
  SELECT A.*,
  CASE WHEN B.CTDEVAL IS NOT NULL THEN B.CTDEVAL ELSE 0 END AS CTDEVAL
  FROM TMP_TTEE_PROFESION A
  LEFT JOIN TMP_TTEE_EVALS_AUX B ON A.PERIODO = B.PERIODO AND A.CODCLAVECIC = B.CODCLAVECIC;

---VARIABLE FLG_PAR-----
DROP TABLE TMP_TTEE_PRE_PAIS;
CREATE TABLE TMP_TTEE_PRE_PAIS TABLESPACE D_AML_99 AS
SELECT A.CODCLAVECIC,A.FECHA_OPERACION,PAIS_DESTINO,CASE WHEN P.CODPAIS3 IS NOT NULL THEN P.CODPAIS3 ELSE C.CODPAIS3 END CODPAIS3 
FROM TMP_TTEE_FINAL A
LEFT JOIN S55632.MD_CODIGOPAIS P ON TRIM(A.PAIS_DESTINO) = P.CODPAIS3
LEFT JOIN ODS_V.MM_DESCODIGOPAISNACIONALIDAD B ON A.PAIS_DESTINO=B.CODPAISNACIONALIDAD
LEFT JOIN S55632.MD_CODIGOPAIS C ON TRIM(B.DESCODPAISNACIONALIDAD)=UPPER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.NOMBREPAIS,'á','a'),'é','e'),'í','i'),'ó','o'),'ú','u'))

DROP TABLE TMP_TTEE_PAIS_AUX;
CREATE TABLE TMP_TTEE_PAIS_AUX TABLESPACE D_AML_99 AS
SELECT A.*,
CASE WHEN A.PAIS_DESTINO='BOS' THEN 'BIH'
WHEN A.PAIS_DESTINO='BOT' THEN 'BWA'
WHEN A.PAIS_DESTINO='BVI' THEN 'VGB'
WHEN A.PAIS_DESTINO='CAM' THEN 'CMR'
WHEN A.PAIS_DESTINO='CAY' THEN 'CYM'
WHEN A.PAIS_DESTINO='CUR' THEN 'CUW'
WHEN A.PAIS_DESTINO='GER' THEN 'DEU'
WHEN A.PAIS_DESTINO='ICE' THEN 'ISL'
WHEN A.PAIS_DESTINO='ISM' THEN 'IMN'
WHEN A.PAIS_DESTINO='KZ ' THEN 'KAZ'
WHEN A.PAIS_DESTINO='LAT' THEN 'LVA'
WHEN A.PAIS_DESTINO='NEP' THEN 'NPL'
WHEN A.PAIS_DESTINO='NET' THEN 'NLD'
WHEN A.PAIS_DESTINO='NEZ' THEN 'NZL'
WHEN A.PAIS_DESTINO='NIR' THEN 'IRL'
WHEN A.PAIS_DESTINO='SPA' THEN 'ESP'
WHEN A.PAIS_DESTINO='STH' THEN 'SHN'
WHEN A.PAIS_DESTINO='STK' THEN 'KNA'
WHEN A.PAIS_DESTINO='UAE' THEN 'ARE'
WHEN A.PAIS_DESTINO='UK ' THEN 'GBR'
WHEN A.PAIS_DESTINO='USV' THEN 'VIR'
WHEN A.PAIS_DESTINO IS NULL THEN NULL ELSE A.CODPAIS3 END CODPAIS3_FINAL FROM TMP_TTEE_PRE_PAIS A;

DROP TABLE TMP_TTEE_PAR;
CREATE TABLE TMP_TTEE_PAR TABLESPACE D_AML_99 AS
SELECT A.*,FLG_ACTIVO       
FROM TMP_TTEE_PAIS_AUX A
LEFT JOIN S55632.MD_CODIGOPAIS B ON A.PAIS_DESTINO=B.CODPAIS3 
LEFT JOIN (SELECT NBRPAIS,FLG_ACTIVO FROM T00985.TMP_HISTORICO_PAISES_RIESGO WHERE FLG_ACTIVO = 1) C ON B.NOMBREPAIS =C.NBRPAIS

DROP TABLE TMP_TTEE_PAIS;
CREATE TABLE TMP_TTEE_PAIS TABLESPACE D_AML_99 AS
SELECT A.*,
CASE WHEN CODPAIS3_FINAL IS NULL THEN 2 
 WHEN CODPAIS3_FINAL IS NOT NULL AND FLG_ACTIVO IS NULL THEN 0 ELSE FLG_ACTIVO END AS FLG_PAR1
 FROM TMP_TTEE_PAR A;
SELECT * FROM TMP_TTEE_PAIS

DROP TABLE TMP_TTEE_PAIS_PAR;
CREATE TABLE TMP_TTEE_PAIS_PAR TABLESPACE D_AML_99 AS
SELECT TO_NUMBER(TO_CHAR(A.FECHA_OPERACION,'YYYYMM')) AS PERIODO, A.CODCLAVECIC,
CASE WHEN MAX(FLG_PAR1) = 0 AND MIN(FLG_PAR1)=0 THEN 0 
     WHEN MAX(FLG_PAR1) = 2 AND MIN(FLG_PAR1)=1 THEN 1
     WHEN MAX(FLG_PAR1) = 2 AND MIN(FLG_PAR1)=0  THEN 2
     WHEN MAX(FLG_PAR1) = 2 AND MIN(FLG_PAR1)=2  THEN 2
     WHEN MAX(FLG_PAR1) = 1 AND MIN(FLG_PAR1)=1  THEN 1
     WHEN MAX(FLG_PAR1) = 1 AND MIN(FLG_PAR1)=0  THEN 1
ELSE 0 END FLG_PAR 
FROM TMP_TTEE_PAIS A
GROUP BY TO_NUMBER(TO_CHAR(FECHA_OPERACION,'YYYYMM')),A.CODCLAVECIC;

DROP TABLE TMP_TTEE_FLG_PAR;
CREATE TABLE TMP_TTEE_FLG_PAR TABLESPACE D_AML_99 AS
SELECT B.*,A.FLG_PAR 
FROM TMP_TTEE_PAIS_PAR A
INNER JOIN TMP_TTEE_EVALS B ON A.CODCLAVECIC=B.CODCLAVECIC  AND A.PERIODO = B.PERIODO


-----VARIABLE PERFIL----
DROP TABLE TMP_TTEE_PERFIL;
CREATE TABLE TMP_TTEE_PERFIL TABLESPACE D_AML_99 AS
SELECT * FROM TMP_TTEE_GGTT_PERFIL
UNION ALL
SELECT * FROM TMP_TTEE_BANNI_PERFIL;

DROP TABLE TMP_TTEE_GROUP_PERFIL;
CREATE TABLE TMP_TTEE_GROUP_PERFIL TABLESPACE D_AML_99 AS
SELECT TO_NUMBER(TO_CHAR(FECDIA,'YYYYMM')) AS PERIODO,  CODCLAVECIC,SUM(MONTO_DOLAR) AS MTO_TRANS 
FROM TMP_TTEE_PERFIL
GROUP BY TO_NUMBER(TO_CHAR(FECDIA,'YYYYMM')),CODCLAVECIC;

DROP TABLE TMP_TTEE_PERFIL1;
CREATE TABLE TMP_TTEE_PERFIL1 TABLESPACE D_AML_99 AS
SELECT * FROM TMP_TTEE_GROUP_PERFIL
UNION ALL
SELECT PERIODO,CODCLAVECIC,MTO_TRANSF FROM TMP_TTEE_UNIVERSO;

DROP TABLE TMP_TTEE_FEC_PERFIL;
CREATE TABLE TMP_TTEE_FEC_PERFIL TABLESPACE D_AML_99 AS
SELECT  A.*,
TO_NUMBER(TO_CHAR(ADD_MONTHS(TO_DATE(TO_CHAR(A.PERIODO||'01'),'YYYYMMDD'),-6),'YYYYMM')) AS FECHA_MIN,
TO_NUMBER(TO_CHAR(ADD_MONTHS(TO_DATE(TO_CHAR(A.PERIODO||'01'),'YYYYMMDD'),-1),'YYYYMM')) AS FECHA_MAX
FROM TMP_TTEE_UNIVERSO A 

SELECT * FROM TMP_TTEE_UNIVERSO
DROP TABLE TTEE_FEC_PERFIL2;
CREATE TABLE TTEE_FEC_PERFIL2 TABLESPACE D_AML_99 AS 
SELECT A.PERIODO,A.CODCLAVECIC,AVG(NULLIF(B.MTO_TRANS,0)) AS MEDIA_DEPO, STDDEV(NULLIF(B.MTO_TRANS,0)) AS DESV_DEPO
FROM TMP_TTEE_FEC_PERFIL A 
LEFT JOIN TMP_TTEE_PERFIL1 B ON A.CODCLAVECIC = B.CODCLAVECIC
WHERE B.PERIODO BETWEEN FECHA_MIN AND FECHA_MAX 
GROUP BY A.PERIODO,A.CODCLAVECIC ;

DROP TABLE TTEE_FEC_PERFIL3;
CREATE TABLE TTEE_FEC_PERFIL3 TABLESPACE D_AML_99 AS
SELECT A.*,
CASE WHEN B.MEDIA_DEPO <> 0 AND B.DESV_DEPO <> 0 AND B.MEDIA_DEPO+3*B.DESV_DEPO<A.MTO_TRANSF THEN 1 ELSE 0 END FLG_PERFIL
 FROM TMP_TTEE_FLG_PAR A
LEFT JOIN TTEE_FEC_PERFIL2 B ON A.CODCLAVECIC = B.CODCLAVECIC AND A.PERIODO=B.PERIODO

DROP TABLE TMP_TTEE_TABLON_FINAL;
CREATE TABLE TMP_TTEE_TABLON_FINAL TABLESPACE D_AML_99 AS
SELECT 
A.PERIODO,
A.CODCLAVECIC,
B.NBRCLIORDENANTE,
A.SEGMENTO,
A.MTO_TRANSF,
A.CTD_OPE,
CASE WHEN A.FLG_PEP = 'SI' THEN 1 ELSE 0 END FLG_PEP, 
A.FLG_PROF,
A.FLG_PAR,
A.FLG_PERFIL,
A.CTDEVAL
 FROM  TTEE_FEC_PERFIL3 A
LEFT JOIN (SELECT DISTINCT CODCLAVECIC, NBRCLIORDENANTE FROM TMP_TTEE_FINAL) B ON A.CODCLAVECIC= B.CODCLAVECIC;