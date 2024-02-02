@&1

SET ECHO ON
WHENEVER SQLERROR EXIT SQL.SQLCODE
ALTER SESSION DISABLE PARALLEL QUERY;

ALTER SESSION SET NLS_NUMERIC_CHARACTERS='.,';

--TABLON DE TOP SOLES

SET ECHO OFF;
SET FEEDBACK OFF;
SET HEAD OFF;
SET LIN 9999;
SET TRIMSPOOL ON;
SET WRAP OFF;
SET PAGES 0;
SET TERM OFF;

SPOOL ./data/production/01_raw.csv

PROMPT PERIODO|NBRCLIENTE|CODIGO_CLIENTE|CODDEPARTAMENTO|NBRUBICACION|FLGZAED|BENEFICIARIO|SOLICITANTE|TOTAL|NACIONALIDAD|CATFLGZAED|CATNACIONAL|CATSEGMENTO|CATPROFESION|FECNACIMIENTO|EDAD|PROFESION|CIIU|SEGMENTO|FFNN|FLGFFNN|NBRCLIENTE_REL|CARGO_REL|AN_CUMPLIMIENTO|CUENTA_PASIVA|CUENTA_ACTIVA|FEC_INV|ORIGEN_INV|FEC_EVA|ORIGEN_EVA|EDAD_C;
SELECT
PERIODO||'|'||
NBRCLIENTE||'|'||
CODIGO_CLIENTE||'|'||
CODDEPARTAMENTO||'|'||
NBRUBICACION||'|'||
FLGZAED||'|'||
BENEFICIARIO||'|'||
SOLICITANTE||'|'||
TOTAL||'|'||
NACIONALIDAD||'|'||
CATFLGZAED||'|'||
CATNACIONAL||'|'||
CATSEGMENTO||'|'||
CATPROFESION||'|'||
FECNACIMIENTO||'|'||
EDAD||'|'||
PROFESION||'|'||
CIIU||'|'||
SEGMENTO||'|'||
FFNN||'|'||
FLGFFNN||'|"'||
REPLACE(NBRCLIENTE_REL,'"')||'"|"'||
REPLACE(CARGO_REL,'"')||'"|'||
AN_CUMPLIMIENTO||'|'||
CUENTA_PASIVA||'|'||
CUENTA_ACTIVA||'|'||
FEC_INV||'|'||
ORIGEN_INV||'|'||
FEC_EVA||'|'||
ORIGEN_EVA||'|'||
CASE WHEN EDAD IS NULL THEN ROUND((select AVG(EDAD) from TMP_BASETOP_DOL_1 WHERE EDAD > 0),1) ELSE EDAD END
FROM TMP_BASETOP_DOL_1;

COMMIT;
SPOOL OFF
QUIT;