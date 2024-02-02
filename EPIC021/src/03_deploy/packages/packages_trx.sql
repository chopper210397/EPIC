alter session disable parallel query;

spool \\Pfilep11\lavadoactivos\99_Procesos_BI\0_SapycWeb\PAQUETES_ADHOC\&&codmes._99999999_MODEM_EPIC021_TRXS_&&CODUNICOCLI..CSV;
PROMPT PERIODO,CODAGENTEVIABCP,CODCLAVECIC,CODUNICOCLI,NOMBRE,CODOPECTAAGENTE,INGRESOEGRESOAGENTE,FECDIA,HORTRANSACCION,TIPTRANSACCIONAGENTEVIABCP,DESTIPTRANSACCIONAGENTEVIABCP,TIPESTTRANSACCIONAGENTEVIABCP,CODMONEDA,MTOTRANSACCION,MTODOLARIZADO,CODCLAVECICSOLICITANTE,CODUNICOCLISOLICITANTE,NOMBRESOLICITANTE,CODOPECTASOLICITANTE,DATOSOLICITANTE,CODCLAVECICBENEFICIARIO,CODUNICOCLIBENEFICIARIO,NOMBREBENEFICIARIO,CODOPECTABENEFICIARIO,DATOBENEFICIARIO,TIPPROCEDENCIADESCARGOGIRO,CODPRESTAMO;

select
	periodo||'|'||
	codagenteviabcp||'|'||
	codclavecic||'|'||
	codunicocli||'|'||
	nombre||'|'||
	codopectaagente||'|'||
	ingresoegresoagente||'|'||
	fecdia||'|'||
	hortransaccion||'|'||
	tiptransaccionagenteviabcp||'|'||
	destiptransaccionagenteviabcp||'|'||
	tipesttransaccionagenteviabcp||'|'||
	codmoneda||'|'||
	replace(trim(to_char(mtotransaccion,'99999999999999999990d00')),'|','.')||'|'||
	replace(trim(to_char(mtodolarizado,'99999999999999999990d00')),'|','.')||'|'||
	codclavecicsolicitante||'|'||
	codunicoclisolicitante||'|'||
	nombresolicitante||'|'||
	codopectasolicitante||'|'||
	datosolicitante||'|'||
	codclavecicbeneficiario||'|'||
	codunicoclibeneficiario||'|'||
	nombrebeneficiario||'|'||
	codopectabeneficiario||'|'||
	datobeneficiario||'|'||
	tipprocedenciadescargogiro||'|'||
	codprestamo
from tmp_escagente_trx_1
where codclavecic = :codclavecic;

spool off;