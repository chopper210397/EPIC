@&1

SET ECHO ON
WHENEVER SQLERROR EXIT SQL.SQLCODE
ALTER SESSION DISABLE PARALLEL QUERY;

--TABLA SOBRE ESCENARIO DE NO CLIENTES

DROP TABLE TMP_ESCPEP_SALIDA_MODELO;

COMMIT;
QUIT;