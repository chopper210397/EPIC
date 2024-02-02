spool \\pfilep11\lavadoactivos\99_procesos_bi\0_sapycweb\paquetes_adhoc\&&codmes.99999999_modem_epic028_trxs_&&codunicocli..csv;

PROMPT CODCLAVECIC_BEN,CODUNICOCLI_BEN,NBR_BENEFICIARIO,DIA_OPERACION,HORA,MONTO_INGRESO,CODCLAVECIC_SOL,CODUNICOCLI_SOL,NBR_SOLICITANTE,CANAL;

select 
	codclavecic_ben||','||
	codunicocli_ben||','||
	nbr_beneficiario||','||
	dia_operacion||','||
	hora||','||
	monto_ingreso||','||
	codclavecic_sol||','||
	codunicocli_sol||','||
	nbr_solicitante||','||
	canal
from tmp_yape_trx_alertas
where codclavecic_ben = :codclavecic;

spool off;
