spool \\PFILEP11\LAVADOACTIVOS\99_PROCESOS_BI\0_SAPYCWEB\PAQUETES_ADHOC\&&CODMES._99999999_MODEM_EPIC022_TRXS_&&CODUNICOCLI..CSV;

PROMPT NUMREGISTRO,CODSUCAGE,CODCLAVECICINT,CODUNICOCLIINT,NOMNBREINT,CODOPECTAINT,CODPAISORIGEN,FECDIA,HORTRANSACCION,CODMONEDA,MTOTRANSACCION,MTODOLARIZADO,CODTRANSACCION,TIPOTRANSACCION,CANAL,CODCLAVECICCLI,CODUNICOCLICLI,NOMNBRECLI,CODOPECTACLI;

select
numregistro||','||
codsucage||','||
codclavecicint||','||
	codunicocliint||','||
	nomnbreint||','||
	codopectaint||','||
	codpaisorigen||','||
	fecdia||','||
	hortransaccion||','||
	codmoneda||','||
	replace(trim(to_char(mtotransaccion,'99999999999999999990d00')),',','.')||','||
	replace(trim(to_char(mtodolarizado,'99999999999999999990d00')),',','.')||','||
	codtransaccion||','||
	tipotransaccion||','||
	canal||','||
	codclaveciccli||','||
	codunicoclicli||','||
	nomnbrecli||','||
	codopectacli
from tmp_trs_epic022
where codclaveciccli = :codclavecic;

spool off;