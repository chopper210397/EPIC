ALTER SESSION DISABLE PARALLEL QUERY;

set echo off
set feedback off
set head off
set lin 999999
set trimspool on
set wrap off
set pages 0
set term off

SPOOL \\Pfilep11\lavadoactivos\99_Procesos_BI\0_SapycWeb\PAQUETES_ADHOC\&&codmes._99999999_MODEM_EPIC029_TRXS_&&CODUNICOCLI..CSV;

PROMPT PERIODO,FECDIA,HORINITRANSACCION,CODSUCAGE,CODSESION,CODINTERNOTRANSACCION,CODTRANSACCIONVENTANILLA,DESTRANSACCIONVENTANILLA,CODCTACOMERCIAL,MTOTRANSACCION,CODUNICOCLISOLICITANTE,NBRCLIENTESOLICITANTE,BANCASOLICITANTE,CODUNICOCLIBENEFICIARIO,NBRCLIENTEBENEFICIARIO,BANCABENEFICIARIO,CODTERMINAL,N_CLUSTER;

select 
	periodo||','||
	fecdia||','||
	horinitransaccion||','||
	codsucage||','||
	codsesion||','||
	codinternotransaccion||','||
	codtransaccionventanilla||','||
	destransaccionventanilla||','||
	codctacomercial||','||
	replace(trim(to_char(mtotransaccion,'99999999999999999990d00')),',','.')||','||
	codunicoclisolicitante||','||
	nbrclientesolicitante||','||
	bancasolicitante||','||
	codunicoclibeneficiario||','||
	nbrclientebeneficiario||','||
	bancabeneficiario||','||
	codterminal||','||
	n_cluster
from tmp_trx_epic029
where codunicoclibeneficiario = :codunicoclimask ;

SPOOL OFF;