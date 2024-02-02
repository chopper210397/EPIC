
/*************************************************************************************************
****************************** ESCENARIO REMESAS DEL EXTERIOR ***************************
*************************************************************************************************/

-- CREADO POR: FRANCESCA MELGAR
-- KEY USER ESCENARIO: PLAFT
-- FECHA:15/06/2023
-- DESCRIPCION: ETL PARA LA EXTRACION DE TRX REALIZADOS POR REMESAS DEL EXTERIOR


-- ************************************ VARIABLES ***************************************************
-- **************** SCRIPTS PARA LAS VARIABLES DEL UNIVERSO ******************************************

alter session disable parallel query;

-- Variable indice de concentracion por semana
truncate table tmp_aut007_mto_semana;
insert into tmp_aut007_mto_semana 
select distinct 
    to_number(to_char(fecdia,'yyyymm')) as periodo,to_number(to_char(fecdia,'W')) as semana,
    codunicocli_limpio,
    sum(mtotransacciondolar) as monto_total,count( mtotransaccion) as ctd_trx
from tmp_aut007_univ
group by to_number(to_char(fecdia,'yyyymm')),to_number(to_char(fecdia,'W')),codunicocli_limpio;

-- Obtencion de los porcentaje de la semana en referencia al monto total del mes
truncate table tmp_aut007_mto_ctd_semanal;
insert into tmp_aut007_mto_ctd_semanal 
with tmp_autt007 as(
select 
    a.*,
    round((a.monto_total/b.monto_total)*100,2) as porcentaje_monto,
    round((a.ctd_trx/b.ctd_trx)*100,2) as porcentaje_ctd
from tmp_aut007_mto_semana a
left join tmp_aut007_monto_total b on a.periodo=b.periodo 
            and a.codunicocli_limpio = b.codunicocli_limpio)
select 
    periodo, codunicocli_limpio, max(monto_total) as monto_total_semanal,
    max(porcentaje_monto) as porcentaje_monto,max(ctd_trx) as ctd_trx_semanal,
    max(porcentaje_ctd) as porcentaje_ctd 
from tmp_autt007 
group by periodo, codunicocli_limpio;

-- Variable monto significativo y alta frecuencia de remesas
truncate table tmp_aut007_monto_total;
insert into tmp_aut007_monto_total 
select distinct 
    to_number(to_char(fecdia,'yyyymm')) as periodo,codunicocli_limpio,
    sum(mtotransacciondolar) as monto_total,count( mtotransaccion) as ctd_trx
from tmp_aut007_univ 
group by to_number(to_char(fecdia,'yyyymm')) ,codunicocli_limpio;

-- Obtencion de la base del perfil
truncate table tmp_aut007_pre_perfil;
insert into tmp_aut007_pre_perfil 
select  
   a.coddocggtt,a.fecdia,
   a.nbrclibeneficiario,
   ltrim(replace(replace(regexp_replace(regexp_replace(
   upper(a.nbrclibeneficiario), '[(][A-Z]+[)]', ''), '[^a-zA-Z-0-9-]', ''),'-',' '),',',' '))
   as nbrbeneficiario,
   a.codunicoclibeneficiario,
   a.codclavecicbeneficiario,
   a.fecemision,
   a.horemision,
   a.codmoneda,
   a.mtoimporteoperacion as mtotransaccion,
   a.mtoimporteoperacion * b.mtocambioaldolar as mtotransacciondolar
from ods_v.hd_documentoemitidoggtt a 
inner join tmp_aut007_docggtt e on a.nbrclibeneficiario=e.nbrclibeneficiario
left join ods_v.hd_tipocambiosaldodiario b on a.fecemision=b.fectipcambio and a.codmoneda  = b.codmoneda 
left join ods_v.md_clienteg94 c on a.codunicoclisolicitante=c.codunicocli and c.flgregeliminado <> 'S'
left join ods_v.md_clienteg94 d on a.codunicocliordenante=d.codunicocli and d.flgregeliminado <> 'S' 
where
a.fecdia between to_date('01/04/2022','dd/mm/yyyy') and to_date('30/09/2022','dd/mm/yyyy') and
a.codproducto in ('TRAXRE') and
a.codtipestadotransaccion = '04' ;

-- Obtencion del codunicoli limpio
truncate table tmp_aut007_perfil;
insert into tmp_aut007_perfil 
select 
    a.*,f.codunicocli_limpio 
from tmp_aut007_pre_perfil a
left join tmp_aut007_univ f on a.nbrclibeneficiario=f.nbrclibeneficiario 

-- Obtenemos el monto total de la base de perfil
truncate table tmp_aut007_group_perfil;
insert into tmp_aut007_group_perfil 
select 
    to_number(to_char(fecdia,'yyyymm')) as periodo,codunicocli_limpio,
    sum(mtotransacciondolar) as mto_total 
from tmp_aut007_perfil
group by to_number(to_char(fecdia,'yyyymm')),codunicocli_limpio;

-- Obtenemos la base de los clientes con sus montos para los diferentes meses
truncate table tmp_aut007_perfil1;
insert into tmp_aut007_perfil1 
select a.* from tmp_aut007_group_perfil a
union all
select periodo,codunicocli_limpio,monto_total from tmp_aut007_monto_total;

--Obtenemos las fechas de los 6 meses anteriores
truncate table tmp_aut007_fec_perfil;
insert into tmp_aut007_fec_perfil 
select  a.*,
to_number(to_char(add_months(to_date(to_char(a.periodo||'01'),'yyyymmdd'),-6),'yyyymm')) as fecha_min,
to_number(to_char(add_months(to_date(to_char(a.periodo||'01'),'yyyymmdd'),-1),'yyyymm')) as fecha_max
from tmp_aut007_monto_total a;

-- Obtenemos el promedio y la desviacion estandar  
truncate table tmp_aut007_fec_perfil2;
insert into tmp_aut007_fec_perfil2 
select 
    a.periodo,a.codunicocli_limpio,avg(nullif(b.mto_total,0)) as media_depo, 
    stddev(nullif(b.mto_total,0)) as desv_depo
from tmp_aut007_fec_perfil a 
left join tmp_aut007_perfil1 b on a.codunicocli_limpio = b.codunicocli_limpio
where b.periodo between fecha_min and fecha_max 
group by a.periodo,a.codunicocli_limpio;

-- Variable multiples ordenantes distintos
truncate table tmp_aut007_ordenantes;
insert into tmp_aut007_ordenantes 
select distinct 
    to_number(to_char(fecdia,'yyyymm')) as periodo,codunicocli_limpio,
    count(distinct nbrordenante) as ctd_ordenantes
from tmp_aut007_univ 
group by to_number(to_char(fecdia,'yyyymm')) ,codunicocli_limpio;

--Variable nacionalidad del beneficiario
truncate table tmp_aut007_extr;
insert into tmp_aut007_extr 
select distinct 
    a.codunicocli_limpio,
    case when c.codpaisnacionalidad='PER' then 0 else 1 end as flg_extranjero 
from tmp_aut007_univ a
left join ods_v.md_clienteg94 b on a.codunicocli_limpio=b.codunicocli and b.flgregeliminado = 'N'
left join ods_v.md_personanatural c on b.codclavecic=c.codclavecic;

-- Variable ros
truncate table tmp_aut007_ros;
insert into tmp_aut007_ros 
with tmp_aut007 as (
select distinct
    a.fecdia,
    a.codunicocli_limpio,'0000'||''||'GR'||codmatricula||'7' as codunicocli_gremio 
from tmp_aut007_univ a
left join ods_v.md_empleadog94 b on a.codunicocli_limpio=b.CODUNICOCLI),
tmp_aut007_1 as (
select distinct
    a.fecdia,codunicocli_limpio,
    case when codunicocli_gremio = '0000GR7' 
        then codunicocli_limpio else codunicocli_gremio end as codunicocli
from tmp_aut007 a
)
select distinct 
    to_number(to_char(fecdia,'yyyymm')) as periodo,codunicocli_limpio  
from tmp_aut007_1 a
inner join s61751.sapy_dminvestigacion b on a.codunicocli=b.codunicocli
left join s61751.sapy_dmcaso c on b.idcaso = c.idcaso
where fecdia>fecfinros and c.idempresa=1;

-- Variables LSB/NP
truncate table tmp_aut007_lsb;
insert into tmp_aut007_lsb 
with tmp_aut007 as (
select distinct
    a.fecdia,
    a.codunicocli_limpio,'0000'||''||'GR'||codmatricula||'7' as codunicocli_gremio 
from tmp_aut007_univ a
left join ods_v.md_empleadog94 b on a.codunicocli_limpio=b.codunicocli),
 tmp_aut007_1 as (
select distinct
    a.fecdia,codunicocli_limpio,
    case when codunicocli_gremio = '0000GR7' 
        then codunicocli_limpio else codunicocli_gremio end as codunicocli
from tmp_aut007 a)
select distinct to_number(to_char(fecdia,'yyyymm')) as periodo,codunicocli_limpio  
from tmp_aut007_1 a
inner join s61751.sapy_dmcaso b on a.codunicocli = b.codunicocli
left join s61751.sapy_dmalerta c on b.codunicocli=c.codunicocli
left join s61751.sapy_origen d on c.idorigen = d.idorigen
where a.fecdia>c.fecregistro and d.idorigen in (2,29) and b.idempresa=1;

-- Variable AN
truncate table tmp_aut007_an;
insert into tmp_aut007_an 
select distinct 
    to_number(to_char(a.fecdia,'yyyymm')) as periodo,a.codunicocli_limpio
from tmp_aut007_univ a
inner join ods_v.md_clientenegativo b on b.codunicocli=a.codunicocli_limpio
left join ods_v.md_motivodetalleclinegativo c on c.codclavecic = b.codclavecic
where b.tipestclinegativo <> 'H' and c.tipmotivonegativo in ('013')
and a.fecdia>c.fecregistrodetallenegativo;

-- Obtencion de los campos de apellidos y nombres del beneficiario y ordenante 
truncate table tmp_aut007_nombre;
insert into tmp_aut007_nombre 
select distinct 
    coddocggtt,fecdia,codunicocli_limpio,nbrclibeneficiario_limpio,
    trim(substr(nbrclibeneficiario_limpio ,1,(instr(nbrclibeneficiario_limpio ,' ',1)-1))) 
        as apepatbeneficiario,
    trim(substr(nbrclibeneficiario_limpio ,instr(nbrclibeneficiario_limpio ,' ',1)+1,
    (instr(nbrclibeneficiario_limpio ,' ',1,2)-instr(nbrclibeneficiario_limpio ,' ',1)))) 
        as apematbeneficiario,
    trim(substr(nbrclibeneficiario_limpio ,instr(nbrclibeneficiario_limpio ,' ',1,2)+1)) 
        as nombrebeneficiario,
    nbrordenante,
    trim(substr(nbrordenante,1,(instr(nbrordenante,' ',1)-1))) as apepatordenante,
    trim(substr(nbrordenante,instr(nbrordenante,' ',1)+1,(instr(nbrordenante,' ',1,2)-
    instr(nbrordenante,' ',1)))) as apematordenante,
    trim(substr(nbrordenante,instr(nbrordenante,' ',1,2)+1)) as nombreordenante
from tmp_aut007_univ;

-- Variable vinculo familiar
truncate table tmp_aut007_varfamiliares;
insert into tmp_aut007_varfamiliares 
with tmp_aut007 as (
select a.*,
case
when (trim(apepatbeneficiario) = trim(apepatordenante) 
        and trim(apematbeneficiario) = trim(apematordenante)) or
     (trim(apepatbeneficiario) = trim(apematordenante) 
        and trim(apematbeneficiario) = trim(apepatordenante)) or  
	 (trim(apepatbeneficiario) = trim(apepatordenante)) or 
	 (trim(apematordenante) = trim(apepatbeneficiario)) or 
	 (trim(apepatordenante) = trim(apematbeneficiario)) then 1
else 0 end as flg_familiar_apellido 
from tmp_aut007_nombre a)
select distinct 
    to_number(to_char(fecdia,'yyyymm')) as periodo ,
    codunicocli_limpio, max(flg_familiar_apellido) as flg_familiar_apellido
from tmp_aut007 
group by to_number(to_char(fecdia,'yyyymm')) ,codunicocli_limpio ;

-- Variable cliente y no cliente
truncate table tmp_aut007_cliente;
insert into tmp_aut007_cliente 
select distinct 
    a.codunicocli_limpio 
from tmp_aut007_univ a
inner join ods_v.md_clienteg94 b on a.codunicocli_limpio=b.codunicocli
where b.flgregeliminado = 'N' and B.tipmarcacli not in ('NC','XC','FA','CF','CD') 
and b.codsubsegmento not in ('NBN','NBE');

-- Tablon final
truncate table tmp_aut007_univ_total;
insert into tmp_aut007_univ_total  
select distinct     
    a.*,
    case when b.ctd_ordenantes is null then 0 else b.ctd_ordenantes end as ctd_ordenantes,
    case when c.flg_extranjero is null then 0 else c.flg_extranjero end as flg_extranjero,
    case when d.codunicocli_limpio is null then 0 else 1 end as flg_ros,
    case when e.codunicocli_limpio is null then 0 else 1 end as flg_lsb_np,
    case when f.codunicocli_limpio is null then 0 else 1 end as flg_an,
    case when h.media_depo <> 0 and h.desv_depo <> 0 and h.media_depo+3*h.desv_depo<a.monto_total  
        then 1 else 0 end flg_perfil,
    case when i.flg_familiar_apellido is null 
        then 0 else i.flg_familiar_apellido end as flg_familiar_apellido,
    case when j.codunicocli_limpio is null then 0 else 1 end as flg_cliente,
    case when k.monto_total_semanal is null 
        then 0 else k.monto_total_semanal end as monto_total_semanal,
    case when k.porcentaje_monto is null then 0 else k.porcentaje_monto end as porcentaje_monto,
    case when k.ctd_trx_semanal is null then 0 else k.ctd_trx_semanal end as ctd_trx_semanal,
    case when k.porcentaje_ctd is null then 0 else k.porcentaje_ctd end as porcentaje_ctd
from tmp_aut007_monto_total a
left join tmp_aut007_ordenantes b on a.periodo=b.periodo and a.codunicocli_limpio=b.codunicocli_limpio
left join tmp_aut007_extr c on a.codunicocli_limpio=c.codunicocli_limpio
left join tmp_aut007_ros d on a.periodo = d.periodo and a.codunicocli_limpio=d.codunicocli_limpio
left join tmp_aut007_lsb e on a.periodo = e.periodo and a.codunicocli_limpio=e.codunicocli_limpio
left join tmp_aut007_an f on a.periodo = f.periodo and a.codunicocli_limpio=f.codunicocli_limpio
left join tmp_aut007_fec_perfil2 h on a.periodo = h.periodo and a.codunicocli_limpio=h.codunicocli_limpio
left join tmp_aut007_varfamiliares i on a.periodo = i.periodo and a.codunicocli_limpio=i.codunicocli_limpio
left join tmp_aut007_cliente j on a.codunicocli_limpio=j.codunicocli_limpio
left join tmp_aut007_mto_ctd_semanal k on a.periodo = k.periodo and a.codunicocli_limpio=k.codunicocli_limpio;

commit;
quit;