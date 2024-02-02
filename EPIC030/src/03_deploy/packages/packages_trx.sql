alter session disable parallel query;

set echo off
set feedback off
set head off
set lin 999999
set trimspool on
set wrap off
set pages 0
set term off

SPOOL \\pfilep11\LavadoActivos\99_Procesos_BI\0_sapycweb\paquetes_adhoc\&&codmes._99999999_MODEM_EPIC030_TRXS_&&codunicocli..CSV;

PROMPT CODCLAVECIC_SOL,CODUNICOCLI_SOL,NOMBRE_SOL,CODOPECTA_SOL,CODCLAVECIC_BEN,CODUNICOCLI_BEN,NOMBRE_BEN,CODOPECTA_BEN,FECDIA,HORTRANSACCION,CODMONEDA,MTOTRANSACCION,MTO_DOLARIZADO,TIPO_TRANSACCION,CANAL,CODPAISORIGEN;

select 
	codclavecic_sol||','||
	codunicocli_sol||','||
	nombre_sol||','||
	codopecta_sol||','||
	codclavecic_ben||','||
	codunicocli_ben||','||
	nombre_ben||','||
	codopecta_ben||','||
	fecdia||','||
	hortransaccion||','||
	codmoneda||','||
    replace(trim(to_char(mtotransaccion,'99999999999999999990d00')),',','.')||','||
    replace(trim(to_char(mto_dolarizado,'99999999999999999990d00')),',','.')||','||
	tipo_transaccion||','||
	canal||','||
	codpaisorigen
from tmp_trx_epic030
where codclavecic_ben = :codclavecic;

spool off;