@&1

SET ECHO ON
WHENEVER SQLERROR EXIT SQL.SQLCODE
ALTER SESSION DISABLE PARALLEL QUERY;

CREATE TABLE TMP_EQUIVAL_TIPOPE_EECC
(
  GLOSA varchar (50),
  GRUPO varchar (50),
  FLG CHAR(1)
)TABLESPACE D_AML_99;