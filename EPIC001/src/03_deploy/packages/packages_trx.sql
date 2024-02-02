alter session disable parallel query;

spool \\Pfilep11\lavadoactivos\99_Procesos_BI\0_SapycWeb\PAQUETES_ADHOC\&&CODMES._99999999_MODEM_EPIC001_TRXS_&&CODUNICOCLI..CSV;
PROMPT CODUNICOCLI,NBRCLI,CODCLAVECIC,FECDIA,HORTRANSACCION,MONTO,CANAL;

select
codunicocli||','||
nbrcli||','||
codclavecic||','||
fecdia||','||
hortransaccion||','||
monto||','||
canal
from tmp_retatmext_trx
where codclavecic = :codclavecic;

spool off;