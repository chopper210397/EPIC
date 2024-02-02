alter session disable parallel query;

spool \\Pfilep11\lavadoactivos\99_Procesos_BI\0_SapycWeb\PAQUETES_ADHOC\&&CODMES._99999999_MODEM_EPIC018_TRXS_&&CODUNICOCLI..CSV;

PROMPT CODCLAVECIC_SOL,CODUNICOCLI_SOL,NOMBRE_SOL,CODOPECTA_SOL,CODCLAVECIC_BEN,CODUNICOCLI_BEN,NOMBRE_BEN,CODOPECTA_BEN,TIPBANCA_BEN,FECDIA,HORTRANSACCION,CODMONEDA,MTO_DOLARIZADO,TIPO_TRANSACCION,CANAL;

select
	codclavecic_sol||','||
	codunicocli_sol||','||
	nombre_sol||','||
	codopecta_sol||','||
	codclavecic_ben||','||
	codunicocli_ben||','||
	nombre_ben||','||
	codopecta_ben||','||
	tipbanca_ben||','||
	fecdia||','||
	hortransaccion||','||
	codmoneda||','||
	replace(trim(to_char(mto_dolarizado,'99999999999999999990d00')),',','.')||','||
	tipo_transaccion||','||
	canal
from tmp_trx_epic018
where codclavecic_ben = :codclavecic and  to_number(to_char(fecdia,'yyyymm')) = (select max(to_number(to_char(fecdia,'yyyymm'))) from tmp_trx_epic018);

spool off;