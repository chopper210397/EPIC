ALTER SESSION DISABLE PARALLEL QUERY;

CREATE TABLE TMP_CONOCMCDO_OUTPUTMODEL
(
  CODCLAVECIC NUMBER,
  PERIODO NUMBER,
  TIPPER_AGRUP VARCHAR2(5),
  MTO_INGRESOS NUMBER,
  MTO_EGRESOS NUMBER,
  RATIO_ING_TOT NUMBER,
  POR_CASH NUMBER,
  FLG_PERFIL_3DESVT_TRX NUMBER,
  FLG_AN NUMBER,
  FLG_LSB_NP NUMBER,
  FLG_ANLSBNP NUMBER,
  OUTLIER NUMBER
)TABLESPACE D_AML_99;