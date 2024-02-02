ALTER SESSION DISABLE PARALLEL QUERY;

set echo off
set feedback off
set head off
set lin 999999
set trimspool on
set wrap off
set pages 0
set term off

SPOOL \\pfilep11\LavadoActivos\99_Procesos_BI\0_sapycweb\paquetes_adhoc\&&codmes._99999999_MODEM_EPIC032_TRXS_&&codunicocli_limpio..CSV;

PROMPT codunicocli_limpio,coddocggtt,fecdia,nbrclibeneficiario_limpio,codunicoclibeneficiario,codclavecicordenante,nbrsolicitante,codunicoclisolicitante,fecemision,horemision,codsucage,numoperacionggtt,codmoneda,mtotransaccion,mtotransacciondolar,codswiftbcodestino,codswiftbcocorresponsal,codswiftbcoemisor,codswiftbcointermediario,nbrbcointermediario,nbrbcodestino,desdetallepago,codtipestadotransaccion;

select 
    codunicocli_limpio||','||
    coddocggtt||','||
    fecdia||','||
    replace(trim(nbrclibeneficiario_limpio),',','')||','||
    codunicoclibeneficiario||','||
    codclavecicbeneficiario||','||
    replace(trim(nbrordenante),',','')||','||
    codunicocliordenante||','||
    codclavecicordenante||','||
    replace(trim(nbrsolicitante),',','')||','||
    codunicoclisolicitante||','||
    fecemision||','||
    horemision||','||
    codsucage||','||
    numoperacionggtt||','||
    codmoneda||','||
    replace(trim(to_char(mtotransaccion,'99999999999999999990d00')),',','.')||','||
    replace(trim(to_char(mtotransacciondolar,'99999999999999999990d00')),',','.')||','||  
    codswiftbcodestino||','||
    codswiftbcocorresponsal||','||
    codswiftbcoemisor||','||
    codswiftbcointermediario||','||
    nbrbcointermediario||','||
    nbrbcodestino||','||
    desdetallepago||','||
    codtipestadotransaccion
from
    tmp_epic032_univ a 
    where a.codunicocli_limpio = :CODCLAVECIC;

spool off;
