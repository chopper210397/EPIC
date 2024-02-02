alter session disable parallel query;

set echo off
set feedback off
set head off
set lin 256
set trimspool on
set wrap off
set pages 0
set term off
set colsep ','

spool D:\_Miguel_Tasayco\GeneracionAlertas\EPIC\EPIC020\PQTS_GENERADOS\99999999_MODEM_EPIC020_EECC_&&CODUNICOCLI..CSV;
prompt codclavecic,codunicocli,nombre,codclaveopecta,codopecta,cuentacomercial,fecdia,hortransaccion,desopetransaccionsavingdetalle,grupo,descanal,nbrsucage,codmoneda,mtotransaccion,tipcargoabono,mtodolarizado;

select
    codclavecic||','||
    codunicocli||','||
	  replace(trim(nombre),',','')||','||
    codclaveopecta||','||
    codopecta||','||
    cuentacomercial||','||
    fecdia||','||
    hortransaccion||','||
	  replace(trim(desopetransaccionsavingdetalle),',','')||','||
    grupo||','||
    descanal||','||
    nbrsucage||','||
    codmoneda||','||
	  replace(trim(to_char(mtotransaccion,'99999999999999999990d00')),',','.')||','||
    tipcargoabono||','||
	  replace(trim(to_char(mtodolarizado,'99999999999999999990d00')),',','.')
from tmp_egbcacei_eecc_alertas
where codclavecic = :codclavecic;

spool off;