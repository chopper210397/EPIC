alter session disable parallel query;

set echo off
set feedback off
set head off
set lin 9999
set trimspool on
set wrap off
set pages 0
set term off
set colsep ','

spool \\Pfilep11\lavadoactivos\99_Procesos_BI\0_SapycWeb\PAQUETES_ADHOC\99999999_MODEM_EPIC020_TRX_&&CODUNICOCLI..CSV;
prompt codclavecic_sol,codunicocli_sol,nombre_sol,codopecta_sol,codclavecic_ben,codunicocli_ben,nombre_ben,codopecta_ben,fecdia,hortransaccion,codmoneda,mtotransaccion,mto_dolarizado,tipo_transaccion,canal;

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
	canal
from
	tmp_egbcacei_trx_2
	where codclavecic_sol = :codclavecic ;

spool off;