--PARAMETRO DE CREDENCIALES
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

var intervalo_1 number 
exec :intervalo_1 := to_number(&2);

select :intervalo_1 from dual;
/*************************************************************************************************
****************************** ESCENARIO REMESAS DEL EXTERIOR ***************************
*************************************************************************************************/

-- creado por: Francesca Melgar
-- key user escenario: plaft
-- fecha:15/06/2023
-- descripcion: etl para la extracion de trx realizados por remesas del exterior


-- ************************************ UNIVERSO ***************************************************
-- **************** SCRIPTS PARA LA CREACION DEL UNIVERSO ******************************************

-- creacion del universo de las trx realizadas por remesas del exterior ---
-- las transacciones deben ser cobradas ---------
-- el periodo es mensual--

alter session disable parallel query;

-- Obtencion del universo, se relaiza la limpieza de caracteres especiales al nombre del beneficiario, ordenante y solicitante
truncate table tmp_epic032_docggtt;
insert into tmp_epic032_docggtt 
select  
   a.coddocggtt,a.fecdia,
   nbrclibeneficiario,
   ltrim(replace(replace(regexp_replace(regexp_replace(
   upper(a.nbrclibeneficiario), '[(][A-Z]+[)]', ''), '[^a-zA-Z-0-9-]', ''),'-',' '),',',' ')) 
   as nbrbeneficiario,
   a.codunicoclibeneficiario,
   a.codinternocomputacionalbenef,a.codclavecicbeneficiario,a.codmodalidadpago,a.tipformapago,
   a.codtipindicadoritf,
   case when d.codunicocli is not null and d.tipper='P' 
            then trim(d.apepatcli)||' '||trim(d.apematcli)||' '||trim(d.nbrcli)
        when d.codunicocli is not null and d.tipper='E' 
            then trim(d.apepatcli)||''||trim(d.apematcli)||''||trim(d.nbrcli) 
   else 
     ltrim(replace(replace(regexp_replace(regexp_replace(
     upper(trim(a.apepatcliordenante)||''||trim(a.apematcliordenante)||''||trim(a.nbrcliordenante)), 
     '[(][A-Z]+[)]', ''), '[^a-zA-Z-0-9-]', ''),'-',' '),',',' '))
   end as nbrordenante,
   a.codunicocliordenante,
   a.codintercomputacionalordenante,a.codclavecicordenante,
   case when c.codunicocli is not null and c.tipper='P' 
            then trim(c.apepatcli)||' '||trim(c.apematcli)||' '||trim(c.nbrcli)
        when c.codunicocli is not null and c.tipper='E' 
            then trim(c.apepatcli)||''||trim(c.apematcli)||''||trim(c.nbrcli)
   ELSE 
     ltrim(replace(replace(regexp_replace(regexp_replace(
     upper(trim(a.apepatclisolicitante)||''||trim(a.apematclisolicitante)||''||trim(a.nbrclisolicitante)), 
     '[(][A-Z]+[)]', ''), '[^a-zA-Z-0-9-]', ''),'-',' '),',',' '))
   end as nbrsolicitante, 
   a.codunicoclisolicitante,
   a.codinternocomputacionalsolicit, a.codclavecicsolicitante,
   a.fecemision,
   a.horemision,
   a.fecvaluta,
   a.codsucage,
   a.codterminal,
   a.codoperadorterminal,
   a.numoperacionggtt,
   a.codusroperador,
   a.codmoneda,
   a.mtoimporteoperacion as mtotransaccion,
   a.mtoimporteoperacion * b.mtocambioaldolar as mtotransacciondolar,
   a.codswiftbcodestino,
   a.codswiftbcocorresponsal,
   a.codswiftbcoemisor,
   a.codswiftbcointermediario,
   a.nbrbcointermediario,
   a.nbrbcodestino,
   a.desdetallepago,
   a.flgextorno,
   a.codopefinesse,
   a.codtipestadotransaccion,
   a.codcausalfinesse 
   from ods_v.hd_documentoemitidoggtt a 
   left join ods_v.hd_tipocambiosaldodiario b  on a.fecemision=b.fectipcambio and a.codmoneda  = b.codmoneda 
   left join ods_v.md_clienteg94 c on a.codunicoclisolicitante=c.codunicocli and c.flgregeliminado <> 'S'
   left join ods_v.md_clienteg94 d on a.codunicocliordenante=d.codunicocli and d.flgregeliminado <> 'S'
   where
   a.fecdia between trunc(add_months(sysdate,:intervalo_1),'mm') and trunc(last_day(add_months(sysdate,:intervalo_1))) 
   and a.codproducto in ('TRAXRE') 
   and a.codtipestadotransaccion = '04';

-- Obtenemos los clientes que tienen 2 o mas codunicoclis
truncate table tmp_epic032_grupos;
insert into tmp_epic032_grupos 
select distinct 
    nbrclibeneficiario_limpio,count(distinct codunicoclibeneficiario) as cantidad_codu 
from tmp_epic032_docggtt 
group by nbrclibeneficiario_limpio
having count(distinct codunicoclibeneficiario)>1;

-- De los clientes que tienen mas de 2 codunicoclis obtenemos cual de esos codunicoclis es el correcto
truncate table tmp_epic032_pre_uncodu;
insert into tmp_epic032_pre_uncodu 
select distinct 
    a.nbrclibeneficiario_limpio,a.codunicoclibeneficiario,a.codclavecicbeneficiario,c.codunicocli,
    trim(replace(c.apepatcli,'-',''))||' '||trim(replace(c.apematcli,'-',''))||' '||trim(replace(c.nbrcli,'-','')) as nombre
from tmp_epic032_docggtt a
inner join tmp_epic032_grupos b on a.nbrclibeneficiario_limpio=b.nbrclibeneficiario_limpio
left join ods_v.md_clienteg94 c on a.codunicoclibeneficiario = c.codunicocli
where 
    ltrim(a.nbrclibeneficiario_limpio) = trim(replace(c.apepatcli,'-',''))||' '||trim(replace(c.apematcli,'-',''))||' '||trim(replace(c.nbrcli,'-',''))
order by a.nbrclibeneficiario_limpio;

-- Se valida si hay clientes que tienen dos o mas codunicoclis correctos
truncate table tmp_epic032_docodu;
insert into tmp_epic032_docodu 
select distinct 
    nbrclibeneficiario_limpio,count(distinct codunicoclibeneficiario) as cantidad_codu 
from tmp_epic032_pre_uncodu 
group by nbrclibeneficiario_limpio
having count(distinct codunicoclibeneficiario)>1;

-- Se separa de nuestra base de clientes con codunicoclis correctos 
truncate table tmp_epic032_uncodu;
insert into tmp_epic032_uncodu 
select distinct 
    a.*
from tmp_epic032_pre_uncodu a
where nbrclibeneficiario_limpio not in (select nbrclibeneficiario_limpio from tmp_epic032_docodu);

-- Universo de los clientes con codunicocli correctos en base a DWH
truncate table tmp_epic032_univ_1;
insert into tmp_epic032_univ_1 
select distinct 
    a.*,b.codunicoclibeneficiario as codunicocli_limpio
from tmp_epic032_docggtt a
inner join tmp_epic032_uncodu b on a.nbrclibeneficiario_limpio=b.nbrclibeneficiario_limpio;

-- universo de los clientes con 1 codunicocli correcto en base a la fuente
truncate table tmp_epic032_univ_2;
insert into tmp_epic032_univ_2 
with tmp_epic032 as(
select distinct 
    a.nbrclibeneficiario_limpio,a.codunicoclibeneficiario
from tmp_epic032_docggtt a
where a.nbrclibeneficiario_limpio not in (select nbrclibeneficiario_limpio from tmp_epic032_grupos)
and a.codunicoclibeneficiario is not null)
select 
    a.*, b.codunicoclibeneficiario as codunicocli_limpio
from tmp_epic032_docggtt a
inner join tmp_epic032 b on a.nbrclibeneficiario_limpio=b.nbrclibeneficiario_limpio;

-- Universo de los clientes que tienen 2 o mas codunicoclis que no sabemos cual es su codunicocli correcto
truncate table tmp_epic032_univ_3;
insert into tmp_epic032_univ_3 
with tmp_epic032 as (
select distinct 
    nbrclibeneficiario_limpio 
from tmp_epic032_univ_1
union
select distinct 
    nbrclibeneficiario_limpio 
from tmp_epic032_univ_2)
select distinct 
    a.*,'NOID'||''||substr(a.nbrclibeneficiario_limpio,5,8)||''||'7' as codunicocli_limpio 
from tmp_epic032_docggtt a
left join tmp_epic032 b on a.nbrclibeneficiario_limpio=b.nbrclibeneficiario_limpio
where b.nbrclibeneficiario_limpio is null;

-- Obtencion del universo con codunicocli correctos
truncate table tmp_epic032_univ;
insert into tmp_epic032_univ 
select * from tmp_epic032_univ_1
union 
select * from tmp_epic032_univ_2
union
select * from tmp_epic032_univ_3;

commit;
quit;