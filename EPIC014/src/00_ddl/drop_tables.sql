@&1

SET ECHO ON
WHENEVER SQLERROR EXIT SQL.SQLCODE
ALTER SESSION DISABLE PARALLEL QUERY;

--Tabla sobre Fuera de Perfil en Gremios

DROP TABLE TMP_EQUIVAL_TIPOPE_EECC;

COMMIT;
quit;