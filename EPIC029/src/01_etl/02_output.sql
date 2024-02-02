--parametro de credenciales
@&1

alter session disable parallel query;

set echo off
set feedback off
set head off
set lin 9999
set trimspool on
set wrap off
set pages 0
set term off

SPOOL '.\data\production\01_raw.csv';

PROMPT CODCLAVECICBENEFICIARIO|CODCLAVECICSOLICITANTE|PERIODO|FECDIA|HORINITRANSACCION|CODSUCAGE|CODSESION|CODINTERNOTRANSACCION|CODTRANSACCIONVENTANILLA|DESTRANSACCIONVENTANILLA|ACTV_BENEFICIARIO|TIPPER_BENEFICIARIO|FLG_FFNN_BENEFICIARIO|FLG_FFNN_SOLICITANTE|TIPBANCA_BENEFICIARIO|TIPBANCA_SOLICITANTE|MTOTRANSACCION|TIPPER_SOLICITANTE|DESBANCA_BENEFICIARIO|DESBANCA_SOLICITANTE|FECONS_BENEFICIARIO|FECONS_SOL|FLG_AN_BENEFICIARIO|FLG_AN_SOLICITANTE|FLG_REL|FLG_ROS_BEN|FLG_ROS_SOL;

SELECT
CODCLAVECICBENEFICIARIO||'|'||
CODCLAVECICSOLICITANTE||'|'||
PERIODO||'|'||
FECDIA||'|'||
HORINITRANSACCION||'|'||
CODSUCAGE||'|'||
CODSESION||'|'||
CODINTERNOTRANSACCION||'|'||
CODTRANSACCIONVENTANILLA||'|'||
DESTRANSACCIONVENTANILLA||'|'||
ACTV_BENEFICIARIO||'|'||
TIPPER_BENEFICIARIO||'|'||
FLG_FFNN_BENEFICIARIO||'|'||
FLG_FFNN_SOLICITANTE||'|'||
TIPBANCA_BENEFICIARIO||'|'||
TIPBANCA_SOLICITANTE||'|'||
REPLACE(TRIM(TO_CHAR(MTOTRANSACCION,'99999999999999999990D00')),',','.')||'|'||
TIPPER_SOLICITANTE||'|'||
DESBANCA_BENEFICIARIO||'|'||
DESBANCA_SOLICITANTE||'|'||
FECONS_BENEFICIARIO||'|'||
FECONS_SOL||'|'||
FLG_AN_BENEFICIARIO||'|'||
FLG_AN_SOLICITANTE||'|'||
FLG_REL||'|'||
FLG_ROS_BEN||'|'||
FLG_ROS_SOL
FROM TMP_TOPSOLICITANTE_SPOOL;

SPOOL OFF;
QUIT;