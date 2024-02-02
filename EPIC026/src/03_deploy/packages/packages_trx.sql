spool \\pfilep11\lavadoactivos\99_procesos_bi\0_sapycweb\paquetes_adhoc\&&codmes._99999999_modem_epic026_trxs_&&codunicocli..csv;
PROMPT PERIODO,FECDIA,HORTRANSACCION,CODOPECTAORIGEN,CODUNICOCLIORIGEN,NOMBREORIGEN,CODOPECTADESTINO,CODUNICOCLIBENEFICIARIO,NOMBREBENEFICIARIO,MTODOLARIZADO;

select
periodo||'|'||
fecdia||'|'||
hortransaccion||'|'||
codopectaorigen||'|'||
codunicocliorigen||'|'||
nombreorigen||'|'||
codopectadestino||'|'||
codunicoclibeneficiario||'|'||
nombrebeneficiario||'|'||
replace(trim(to_char(mtodolarizado,'99999999999999999990d00')),',','.')
from tmp_trx_epic026
where codclavecicorigen = :codclavecic;

spool off;