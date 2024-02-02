spool \\pfilep11\lavadoactivos\99_procesos_bi\0_sapycweb\paquetes_adhoc\&&codmes._99999999_modem_epic027_trxs_&&codunicocli..csv;
PROMPT CODMES,CODCLAVECIC,CODUNICOCLI,NBRGREMIO,PUESTO,MONTO_DEUDA_BCP,MONTO_DEUDA_INTERBANK,MONTO_DEUDA_SCOTIABANK,MONTO_DEUDA_BBVA,MONTO_DEUDA_OTROS,HABERES,DEUDA_HIPOTECARIO_BCP,DEUDA_VEHICULAR_BCP,DEUDA_CEF_BCP,DEUDA_TARJETACREDITO_BCP;

select
	codmes||','||
	codclavecic||','||
	codunicocli||','||
	nbrgremio||','||
	puesto||','||
	monto_deuda_bcp||','||
	monto_deuda_interbank||','||
	monto_deuda_scotiabank||','||
	monto_deuda_bbva||','||
	monto_deuda_otros||','||
	haberes||','||
	deuda_hipotecario_bcp||','||
	deuda_vehicular_bcp||','||
	deuda_cef_bcp||','||
	deuda_tarjetacredito_bcp
from tmp_grm_trx_alertas_data
where codclavecic = :codclavecic;

spool off;