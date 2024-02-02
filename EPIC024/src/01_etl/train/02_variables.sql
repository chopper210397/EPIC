
ALTER session disable parallel query

--Ejecución en Novi23 con test de abril23 a oct23

-----**  MES 01 - Oct23  **--------

--Extraer las trx historica de los 7 ultimos meses del mes analisis
drop table tmp_ingrestrc_trxs_total_vf_m;
create table tmp_ingrestrc_trxs_total_vf_m tablespace d_aml_99 as
select  * from  tmp_ingrestrc_trxs_total_vf
where periodo between  to_number(to_char(add_months(sysdate, -7),'yyyymm')) and  to_number(to_char(add_months(sysdate, -1),'yyyymm'));

--Extraer el mes de analisis
drop table tmp_ingrestrc_universo_cli_m;
create table tmp_ingrestrc_universo_cli_m tablespace d_aml_99 as
select  * from  tmp_ingrestrc_universo_cli
where periodo = to_number(to_char(add_months(sysdate, -1),'yyyymm'));

--edad
drop table tmp_ingrestrc_edad;
create table tmp_ingrestrc_edad tablespace d_aml_99 as
with tmp_proc_edad_ppnn_aux as
(select a.codclavecic,a.periodo,c.fecnacimiento, floor(months_between(to_date(to_char(periodo||'01'),'yyyymmdd'), c.fecnacimiento) /12) as edad
from tmp_ingrestrc_universo_cli_m a
inner join ods_v.md_cliente b on a.codclavecic = b.codclavecic
left join ods_v.md_personanatural c on a.codclavecic = c.codclavecic
where trim(b.tipper) = 'P'
),tmp_proc_edad_ppjj_aux as
(select a.codclavecic,a.periodo,c.fecconstitucion, floor(months_between(to_date(to_char(periodo||'01'),'yyyymmdd'), c.fecconstitucion) /12) as edad
from tmp_ingrestrc_universo_cli_m a
inner join ods_v.md_cliente b on a.codclavecic = b.codclavecic
left join ods_v.mm_empresa c on a.codclavecic = c.codclavecic
where trim(b.tipper) = 'E'
)select a.periodo, a.codclavecic, case when trim(x.tipper) = 'P' then b.edad else case when trim(x.tipper) = 'E' then c.edad else null end end as edad
from tmp_ingrestrc_universo_cli_m a
left join ods_v.md_cliente x on a.codclavecic = x.codclavecic
left join tmp_proc_edad_ppnn_aux b on a.periodo = b.periodo and a.codclavecic = b.codclavecic
left join tmp_proc_edad_ppjj_aux c on a.periodo = c.periodo and a.codclavecic = c.codclavecic;

--tipper
drop table tmp_ingrestrc_tipper;
create table tmp_ingrestrc_tipper tablespace d_aml_99 as
select a.*, b.tipper
from tmp_ingrestrc_edad a
inner join ods_v.md_cliente b on a.codclavecic = b.codclavecic;

--antiguedad cliente
drop table tmp_ingrestrc_antiguedad;
create table tmp_ingrestrc_antiguedad tablespace d_aml_99 as
with tmp_proc_antg_fecapertura as
(select codclavecic,min(t.fecapertura) as fecapertura
from (select distinct codclavecic,fecapertura from ods_v.md_prestamo
    union all
    select distinct codclavecic,fecapertura from ods_v.md_impac
    union all
    select distinct codclavecic,fecapertura from ods_v.md_saving
    union all
    select distinct codclavecic,fecapertura from ods_v.md_cuentavp) t
group by codclavecic
),tmp_proc_antig_aux as
(select a.periodo, a.codclavecic, b.fecapertura,
floor(months_between(to_date(to_char(periodo||'01'),'yyyymmdd'), b.fecapertura) ) as antiguedad
from tmp_ingrestrc_tipper a
left join tmp_proc_antg_fecapertura b on a.codclavecic = b.codclavecic
)select a.*, b.antiguedad
from tmp_ingrestrc_tipper a
left join tmp_proc_antig_aux b on a.periodo = b.periodo and a.codclavecic = b.codclavecic;

--flg actividad economica no definida
drop table tmp_ingrestrc_acteconomica_nodef_aux;
create table tmp_ingrestrc_acteconomica_nodef_aux tablespace d_aml_99 as
  select codacteconomica,desacteconomica,'OTRSERV'as busq
  from ods_v.mm_descodactividadeconomica
  where upper(desacteconomica) like '%OTR%SERV%'
  union
  select codacteconomica,desacteconomica,'NO ESPECIF'
  from ods_v.mm_descodactividadeconomica
  where upper(desacteconomica) like '%NO ESPECIF%'
  union
  select codacteconomica,desacteconomica,'NO DISPO'
  from ods_v.mm_descodactividadeconomica
  where upper(desacteconomica) like '%NO DISPO%'
  union
  select codacteconomica,desacteconomica,'MAYOROTRPROD'
  from ods_v.mm_descodactividadeconomica
  where upper(desacteconomica) like '%MAYOR%OTR%PROD%'
  union
  select codacteconomica,desacteconomica,'MENOROTRPROD'
  from ods_v.mm_descodactividadeconomica
  where upper(desacteconomica) like '%MENOR%OTR%PROD%';

drop table tmp_ingrestrc_acteconomica_nodef;
create table tmp_ingrestrc_acteconomica_nodef tablespace d_aml_99 as
select a.*, b.codacteconomica, d.desacteconomica,
case when b.codacteconomica is null then 1
    when c.codacteconomica is not null then 1
else 0 end flg_acteco_nodef
from tmp_ingrestrc_antiguedad a
left join ods_v.md_cliente b on a.codclavecic = b.codclavecic
left join tmp_ingrestrc_acteconomica_nodef_aux c on trim(b.codacteconomica) = trim(c.codacteconomica)
left join ods_v.mm_descodactividadeconomica d on trim(b.codacteconomica) = trim(d.codacteconomica);

--variables sapyc: np
drop table tmp_ingrestrc_np_aux2;
create table tmp_ingrestrc_np_aux2 tablespace d_aml_99 as
with tmp_ingrestrc_np_aux as
(select a.*, b.idorigen, b.nbrorigen as origen, b.codtransaccion as escenario, b.nbrtransaccion as desescenario
from (
select a.idcaso, case when instr(a.codunicocli,'GR') > 0 then c.codclavecic else d.codclavecic end as codclavecic, a.idresultado as idresultadoeval, a.fecfineval as fecfineval, b."IDRESULTADOSUPERVISOR"
from s61751.sapy_dmevaluacion a
left join s61751.sapy_dminvestigacion b on a.idcaso = b.idcaso
left join ods_v.md_empleadog94 c on trim(substr(a.codunicocli,instr(a.codunicocli,'GR')+2,6)) = trim(c.codmatricula)
left join ods_v.md_clienteg94 d on trim(a.codunicocli) = trim(d.codunicocli)
) a
left join s61751.sapy_dmalerta b on a.idcaso = b.idcaso
where idorigen in (2)
)select a.periodo,a.codclavecic, sum(case when b.fecfineval < to_date(to_char(a.periodo||'01'),'yyyymmdd') then 1 else 0 end) as ctdnp
from tmp_ingrestrc_acteconomica_nodef a
left join tmp_ingrestrc_np_aux b on a.codclavecic = b.codclavecic
group by a.periodo,a.codclavecic;

drop table tmp_ingrestrc_np;
create table tmp_ingrestrc_np tablespace d_aml_99 as
select a.*,
case when b.ctdnp > 0 then 1 else 0 end flgnp,
case when b.ctdnp is not null then b.ctdnp else 0 end ctdnp
from tmp_ingrestrc_acteconomica_nodef a
left join tmp_ingrestrc_np_aux2 b on a.periodo = b.periodo and a.codclavecic = b.codclavecic;

--variables sapyc: lsb
drop table tmp_ingrestrc_lsb_aux2;
create table tmp_ingrestrc_lsb_aux2 tablespace d_aml_99 as
with tmp_ingrestrc_lsb_aux as
(select a.*, b.idorigen, b.nbrorigen as origen, b.codtransaccion as escenario, b.nbrtransaccion as desescenario
from (
    select a.idcaso, case when instr(a.codunicocli,'GR') > 0 then c.codclavecic else d.codclavecic end as codclavecic, a.idresultado as idresultadoeval, a.fecfineval as fecfineval, b."IDRESULTADOSUPERVISOR"
    from s61751.sapy_dmevaluacion a
    left join s61751.sapy_dminvestigacion b on a.idcaso = b.idcaso
    left join ods_v.md_empleadog94 c on trim(substr(a.codunicocli,instr(a.codunicocli,'GR')+2,6)) = trim(c.codmatricula)
    left join ods_v.md_clienteg94 d on trim(a.codunicocli) = trim(d.codunicocli)
) a
left join s61751.sapy_dmalerta b on a.idcaso = b.idcaso
where idorigen in (29)
)select a.periodo,a.codclavecic, sum(case when b.fecfineval < to_date(to_char(a.periodo||'01'),'yyyymmdd') then 1 else 0 end) as ctdlsb
from tmp_ingrestrc_np a
left join tmp_ingrestrc_lsb_aux b on a.codclavecic = b.codclavecic
group by a.periodo,a.codclavecic;

--var ctd_np_lsb
drop table tmp_ingrestrc_lsb;
create table tmp_ingrestrc_lsb tablespace d_aml_99 as
select a.*,
case when b.ctdlsb > 0 then 1 else 0 end flglsb,
case when b.ctdlsb is not null then b.ctdlsb else 0 end ctdlsb
from tmp_ingrestrc_np a
left join tmp_ingrestrc_lsb_aux2 b on a.periodo = b.periodo and a.codclavecic = b.codclavecic;

--var archivo negativo
drop table tmp_ingrestrc_archnegativo;
create table tmp_ingrestrc_archnegativo tablespace d_aml_99 as
with tmp_ingrestrc_archivonegativo_aux as (
select distinct a.codclavecic, max(b.destipmotivonegativo) as destipmotivonegativo
from ods_v.md_motivodetalleclinegativo a
left join ods_v.md_destipomotivonegativo b on a.tipmotivonegativo = b.tipmotivonegativo
inner join (
    select codclavecic, max(fecregistrodetallenegativo) as maxfecregistrodetallenegativo
    from ods_v.md_motivodetalleclinegativo
    group by codclavecic
) c on a.codclavecic = c.codclavecic and a.fecregistrodetallenegativo = c.maxfecregistrodetallenegativo
where a.flghistorico = 'N' and a.tipmotivonegativo='013' and a.tipdetallemotivonegativo='001'
group by a.codclavecic
)select a.*,
case when b.codclavecic is not null then 1 else 0 end as flgarchivonegativo,
b.destipmotivonegativo as destipmotivonegativo
from tmp_ingrestrc_lsb a
left join tmp_ingrestrc_archivonegativo_aux b on a.codclavecic = b.codclavecic;

drop table tmp_ingrestrc_ctd_nplsb;
create table tmp_ingrestrc_ctd_nplsb tablespace d_aml_99 as
select a.*, ctdnp+ctdlsb as ctd_np_lsb
from tmp_ingrestrc_archnegativo a;

--ctd evaluaciones
drop table tmp_ingrestrc_sapyc;
create table tmp_ingrestrc_sapyc tablespace d_aml_99 as
select a.*
from (
   select a.idcaso, case when instr(a.codunicocli,'GR') > 0 then c.codclavecic else d.codclavecic end as codclavecic, a.idresultado as idresultadoeval, a.fecfineval as fecfineval, b."IDRESULTADOSUPERVISOR"
     from s61751.sapy_dmevaluacion a
     left join s61751.sapy_dminvestigacion b on a.idcaso = b.idcaso
     left join ods_v.md_empleadog94 c on trim(substr(a.codunicocli,instr(a.codunicocli,'GR')+2,6)) = trim(c.codmatricula)
     left join ods_v.md_clienteg94 d on trim(a.codunicocli) = trim(d.codunicocli)
) a;

drop table tmp_ingrestrc_evals;
create table tmp_ingrestrc_evals tablespace d_aml_99 as
with tmp_ingrestrc_evals_aux as
(select a.periodo,a.codclavecic, sum(case when b.fecfineval < to_date(to_char(a.periodo||'01'),'yyyymmdd') then 1 else 0 end) as ctdeval
from tmp_ingrestrc_ctd_nplsb a
left join tmp_ingrestrc_sapyc b on a.codclavecic = b.codclavecic
group by a.periodo,a.codclavecic
)select a.*,
case when b.ctdeval is not null then b.ctdeval else 0 end as ctdeval
from tmp_ingrestrc_ctd_nplsb a
left join tmp_ingrestrc_evals_aux b on a.periodo = b.periodo and a.codclavecic = b.codclavecic;

--var segmento del cliente
drop table tmp_ingrestrc_segmento;
create table tmp_ingrestrc_segmento tablespace d_aml_99 as
with tmp_ingrestrc_segmento_aux as (
  select distinct trim(subseg.codsubsegmento) as codsubsegmento, subseg.dessubsegmento, trim(seg.codsegmento) as codsegmento, seg.dessegmento
  from ods_v.mm_descodigosubsegmento subseg
  left join ods_v.mm_descodsubseggen subseggen on trim(subseg.codsubseggeneral)=trim(subseggen.codsubseggeneral)
  left join ods_v.mm_descodigosegmento seg on trim(subseggen.codsegmento)=trim(seg.codsegmento)
) select a.*, c.codsubsegmento, c.dessubsegmento, c.codsegmento, c.dessegmento
  from tmp_ingrestrc_evals a
  left join ods_v.md_cliente b on a.codclavecic = b.codclavecic
  left join tmp_ingrestrc_segmento_aux c on trim(b.codsubsegmento) = trim(c.codsubsegmento);

-- var lugar de residencia mas actual
drop table tmp_ingrestrc_lugarresidencia_aux2;
create table tmp_ingrestrc_lugarresidencia_aux2 tablespace d_aml_99 as
with tmp_ingrestrc_lugarresidencia_aux as (
  select codclavecic,max(numdir) as maxnumdir
  from ods_v.mm_direccioncliente
  where
  tipdir in ('D')
  group by codclavecic
) select  distinct b.codclavecic, b.tipdir, c.codubigeo, b.coddistrito, c.descoddistrito, c.codprovincia, d.descodprovincia, d.coddepartamento, e.descoddepartamento
  from tmp_ingrestrc_segmento a
  left join ods_v.mm_direccioncliente b on a.codclavecic = b.codclavecic
  inner join tmp_ingrestrc_lugarresidencia_aux x on b.codclavecic = x.codclavecic and b.numdir = x.maxnumdir
  left join ods_v.mm_distrito c on b.coddistrito = c.coddistrito
  left join ods_v.mm_provincia d on c.codprovincia = d.codprovincia
  left join ods_v.mm_departamento e on d.coddepartamento = e.coddepartamento;

drop table tmp_ingrestrc_lugarresidencia;
create table tmp_ingrestrc_lugarresidencia tablespace d_aml_99 as
select a.*, b.tipdir, b.codubigeo, b.coddistrito, b.descoddistrito, b.codprovincia, b.descodprovincia, b.coddepartamento, b.descoddepartamento
from tmp_ingrestrc_segmento a
left join tmp_ingrestrc_lugarresidencia_aux2 b on a.codclavecic = b.codclavecic;

--var nacionalidad
drop table tmp_ingrestrc_nacionalidad;
create table tmp_ingrestrc_nacionalidad tablespace d_aml_99 as
with tmp_ingrestrc_nacionalidad_pn as (
	select distinct a.codclavecic, a.tipper, trim(c.codpaisnacionalidad) as codpaisnacionalidad, trim(d.descodpaisnacionalidad) as descodpaisnacionalidad,
	case when trim(c.codpaisnacionalidad) = 'PER' then 0
		 when c.codpaisnacionalidad is not null and trim(c.codpaisnacionalidad) <> 'PER' then 1
	else null end as flgnacionalidad
	from tmp_ingrestrc_lugarresidencia a
	inner join ods_v.md_cliente b on a.codclavecic = b.codclavecic
	left join ods_v.md_personanatural c on b.codclavecic = c.codclavecic
	left join ods_v.mm_descodigopaisnacionalidad d on c.codpaisnacionalidad = d.codpaisnacionalidad
	where a.tipper = 'P'
),tmp_ingrestrc_nacionalidad_pj as (
	select distinct a.codclavecic, a.tipper, 'PER' as codpaisnacionalidad, 'PERU' as descodpaisnacionalidad, 0 as flgnacionalidad
	from tmp_ingrestrc_lugarresidencia a
	inner join ods_v.mm_direccioncliente c on a.codclavecic = c.codclavecic
	where a.tipper = 'E'
)select a.*,
case when a.tipper = 'P' then b.codpaisnacionalidad else c.codpaisnacionalidad end as codpaisnacionalidad,
case when a.tipper = 'P' then b.descodpaisnacionalidad else c.descodpaisnacionalidad end as descodpaisnacionalidad,
case when a.tipper = 'P' then b.flgnacionalidad else c.flgnacionalidad end as flgnacionalidad
from tmp_ingrestrc_lugarresidencia a
left join tmp_ingrestrc_nacionalidad_pn b on a.codclavecic = b.codclavecic
left join tmp_ingrestrc_nacionalidad_pj c on a.codclavecic = c.codclavecic;

---- /MONTOS /-------

--variables de comportamiento: mto_ingresos_mes, ctd_ingresos_mes
drop table tmp_ingrestrc_varcomportamiento;
create table tmp_ingrestrc_varcomportamiento tablespace d_aml_99 as
with tmp_ingrestrc_varcomp as (
  select periodo, codclavecicbeneficiario as codclavecic,
  sum(mtodolarizado) as mto_ingresos_mes,
  count(periodo) as ctd_ingresos_mes
  from tmp_ingrestrc_trxs_total_vf_m
  group by periodo, codclavecicbeneficiario
)select a.*,b.mto_ingresos_mes,b.ctd_ingresos_mes
from tmp_ingrestrc_nacionalidad a
left join tmp_ingrestrc_varcomp b on a.periodo = b.periodo and a.codclavecic = b.codclavecic;

--perfil total
drop table tmp_ingrestrc_perfi1;
create table tmp_ingrestrc_perfi1 tablespace d_aml_99 as
with tmp_ingrestrc_perfi1_aux as (
     select periodo, codclavecicbeneficiario as codclavecic, sum(mtodolarizado) as mto_ingresos
     from tmp_ingrestrc_trxs_total_vf_m
     group by periodo, codclavecicbeneficiario
) select  a.codclavecic,a.periodo as numperiodo,b.periodo,
  months_between(to_date(a.periodo,'yyyymm'),to_date(b.periodo,'yyyymm')) meses,
  case when b.mto_ingresos is null then 0 else b.mto_ingresos end mto_ingresos
  from tmp_ingrestrc_perfi1_aux a
  inner join tmp_ingrestrc_perfi1_aux b on a.codclavecic=b.codclavecic;

drop table tmp_ingrestrc_perfi2;
create table tmp_ingrestrc_perfi2 tablespace d_aml_99 as
select numperiodo,codclavecic,mto_ingresos
from tmp_ingrestrc_perfi1 a
where numperiodo=periodo;

--media y desviacion_estandar
drop table tmp_ingrestrc_perfi3;
create table tmp_ingrestrc_perfi3 tablespace d_aml_99 as
with temp_tab as(
  select numperiodo,codclavecic,
  avg(nullif(mto_ingresos,0)) as media_depo,stddev(nullif(mto_ingresos,0)) as desv_depo
  from tmp_ingrestrc_perfi1
  where meses<=6 and meses>=1
  group by numperiodo,codclavecic
) select a.*,
  round(nvl(b.media_depo,0),2) media_ingresos,
  round(nvl(b.desv_depo,0),2) desv_ingresos
  from tmp_ingrestrc_perfi2 a
  left join temp_tab b on (a.numperiodo=b.numperiodo and a.codclavecic=b.codclavecic);

-- var el flg perfil total en tabla cliente mes: flg_perfil_ingresos_3ds
drop table tmp_ingrestrc_perfilingresos;
create table tmp_ingrestrc_perfilingresos tablespace d_aml_99 as
select  a.*, b.media_ingresos, b.desv_ingresos,
case when b.media_ingresos <> 0 and b.desv_ingresos <> 0 and b.media_ingresos+3*b.desv_ingresos<b.mto_ingresos then 1 else 0 end flg_perfil_ingresos_3ds
from   tmp_ingrestrc_varcomportamiento a
left join tmp_ingrestrc_perfi3 b on (a.periodo=b.numperiodo and a.codclavecic=b.codclavecic)
where periodo = to_number(to_char(add_months(sysdate, -1),'yyyymm'));

-------------------
--var mtos redondos :  max_ctdmtosredondos,sum_mtosredondos
drop table tmp_ingrestrc_mtosredondos;
create table tmp_ingrestrc_mtosredondos tablespace d_aml_99 as
with tmp_ingrestrc_mtosredondos_1 as (
  select a.*,
  floor(mtotransaccion) as mtotransaccion_sindecimal, case when mtotransaccion=floor(a.mtotransaccion) then 1 else 0 end flgredondo
  from tmp_ingrestrc_trxs_total_vf_m a
),
tmp_ingrestrc_mtosredondos_2 as (
  select periodo,codclavecicbeneficiario as codclavecic,mtotransaccion,
  sum(flgredondo) as ctdredondo,
  sum(case when flgredondo = 1 then mtodolarizado else 0 end) as summtoredondo
  from tmp_ingrestrc_mtosredondos_1
  group by periodo, codclavecicbeneficiario, mtotransaccion
),
tmp_ingrestrc_mtosredondos_3 as (
  select periodo,codclavecic,max(ctdredondo) as max_ctdmtosredondos
  from tmp_ingrestrc_mtosredondos_2
  group by periodo, codclavecic
),
tmp_ingrestrc_mtosredondos_4 as (
  select periodo,codclavecic,sum(summtoredondo) as sum_mtosredondos
  from tmp_ingrestrc_mtosredondos_2
  group by periodo, codclavecic
)select a.*,
case when b.max_ctdmtosredondos is not null then b.max_ctdmtosredondos else 0 end max_ctdmtosredondos,
case when c.sum_mtosredondos is not null then c.sum_mtosredondos else 0 end sum_mtosredondos
from tmp_ingrestrc_perfilingresos a
left join tmp_ingrestrc_mtosredondos_3 b on a.periodo = b.periodo and a.codclavecic = b.codclavecic
left join tmp_ingrestrc_mtosredondos_4 c on a.periodo = c.periodo and a.codclavecic = c.codclavecic;

-----------------
-- mtos y ctds
drop table tmpctds;
create table tmpctds tablespace d_aml_99 as
select periodo,codclavecicbeneficiario as codclavecic,mtotransaccion,count(*) as ctd
from tmp_ingrestrc_trxs_total_vf_m
group by periodo,codclavecicbeneficiario,mtotransaccion;

-- max ctd
drop table tmpctdsmax;
create table tmpctdsmax tablespace d_aml_99 as
select periodo,codclavecic,max(ctd) as max_ctd
from tmpctds
group by periodo,codclavecic;

-- orden de las ctds
drop table tmpctdsycdtsmax;
create table tmpctdsycdtsmax tablespace d_aml_99 as
select a.*, b.max_ctd
from tmpctds a
inner join tmpctdsmax b on a.periodo = b.periodo and a.codclavecic = b.codclavecic and a.ctd = b.max_ctd
order by b.max_ctd desc;

-- ctd max no repetidos
drop table tmpmaxsnorepetidos;
create table tmpmaxsnorepetidos tablespace d_aml_99 as
with tmpx as (
  select periodo, codclavecic, ctd as ctdmaxima, count(*) as ctdmaximos
  from (
  tmpctdsycdtsmax
  )
  group by periodo, codclavecic, ctd
  having count(*) <= 1
)
select b.*, a.mtotransaccion
from tmpctdsycdtsmax a
inner join tmpx b on a.periodo = b.periodo and a.codclavecic = b.codclavecic and a.max_ctd = b.ctdmaxima;

--ctd max repetidos
drop table tmpmaxsrepetidos;
create table tmpmaxsrepetidos tablespace d_aml_99 as
select periodo, codclavecic, ctd as ctdmaxima, count(*) as ctdmaximos
from (
tmpctdsycdtsmax
)
group by periodo, codclavecic, ctd
having count(*) > 1;

--mto maximo de la maxima ctd repetida
drop table tmpmaxsrepetidosunicos;
create table tmpmaxsrepetidosunicos tablespace d_aml_99 as
with tmpy as (
  select a.*, b.ctdmaximos
  from tmpctdsycdtsmax a
  inner join tmpmaxsrepetidos b on a.periodo = b.periodo and a.codclavecic = b.codclavecic and a.max_ctd = b.ctdmaxima
  order by a.periodo, a.codclavecic, a.max_ctd
)
select periodo, codclavecic, max_ctd as ctdmaxima, ctdmaximos, max(mtotransaccion) as mtomaxdemaxrepetidos
from tmpy
group by periodo, codclavecic, max_ctd, ctdmaximos;

--union de los mtos maximos de la max ctd repetida (mtomaxdemaxrepetidos),  mto de la max ctd  no repetida
drop table tmpclientesmtosmaximosunicos;
create table tmpclientesmtosmaximosunicos tablespace d_aml_99 as
select periodo, codclavecic, ctdmaxima, ctdmaximos, mtomaxdemaxrepetidos from tmpmaxsrepetidosunicos union all
select periodo, codclavecic, ctdmaxima, ctdmaximos, mtotransaccion  from tmpmaxsnorepetidos;

--suma de los mtos con max ctd repetida
drop table tmp_ingrestrc_mtosmaximosrepetidos_aux;
create table tmp_ingrestrc_mtosmaximosrepetidos_aux tablespace d_aml_99 as
select a.periodo, a.codclavecic, a.ctdmaxima,sum(b.mtodolarizado) as mto_maximosrepetidos
from tmpclientesmtosmaximosunicos a
left join tmp_ingrestrc_trxs_total_vf_m b on a.periodo = b.periodo and a.codclavecic = b.codclavecicbeneficiario and a.mtomaxdemaxrepetidos = b.mtotransaccion
group by a.periodo, a.codclavecic, a.ctdmaxima;

--var  ctmaxima, mto_maximosrepetidos,
drop table tmp_ingrestrc_mtosmaximosrepetidos;
create table tmp_ingrestrc_mtosmaximosrepetidos tablespace d_aml_99 as
select a.*,
case when b.ctdmaxima is null then 0 else b.ctdmaxima  end ctdmaxima,
case when b.mto_maximosrepetidos is null then 0 else b.mto_maximosrepetidos  end mto_maximosrepetidos
from tmp_ingrestrc_mtosredondos a
left join tmp_ingrestrc_mtosmaximosrepetidos_aux b on a.periodo = b.periodo and a.codclavecic = b.codclavecic ;

------------------
--var mtos proximos  : mtomaxdemaxrepetidos, mto_conotrosproximos , ctd_conotrosproximos
drop table tmp_ingrestrc_mtosyctdsproximos_aux;
create table tmp_ingrestrc_mtosyctdsproximos_aux tablespace d_aml_99 as
select a.periodo, a.codclavecic, a.mtomaxdemaxrepetidos,
sum(case when a.mtomaxdemaxrepetidos*0.9 < b.mtotransaccion and b.mtotransaccion < a.mtomaxdemaxrepetidos*1.1 then b.mtodolarizado else 0 end) as mto_conotrosproximos,
sum(case when a.mtomaxdemaxrepetidos*0.9 < b.mtotransaccion and b.mtotransaccion < a.mtomaxdemaxrepetidos*1.1 then 1 else 0 end) as ctd_conotrosproximos
from tmpclientesmtosmaximosunicos a
left join tmp_ingrestrc_trxs_total_vf_m b on a.periodo = b.periodo and a.codclavecic = b.codclavecicbeneficiario
group by a.periodo, a.codclavecic, a.mtomaxdemaxrepetidos;

drop table tmp_ingrestrc_mtosyctdsproximos;
create table tmp_ingrestrc_mtosyctdsproximos tablespace d_aml_99 as
select a.*,
case when b.mtomaxdemaxrepetidos is null then 0 else b.mtomaxdemaxrepetidos  end mtomaxdemaxrepetidos,
case when b.mto_conotrosproximos is null then 0 else b.mto_conotrosproximos  end mto_conotrosproximos,
case when b.ctd_conotrosproximos is null then 0 else b.ctd_conotrosproximos  end ctd_conotrosproximos
from tmp_ingrestrc_mtosmaximosrepetidos a
left join tmp_ingrestrc_mtosyctdsproximos_aux b on a.periodo = b.periodo and a.codclavecic = b.codclavecic ;

--tablon final mes 1
drop table tmp_ingrestrc_mtosyctdsproximos_tablon_m1;
create table tmp_ingrestrc_mtosyctdsproximos_tablon_m1 tablespace d_aml_99 as
select * from tmp_ingrestrc_mtosyctdsproximos;

---- ** MES 02 - Seti23 **-----

--Extraer las trx historica de los 7 ultimos meses del mes analisis
drop table tmp_ingrestrc_trxs_total_vf_m;
create table tmp_ingrestrc_trxs_total_vf_m tablespace d_aml_99 as
select  * from  tmp_ingrestrc_trxs_total_vf
where periodo between  to_number(to_char(add_months(sysdate, -8),'yyyymm')) and  to_number(to_char(add_months(sysdate, -2),'yyyymm'));

--Extraer el mes de analisis
drop table tmp_ingrestrc_universo_cli_m;
create table tmp_ingrestrc_universo_cli_m tablespace d_aml_99 as
select  * from  tmp_ingrestrc_universo_cli
where periodo = to_number(to_char(add_months(sysdate, -2),'yyyymm'));

--edad
drop table tmp_ingrestrc_edad;
create table tmp_ingrestrc_edad tablespace d_aml_99 as
with tmp_proc_edad_ppnn_aux as
( select a.codclavecic,a.periodo,c.fecnacimiento, floor(months_between(to_date(to_char(periodo||'01'),'yyyymmdd'), c.fecnacimiento) /12) as edad
  from tmp_ingrestrc_universo_cli_m a
  inner join ods_v.md_cliente b on a.codclavecic = b.codclavecic
  left join ods_v.md_personanatural c on a.codclavecic = c.codclavecic
  where trim(b.tipper) = 'P'
),tmp_proc_edad_ppjj_aux as
( select a.codclavecic,a.periodo,c.fecconstitucion, floor(months_between(to_date(to_char(periodo||'01'),'yyyymmdd'), c.fecconstitucion) /12) as edad
  from tmp_ingrestrc_universo_cli_m a
  inner join ods_v.md_cliente b on a.codclavecic = b.codclavecic
  left join ods_v.mm_empresa c on a.codclavecic = c.codclavecic
  where trim(b.tipper) = 'E'
)select a.periodo, a.codclavecic, case when trim(x.tipper) = 'P' then b.edad else case when trim(x.tipper) = 'E' then c.edad else null end end as edad
  from tmp_ingrestrc_universo_cli_m a
  left join ods_v.md_cliente x on a.codclavecic = x.codclavecic
  left join tmp_proc_edad_ppnn_aux b on a.periodo = b.periodo and a.codclavecic = b.codclavecic
  left join tmp_proc_edad_ppjj_aux c on a.periodo = c.periodo and a.codclavecic = c.codclavecic;

--tipper
drop table tmp_ingrestrc_tipper;
create table tmp_ingrestrc_tipper tablespace d_aml_99 as
select a.*, b.tipper
from tmp_ingrestrc_edad a
inner join ods_v.md_cliente b on a.codclavecic = b.codclavecic;

--antiguedad cliente
drop table tmp_ingrestrc_antiguedad;
create table tmp_ingrestrc_antiguedad tablespace d_aml_99 as
with tmp_proc_antg_fecapertura as
( select codclavecic,min(t.fecapertura) as fecapertura
  from ( select distinct codclavecic,fecapertura from ods_v.md_prestamo
         union all
         select distinct codclavecic,fecapertura from ods_v.md_impac
         union all
         select distinct codclavecic,fecapertura from ods_v.md_saving
         union all
         select distinct codclavecic,fecapertura from ods_v.md_cuentavp) t
  group by codclavecic
),tmp_proc_antig_aux as
(select a.periodo, a.codclavecic, b.fecapertura,
  floor(months_between(to_date(to_char(periodo||'01'),'yyyymmdd'), b.fecapertura) ) as antiguedad
  from tmp_ingrestrc_tipper a
  left join tmp_proc_antg_fecapertura b on a.codclavecic = b.codclavecic
)select a.*, b.antiguedad
  from tmp_ingrestrc_tipper a
  left join tmp_proc_antig_aux b on a.periodo = b.periodo and a.codclavecic = b.codclavecic;

--flg actividad economica no definida
drop table tmp_ingrestrc_acteconomica_nodef_aux;
create table tmp_ingrestrc_acteconomica_nodef_aux tablespace d_aml_99 as
  select codacteconomica,desacteconomica,'OTRSERV'as busq
  from ods_v.mm_descodactividadeconomica
  where upper(desacteconomica) like '%OTR%SERV%'
        union
  select codacteconomica,desacteconomica,'NO ESPECIF'
  from ods_v.mm_descodactividadeconomica
  where upper(desacteconomica) like '%NO ESPECIF%'
        union
  select codacteconomica,desacteconomica,'NO DISPO'
  from ods_v.mm_descodactividadeconomica
  where upper(desacteconomica) like '%NO DISPO%'
         union
  select codacteconomica,desacteconomica,'MAYOROTRPROD'
  from ods_v.mm_descodactividadeconomica
  where upper(desacteconomica) like '%MAYOR%OTR%PROD%'
         union
  select codacteconomica,desacteconomica,'MENOROTRPROD'
  from ods_v.mm_descodactividadeconomica
  where upper(desacteconomica) like '%MENOR%OTR%PROD%';

drop table tmp_ingrestrc_acteconomica_nodef;
create table tmp_ingrestrc_acteconomica_nodef tablespace d_aml_99 as
select a.*, b.codacteconomica, d.desacteconomica,
    case
        when b.codacteconomica is null then 1
        when c.codacteconomica is not null then 1
    else 0
    end flg_acteco_nodef
from tmp_ingrestrc_antiguedad a
left join ods_v.md_cliente b on a.codclavecic = b.codclavecic
left join tmp_ingrestrc_acteconomica_nodef_aux c on trim(b.codacteconomica) = trim(c.codacteconomica)
left join ods_v.mm_descodactividadeconomica d on trim(b.codacteconomica) = trim(d.codacteconomica);

--variables sapyc: np
drop table tmp_ingrestrc_np_aux2;
create table tmp_ingrestrc_np_aux2 tablespace d_aml_99 as
with tmp_ingrestrc_np_aux as
(select a.*, b.idorigen, b.nbrorigen as origen, b.codtransaccion as escenario, b.nbrtransaccion as desescenario
  from (
    select a.idcaso, case when instr(a.codunicocli,'GR') > 0 then c.codclavecic else d.codclavecic end as codclavecic, a.idresultado as idresultadoeval, a.fecfineval as fecfineval, b."IDRESULTADOSUPERVISOR"
    from s61751.sapy_dmevaluacion a
    left join s61751.sapy_dminvestigacion b on a.idcaso = b.idcaso
    left join ods_v.md_empleadog94 c on trim(substr(a.codunicocli,instr(a.codunicocli,'GR')+2,6)) = trim(c.codmatricula)
    left join ods_v.md_clienteg94 d on trim(a.codunicocli) = trim(d.codunicocli)
  ) a
left join s61751.sapy_dmalerta b on a.idcaso = b.idcaso
where idorigen in (2)
)select a.periodo,a.codclavecic, sum(case when b.fecfineval < to_date(to_char(a.periodo||'01'),'yyyymmdd') then 1 else 0 end) as ctdnp
from tmp_ingrestrc_acteconomica_nodef a
left join tmp_ingrestrc_np_aux b on a.codclavecic = b.codclavecic
group by a.periodo,a.codclavecic;

drop table tmp_ingrestrc_np;
create table tmp_ingrestrc_np tablespace d_aml_99 as
select a.*,
case when b.ctdnp > 0 then 1 else 0 end flgnp,
case when b.ctdnp is not null then b.ctdnp else 0 end ctdnp
from tmp_ingrestrc_acteconomica_nodef a
left join tmp_ingrestrc_np_aux2 b on a.periodo = b.periodo and a.codclavecic = b.codclavecic;

--variables sapyc: lsb
drop table tmp_ingrestrc_lsb_aux2;
create table tmp_ingrestrc_lsb_aux2 tablespace d_aml_99 as
with tmp_ingrestrc_lsb_aux as
(select a.*, b.idorigen, b.nbrorigen as origen, b.codtransaccion as escenario, b.nbrtransaccion as desescenario
  from (
     select a.idcaso, case when instr(a.codunicocli,'GR') > 0 then c.codclavecic else d.codclavecic end as codclavecic, a.idresultado as idresultadoeval, a.fecfineval as fecfineval, b."IDRESULTADOSUPERVISOR"
     from s61751.sapy_dmevaluacion a
     left join s61751.sapy_dminvestigacion b on a.idcaso = b.idcaso
     left join ods_v.md_empleadog94 c on trim(substr(a.codunicocli,instr(a.codunicocli,'GR')+2,6)) = trim(c.codmatricula)
     left join ods_v.md_clienteg94 d on trim(a.codunicocli) = trim(d.codunicocli)
  ) a
  left join s61751.sapy_dmalerta b on a.idcaso = b.idcaso
  where idorigen in (29)
)select a.periodo,a.codclavecic, sum(case when b.fecfineval < to_date(to_char(a.periodo||'01'),'yyyymmdd') then 1 else 0 end) as ctdlsb
from tmp_ingrestrc_np a
left join tmp_ingrestrc_lsb_aux b on a.codclavecic = b.codclavecic
group by a.periodo,a.codclavecic;

--var ctd_np_lsb
drop table tmp_ingrestrc_lsb;
create table tmp_ingrestrc_lsb tablespace d_aml_99 as
select a.*,
case when b.ctdlsb > 0 then 1 else 0 end flglsb,
case when b.ctdlsb is not null then b.ctdlsb else 0 end ctdlsb
from tmp_ingrestrc_np a
left join tmp_ingrestrc_lsb_aux2 b on a.periodo = b.periodo and a.codclavecic = b.codclavecic;

--var archivo negativo
drop table tmp_ingrestrc_archnegativo;
create table tmp_ingrestrc_archnegativo tablespace d_aml_99 as
with tmp_ingrestrc_archivonegativo_aux as (
  select distinct a.codclavecic, max(b.destipmotivonegativo) as destipmotivonegativo
  from ods_v.md_motivodetalleclinegativo a
  left join ods_v.md_destipomotivonegativo b on a.tipmotivonegativo = b.tipmotivonegativo
  inner join (
        select codclavecic, max(fecregistrodetallenegativo) as maxfecregistrodetallenegativo
        from ods_v.md_motivodetalleclinegativo
        group by codclavecic
  ) c on a.codclavecic = c.codclavecic and a.fecregistrodetallenegativo = c.maxfecregistrodetallenegativo
  where a.flghistorico = 'N' and a.tipmotivonegativo='013' and a.tipdetallemotivonegativo='001'
  group by a.codclavecic
) select a.*,
  case when b.codclavecic is not null then 1 else 0 end as flgarchivonegativo,
  b.destipmotivonegativo as destipmotivonegativo
  from tmp_ingrestrc_lsb a
  left join tmp_ingrestrc_archivonegativo_aux b on a.codclavecic = b.codclavecic;

drop table tmp_ingrestrc_ctd_nplsb;
create table tmp_ingrestrc_ctd_nplsb tablespace d_aml_99 as
select a.*,ctdnp+ctdlsb as ctd_np_lsb
from tmp_ingrestrc_archnegativo a;

--ctd evaluaciones
drop table tmp_ingrestrc_sapyc;
create table tmp_ingrestrc_sapyc tablespace d_aml_99 as
select a.*
from (
   select a.idcaso, case when instr(a.codunicocli,'GR') > 0 then c.codclavecic else d.codclavecic end as codclavecic, a.idresultado as idresultadoeval, a.fecfineval as fecfineval, b."IDRESULTADOSUPERVISOR"
     from s61751.sapy_dmevaluacion a
     left join s61751.sapy_dminvestigacion b on a.idcaso = b.idcaso
     left join ods_v.md_empleadog94 c on trim(substr(a.codunicocli,instr(a.codunicocli,'GR')+2,6)) = trim(c.codmatricula)
     left join ods_v.md_clienteg94 d on trim(a.codunicocli) = trim(d.codunicocli)
) a;

drop table tmp_ingrestrc_evals;
create table tmp_ingrestrc_evals tablespace d_aml_99 as
with tmp_ingrestrc_evals_aux as
(select a.periodo,a.codclavecic, sum(case when b.fecfineval < to_date(to_char(a.periodo||'01'),'yyyymmdd') then 1 else 0 end) as ctdeval
  from tmp_ingrestrc_ctd_nplsb a
  left join tmp_ingrestrc_sapyc b on a.codclavecic = b.codclavecic
  group by a.periodo,a.codclavecic
)select a.*,
  case when b.ctdeval is not null then b.ctdeval else 0 end as ctdeval
  from tmp_ingrestrc_ctd_nplsb a
  left join tmp_ingrestrc_evals_aux b on a.periodo = b.periodo and a.codclavecic = b.codclavecic;

--var segmento del cliente
drop table tmp_ingrestrc_segmento;
create table tmp_ingrestrc_segmento tablespace d_aml_99 as
with tmp_ingrestrc_segmento_aux as (
  select distinct trim(subseg.codsubsegmento) as codsubsegmento, subseg.dessubsegmento, trim(seg.codsegmento) as codsegmento, seg.dessegmento
  from ods_v.mm_descodigosubsegmento subseg
  left join ods_v.mm_descodsubseggen subseggen on trim(subseg.codsubseggeneral)=trim(subseggen.codsubseggeneral)
  left join ods_v.mm_descodigosegmento seg on trim(subseggen.codsegmento)=trim(seg.codsegmento)
) select a.*, c.codsubsegmento, c.dessubsegmento, c.codsegmento, c.dessegmento
  from tmp_ingrestrc_evals a
  left join ods_v.md_cliente b on a.codclavecic = b.codclavecic
  left join tmp_ingrestrc_segmento_aux c on trim(b.codsubsegmento) = trim(c.codsubsegmento);

-- var lugar de residencia mas actual
drop table tmp_ingrestrc_lugarresidencia_aux2;
create table tmp_ingrestrc_lugarresidencia_aux2 tablespace d_aml_99 as
with tmp_ingrestrc_lugarresidencia_aux as (
  select codclavecic,max(numdir) as maxnumdir
  from ods_v.mm_direccioncliente
  where
  tipdir in ('D')
  group by codclavecic
) select  distinct b.codclavecic, b.tipdir, c.codubigeo, b.coddistrito, c.descoddistrito, c.codprovincia, d.descodprovincia, d.coddepartamento, e.descoddepartamento
  from tmp_ingrestrc_segmento a
  left join ods_v.mm_direccioncliente b on a.codclavecic = b.codclavecic
  inner join tmp_ingrestrc_lugarresidencia_aux x on b.codclavecic = x.codclavecic and b.numdir = x.maxnumdir
  left join ods_v.mm_distrito c on b.coddistrito = c.coddistrito
  left join ods_v.mm_provincia d on c.codprovincia = d.codprovincia
  left join ods_v.mm_departamento e on d.coddepartamento = e.coddepartamento;

drop table tmp_ingrestrc_lugarresidencia;
create table tmp_ingrestrc_lugarresidencia tablespace d_aml_99 as
select a.*, b.tipdir, b.codubigeo, b.coddistrito, b.descoddistrito, b.codprovincia, b.descodprovincia, b.coddepartamento, b.descoddepartamento
from tmp_ingrestrc_segmento a
left join tmp_ingrestrc_lugarresidencia_aux2 b on a.codclavecic = b.codclavecic;

--var nacionalidad
drop table tmp_ingrestrc_nacionalidad;
create table tmp_ingrestrc_nacionalidad tablespace d_aml_99 as
with tmp_ingrestrc_nacionalidad_pn as (
select distinct a.codclavecic, a.tipper, trim(c.codpaisnacionalidad) as codpaisnacionalidad, trim(d.descodpaisnacionalidad) as descodpaisnacionalidad,
case when trim(c.codpaisnacionalidad) = 'PER' then 0
when c.codpaisnacionalidad is not null and trim(c.codpaisnacionalidad) <> 'PER' then 1
else null end as flgnacionalidad
from tmp_ingrestrc_lugarresidencia a
inner join ods_v.md_cliente b on a.codclavecic = b.codclavecic
left join ods_v.md_personanatural c on b.codclavecic = c.codclavecic
left join ods_v.mm_descodigopaisnacionalidad d on c.codpaisnacionalidad = d.codpaisnacionalidad
where a.tipper = 'P'
),tmp_ingrestrc_nacionalidad_pj as (
  select distinct a.codclavecic, a.tipper, 'PER' as codpaisnacionalidad, 'PERU' as descodpaisnacionalidad, 0 as flgnacionalidad
  from tmp_ingrestrc_lugarresidencia a
  inner join ods_v.mm_direccioncliente c on a.codclavecic = c.codclavecic
  where a.tipper = 'E'
)select a.*,
  case when a.tipper = 'P' then b.codpaisnacionalidad else c.codpaisnacionalidad end as codpaisnacionalidad,
  case when a.tipper = 'P' then b.descodpaisnacionalidad else c.descodpaisnacionalidad end as descodpaisnacionalidad,
  case when a.tipper = 'P' then b.flgnacionalidad else c.flgnacionalidad end as flgnacionalidad
  from tmp_ingrestrc_lugarresidencia a
  left join tmp_ingrestrc_nacionalidad_pn b on a.codclavecic = b.codclavecic
  left join tmp_ingrestrc_nacionalidad_pj c on a.codclavecic = c.codclavecic;

--variables de comportamiento: mto_ingresos_mes, ctd_ingresos_mes
drop table tmp_ingrestrc_varcomportamiento;
create table tmp_ingrestrc_varcomportamiento tablespace d_aml_99 as
with tmp_ingrestrc_varcomp as (
  select periodo, codclavecicbeneficiario as codclavecic,
  sum(mtodolarizado) as mto_ingresos_mes,
  count(periodo) as ctd_ingresos_mes
  from tmp_ingrestrc_trxs_total_vf_m
  group by periodo, codclavecicbeneficiario
)select a.*,b.mto_ingresos_mes,b.ctd_ingresos_mes
from tmp_ingrestrc_nacionalidad a
left join tmp_ingrestrc_varcomp b on a.periodo = b.periodo and a.codclavecic = b.codclavecic;

--perfil total
drop table tmp_ingrestrc_perfi1
create table tmp_ingrestrc_perfi1 tablespace d_aml_99 as
with tmp_ingrestrc_perfi1_aux as (
     select periodo, codclavecicbeneficiario as codclavecic, sum(mtodolarizado) as mto_ingresos
     from tmp_ingrestrc_trxs_total_vf_m
     group by periodo, codclavecicbeneficiario
) select  a.codclavecic,a.periodo as numperiodo,b.periodo,
  months_between(to_date(a.periodo,'yyyymm'),to_date(b.periodo,'yyyymm')) meses,
  case when b.mto_ingresos is null then 0 else b.mto_ingresos end mto_ingresos
  from tmp_ingrestrc_perfi1_aux a
  inner join tmp_ingrestrc_perfi1_aux b on a.codclavecic=b.codclavecic;

drop table tmp_ingrestrc_perfi2;
create table tmp_ingrestrc_perfi2 tablespace d_aml_99 as
select numperiodo,codclavecic,mto_ingresos
from tmp_ingrestrc_perfi1 a
where numperiodo=periodo;

drop table tmp_ingrestrc_perfi3;
create table tmp_ingrestrc_perfi3 tablespace d_aml_99 as
with temp_tab as(
  select numperiodo,codclavecic,
  avg(nullif(mto_ingresos,0)) as media_depo,stddev(nullif(mto_ingresos,0)) as desv_depo
  from tmp_ingrestrc_perfi1
  where meses<=6 and meses>=1
  group by numperiodo,codclavecic
) select a.*,
  round(nvl(b.media_depo,0),2) media_ingresos,
  round(nvl(b.desv_depo,0),2) desv_ingresos
  from tmp_ingrestrc_perfi2 a
  left join temp_tab b on (a.numperiodo=b.numperiodo and a.codclavecic=b.codclavecic);

-- creación el flg perfil total en tabla cliente mes: flg_perfil_ingresos_3ds
drop table tmp_ingrestrc_perfilingresos;
create table tmp_ingrestrc_perfilingresos tablespace d_aml_99 as
select  a.*, b.media_ingresos, b.desv_ingresos,
case when b.media_ingresos <> 0 and b.desv_ingresos <> 0 and b.media_ingresos+3*b.desv_ingresos<b.mto_ingresos then 1 else 0 end flg_perfil_ingresos_3ds
from   tmp_ingrestrc_varcomportamiento a
left join tmp_ingrestrc_perfi3 b on (a.periodo=b.numperiodo and a.codclavecic=b.codclavecic)
where periodo = to_number(to_char(add_months(sysdate, -2),'yyyymm'));

--mtos redondos :  max_ctdmtosredondos,sum_mtosredondos
drop table tmp_ingrestrc_mtosredondos;
create table tmp_ingrestrc_mtosredondos tablespace d_aml_99 as
with tmp_ingrestrc_mtosredondos_1 as (
  select a.*,
  floor(mtotransaccion) as mtotransaccion_sindecimal, case when mtotransaccion=floor(a.mtotransaccion) then 1 else 0 end flgredondo
  from tmp_ingrestrc_trxs_total_vf_m a
),tmp_ingrestrc_mtosredondos_2 as (
  select periodo,codclavecicbeneficiario as codclavecic,mtotransaccion,
  sum(flgredondo) as ctdredondo,
  sum(case when flgredondo = 1 then mtodolarizado else 0 end) as summtoredondo
  from tmp_ingrestrc_mtosredondos_1
  group by periodo, codclavecicbeneficiario, mtotransaccion
),tmp_ingrestrc_mtosredondos_3 as (
  select periodo,codclavecic,max(ctdredondo) as max_ctdmtosredondos
  from tmp_ingrestrc_mtosredondos_2
  group by periodo, codclavecic
),tmp_ingrestrc_mtosredondos_4 as (
  select periodo,codclavecic,sum(summtoredondo) as sum_mtosredondos
  from tmp_ingrestrc_mtosredondos_2
  group by periodo, codclavecic
)select a.*,
case when b.max_ctdmtosredondos is not null then b.max_ctdmtosredondos else 0 end max_ctdmtosredondos,
case when c.sum_mtosredondos is not null then c.sum_mtosredondos else 0 end sum_mtosredondos
from tmp_ingrestrc_perfilingresos a
left join tmp_ingrestrc_mtosredondos_3 b on a.periodo = b.periodo and a.codclavecic = b.codclavecic
left join tmp_ingrestrc_mtosredondos_4 c on a.periodo = c.periodo and a.codclavecic = c.codclavecic;

--mtos repetidos max
drop table tmpctds;
create table tmpctds tablespace d_aml_99 as
select periodo,codclavecicbeneficiario as codclavecic,mtotransaccion,count(*) as ctd
from tmp_ingrestrc_trxs_total_vf_m
group by periodo,codclavecicbeneficiario,mtotransaccion;

drop table tmpctdsmax;
create table tmpctdsmax tablespace d_aml_99 as
select periodo,codclavecic,max(ctd) as max_ctd
from tmpctds
group by periodo,codclavecic;

--sumamtos ctdmax
drop table tmpctdsycdtsmax;
create table tmpctdsycdtsmax tablespace d_aml_99 as
select a.*, b.max_ctd
from tmpctds a
inner join tmpctdsmax b on a.periodo = b.periodo and a.codclavecic = b.codclavecic and a.ctd = b.max_ctd
order by b.max_ctd desc;

drop table tmpmaxsnorepetidos;
create table tmpmaxsnorepetidos tablespace d_aml_99 as
with tmpx as (
  select periodo, codclavecic, ctd as ctdmaxima, count(*) as ctdmaximos
  from (
  tmpctdsycdtsmax
  )
  group by periodo, codclavecic, ctd
  having count(*) <= 1
)select b.*, a.mtotransaccion
from tmpctdsycdtsmax a
inner join tmpx b on a.periodo = b.periodo and a.codclavecic = b.codclavecic and a.max_ctd = b.ctdmaxima;

drop table tmpmaxsrepetidos;
create table tmpmaxsrepetidos tablespace d_aml_99 as
select periodo, codclavecic, ctd as ctdmaxima, count(*) as ctdmaximos
from (
tmpctdsycdtsmax
)
group by periodo, codclavecic, ctd
having count(*) > 1;

drop table tmpmaxsrepetidosunicos;
create table tmpmaxsrepetidosunicos tablespace d_aml_99 as
with tmpy as (
  select a.*, b.ctdmaximos
  from tmpctdsycdtsmax a
  inner join tmpmaxsrepetidos b on a.periodo = b.periodo and a.codclavecic = b.codclavecic and a.max_ctd = b.ctdmaxima
  order by a.periodo, a.codclavecic, a.max_ctd
)select periodo, codclavecic, max_ctd as ctdmaxima, ctdmaximos, max(mtotransaccion) as mtomaxdemaxrepetidos
from tmpy
group by periodo, codclavecic, max_ctd, ctdmaximos;

drop table tmpclientesmtosmaximosunicos;
create table tmpclientesmtosmaximosunicos tablespace d_aml_99 as
select periodo, codclavecic, ctdmaxima, ctdmaximos, mtomaxdemaxrepetidos from tmpmaxsrepetidosunicos union all
select periodo, codclavecic, ctdmaxima, ctdmaximos, mtotransaccion  from tmpmaxsnorepetidos;

drop table tmp_ingrestrc_mtosmaximosrepetidos_aux;
create table tmp_ingrestrc_mtosmaximosrepetidos_aux tablespace d_aml_99 as
select a.periodo, a.codclavecic, a.ctdmaxima,sum(b.mtodolarizado) as mto_maximosrepetidos
from tmpclientesmtosmaximosunicos a
left join tmp_ingrestrc_trxs_total_vf_m b on a.periodo = b.periodo and a.codclavecic = b.codclavecicbeneficiario and a.mtomaxdemaxrepetidos = b.mtotransaccion
group by a.periodo, a.codclavecic, a.ctdmaxima;

--mtomaxdemaxrepetidos ,ctmaxima, mto_maximosrepetidos,
drop table tmp_ingrestrc_mtosmaximosrepetidos;
create table tmp_ingrestrc_mtosmaximosrepetidos tablespace d_aml_99 as
select a.*,
case when b.ctdmaxima is null then 0 else b.ctdmaxima  end ctdmaxima,
case when b.mto_maximosrepetidos is null then 0 else b.mto_maximosrepetidos  end mto_maximosrepetidos
from tmp_ingrestrc_mtosredondos a
left join tmp_ingrestrc_mtosmaximosrepetidos_aux b on a.periodo = b.periodo and a.codclavecic = b.codclavecic ;

--mtos proximos
drop table tmp_ingrestrc_mtosyctdsproximos_aux;
create table tmp_ingrestrc_mtosyctdsproximos_aux tablespace d_aml_99 as
select a.periodo, a.codclavecic, a.mtomaxdemaxrepetidos,
sum(case when a.mtomaxdemaxrepetidos*0.9 < b.mtotransaccion and b.mtotransaccion < a.mtomaxdemaxrepetidos*1.1 then b.mtodolarizado else 0 end) as mto_conotrosproximos,
sum(case when a.mtomaxdemaxrepetidos*0.9 < b.mtotransaccion and b.mtotransaccion < a.mtomaxdemaxrepetidos*1.1 then 1 else 0 end) as ctd_conotrosproximos
from tmpclientesmtosmaximosunicos a
left join tmp_ingrestrc_trxs_total_vf_m b on a.periodo = b.periodo and a.codclavecic = b.codclavecicbeneficiario
group by a.periodo, a.codclavecic, a.mtomaxdemaxrepetidos;

drop table tmp_ingrestrc_mtosyctdsproximos;
create table tmp_ingrestrc_mtosyctdsproximos tablespace d_aml_99 as
select a.*,
case when b.mtomaxdemaxrepetidos is null then 0 else b.mtomaxdemaxrepetidos  end mtomaxdemaxrepetidos,
case when b.mto_conotrosproximos is null then 0 else b.mto_conotrosproximos  end mto_conotrosproximos,
case when b.ctd_conotrosproximos is null then 0 else b.ctd_conotrosproximos  end ctd_conotrosproximos
from tmp_ingrestrc_mtosmaximosrepetidos a
left join tmp_ingrestrc_mtosyctdsproximos_aux b on a.periodo = b.periodo and a.codclavecic = b.codclavecic ;

--tablon final mes 2
drop table tmp_ingrestrc_mtosyctdsproximos_tablon_m2;
create table tmp_ingrestrc_mtosyctdsproximos_tablon_m2 tablespace d_aml_99 as
select * from tmp_ingrestrc_mtosyctdsproximos;

---- ** MES 03 - Agost23 **-----

--Extraer las trx historica de los 7 ultimos meses del mes analisis
drop table tmp_ingrestrc_trxs_total_vf_m;
create table tmp_ingrestrc_trxs_total_vf_m tablespace d_aml_99 as
select  *
from  tmp_ingrestrc_trxs_total_vf
where periodo between  to_number(to_char(add_months(sysdate, -9),'yyyymm')) and  to_number(to_char(add_months(sysdate, -3),'yyyymm'));

--Extraer el mes de analisis
drop table tmp_ingrestrc_universo_cli_m;
create table tmp_ingrestrc_universo_cli_m tablespace d_aml_99 as
select  *
from  tmp_ingrestrc_universo_cli
where periodo = to_number(to_char(add_months(sysdate, -3),'yyyymm'));

--edad
drop table tmp_ingrestrc_edad;
create table tmp_ingrestrc_edad tablespace d_aml_99 as
with tmp_proc_edad_ppnn_aux as
(
  select a.codclavecic,a.periodo,c.fecnacimiento, floor(months_between(to_date(to_char(periodo||'01'),'yyyymmdd'), c.fecnacimiento) /12) as edad
  from tmp_ingrestrc_universo_cli_m a
  inner join ods_v.md_cliente b on a.codclavecic = b.codclavecic
  left join ods_v.md_personanatural c on a.codclavecic = c.codclavecic
  where trim(b.tipper) = 'P'
),
tmp_proc_edad_ppjj_aux as
(
  select a.codclavecic,a.periodo,c.fecconstitucion, floor(months_between(to_date(to_char(periodo||'01'),'yyyymmdd'), c.fecconstitucion) /12) as edad
  from tmp_ingrestrc_universo_cli_m a
  inner join ods_v.md_cliente b on a.codclavecic = b.codclavecic
  left join ods_v.mm_empresa c on a.codclavecic = c.codclavecic
  where trim(b.tipper) = 'E'
)
select a.periodo, a.codclavecic, case when trim(x.tipper) = 'P' then b.edad else case when trim(x.tipper) = 'E' then c.edad else null end end as edad
  from tmp_ingrestrc_universo_cli_m a
  left join ods_v.md_cliente x on a.codclavecic = x.codclavecic
  left join tmp_proc_edad_ppnn_aux b on a.periodo = b.periodo and a.codclavecic = b.codclavecic
  left join tmp_proc_edad_ppjj_aux c on a.periodo = c.periodo and a.codclavecic = c.codclavecic;

--tipper
drop table tmp_ingrestrc_tipper;
create table tmp_ingrestrc_tipper tablespace d_aml_99 as
select a.*, b.tipper
from tmp_ingrestrc_edad a
inner join ods_v.md_cliente b on a.codclavecic = b.codclavecic;

--antiguedad cliente
drop table tmp_ingrestrc_antiguedad;
create table tmp_ingrestrc_antiguedad tablespace d_aml_99 as
with tmp_proc_antg_fecapertura as
( select codclavecic,min(t.fecapertura) as fecapertura
  from ( select distinct codclavecic,fecapertura from ods_v.md_prestamo
         union all
         select distinct codclavecic,fecapertura from ods_v.md_impac
         union all
         select distinct codclavecic,fecapertura from ods_v.md_saving
         union all
         select distinct codclavecic,fecapertura from ods_v.md_cuentavp) t
  group by codclavecic
),tmp_proc_antig_aux as
(select a.periodo, a.codclavecic, b.fecapertura,
  floor(months_between(to_date(to_char(periodo||'01'),'yyyymmdd'), b.fecapertura) ) as antiguedad
  from tmp_ingrestrc_tipper a
  left join tmp_proc_antg_fecapertura b on a.codclavecic = b.codclavecic
)select a.*,b.antiguedad
  from tmp_ingrestrc_tipper a
  left join tmp_proc_antig_aux b on a.periodo = b.periodo and a.codclavecic = b.codclavecic;

--flg actividad economica no definida
drop table tmp_ingrestrc_acteconomica_nodef_aux;
create table tmp_ingrestrc_acteconomica_nodef_aux tablespace d_aml_99 as
  select codacteconomica,desacteconomica,'OTRSERV'as busq
  from ods_v.mm_descodactividadeconomica
  where upper(desacteconomica) like '%OTR%SERV%'
  union
  select codacteconomica,desacteconomica,'NO ESPECIF'
  from ods_v.mm_descodactividadeconomica
  where upper(desacteconomica) like '%NO ESPECIF%'
  union
  select codacteconomica,desacteconomica,'NO DISPO'
  from ods_v.mm_descodactividadeconomica
  where upper(desacteconomica) like '%NO DISPO%'
  union
  select codacteconomica,desacteconomica,'MAYOROTRPROD'
  from ods_v.mm_descodactividadeconomica
  where upper(desacteconomica) like '%MAYOR%OTR%PROD%'
  union
  select codacteconomica,desacteconomica,'MENOROTRPROD'
  from ods_v.mm_descodactividadeconomica
  where upper(desacteconomica) like '%MENOR%OTR%PROD%';

drop table tmp_ingrestrc_acteconomica_nodef;
create table tmp_ingrestrc_acteconomica_nodef tablespace d_aml_99 as
select a.*, b.codacteconomica, d.desacteconomica,
    case
    when b.codacteconomica is null then 1
    when c.codacteconomica is not null then 1
    else 0
    end flg_acteco_nodef
from tmp_ingrestrc_antiguedad a
left join ods_v.md_cliente b on a.codclavecic = b.codclavecic
left join tmp_ingrestrc_acteconomica_nodef_aux c on trim(b.codacteconomica) = trim(c.codacteconomica)
left join ods_v.mm_descodactividadeconomica d on trim(b.codacteconomica) = trim(d.codacteconomica);

--variables sapyc: np
drop table tmp_ingrestrc_np_aux2;
create table tmp_ingrestrc_np_aux2 tablespace d_aml_99 as
with tmp_ingrestrc_np_aux as
(select a.*, b.idorigen, b.nbrorigen as origen, b.codtransaccion as escenario, b.nbrtransaccion as desescenario
  from (
  select a.idcaso, case when instr(a.codunicocli,'GR') > 0 then c.codclavecic else d.codclavecic end as codclavecic, a.idresultado as idresultadoeval, a.fecfineval as fecfineval, b."IDRESULTADOSUPERVISOR"
  from s61751.sapy_dmevaluacion a
  left join s61751.sapy_dminvestigacion b on a.idcaso = b.idcaso
  left join ods_v.md_empleadog94 c on trim(substr(a.codunicocli,instr(a.codunicocli,'GR')+2,6)) = trim(c.codmatricula)
  left join ods_v.md_clienteg94 d on trim(a.codunicocli) = trim(d.codunicocli)
) a
  left join s61751.sapy_dmalerta b on a.idcaso = b.idcaso
  where idorigen in (2)
)select a.periodo,a.codclavecic, sum(case when b.fecfineval < to_date(to_char(a.periodo||'01'),'yyyymmdd') then 1 else 0 end) as ctdnp
from tmp_ingrestrc_acteconomica_nodef a
left join tmp_ingrestrc_np_aux b on a.codclavecic = b.codclavecic
group by a.periodo,a.codclavecic;

drop table tmp_ingrestrc_np;
create table tmp_ingrestrc_np tablespace d_aml_99 as
select a.*,
case when b.ctdnp > 0 then 1 else 0 end flgnp,
case when b.ctdnp is not null then b.ctdnp else 0 end ctdnp
from tmp_ingrestrc_acteconomica_nodef a
left join tmp_ingrestrc_np_aux2 b on a.periodo = b.periodo and a.codclavecic = b.codclavecic;

--variables sapyc: lsb
drop table tmp_ingrestrc_lsb_aux2;
create table tmp_ingrestrc_lsb_aux2 tablespace d_aml_99 as
with tmp_ingrestrc_lsb_aux as
( select a.*, b.idorigen, b.nbrorigen as origen, b.codtransaccion as escenario, b.nbrtransaccion as desescenario
  from (
    select a.idcaso, case when instr(a.codunicocli,'GR') > 0 then c.codclavecic else d.codclavecic end as codclavecic, a.idresultado as idresultadoeval, a.fecfineval as fecfineval, b."IDRESULTADOSUPERVISOR"
    from s61751.sapy_dmevaluacion a
    left join s61751.sapy_dminvestigacion b on a.idcaso = b.idcaso
    left join ods_v.md_empleadog94 c on trim(substr(a.codunicocli,instr(a.codunicocli,'GR')+2,6)) = trim(c.codmatricula)
    left join ods_v.md_clienteg94 d on trim(a.codunicocli) = trim(d.codunicocli)
  ) a
  left join s61751.sapy_dmalerta b on a.idcaso = b.idcaso
  where idorigen in (29)
)select a.periodo,a.codclavecic, sum(case when b.fecfineval < to_date(to_char(a.periodo||'01'),'yyyymmdd') then 1 else 0 end) as ctdlsb
from tmp_ingrestrc_np a
left join tmp_ingrestrc_lsb_aux b on a.codclavecic = b.codclavecic
group by a.periodo,a.codclavecic;

--var ctd_np_lsb
drop table tmp_ingrestrc_lsb;
create table tmp_ingrestrc_lsb tablespace d_aml_99 as
select a.*,
case when b.ctdlsb > 0 then 1 else 0 end flglsb,
case when b.ctdlsb is not null then b.ctdlsb else 0 end ctdlsb
from tmp_ingrestrc_np a
left join tmp_ingrestrc_lsb_aux2 b on a.periodo = b.periodo and a.codclavecic = b.codclavecic;

--var archivo negativo
drop table tmp_ingrestrc_archnegativo;
create table tmp_ingrestrc_archnegativo tablespace d_aml_99 as
with tmp_ingrestrc_archivonegativo_aux as (
  select distinct a.codclavecic, max(b.destipmotivonegativo) as destipmotivonegativo
  from ods_v.md_motivodetalleclinegativo a
  left join ods_v.md_destipomotivonegativo b on a.tipmotivonegativo = b.tipmotivonegativo
  inner join (
        select codclavecic, max(fecregistrodetallenegativo) as maxfecregistrodetallenegativo
        from ods_v.md_motivodetalleclinegativo
        group by codclavecic
  ) c on a.codclavecic = c.codclavecic and a.fecregistrodetallenegativo = c.maxfecregistrodetallenegativo
  where a.flghistorico = 'N' and a.tipmotivonegativo='013' and a.tipdetallemotivonegativo='001'
  group by a.codclavecic
) select a.*,
  case when b.codclavecic is not null then 1 else 0 end as flgarchivonegativo,
  b.destipmotivonegativo as destipmotivonegativo
  from tmp_ingrestrc_lsb a
  left join tmp_ingrestrc_archivonegativo_aux b on a.codclavecic = b.codclavecic;

drop table tmp_ingrestrc_ctd_nplsb;
create table tmp_ingrestrc_ctd_nplsb tablespace d_aml_99 as
select a.*, ctdnp+ctdlsb as ctd_np_lsb
from tmp_ingrestrc_archnegativo a;

--ctd evaluaciones
drop table tmp_ingrestrc_sapyc;
create table tmp_ingrestrc_sapyc tablespace d_aml_99 as
select a.*
from (
   select a.idcaso, case when instr(a.codunicocli,'GR') > 0 then c.codclavecic else d.codclavecic end as codclavecic, a.idresultado as idresultadoeval, a.fecfineval as fecfineval, b."IDRESULTADOSUPERVISOR"
     from s61751.sapy_dmevaluacion a
     left join s61751.sapy_dminvestigacion b on a.idcaso = b.idcaso
     left join ods_v.md_empleadog94 c on trim(substr(a.codunicocli,instr(a.codunicocli,'GR')+2,6)) = trim(c.codmatricula)
     left join ods_v.md_clienteg94 d on trim(a.codunicocli) = trim(d.codunicocli)
) a;

drop table tmp_ingrestrc_evals;
create table tmp_ingrestrc_evals tablespace d_aml_99 as
with tmp_ingrestrc_evals_aux as
(
  select a.periodo,a.codclavecic, sum(case when b.fecfineval < to_date(to_char(a.periodo||'01'),'yyyymmdd') then 1 else 0 end) as ctdeval
  from tmp_ingrestrc_ctd_nplsb a
  left join tmp_ingrestrc_sapyc b on a.codclavecic = b.codclavecic
  group by a.periodo,a.codclavecic
)
  select a.*,
  case when b.ctdeval is not null then b.ctdeval else 0 end as ctdeval
  from tmp_ingrestrc_ctd_nplsb a
  left join tmp_ingrestrc_evals_aux b on a.periodo = b.periodo and a.codclavecic = b.codclavecic;

--var segmento del cliente
drop table tmp_ingrestrc_segmento;
create table tmp_ingrestrc_segmento tablespace d_aml_99 as
with tmp_ingrestrc_segmento_aux as (
  select distinct trim(subseg.codsubsegmento) as codsubsegmento, subseg.dessubsegmento, trim(seg.codsegmento) as codsegmento, seg.dessegmento
  from ods_v.mm_descodigosubsegmento subseg
  left join ods_v.mm_descodsubseggen subseggen on trim(subseg.codsubseggeneral)=trim(subseggen.codsubseggeneral)
  left join ods_v.mm_descodigosegmento seg on trim(subseggen.codsegmento)=trim(seg.codsegmento)
) select a.*, c.codsubsegmento, c.dessubsegmento, c.codsegmento, c.dessegmento
  from tmp_ingrestrc_evals a
  left join ods_v.md_cliente b on a.codclavecic = b.codclavecic
  left join tmp_ingrestrc_segmento_aux c on trim(b.codsubsegmento) = trim(c.codsubsegmento);

-- var lugar de residencia mas actual
drop table tmp_ingrestrc_lugarresidencia_aux2;
create table tmp_ingrestrc_lugarresidencia_aux2 tablespace d_aml_99 as
with tmp_ingrestrc_lugarresidencia_aux as (
  select codclavecic,max(numdir) as maxnumdir
  from ods_v.mm_direccioncliente
  where
  tipdir in ('D')
  group by codclavecic
) select  distinct b.codclavecic, b.tipdir, c.codubigeo, b.coddistrito, c.descoddistrito, c.codprovincia, d.descodprovincia, d.coddepartamento, e.descoddepartamento
  from tmp_ingrestrc_segmento a
  left join ods_v.mm_direccioncliente b on a.codclavecic = b.codclavecic
  inner join tmp_ingrestrc_lugarresidencia_aux x on b.codclavecic = x.codclavecic and b.numdir = x.maxnumdir
  left join ods_v.mm_distrito c on b.coddistrito = c.coddistrito
  left join ods_v.mm_provincia d on c.codprovincia = d.codprovincia
  left join ods_v.mm_departamento e on d.coddepartamento = e.coddepartamento;

drop table tmp_ingrestrc_lugarresidencia;
create table tmp_ingrestrc_lugarresidencia tablespace d_aml_99 as
select a.*, b.tipdir, b.codubigeo, b.coddistrito, b.descoddistrito, b.codprovincia, b.descodprovincia, b.coddepartamento, b.descoddepartamento
from tmp_ingrestrc_segmento a
left join tmp_ingrestrc_lugarresidencia_aux2 b on a.codclavecic = b.codclavecic;

--var nacionalidad
drop table tmp_ingrestrc_nacionalidad;
create table tmp_ingrestrc_nacionalidad tablespace d_aml_99 a
with tmp_ingrestrc_nacionalidad_pn as (
  select distinct a.codclavecic, a.tipper, trim(c.codpaisnacionalidad) as codpaisnacionalidad, trim(d.descodpaisnacionalidad) as descodpaisnacionalidad,
  case when trim(c.codpaisnacionalidad) = 'PER' then 0
       when c.codpaisnacionalidad is not null and trim(c.codpaisnacionalidad) <> 'PER' then 1
       else null end as flgnacionalidad
  from tmp_ingrestrc_lugarresidencia a
    inner join ods_v.md_cliente b on a.codclavecic = b.codclavecic
    left join ods_v.md_personanatural c on b.codclavecic = c.codclavecic
    left join ods_v.mm_descodigopaisnacionalidad d on c.codpaisnacionalidad = d.codpaisnacionalidad
    where a.tipper = 'P'
),tmp_ingrestrc_nacionalidad_pj as (
  select distinct a.codclavecic, a.tipper, 'PER' as codpaisnacionalidad, 'PERU' as descodpaisnacionalidad, 0 as flgnacionalidad
  from tmp_ingrestrc_lugarresidencia a
  inner join ods_v.mm_direccioncliente c on a.codclavecic = c.codclavecic
    where a.tipper = 'E'
)select a.*,
  case when a.tipper = 'P' then b.codpaisnacionalidad else c.codpaisnacionalidad end as codpaisnacionalidad,
  case when a.tipper = 'P' then b.descodpaisnacionalidad else c.descodpaisnacionalidad end as descodpaisnacionalidad,
  case when a.tipper = 'P' then b.flgnacionalidad else c.flgnacionalidad end as flgnacionalidad
  from tmp_ingrestrc_lugarresidencia a
    left join tmp_ingrestrc_nacionalidad_pn b on a.codclavecic = b.codclavecic
    left join tmp_ingrestrc_nacionalidad_pj c on a.codclavecic = c.codclavecic;

--variables de comportamiento: mto_ingresos_mes, ctd_ingresos_mes
drop table tmp_ingrestrc_varcomportamiento;
create table tmp_ingrestrc_varcomportamiento tablespace d_aml_99 as
with tmp_ingrestrc_varcomp as (
  select periodo, codclavecicbeneficiario as codclavecic,
  sum(mtodolarizado) as mto_ingresos_mes,
  count(periodo) as ctd_ingresos_mes
  from tmp_ingrestrc_trxs_total_vf_m
  group by periodo, codclavecicbeneficiario
)select a.*,b.mto_ingresos_mes,b.ctd_ingresos_mes
from tmp_ingrestrc_nacionalidad a
left join tmp_ingrestrc_varcomp b on a.periodo = b.periodo and a.codclavecic = b.codclavecic;

--perfil total
drop table tmp_ingrestrc_perfi1;
create table tmp_ingrestrc_perfi1 tablespace d_aml_99 as
with tmp_ingrestrc_perfi1_aux as (
     select periodo, codclavecicbeneficiario as codclavecic, sum(mtodolarizado) as mto_ingresos
     from tmp_ingrestrc_trxs_total_vf_m
     group by periodo, codclavecicbeneficiario
) select  a.codclavecic,a.periodo as numperiodo,b.periodo,
  months_between(to_date(a.periodo,'yyyymm'),to_date(b.periodo,'yyyymm')) meses,
  case when b.mto_ingresos is null then 0 else b.mto_ingresos end mto_ingresos
  from tmp_ingrestrc_perfi1_aux a
  inner join tmp_ingrestrc_perfi1_aux b on a.codclavecic=b.codclavecic;

drop table tmp_ingrestrc_perfi2;
create table tmp_ingrestrc_perfi2 tablespace d_aml_99 as
select numperiodo,codclavecic,mto_ingresos
from tmp_ingrestrc_perfi1 a
where numperiodo=periodo;

drop table tmp_ingrestrc_perfi3;
create table tmp_ingrestrc_perfi3 tablespace d_aml_99 as
with temp_tab as(
  select numperiodo,codclavecic,
  avg(nullif(mto_ingresos,0)) as media_depo,stddev(nullif(mto_ingresos,0)) as desv_depo
  from tmp_ingrestrc_perfi1
  where meses<=6 and meses>=1
  group by numperiodo,codclavecic
) select a.*,
  round(nvl(b.media_depo,0),2) media_ingresos,
  round(nvl(b.desv_depo,0),2) desv_ingresos
  from tmp_ingrestrc_perfi2 a
  left join temp_tab b on (a.numperiodo=b.numperiodo and a.codclavecic=b.codclavecic);

-- creación el flg perfil total en tabla cliente mes: flg_perfil_ingresos_3ds
drop table tmp_ingrestrc_perfilingresos;
create table tmp_ingrestrc_perfilingresos tablespace d_aml_99 as
select  a.*, b.media_ingresos, b.desv_ingresos,
case when b.media_ingresos <> 0 and b.desv_ingresos <> 0 and b.media_ingresos+3*b.desv_ingresos<b.mto_ingresos then 1 else 0 end flg_perfil_ingresos_3ds
from   tmp_ingrestrc_varcomportamiento a
left join tmp_ingrestrc_perfi3 b on (a.periodo=b.numperiodo and a.codclavecic=b.codclavecic)
where periodo = to_number(to_char(add_months(sysdate, -3),'yyyymm'));

--mtos redondos :  max_ctdmtosredondos,sum_mtosredondos
drop table tmp_ingrestrc_mtosredondos;
create table tmp_ingrestrc_mtosredondos tablespace d_aml_99 as
with tmp_ingrestrc_mtosredondos_1 as (
  select a.*,
  floor(mtotransaccion) as mtotransaccion_sindecimal, case when mtotransaccion=floor(a.mtotransaccion) then 1 else 0 end flgredondo
  from tmp_ingrestrc_trxs_total_vf_m a
),tmp_ingrestrc_mtosredondos_2 as (
  select periodo,codclavecicbeneficiario as codclavecic,mtotransaccion,
  sum(flgredondo) as ctdredondo,
  sum(case when flgredondo = 1 then mtodolarizado else 0 end) as summtoredondo
  from tmp_ingrestrc_mtosredondos_1
  group by periodo, codclavecicbeneficiario, mtotransaccion
),tmp_ingrestrc_mtosredondos_3 as (
  select periodo,codclavecic,max(ctdredondo) as max_ctdmtosredondos
  from tmp_ingrestrc_mtosredondos_2
  group by periodo, codclavecic
),tmp_ingrestrc_mtosredondos_4 as (
  select periodo,codclavecic,sum(summtoredondo) as sum_mtosredondos
  from tmp_ingrestrc_mtosredondos_2
  group by periodo, codclavecic
)select a.*,
case when b.max_ctdmtosredondos is not null then b.max_ctdmtosredondos else 0 end max_ctdmtosredondos,
case when c.sum_mtosredondos is not null then c.sum_mtosredondos else 0 end sum_mtosredondos
from tmp_ingrestrc_perfilingresos a
left join tmp_ingrestrc_mtosredondos_3 b on a.periodo = b.periodo and a.codclavecic = b.codclavecic
left join tmp_ingrestrc_mtosredondos_4 c on a.periodo = c.periodo and a.codclavecic = c.codclavecic;

--mtos repetidos max
drop table tmpctds;
create table tmpctds tablespace d_aml_99 as

select periodo,codclavecicbeneficiario as codclavecic,mtotransaccion,count(*) as ctd
from tmp_ingrestrc_trxs_total_vf_m
group by periodo,codclavecicbeneficiario,mtotransaccion;

drop table tmpctdsmax;
create table tmpctdsmax tablespace d_aml_99 as
select periodo,codclavecic,max(ctd) as max_ctd
from tmpctds
group by periodo,codclavecic;

--sumamtos ctdmax
drop table tmpctdsycdtsmax;
create table tmpctdsycdtsmax tablespace d_aml_99 as
select a.*, b.max_ctd
from tmpctds a
inner join tmpctdsmax b on a.periodo = b.periodo and a.codclavecic = b.codclavecic and a.ctd = b.max_ctd
order by b.max_ctd desc;

drop table tmpmaxsnorepetidos;
create table tmpmaxsnorepetidos tablespace d_aml_99 as
with tmpx as (
  select periodo, codclavecic, ctd as ctdmaxima, count(*) as ctdmaximos
  from (
  tmpctdsycdtsmax
  )
  group by periodo, codclavecic, ctd
  having count(*) <= 1
)
select b.*, a.mtotransaccion
from tmpctdsycdtsmax a
inner join tmpx b on a.periodo = b.periodo and a.codclavecic = b.codclavecic and a.max_ctd = b.ctdmaxima;

drop table tmpmaxsrepetidos;
create table tmpmaxsrepetidos tablespace d_aml_99 as
select periodo, codclavecic, ctd as ctdmaxima, count(*) as ctdmaximos
from (
tmpctdsycdtsmax
)
group by periodo, codclavecic, ctd
having count(*) > 1;

drop table tmpmaxsrepetidosunicos;
create table tmpmaxsrepetidosunicos tablespace d_aml_99 as
with tmpy as (
  select a.*, b.ctdmaximos
  from tmpctdsycdtsmax a
  inner join tmpmaxsrepetidos b on a.periodo = b.periodo and a.codclavecic = b.codclavecic and a.max_ctd = b.ctdmaxima
  order by a.periodo, a.codclavecic, a.max_ctd
)
select periodo, codclavecic, max_ctd as ctdmaxima, ctdmaximos, max(mtotransaccion) as mtomaxdemaxrepetidos
from tmpy
group by periodo, codclavecic, max_ctd, ctdmaximos;

drop table tmpclientesmtosmaximosunicos;
create table tmpclientesmtosmaximosunicos tablespace d_aml_99 as
select periodo, codclavecic, ctdmaxima, ctdmaximos, mtomaxdemaxrepetidos from tmpmaxsrepetidosunicos union all
select periodo, codclavecic, ctdmaxima, ctdmaximos, mtotransaccion  from tmpmaxsnorepetidos;

drop table tmp_ingrestrc_mtosmaximosrepetidos_aux;
create table tmp_ingrestrc_mtosmaximosrepetidos_aux tablespace d_aml_99 as
select a.periodo, a.codclavecic, a.ctdmaxima,sum(b.mtodolarizado) as mto_maximosrepetidos
from tmpclientesmtosmaximosunicos a
left join tmp_ingrestrc_trxs_total_vf_m b on a.periodo = b.periodo and a.codclavecic = b.codclavecicbeneficiario and a.mtomaxdemaxrepetidos = b.mtotransaccion
group by a.periodo, a.codclavecic, a.ctdmaxima;

--mtomaxdemaxrepetidos ,ctmaxima, mto_maximosrepetidos,
drop table tmp_ingrestrc_mtosmaximosrepetidos;
create table tmp_ingrestrc_mtosmaximosrepetidos tablespace d_aml_99 as
select a.*,
case when b.ctdmaxima is null then 0 else b.ctdmaxima  end ctdmaxima,
case when b.mto_maximosrepetidos is null then 0 else b.mto_maximosrepetidos  end mto_maximosrepetidos
from tmp_ingrestrc_mtosredondos a
left join tmp_ingrestrc_mtosmaximosrepetidos_aux b on a.periodo = b.periodo and a.codclavecic = b.codclavecic ;

--mtos proximos
drop table tmp_ingrestrc_mtosyctdsproximos_aux;
create table tmp_ingrestrc_mtosyctdsproximos_aux tablespace d_aml_99 as
  select a.periodo, a.codclavecic, a.mtomaxdemaxrepetidos,
  sum(case when a.mtomaxdemaxrepetidos*0.9 < b.mtotransaccion and b.mtotransaccion < a.mtomaxdemaxrepetidos*1.1 then b.mtodolarizado else 0 end) as mto_conotrosproximos,
  sum(case when a.mtomaxdemaxrepetidos*0.9 < b.mtotransaccion and b.mtotransaccion < a.mtomaxdemaxrepetidos*1.1 then 1 else 0 end) as ctd_conotrosproximos
  from tmpclientesmtosmaximosunicos a
  left join tmp_ingrestrc_trxs_total_vf_m b on a.periodo = b.periodo and a.codclavecic = b.codclavecicbeneficiario
  group by a.periodo, a.codclavecic, a.mtomaxdemaxrepetidos;

drop table tmp_ingrestrc_mtosyctdsproximos;
create table tmp_ingrestrc_mtosyctdsproximos tablespace d_aml_99 as
select a.*,
case when b.mtomaxdemaxrepetidos is null then 0 else b.mtomaxdemaxrepetidos  end mtomaxdemaxrepetidos,
case when b.mto_conotrosproximos is null then 0 else b.mto_conotrosproximos  end mto_conotrosproximos,
case when b.ctd_conotrosproximos is null then 0 else b.ctd_conotrosproximos  end ctd_conotrosproximos
from tmp_ingrestrc_mtosmaximosrepetidos a
left join tmp_ingrestrc_mtosyctdsproximos_aux b on a.periodo = b.periodo and a.codclavecic = b.codclavecic ;


--tablon final mes 3
drop table tmp_ingrestrc_mtosyctdsproximos_tablon_m3;
create table tmp_ingrestrc_mtosyctdsproximos_tablon_m3 tablespace d_aml_99 as
select * from tmp_ingrestrc_mtosyctdsproximos;

---- ** MES 04 - Julio23 **-----

--Extraer las trx historica de los 7 ultimos meses del mes analisis
drop table tmp_ingrestrc_trxs_total_vf_m;
create table tmp_ingrestrc_trxs_total_vf_m tablespace d_aml_99 as
select  *
from  tmp_ingrestrc_trxs_total_vf
where periodo between  to_number(to_char(add_months(sysdate, -10),'yyyymm')) and  to_number(to_char(add_months(sysdate, -4),'yyyymm'));

--Extraer el mes de analisis
drop table tmp_ingrestrc_universo_cli_m;
create table tmp_ingrestrc_universo_cli_m tablespace d_aml_99 as
select  *
from  tmp_ingrestrc_universo_cli
where periodo = to_number(to_char(add_months(sysdate, -4),'yyyymm'));

--edad
drop table tmp_ingrestrc_edad;
create table tmp_ingrestrc_edad tablespace d_aml_99 as
with tmp_proc_edad_ppnn_aux as
(
  select a.codclavecic,a.periodo,c.fecnacimiento, floor(months_between(to_date(to_char(periodo||'01'),'yyyymmdd'), c.fecnacimiento) /12) as edad
  from tmp_ingrestrc_universo_cli_m a
  inner join ods_v.md_cliente b on a.codclavecic = b.codclavecic
  left join ods_v.md_personanatural c on a.codclavecic = c.codclavecic
  where trim(b.tipper) = 'P'
),tmp_proc_edad_ppjj_aux as
(
  select a.codclavecic,a.periodo,c.fecconstitucion, floor(months_between(to_date(to_char(periodo||'01'),'yyyymmdd'), c.fecconstitucion) /12) as edad
  from tmp_ingrestrc_universo_cli_m a
  inner join ods_v.md_cliente b on a.codclavecic = b.codclavecic
  left join ods_v.mm_empresa c on a.codclavecic = c.codclavecic
  where trim(b.tipper) = 'E'
)select a.periodo, a.codclavecic, case when trim(x.tipper) = 'P' then b.edad else case when trim(x.tipper) = 'E' then c.edad else null end end as edad
  from tmp_ingrestrc_universo_cli_m a
  left join ods_v.md_cliente x on a.codclavecic = x.codclavecic
  left join tmp_proc_edad_ppnn_aux b on a.periodo = b.periodo and a.codclavecic = b.codclavecic
  left join tmp_proc_edad_ppjj_aux c on a.periodo = c.periodo and a.codclavecic = c.codclavecic;

--tipper
drop table tmp_ingrestrc_tipper;
create table tmp_ingrestrc_tipper tablespace d_aml_99 as
select a.*, b.tipper
from tmp_ingrestrc_edad a
inner join ods_v.md_cliente b on a.codclavecic = b.codclavecic;

--antiguedad cliente
drop table tmp_ingrestrc_antiguedad;
create table tmp_ingrestrc_antiguedad tablespace d_aml_99 as
with tmp_proc_antg_fecapertura as
( select codclavecic,min(t.fecapertura) as fecapertura
  from ( select distinct codclavecic,fecapertura from ods_v.md_prestamo
         union all
         select distinct codclavecic,fecapertura from ods_v.md_impac
         union all
         select distinct codclavecic,fecapertura from ods_v.md_saving
         union all
         select distinct codclavecic,fecapertura from ods_v.md_cuentavp) t
  group by codclavecic
),tmp_proc_antig_aux as
(select a.periodo, a.codclavecic, b.fecapertura,
  floor(months_between(to_date(to_char(periodo||'01'),'yyyymmdd'), b.fecapertura) ) as antiguedad
  from tmp_ingrestrc_tipper a
  left join tmp_proc_antg_fecapertura b on a.codclavecic = b.codclavecic
)select a.*, b.antiguedad
  from tmp_ingrestrc_tipper a
  left join tmp_proc_antig_aux b on a.periodo = b.periodo and a.codclavecic = b.codclavecic;

--flg actividad economica no definida
drop table tmp_ingrestrc_acteconomica_nodef_aux;
create table tmp_ingrestrc_acteconomica_nodef_aux tablespace d_aml_99 as
  select codacteconomica,desacteconomica,'OTRSERV'as busq
  from ods_v.mm_descodactividadeconomica
  where upper(desacteconomica) like '%OTR%SERV%'
  union
  select codacteconomica,desacteconomica,'NO ESPECIF'
  from ods_v.mm_descodactividadeconomica
  where upper(desacteconomica) like '%NO ESPECIF%'
  union
  select codacteconomica,desacteconomica,'NO DISPO'
  from ods_v.mm_descodactividadeconomica
  where upper(desacteconomica) like '%NO DISPO%'
  union
  select codacteconomica,desacteconomica,'MAYOROTRPROD'
  from ods_v.mm_descodactividadeconomica
  where upper(desacteconomica) like '%MAYOR%OTR%PROD%'
  union
  select codacteconomica,desacteconomica,'MENOROTRPROD'
  from ods_v.mm_descodactividadeconomica
  where upper(desacteconomica) like '%MENOR%OTR%PROD%';

drop table tmp_ingrestrc_acteconomica_nodef;
create table tmp_ingrestrc_acteconomica_nodef tablespace d_aml_99 as
select a.*, b.codacteconomica, d.desacteconomica,
case
    when b.codacteconomica is null then 1
    when c.codacteconomica is not null then 1
else 0
end flg_acteco_nodef
from tmp_ingrestrc_antiguedad a
left join ods_v.md_cliente b on a.codclavecic = b.codclavecic
left join tmp_ingrestrc_acteconomica_nodef_aux c on trim(b.codacteconomica) = trim(c.codacteconomica)
left join ods_v.mm_descodactividadeconomica d on trim(b.codacteconomica) = trim(d.codacteconomica);

--variables sapyc: np
drop table tmp_ingrestrc_np_aux2;
create table tmp_ingrestrc_np_aux2 tablespace d_aml_99 as
with tmp_ingrestrc_np_aux as
( select a.*, b.idorigen, b.nbrorigen as origen, b.codtransaccion as escenario, b.nbrtransaccion as desescenario
  from (
     select a.idcaso, case when instr(a.codunicocli,'GR') > 0 then c.codclavecic else d.codclavecic end as codclavecic, a.idresultado as idresultadoeval, a.fecfineval as fecfineval, b."IDRESULTADOSUPERVISOR"
     from s61751.sapy_dmevaluacion a
     left join s61751.sapy_dminvestigacion b on a.idcaso = b.idcaso
     left join ods_v.md_empleadog94 c on trim(substr(a.codunicocli,instr(a.codunicocli,'GR')+2,6)) = trim(c.codmatricula)
     left join ods_v.md_clienteg94 d on trim(a.codunicocli) = trim(d.codunicocli)
  ) a
  left join s61751.sapy_dmalerta b on a.idcaso = b.idcaso
  where idorigen in (2)
)select a.periodo,a.codclavecic, sum(case when b.fecfineval < to_date(to_char(a.periodo||'01'),'yyyymmdd') then 1 else 0 end) as ctdnp
from tmp_ingrestrc_acteconomica_nodef a
left join tmp_ingrestrc_np_aux b on a.codclavecic = b.codclavecic
group by a.periodo,a.codclavecic;

drop table tmp_ingrestrc_np;
create table tmp_ingrestrc_np tablespace d_aml_99 as
select a.*,
case when b.ctdnp > 0 then 1 else 0 end flgnp,
case when b.ctdnp is not null then b.ctdnp else 0 end ctdnp
from tmp_ingrestrc_acteconomica_nodef a
left join tmp_ingrestrc_np_aux2 b on a.periodo = b.periodo and a.codclavecic = b.codclavecic;

--variables sapyc: lsb
drop table tmp_ingrestrc_lsb_aux2;
create table tmp_ingrestrc_lsb_aux2 tablespace d_aml_99 as
with tmp_ingrestrc_lsb_aux as
( select a.*, b.idorigen, b.nbrorigen as origen, b.codtransaccion as escenario, b.nbrtransaccion as desescenario
  from (
     select a.idcaso, case when instr(a.codunicocli,'GR') > 0 then c.codclavecic else d.codclavecic end as codclavecic, a.idresultado as idresultadoeval, a.fecfineval as fecfineval, b."IDRESULTADOSUPERVISOR"
     from s61751.sapy_dmevaluacion a
     left join s61751.sapy_dminvestigacion b on a.idcaso = b.idcaso
     left join ods_v.md_empleadog94 c on trim(substr(a.codunicocli,instr(a.codunicocli,'GR')+2,6)) = trim(c.codmatricula)
     left join ods_v.md_clienteg94 d on trim(a.codunicocli) = trim(d.codunicocli)
  ) a
  left join s61751.sapy_dmalerta b on a.idcaso = b.idcaso
  where idorigen in (29)
)select a.periodo,a.codclavecic, sum(case when b.fecfineval < to_date(to_char(a.periodo||'01'),'yyyymmdd') then 1 else 0 end) as ctdlsb
from tmp_ingrestrc_np a
left join tmp_ingrestrc_lsb_aux b on a.codclavecic = b.codclavecic
group by a.periodo,a.codclavecic;

--var ctd_np_lsb
drop table tmp_ingrestrc_lsb;
create table tmp_ingrestrc_lsb tablespace d_aml_99 as
select a.*,
case when b.ctdlsb > 0 then 1 else 0 end flglsb,
case when b.ctdlsb is not null then b.ctdlsb else 0 end ctdlsb
from tmp_ingrestrc_np a
left join tmp_ingrestrc_lsb_aux2 b on a.periodo = b.periodo and a.codclavecic = b.codclavecic;

--var archivo negativo
drop table tmp_ingrestrc_archnegativo;
create table tmp_ingrestrc_archnegativo tablespace d_aml_99 as
with tmp_ingrestrc_archivonegativo_aux as (
  select distinct a.codclavecic, max(b.destipmotivonegativo) as destipmotivonegativo
  from ods_v.md_motivodetalleclinegativo a
  left join ods_v.md_destipomotivonegativo b on a.tipmotivonegativo = b.tipmotivonegativo
  inner join (
        select codclavecic, max(fecregistrodetallenegativo) as maxfecregistrodetallenegativo
        from ods_v.md_motivodetalleclinegativo
        group by codclavecic
  ) c on a.codclavecic = c.codclavecic and a.fecregistrodetallenegativo = c.maxfecregistrodetallenegativo
  where a.flghistorico = 'N' and a.tipmotivonegativo='013' and a.tipdetallemotivonegativo='001'
  group by a.codclavecic
) select a.*,
  case when b.codclavecic is not null then 1 else 0 end as flgarchivonegativo,
  b.destipmotivonegativo as destipmotivonegativo
  from tmp_ingrestrc_lsb a
  left join tmp_ingrestrc_archivonegativo_aux b on a.codclavecic = b.codclavecic;

drop table tmp_ingrestrc_ctd_nplsb;
create table tmp_ingrestrc_ctd_nplsb tablespace d_aml_99 as
select a.*,
ctdnp+ctdlsb as ctd_np_lsb
from tmp_ingrestrc_archnegativo a;

--ctd evaluaciones
drop table tmp_ingrestrc_sapyc;
create table tmp_ingrestrc_sapyc tablespace d_aml_99 as
select a.*
from (
   select a.idcaso, case when instr(a.codunicocli,'GR') > 0 then c.codclavecic else d.codclavecic end as codclavecic, a.idresultado as idresultadoeval, a.fecfineval as fecfineval, b."IDRESULTADOSUPERVISOR"
     from s61751.sapy_dmevaluacion a
     left join s61751.sapy_dminvestigacion b on a.idcaso = b.idcaso
     left join ods_v.md_empleadog94 c on trim(substr(a.codunicocli,instr(a.codunicocli,'GR')+2,6)) = trim(c.codmatricula)
     left join ods_v.md_clienteg94 d on trim(a.codunicocli) = trim(d.codunicocli)
) a;

drop table tmp_ingrestrc_evals;
create table tmp_ingrestrc_evals tablespace d_aml_99 as
with tmp_ingrestrc_evals_aux as
( select a.periodo,a.codclavecic, sum(case when b.fecfineval < to_date(to_char(a.periodo||'01'),'yyyymmdd') then 1 else 0 end) as ctdeval
  from tmp_ingrestrc_ctd_nplsb a
  left join tmp_ingrestrc_sapyc b on a.codclavecic = b.codclavecic
  group by a.periodo,a.codclavecic
) select a.*,
  case when b.ctdeval is not null then b.ctdeval else 0 end as ctdeval
  from tmp_ingrestrc_ctd_nplsb a
  left join tmp_ingrestrc_evals_aux b on a.periodo = b.periodo and a.codclavecic = b.codclavecic;

--var segmento del cliente
drop table tmp_ingrestrc_segmento;
create table tmp_ingrestrc_segmento tablespace d_aml_99 as
with tmp_ingrestrc_segmento_aux as (
  select distinct trim(subseg.codsubsegmento) as codsubsegmento, subseg.dessubsegmento, trim(seg.codsegmento) as codsegmento, seg.dessegmento
  from ods_v.mm_descodigosubsegmento subseg
  left join ods_v.mm_descodsubseggen subseggen on trim(subseg.codsubseggeneral)=trim(subseggen.codsubseggeneral)
  left join ods_v.mm_descodigosegmento seg on trim(subseggen.codsegmento)=trim(seg.codsegmento)
) select a.*, c.codsubsegmento, c.dessubsegmento, c.codsegmento, c.dessegmento
  from tmp_ingrestrc_evals a
  left join ods_v.md_cliente b on a.codclavecic = b.codclavecic
  left join tmp_ingrestrc_segmento_aux c on trim(b.codsubsegmento) = trim(c.codsubsegmento);

-- var lugar de residencia mas actual
drop table tmp_ingrestrc_lugarresidencia_aux2;
create table tmp_ingrestrc_lugarresidencia_aux2 tablespace d_aml_99 as
with tmp_ingrestrc_lugarresidencia_aux as (
  select codclavecic,max(numdir) as maxnumdir
  from ods_v.mm_direccioncliente
  where
  tipdir in ('D')
  group by codclavecic
) select  distinct b.codclavecic, b.tipdir, c.codubigeo, b.coddistrito, c.descoddistrito, c.codprovincia, d.descodprovincia, d.coddepartamento, e.descoddepartamento
  from tmp_ingrestrc_segmento a
  left join ods_v.mm_direccioncliente b on a.codclavecic = b.codclavecic
  inner join tmp_ingrestrc_lugarresidencia_aux x on b.codclavecic = x.codclavecic and b.numdir = x.maxnumdir
  left join ods_v.mm_distrito c on b.coddistrito = c.coddistrito
  left join ods_v.mm_provincia d on c.codprovincia = d.codprovincia
  left join ods_v.mm_departamento e on d.coddepartamento = e.coddepartamento;

drop table tmp_ingrestrc_lugarresidencia;
create table tmp_ingrestrc_lugarresidencia tablespace d_aml_99 as
select a.*, b.tipdir, b.codubigeo, b.coddistrito, b.descoddistrito, b.codprovincia, b.descodprovincia, b.coddepartamento, b.descoddepartamento
from tmp_ingrestrc_segmento a
left join tmp_ingrestrc_lugarresidencia_aux2 b on a.codclavecic = b.codclavecic;

--var nacionalidad
drop table tmp_ingrestrc_nacionalidad;
create table tmp_ingrestrc_nacionalidad tablespace d_aml_99 as
with tmp_ingrestrc_nacionalidad_pn as (
  select distinct a.codclavecic, a.tipper, trim(c.codpaisnacionalidad) as codpaisnacionalidad, trim(d.descodpaisnacionalidad) as descodpaisnacionalidad,
  case when trim(c.codpaisnacionalidad) = 'PER' then 0
       when c.codpaisnacionalidad is not null and trim(c.codpaisnacionalidad) <> 'PER' then 1
       else null end as flgnacionalidad
  from tmp_ingrestrc_lugarresidencia a
    inner join ods_v.md_cliente b on a.codclavecic = b.codclavecic
    left join ods_v.md_personanatural c on b.codclavecic = c.codclavecic
    left join ods_v.mm_descodigopaisnacionalidad d on c.codpaisnacionalidad = d.codpaisnacionalidad
    where a.tipper = 'P'
),
tmp_ingrestrc_nacionalidad_pj as (
  select distinct a.codclavecic, a.tipper, 'PER' as codpaisnacionalidad, 'PERU' as descodpaisnacionalidad, 0 as flgnacionalidad
  from tmp_ingrestrc_lugarresidencia a
  inner join ods_v.mm_direccioncliente c on a.codclavecic = c.codclavecic
    where a.tipper = 'E'
)
  select a.*,
  case when a.tipper = 'P' then b.codpaisnacionalidad else c.codpaisnacionalidad end as codpaisnacionalidad,
  case when a.tipper = 'P' then b.descodpaisnacionalidad else c.descodpaisnacionalidad end as descodpaisnacionalidad,
  case when a.tipper = 'P' then b.flgnacionalidad else c.flgnacionalidad end as flgnacionalidad
  from tmp_ingrestrc_lugarresidencia a
    left join tmp_ingrestrc_nacionalidad_pn b on a.codclavecic = b.codclavecic
    left join tmp_ingrestrc_nacionalidad_pj c on a.codclavecic = c.codclavecic;

--variables de comportamiento: mto_ingresos_mes, ctd_ingresos_mes
drop table tmp_ingrestrc_varcomportamiento;
create table tmp_ingrestrc_varcomportamiento tablespace d_aml_99 as
with tmp_ingrestrc_varcomp as (
  select periodo, codclavecicbeneficiario as codclavecic,
  sum(mtodolarizado) as mto_ingresos_mes,
  count(periodo) as ctd_ingresos_mes
  from tmp_ingrestrc_trxs_total_vf_m
  group by periodo, codclavecicbeneficiario
)
select a.*,b.mto_ingresos_mes,b.ctd_ingresos_mes
from tmp_ingrestrc_nacionalidad a
left join tmp_ingrestrc_varcomp b on a.periodo = b.periodo and a.codclavecic = b.codclavecic;

--perfil total
drop table tmp_ingrestrc_perfi1;
create table tmp_ingrestrc_perfi1 tablespace d_aml_99 as
with tmp_ingrestrc_perfi1_aux as (
     select periodo, codclavecicbeneficiario as codclavecic, sum(mtodolarizado) as mto_ingresos
     from tmp_ingrestrc_trxs_total_vf_m
     group by periodo, codclavecicbeneficiario
) select  a.codclavecic,a.periodo as numperiodo,b.periodo,
  months_between(to_date(a.periodo,'yyyymm'),to_date(b.periodo,'yyyymm')) meses,
  case when b.mto_ingresos is null then 0 else b.mto_ingresos end mto_ingresos
  from tmp_ingrestrc_perfi1_aux a
  inner join tmp_ingrestrc_perfi1_aux b on a.codclavecic=b.codclavecic;

drop table tmp_ingrestrc_perfi2;
create table tmp_ingrestrc_perfi2 tablespace d_aml_99 as
select numperiodo,codclavecic,mto_ingresos
from tmp_ingrestrc_perfi1 a
where numperiodo=periodo;

drop table tmp_ingrestrc_perfi3;
create table tmp_ingrestrc_perfi3 tablespace d_aml_99 as
with temp_tab as(
  select numperiodo,codclavecic,
  avg(nullif(mto_ingresos,0)) as media_depo,stddev(nullif(mto_ingresos,0)) as desv_depo
  from tmp_ingrestrc_perfi1
  where meses<=6 and meses>=1
  group by numperiodo,codclavecic
) select a.*,
  round(nvl(b.media_depo,0),2) media_ingresos,
  round(nvl(b.desv_depo,0),2) desv_ingresos
  from tmp_ingrestrc_perfi2 a
  left join temp_tab b on (a.numperiodo=b.numperiodo and a.codclavecic=b.codclavecic);

-- creación el flg perfil total en tabla cliente mes: flg_perfil_ingresos_3ds
drop table tmp_ingrestrc_perfilingresos;
create table tmp_ingrestrc_perfilingresos tablespace d_aml_99 as
select  a.*, b.media_ingresos, b.desv_ingresos,
case when b.media_ingresos <> 0 and b.desv_ingresos <> 0 and b.media_ingresos+3*b.desv_ingresos<b.mto_ingresos then 1 else 0 end flg_perfil_ingresos_3ds
from   tmp_ingrestrc_varcomportamiento a
left join tmp_ingrestrc_perfi3 b on (a.periodo=b.numperiodo and a.codclavecic=b.codclavecic)
where periodo = to_number(to_char(add_months(sysdate, -4),'yyyymm'));

--mtos redondos :  max_ctdmtosredondos,sum_mtosredondos
drop table tmp_ingrestrc_mtosredondos;
create table tmp_ingrestrc_mtosredondos tablespace d_aml_99 as
with tmp_ingrestrc_mtosredondos_1 as (
  select a.*,
  floor(mtotransaccion) as mtotransaccion_sindecimal, case when mtotransaccion=floor(a.mtotransaccion) then 1 else 0 end flgredondo
  from tmp_ingrestrc_trxs_total_vf_m a
),tmp_ingrestrc_mtosredondos_2 as (
  select periodo,codclavecicbeneficiario as codclavecic,mtotransaccion,
  sum(flgredondo) as ctdredondo,
  sum(case when flgredondo = 1 then mtodolarizado else 0 end) as summtoredondo
  from tmp_ingrestrc_mtosredondos_1
  group by periodo, codclavecicbeneficiario, mtotransaccion
),tmp_ingrestrc_mtosredondos_3 as (
  select periodo,codclavecic,max(ctdredondo) as max_ctdmtosredondos
  from tmp_ingrestrc_mtosredondos_2
  group by periodo, codclavecic
),tmp_ingrestrc_mtosredondos_4 as (
  select periodo,codclavecic,sum(summtoredondo) as sum_mtosredondos
  from tmp_ingrestrc_mtosredondos_2
  group by periodo, codclavecic
)select a.*,
case when b.max_ctdmtosredondos is not null then b.max_ctdmtosredondos else 0 end max_ctdmtosredondos,
case when c.sum_mtosredondos is not null then c.sum_mtosredondos else 0 end sum_mtosredondos
from tmp_ingrestrc_perfilingresos a
left join tmp_ingrestrc_mtosredondos_3 b on a.periodo = b.periodo and a.codclavecic = b.codclavecic
left join tmp_ingrestrc_mtosredondos_4 c on a.periodo = c.periodo and a.codclavecic = c.codclavecic;

--mtos repetidos max
drop table tmpctds;
create table tmpctds tablespace d_aml_99 as
select periodo,codclavecicbeneficiario as codclavecic,mtotransaccion,count(*) as ctd
from tmp_ingrestrc_trxs_total_vf_m
group by periodo,codclavecicbeneficiario,mtotransaccion;

drop table tmpctdsmax;
create table tmpctdsmax tablespace d_aml_99 as
select periodo,codclavecic,max(ctd) as max_ctd
from tmpctds
group by periodo,codclavecic;

--sumamtos ctdmax
drop table tmpctdsycdtsmax;
create table tmpctdsycdtsmax tablespace d_aml_99 as
select a.*, b.max_ctd
from tmpctds a
inner join tmpctdsmax b on a.periodo = b.periodo and a.codclavecic = b.codclavecic and a.ctd = b.max_ctd
order by b.max_ctd desc;

drop table tmpmaxsnorepetidos;
create table tmpmaxsnorepetidos tablespace d_aml_99 as
with tmpx as (
  select periodo, codclavecic, ctd as ctdmaxima, count(*) as ctdmaximos
  from (
  tmpctdsycdtsmax
  )
  group by periodo, codclavecic, ctd
  having count(*) <= 1
)select b.*, a.mtotransaccion
from tmpctdsycdtsmax a
inner join tmpx b on a.periodo = b.periodo and a.codclavecic = b.codclavecic and a.max_ctd = b.ctdmaxima;

drop table tmpmaxsrepetidos;
create table tmpmaxsrepetidos tablespace d_aml_99 as
select periodo, codclavecic, ctd as ctdmaxima, count(*) as ctdmaximos
from (
tmpctdsycdtsmax
)
group by periodo, codclavecic, ctd
having count(*) > 1;

drop table tmpmaxsrepetidosunicos;
create table tmpmaxsrepetidosunicos tablespace d_aml_99 as
with tmpy as (
  select a.*, b.ctdmaximos
  from tmpctdsycdtsmax a
  inner join tmpmaxsrepetidos b on a.periodo = b.periodo and a.codclavecic = b.codclavecic and a.max_ctd = b.ctdmaxima
  order by a.periodo, a.codclavecic, a.max_ctd
)select periodo, codclavecic, max_ctd as ctdmaxima, ctdmaximos, max(mtotransaccion) as mtomaxdemaxrepetidos
from tmpy
group by periodo, codclavecic, max_ctd, ctdmaximos;

drop table tmpclientesmtosmaximosunicos;
create table tmpclientesmtosmaximosunicos tablespace d_aml_99 as
select periodo, codclavecic, ctdmaxima, ctdmaximos, mtomaxdemaxrepetidos from tmpmaxsrepetidosunicos union all
select periodo, codclavecic, ctdmaxima, ctdmaximos, mtotransaccion  from tmpmaxsnorepetidos;

drop table tmp_ingrestrc_mtosmaximosrepetidos_aux;
create table tmp_ingrestrc_mtosmaximosrepetidos_aux tablespace d_aml_99 as
select a.periodo, a.codclavecic, a.ctdmaxima,sum(b.mtodolarizado) as mto_maximosrepetidos
from tmpclientesmtosmaximosunicos a
left join tmp_ingrestrc_trxs_total_vf_m b on a.periodo = b.periodo and a.codclavecic = b.codclavecicbeneficiario and a.mtomaxdemaxrepetidos = b.mtotransaccion
group by a.periodo, a.codclavecic, a.ctdmaxima;

--mtomaxdemaxrepetidos ,ctmaxima, mto_maximosrepetidos,
drop table tmp_ingrestrc_mtosmaximosrepetidos;
create table tmp_ingrestrc_mtosmaximosrepetidos tablespace d_aml_99 as
select a.*,
case when b.ctdmaxima is null then 0 else b.ctdmaxima  end ctdmaxima,
case when b.mto_maximosrepetidos is null then 0 else b.mto_maximosrepetidos  end mto_maximosrepetidos
from tmp_ingrestrc_mtosredondos a
left join tmp_ingrestrc_mtosmaximosrepetidos_aux b on a.periodo = b.periodo and a.codclavecic = b.codclavecic ;

--mtos proximos
drop table tmp_ingrestrc_mtosyctdsproximos_aux;
create table tmp_ingrestrc_mtosyctdsproximos_aux tablespace d_aml_99 as
  select a.periodo, a.codclavecic, a.mtomaxdemaxrepetidos,
  sum(case when a.mtomaxdemaxrepetidos*0.9 < b.mtotransaccion and b.mtotransaccion < a.mtomaxdemaxrepetidos*1.1 then b.mtodolarizado else 0 end) as mto_conotrosproximos,
  sum(case when a.mtomaxdemaxrepetidos*0.9 < b.mtotransaccion and b.mtotransaccion < a.mtomaxdemaxrepetidos*1.1 then 1 else 0 end) as ctd_conotrosproximos
  from tmpclientesmtosmaximosunicos a
  left join tmp_ingrestrc_trxs_total_vf_m b on a.periodo = b.periodo and a.codclavecic = b.codclavecicbeneficiario
  group by a.periodo, a.codclavecic, a.mtomaxdemaxrepetidos;

drop table tmp_ingrestrc_mtosyctdsproximos;
create table tmp_ingrestrc_mtosyctdsproximos tablespace d_aml_99 as
select a.*,
case when b.mtomaxdemaxrepetidos is null then 0 else b.mtomaxdemaxrepetidos  end mtomaxdemaxrepetidos,
case when b.mto_conotrosproximos is null then 0 else b.mto_conotrosproximos  end mto_conotrosproximos,
case when b.ctd_conotrosproximos is null then 0 else b.ctd_conotrosproximos  end ctd_conotrosproximos
from tmp_ingrestrc_mtosmaximosrepetidos a
left join tmp_ingrestrc_mtosyctdsproximos_aux b on a.periodo = b.periodo and a.codclavecic = b.codclavecic ;

--tablon final mes 4
drop table tmp_ingrestrc_mtosyctdsproximos_tablon_m4;
create table tmp_ingrestrc_mtosyctdsproximos_tablon_m4 tablespace d_aml_99 as
select * from tmp_ingrestrc_mtosyctdsproximos;

---- ** MES 05 - Junio23 **-----

--Extraer las trx historica de los 7 ultimos meses del mes analisis
drop table tmp_ingrestrc_trxs_total_vf_m;
create table tmp_ingrestrc_trxs_total_vf_m tablespace d_aml_99 as
select  * from  tmp_ingrestrc_trxs_total_vf
where periodo between  to_number(to_char(add_months(sysdate, -11),'yyyymm')) and  to_number(to_char(add_months(sysdate, -5),'yyyymm'));

--Extraer el mes de analisis
drop table tmp_ingrestrc_universo_cli_m;
create table tmp_ingrestrc_universo_cli_m tablespace d_aml_99 as
select  *
from  tmp_ingrestrc_universo_cli
where periodo = to_number(to_char(add_months(sysdate, -5),'yyyymm'));

--edad
drop table tmp_ingrestrc_edad;
create table tmp_ingrestrc_edad tablespace d_aml_99 as
with tmp_proc_edad_ppnn_aux as
( select a.codclavecic,a.periodo,c.fecnacimiento, floor(months_between(to_date(to_char(periodo||'01'),'yyyymmdd'), c.fecnacimiento) /12) as edad
  from tmp_ingrestrc_universo_cli_m a
  inner join ods_v.md_cliente b on a.codclavecic = b.codclavecic
  left join ods_v.md_personanatural c on a.codclavecic = c.codclavecic
  where trim(b.tipper) = 'P'
),tmp_proc_edad_ppjj_aux as
( select a.codclavecic,a.periodo,c.fecconstitucion, floor(months_between(to_date(to_char(periodo||'01'),'yyyymmdd'), c.fecconstitucion) /12) as edad
  from tmp_ingrestrc_universo_cli_m a
  inner join ods_v.md_cliente b on a.codclavecic = b.codclavecic
  left join ods_v.mm_empresa c on a.codclavecic = c.codclavecic
  where trim(b.tipper) = 'E'
)select a.periodo, a.codclavecic, case when trim(x.tipper) = 'P' then b.edad else case when trim(x.tipper) = 'E' then c.edad else null end end as edad
  from tmp_ingrestrc_universo_cli_m a
  left join ods_v.md_cliente x on a.codclavecic = x.codclavecic
  left join tmp_proc_edad_ppnn_aux b on a.periodo = b.periodo and a.codclavecic = b.codclavecic
  left join tmp_proc_edad_ppjj_aux c on a.periodo = c.periodo and a.codclavecic = c.codclavecic;

--tipper
drop table tmp_ingrestrc_tipper;
create table tmp_ingrestrc_tipper tablespace d_aml_99 as
select a.*, b.tipper
from tmp_ingrestrc_edad a
inner join ods_v.md_cliente b on a.codclavecic = b.codclavecic;

--antiguedad cliente
drop table tmp_ingrestrc_antiguedad;
create table tmp_ingrestrc_antiguedad tablespace d_aml_99 as
with tmp_proc_antg_fecapertura as
( select codclavecic,min(t.fecapertura) as fecapertura
  from ( select distinct codclavecic,fecapertura from ods_v.md_prestamo
         union all
         select distinct codclavecic,fecapertura from ods_v.md_impac
         union all
         select distinct codclavecic,fecapertura from ods_v.md_saving
         union all
         select distinct codclavecic,fecapertura from ods_v.md_cuentavp) t
  group by codclavecic
),tmp_proc_antig_aux as
(select a.periodo, a.codclavecic, b.fecapertura,
  floor(months_between(to_date(to_char(periodo||'01'),'yyyymmdd'), b.fecapertura) ) as antiguedad
  from tmp_ingrestrc_tipper a
  left join tmp_proc_antg_fecapertura b on a.codclavecic = b.codclavecic
)select a.*, b.antiguedad
  from tmp_ingrestrc_tipper a
  left join tmp_proc_antig_aux b on a.periodo = b.periodo and a.codclavecic = b.codclavecic;

--flg actividad economica no definida
drop table tmp_ingrestrc_acteconomica_nodef_aux;
create table tmp_ingrestrc_acteconomica_nodef_aux tablespace d_aml_99 as
  select codacteconomica,desacteconomica,'OTRSERV'as busq
  from ods_v.mm_descodactividadeconomica
  where upper(desacteconomica) like '%OTR%SERV%'
  union
  select codacteconomica,desacteconomica,'NO ESPECIF'
  from ods_v.mm_descodactividadeconomica
  where upper(desacteconomica) like '%NO ESPECIF%'
  union
  select codacteconomica,desacteconomica,'NO DISPO'
  from ods_v.mm_descodactividadeconomica
  where upper(desacteconomica) like '%NO DISPO%'
  union
  select codacteconomica,desacteconomica,'MAYOROTRPROD'
  from ods_v.mm_descodactividadeconomica
  where upper(desacteconomica) like '%MAYOR%OTR%PROD%'
  union
  select codacteconomica,desacteconomica,'MENOROTRPROD'
  from ods_v.mm_descodactividadeconomica
  where upper(desacteconomica) like '%MENOR%OTR%PROD%';

drop table tmp_ingrestrc_acteconomica_nodef;
create table tmp_ingrestrc_acteconomica_nodef tablespace d_aml_99 as
select a.*, b.codacteconomica, d.desacteconomica,
    case
    when b.codacteconomica is null then 1
    when c.codacteconomica is not null then 1
    else 0
    end flg_acteco_nodef
from tmp_ingrestrc_antiguedad a
left join ods_v.md_cliente b on a.codclavecic = b.codclavecic
left join tmp_ingrestrc_acteconomica_nodef_aux c on trim(b.codacteconomica) = trim(c.codacteconomica)
left join ods_v.mm_descodactividadeconomica d on trim(b.codacteconomica) = trim(d.codacteconomica);

--variables sapyc: np - 2
drop table tmp_ingrestrc_np_aux2;
create table tmp_ingrestrc_np_aux2 tablespace d_aml_99 as
with tmp_ingrestrc_np_aux as
( select a.*, b.idorigen, b.nbrorigen as origen, b.codtransaccion as escenario, b.nbrtransaccion as desescenario
  from (
     select a.idcaso, case when instr(a.codunicocli,'GR') > 0 then c.codclavecic else d.codclavecic end as codclavecic, a.idresultado as idresultadoeval, a.fecfineval as fecfineval, b."IDRESULTADOSUPERVISOR"
     from s61751.sapy_dmevaluacion a
     left join s61751.sapy_dminvestigacion b on a.idcaso = b.idcaso
     left join ods_v.md_empleadog94 c on trim(substr(a.codunicocli,instr(a.codunicocli,'GR')+2,6)) = trim(c.codmatricula)
     left join ods_v.md_clienteg94 d on trim(a.codunicocli) = trim(d.codunicocli)
  ) a
  left join s61751.sapy_dmalerta b on a.idcaso = b.idcaso
  where idorigen in (2)
)select a.periodo,a.codclavecic, sum(case when b.fecfineval < to_date(to_char(a.periodo||'01'),'yyyymmdd') then 1 else 0 end) as ctdnp
from tmp_ingrestrc_acteconomica_nodef a
left join tmp_ingrestrc_np_aux b on a.codclavecic = b.codclavecic
group by a.periodo,a.codclavecic;

drop table tmp_ingrestrc_np;
create table tmp_ingrestrc_np tablespace d_aml_99 as
select a.*,
case when b.ctdnp > 0 then 1 else 0 end flgnp,
case when b.ctdnp is not null then b.ctdnp else 0 end ctdnp
from tmp_ingrestrc_acteconomica_nodef a
left join tmp_ingrestrc_np_aux2 b on a.periodo = b.periodo and a.codclavecic = b.codclavecic;

--variables sapyc: lsb - 29
drop table tmp_ingrestrc_lsb_aux2;
create table tmp_ingrestrc_lsb_aux2 tablespace d_aml_99 as
with tmp_ingrestrc_lsb_aux as
( select a.*, b.idorigen, b.nbrorigen as origen, b.codtransaccion as escenario, b.nbrtransaccion as desescenario
  from (
     select a.idcaso, case when instr(a.codunicocli,'GR') > 0 then c.codclavecic else d.codclavecic end as codclavecic, a.idresultado as idresultadoeval, a.fecfineval as fecfineval, b."IDRESULTADOSUPERVISOR"
     from s61751.sapy_dmevaluacion a
     left join s61751.sapy_dminvestigacion b on a.idcaso = b.idcaso
     left join ods_v.md_empleadog94 c on trim(substr(a.codunicocli,instr(a.codunicocli,'GR')+2,6)) = trim(c.codmatricula)
     left join ods_v.md_clienteg94 d on trim(a.codunicocli) = trim(d.codunicocli)
  ) a
  left join s61751.sapy_dmalerta b on a.idcaso = b.idcaso
  where idorigen in (29)
)select a.periodo,a.codclavecic, sum(case when b.fecfineval < to_date(to_char(a.periodo||'01'),'yyyymmdd') then 1 else 0 end) as ctdlsb
from tmp_ingrestrc_np a
left join tmp_ingrestrc_lsb_aux b on a.codclavecic = b.codclavecic
group by a.periodo,a.codclavecic;

--var ctd_np_lsb
drop table tmp_ingrestrc_lsb;
create table tmp_ingrestrc_lsb tablespace d_aml_99 as
select a.*,
case when b.ctdlsb > 0 then 1 else 0 end flglsb,
case when b.ctdlsb is not null then b.ctdlsb else 0 end ctdlsb
from tmp_ingrestrc_np a
left join tmp_ingrestrc_lsb_aux2 b on a.periodo = b.periodo and a.codclavecic = b.codclavecic;

--var archivo negativo
drop table tmp_ingrestrc_archnegativo;
create table tmp_ingrestrc_archnegativo tablespace d_aml_99 as
with tmp_ingrestrc_archivonegativo_aux as (
  select distinct a.codclavecic, max(b.destipmotivonegativo) as destipmotivonegativo
  from ods_v.md_motivodetalleclinegativo a
  left join ods_v.md_destipomotivonegativo b on a.tipmotivonegativo = b.tipmotivonegativo
  inner join (
        select codclavecic, max(fecregistrodetallenegativo) as maxfecregistrodetallenegativo
        from ods_v.md_motivodetalleclinegativo
        group by codclavecic
  ) c on a.codclavecic = c.codclavecic and a.fecregistrodetallenegativo = c.maxfecregistrodetallenegativo
  where a.flghistorico = 'N' and a.tipmotivonegativo='013' and a.tipdetallemotivonegativo='001'
  group by a.codclavecic
) select a.*,
  case when b.codclavecic is not null then 1 else 0 end as flgarchivonegativo,
  b.destipmotivonegativo as destipmotivonegativo
  from tmp_ingrestrc_lsb a
  left join tmp_ingrestrc_archivonegativo_aux b on a.codclavecic = b.codclavecic;

drop table tmp_ingrestrc_ctd_nplsb;
create table tmp_ingrestrc_ctd_nplsb tablespace d_aml_99 as
select a.*,
ctdnp+ctdlsb as ctd_np_lsb
from tmp_ingrestrc_archnegativo a;

--ctd evaluaciones
drop table tmp_ingrestrc_sapyc;
create table tmp_ingrestrc_sapyc tablespace d_aml_99 as
select a.*
from (
   select a.idcaso, case when instr(a.codunicocli,'GR') > 0 then c.codclavecic else d.codclavecic end as codclavecic, a.idresultado as idresultadoeval, a.fecfineval as fecfineval, b."IDRESULTADOSUPERVISOR"
     from s61751.sapy_dmevaluacion a
     left join s61751.sapy_dminvestigacion b on a.idcaso = b.idcaso
     left join ods_v.md_empleadog94 c on trim(substr(a.codunicocli,instr(a.codunicocli,'GR')+2,6)) = trim(c.codmatricula)
     left join ods_v.md_clienteg94 d on trim(a.codunicocli) = trim(d.codunicocli)
) a;

drop table tmp_ingrestrc_evals;
create table tmp_ingrestrc_evals tablespace d_aml_99 as
with tmp_ingrestrc_evals_aux as
( select a.periodo,a.codclavecic, sum(case when b.fecfineval < to_date(to_char(a.periodo||'01'),'yyyymmdd') then 1 else 0 end) as ctdeval
  from tmp_ingrestrc_ctd_nplsb a
  left join tmp_ingrestrc_sapyc b on a.codclavecic = b.codclavecic
  group by a.periodo,a.codclavecic
) select a.*,
  case when b.ctdeval is not null then b.ctdeval else 0 end as ctdeval
  from tmp_ingrestrc_ctd_nplsb a
  left join tmp_ingrestrc_evals_aux b on a.periodo = b.periodo and a.codclavecic = b.codclavecic;

--var segmento del cliente
drop table tmp_ingrestrc_segmento;
create table tmp_ingrestrc_segmento tablespace d_aml_99 as
with tmp_ingrestrc_segmento_aux as (
  select distinct trim(subseg.codsubsegmento) as codsubsegmento, subseg.dessubsegmento, trim(seg.codsegmento) as codsegmento, seg.dessegmento
  from ods_v.mm_descodigosubsegmento subseg
  left join ods_v.mm_descodsubseggen subseggen on trim(subseg.codsubseggeneral)=trim(subseggen.codsubseggeneral)
  left join ods_v.mm_descodigosegmento seg on trim(subseggen.codsegmento)=trim(seg.codsegmento)
) select a.*, c.codsubsegmento, c.dessubsegmento, c.codsegmento, c.dessegmento
  from tmp_ingrestrc_evals a
  left join ods_v.md_cliente b on a.codclavecic = b.codclavecic
  left join tmp_ingrestrc_segmento_aux c on trim(b.codsubsegmento) = trim(c.codsubsegmento);

-- var lugar de residencia mas actual
drop table tmp_ingrestrc_lugarresidencia_aux2;
create table tmp_ingrestrc_lugarresidencia_aux2 tablespace d_aml_99 as
with tmp_ingrestrc_lugarresidencia_aux as (
  select codclavecic,max(numdir) as maxnumdir
  from ods_v.mm_direccioncliente
  where
  tipdir in ('D')
  group by codclavecic
) select  distinct b.codclavecic, b.tipdir, c.codubigeo, b.coddistrito, c.descoddistrito, c.codprovincia, d.descodprovincia, d.coddepartamento, e.descoddepartamento
  from tmp_ingrestrc_segmento a
  left join ods_v.mm_direccioncliente b on a.codclavecic = b.codclavecic
  inner join tmp_ingrestrc_lugarresidencia_aux x on b.codclavecic = x.codclavecic and b.numdir = x.maxnumdir
  left join ods_v.mm_distrito c on b.coddistrito = c.coddistrito
  left join ods_v.mm_provincia d on c.codprovincia = d.codprovincia
  left join ods_v.mm_departamento e on d.coddepartamento = e.coddepartamento;

drop table tmp_ingrestrc_lugarresidencia;
create table tmp_ingrestrc_lugarresidencia tablespace d_aml_99 as
select a.*, b.tipdir, b.codubigeo, b.coddistrito, b.descoddistrito, b.codprovincia, b.descodprovincia, b.coddepartamento, b.descoddepartamento
from tmp_ingrestrc_segmento a
left join tmp_ingrestrc_lugarresidencia_aux2 b on a.codclavecic = b.codclavecic;

--var nacionalidad
drop table tmp_ingrestrc_nacionalidad;
create table tmp_ingrestrc_nacionalidad tablespace d_aml_99 as
with tmp_ingrestrc_nacionalidad_pn as (
  select distinct a.codclavecic, a.tipper, trim(c.codpaisnacionalidad) as codpaisnacionalidad, trim(d.descodpaisnacionalidad) as descodpaisnacionalidad,
  case when trim(c.codpaisnacionalidad) = 'PER' then 0
       when c.codpaisnacionalidad is not null and trim(c.codpaisnacionalidad) <> 'PER' then 1
       else null end as flgnacionalidad
  from tmp_ingrestrc_lugarresidencia a
    inner join ods_v.md_cliente b on a.codclavecic = b.codclavecic
    left join ods_v.md_personanatural c on b.codclavecic = c.codclavecic
    left join ods_v.mm_descodigopaisnacionalidad d on c.codpaisnacionalidad = d.codpaisnacionalidad
    where a.tipper = 'P'
),tmp_ingrestrc_nacionalidad_pj as (
  select distinct a.codclavecic, a.tipper, 'PER' as codpaisnacionalidad, 'PERU' as descodpaisnacionalidad, 0 as flgnacionalidad
  from tmp_ingrestrc_lugarresidencia a
  inner join ods_v.mm_direccioncliente c on a.codclavecic = c.codclavecic
    where a.tipper = 'E'
) select a.*,
  case when a.tipper = 'P' then b.codpaisnacionalidad else c.codpaisnacionalidad end as codpaisnacionalidad,
  case when a.tipper = 'P' then b.descodpaisnacionalidad else c.descodpaisnacionalidad end as descodpaisnacionalidad,
  case when a.tipper = 'P' then b.flgnacionalidad else c.flgnacionalidad end as flgnacionalidad
  from tmp_ingrestrc_lugarresidencia a
  left join tmp_ingrestrc_nacionalidad_pn b on a.codclavecic = b.codclavecic
  left join tmp_ingrestrc_nacionalidad_pj c on a.codclavecic = c.codclavecic;

--variables de comportamiento: mto_ingresos_mes, ctd_ingresos_mes
drop table tmp_ingrestrc_varcomportamiento;
create table tmp_ingrestrc_varcomportamiento tablespace d_aml_99 as
with tmp_ingrestrc_varcomp as (
  select periodo, codclavecicbeneficiario as codclavecic,
  sum(mtodolarizado) as mto_ingresos_mes,
  count(periodo) as ctd_ingresos_mes
  from tmp_ingrestrc_trxs_total_vf_m
  group by periodo, codclavecicbeneficiario
)
select a.*,b.mto_ingresos_mes,b.ctd_ingresos_mes
from tmp_ingrestrc_nacionalidad a
left join tmp_ingrestrc_varcomp b on a.periodo = b.periodo and a.codclavecic = b.codclavecic;

--perfil total
drop table tmp_ingrestrc_perfi1;
create table tmp_ingrestrc_perfi1 tablespace d_aml_99 as
with tmp_ingrestrc_perfi1_aux as (
     select periodo, codclavecicbeneficiario as codclavecic, sum(mtodolarizado) as mto_ingresos
     from tmp_ingrestrc_trxs_total_vf_m
     group by periodo, codclavecicbeneficiario
) select  a.codclavecic,a.periodo as numperiodo,b.periodo,
  months_between(to_date(a.periodo,'yyyymm'),to_date(b.periodo,'yyyymm')) meses,
  case when b.mto_ingresos is null then 0 else b.mto_ingresos end mto_ingresos
  from tmp_ingrestrc_perfi1_aux a
  inner join tmp_ingrestrc_perfi1_aux b on a.codclavecic=b.codclavecic;

drop table tmp_ingrestrc_perfi2;
create table tmp_ingrestrc_perfi2 tablespace d_aml_99 as
select numperiodo,codclavecic,mto_ingresos
from tmp_ingrestrc_perfi1 a
where numperiodo=periodo;

drop table tmp_ingrestrc_perfi3;
create table tmp_ingrestrc_perfi3 tablespace d_aml_99 as
with temp_tab as(
  select numperiodo,codclavecic,
  avg(nullif(mto_ingresos,0)) as media_depo,stddev(nullif(mto_ingresos,0)) as desv_depo
  from tmp_ingrestrc_perfi1
  where meses<=6 and meses>=1
  group by numperiodo,codclavecic
) select a.*,
  round(nvl(b.media_depo,0),2) media_ingresos,
  round(nvl(b.desv_depo,0),2) desv_ingresos
  from tmp_ingrestrc_perfi2 a
  left join temp_tab b on (a.numperiodo=b.numperiodo and a.codclavecic=b.codclavecic);

-- creación el flg perfil total en tabla cliente mes: flg_perfil_ingresos_3ds
drop table tmp_ingrestrc_perfilingresos;
create table tmp_ingrestrc_perfilingresos tablespace d_aml_99 as
select  a.*, b.media_ingresos, b.desv_ingresos,
case when b.media_ingresos <> 0 and b.desv_ingresos <> 0 and b.media_ingresos+3*b.desv_ingresos<b.mto_ingresos then 1 else 0 end flg_perfil_ingresos_3ds
from   tmp_ingrestrc_varcomportamiento a
left join tmp_ingrestrc_perfi3 b on (a.periodo=b.numperiodo and a.codclavecic=b.codclavecic)
where periodo = to_number(to_char(add_months(sysdate, -5),'yyyymm'));

--mtos redondos :  max_ctdmtosredondos,sum_mtosredondos
drop table tmp_ingrestrc_mtosredondos;
create table tmp_ingrestrc_mtosredondos tablespace d_aml_99 as
with tmp_ingrestrc_mtosredondos_1 as (
  select a.*,
  floor(mtotransaccion) as mtotransaccion_sindecimal, case when mtotransaccion=floor(a.mtotransaccion) then 1 else 0 end flgredondo
  from tmp_ingrestrc_trxs_total_vf_m a
),tmp_ingrestrc_mtosredondos_2 as (
  select periodo,codclavecicbeneficiario as codclavecic,mtotransaccion,
  sum(flgredondo) as ctdredondo,
  sum(case when flgredondo = 1 then mtodolarizado else 0 end) as summtoredondo
  from tmp_ingrestrc_mtosredondos_1
  group by periodo, codclavecicbeneficiario, mtotransaccion
),tmp_ingrestrc_mtosredondos_3 as (
  select periodo,codclavecic,max(ctdredondo) as max_ctdmtosredondos
  from tmp_ingrestrc_mtosredondos_2
  group by periodo, codclavecic
),tmp_ingrestrc_mtosredondos_4 as (
  select periodo,codclavecic,sum(summtoredondo) as sum_mtosredondos
  from tmp_ingrestrc_mtosredondos_2
  group by periodo, codclavecic
)select a.*,
case when b.max_ctdmtosredondos is not null then b.max_ctdmtosredondos else 0 end max_ctdmtosredondos,
case when c.sum_mtosredondos is not null then c.sum_mtosredondos else 0 end sum_mtosredondos
from tmp_ingrestrc_perfilingresos a
left join tmp_ingrestrc_mtosredondos_3 b on a.periodo = b.periodo and a.codclavecic = b.codclavecic
left join tmp_ingrestrc_mtosredondos_4 c on a.periodo = c.periodo and a.codclavecic = c.codclavecic;

--mtos repetidos max
drop table tmpctds;
create table tmpctds tablespace d_aml_99 as
select periodo,codclavecicbeneficiario as codclavecic,mtotransaccion,count(*) as ctd
from tmp_ingrestrc_trxs_total_vf_m
group by periodo,codclavecicbeneficiario,mtotransaccion;

drop table tmpctdsmax;
create table tmpctdsmax tablespace d_aml_99 as
select periodo,codclavecic,max(ctd) as max_ctd
from tmpctds
group by periodo,codclavecic;

--sumamtos ctdmax
drop table tmpctdsycdtsmax;
create table tmpctdsycdtsmax tablespace d_aml_99 as
select a.*, b.max_ctd
from tmpctds a
inner join tmpctdsmax b on a.periodo = b.periodo and a.codclavecic = b.codclavecic and a.ctd = b.max_ctd
order by b.max_ctd desc;

drop table tmpmaxsnorepetidos;
create table tmpmaxsnorepetidos tablespace d_aml_99 as
with tmpx as (
  select periodo, codclavecic, ctd as ctdmaxima, count(*) as ctdmaximos
  from (
  tmpctdsycdtsmax
  )
  group by periodo, codclavecic, ctd
  having count(*) <= 1
)
select b.*, a.mtotransaccion
from tmpctdsycdtsmax a
inner join tmpx b on a.periodo = b.periodo and a.codclavecic = b.codclavecic and a.max_ctd = b.ctdmaxima;

drop table tmpmaxsrepetidos;
create table tmpmaxsrepetidos tablespace d_aml_99 as
select periodo, codclavecic, ctd as ctdmaxima, count(*) as ctdmaximos
from (
tmpctdsycdtsmax
)
group by periodo, codclavecic, ctd
having count(*) > 1;

drop table tmpmaxsrepetidosunicos;
create table tmpmaxsrepetidosunicos tablespace d_aml_99 as
with tmpy as (
  select a.*, b.ctdmaximos
  from tmpctdsycdtsmax a
  inner join tmpmaxsrepetidos b on a.periodo = b.periodo and a.codclavecic = b.codclavecic and a.max_ctd = b.ctdmaxima
  order by a.periodo, a.codclavecic, a.max_ctd
)select periodo, codclavecic, max_ctd as ctdmaxima, ctdmaximos, max(mtotransaccion) as mtomaxdemaxrepetidos
from tmpy
group by periodo, codclavecic, max_ctd, ctdmaximos;

drop table tmpclientesmtosmaximosunicos;
create table tmpclientesmtosmaximosunicos tablespace d_aml_99 as
select periodo, codclavecic, ctdmaxima, ctdmaximos, mtomaxdemaxrepetidos from tmpmaxsrepetidosunicos union all
select periodo, codclavecic, ctdmaxima, ctdmaximos, mtotransaccion  from tmpmaxsnorepetidos;

drop table tmp_ingrestrc_mtosmaximosrepetidos_aux;
create table tmp_ingrestrc_mtosmaximosrepetidos_aux tablespace d_aml_99 as
select a.periodo, a.codclavecic, a.ctdmaxima,sum(b.mtodolarizado) as mto_maximosrepetidos
from tmpclientesmtosmaximosunicos a
left join tmp_ingrestrc_trxs_total_vf_m b on a.periodo = b.periodo and a.codclavecic = b.codclavecicbeneficiario and a.mtomaxdemaxrepetidos = b.mtotransaccion
group by a.periodo, a.codclavecic, a.ctdmaxima;

--mtomaxdemaxrepetidos ,ctmaxima, mto_maximosrepetidos,
drop table tmp_ingrestrc_mtosmaximosrepetidos;
create table tmp_ingrestrc_mtosmaximosrepetidos tablespace d_aml_99 as
select a.*,
case when b.ctdmaxima is null then 0 else b.ctdmaxima  end ctdmaxima,
case when b.mto_maximosrepetidos is null then 0 else b.mto_maximosrepetidos  end mto_maximosrepetidos
from tmp_ingrestrc_mtosredondos a
left join tmp_ingrestrc_mtosmaximosrepetidos_aux b on a.periodo = b.periodo and a.codclavecic = b.codclavecic ;

--mtos proximos
drop table tmp_ingrestrc_mtosyctdsproximos_aux;
create table tmp_ingrestrc_mtosyctdsproximos_aux tablespace d_aml_99 as
  select a.periodo, a.codclavecic, a.mtomaxdemaxrepetidos,
  sum(case when a.mtomaxdemaxrepetidos*0.9 < b.mtotransaccion and b.mtotransaccion < a.mtomaxdemaxrepetidos*1.1 then b.mtodolarizado else 0 end) as mto_conotrosproximos,
  sum(case when a.mtomaxdemaxrepetidos*0.9 < b.mtotransaccion and b.mtotransaccion < a.mtomaxdemaxrepetidos*1.1 then 1 else 0 end) as ctd_conotrosproximos
  from tmpclientesmtosmaximosunicos a
  left join tmp_ingrestrc_trxs_total_vf_m b on a.periodo = b.periodo and a.codclavecic = b.codclavecicbeneficiario
  group by a.periodo, a.codclavecic, a.mtomaxdemaxrepetidos;

drop table tmp_ingrestrc_mtosyctdsproximos;
create table tmp_ingrestrc_mtosyctdsproximos tablespace d_aml_99 as
select a.*,
case when b.mtomaxdemaxrepetidos is null then 0 else b.mtomaxdemaxrepetidos  end mtomaxdemaxrepetidos,
case when b.mto_conotrosproximos is null then 0 else b.mto_conotrosproximos  end mto_conotrosproximos,
case when b.ctd_conotrosproximos is null then 0 else b.ctd_conotrosproximos  end ctd_conotrosproximos
from tmp_ingrestrc_mtosmaximosrepetidos a
left join tmp_ingrestrc_mtosyctdsproximos_aux b on a.periodo = b.periodo and a.codclavecic = b.codclavecic ;

--tablon final mes 5
drop table tmp_ingrestrc_mtosyctdsproximos_tablon_m5;
create table tmp_ingrestrc_mtosyctdsproximos_tablon_m5 tablespace d_aml_99 as
select * from tmp_ingrestrc_mtosyctdsproximos;

---- ** MES 06 - Mayo23 **-----

--Extraer las trx historica de los 7 ultimos meses del mes analisis
drop table tmp_ingrestrc_trxs_total_vf_m;
create table tmp_ingrestrc_trxs_total_vf_m tablespace d_aml_99 as
select  * from  tmp_ingrestrc_trxs_total_vf
where periodo between  to_number(to_char(add_months(sysdate, -12),'yyyymm')) and  to_number(to_char(add_months(sysdate, -6),'yyyymm'));

--Extraer el mes de analisis
drop table tmp_ingrestrc_universo_cli_m;
create table tmp_ingrestrc_universo_cli_m tablespace d_aml_99 as
select  *
from  tmp_ingrestrc_universo_cli
where periodo = to_number(to_char(add_months(sysdate, -6),'yyyymm'));

--edad
drop table tmp_ingrestrc_edad;
create table tmp_ingrestrc_edad tablespace d_aml_99 as
with tmp_proc_edad_ppnn_aux as
(
  select a.codclavecic,a.periodo,c.fecnacimiento, floor(months_between(to_date(to_char(periodo||'01'),'yyyymmdd'), c.fecnacimiento) /12) as edad
  from tmp_ingrestrc_universo_cli_m a
  inner join ods_v.md_cliente b on a.codclavecic = b.codclavecic
  left join ods_v.md_personanatural c on a.codclavecic = c.codclavecic
  where trim(b.tipper) = 'P'
),tmp_proc_edad_ppjj_aux as
(select a.codclavecic,a.periodo,c.fecconstitucion, floor(months_between(to_date(to_char(periodo||'01'),'yyyymmdd'), c.fecconstitucion) /12) as edad
  from tmp_ingrestrc_universo_cli_m a
  inner join ods_v.md_cliente b on a.codclavecic = b.codclavecic
  left join ods_v.mm_empresa c on a.codclavecic = c.codclavecic
  where trim(b.tipper) = 'E'
)select a.periodo, a.codclavecic, case when trim(x.tipper) = 'P' then b.edad else case when trim(x.tipper) = 'E' then c.edad else null end end as edad
  from tmp_ingrestrc_universo_cli_m a
  left join ods_v.md_cliente x on a.codclavecic = x.codclavecic
  left join tmp_proc_edad_ppnn_aux b on a.periodo = b.periodo and a.codclavecic = b.codclavecic
  left join tmp_proc_edad_ppjj_aux c on a.periodo = c.periodo and a.codclavecic = c.codclavecic;

--tipper
drop table tmp_ingrestrc_tipper;
create table tmp_ingrestrc_tipper tablespace d_aml_99 as
select a.*, b.tipper
from tmp_ingrestrc_edad a
inner join ods_v.md_cliente b on a.codclavecic = b.codclavecic;

--antiguedad cliente
drop table tmp_ingrestrc_antiguedad;
create table tmp_ingrestrc_antiguedad tablespace d_aml_99 as
with tmp_proc_antg_fecapertura as
( select codclavecic,min(t.fecapertura) as fecapertura
  from ( select distinct codclavecic,fecapertura from ods_v.md_prestamo
         union all
         select distinct codclavecic,fecapertura from ods_v.md_impac
         union all
         select distinct codclavecic,fecapertura from ods_v.md_saving
         union all
         select distinct codclavecic,fecapertura from ods_v.md_cuentavp) t
  group by codclavecic
),tmp_proc_antig_aux as
(select a.periodo, a.codclavecic, b.fecapertura,
  floor(months_between(to_date(to_char(periodo||'01'),'yyyymmdd'), b.fecapertura) ) as antiguedad
  from tmp_ingrestrc_tipper a
  left join tmp_proc_antg_fecapertura b on a.codclavecic = b.codclavecic
)select a.*, b.antiguedad
  from tmp_ingrestrc_tipper a
  left join tmp_proc_antig_aux b on a.periodo = b.periodo and a.codclavecic = b.codclavecic;

--flg actividad economica no definida
drop table tmp_ingrestrc_acteconomica_nodef_aux;
create table tmp_ingrestrc_acteconomica_nodef_aux tablespace d_aml_99 as
  select codacteconomica,desacteconomica,'OTRSERV'as busq
  from ods_v.mm_descodactividadeconomica
  where upper(desacteconomica) like '%OTR%SERV%'
  union
  select codacteconomica,desacteconomica,'NO ESPECIF'
  from ods_v.mm_descodactividadeconomica
  where upper(desacteconomica) like '%NO ESPECIF%'
  union
  select codacteconomica,desacteconomica,'NO DISPO'
  from ods_v.mm_descodactividadeconomica
  where upper(desacteconomica) like '%NO DISPO%'
  union
  select codacteconomica,desacteconomica,'MAYOROTRPROD'
  from ods_v.mm_descodactividadeconomica
  where upper(desacteconomica) like '%MAYOR%OTR%PROD%'
  union
  select codacteconomica,desacteconomica,'MENOROTRPROD'
  from ods_v.mm_descodactividadeconomica
  where upper(desacteconomica) like '%MENOR%OTR%PROD%';

drop table tmp_ingrestrc_acteconomica_nodef;
create table tmp_ingrestrc_acteconomica_nodef tablespace d_aml_99 as
select a.*, b.codacteconomica, d.desacteconomica,
case
    when b.codacteconomica is null then 1
    when c.codacteconomica is not null then 1
	else 0
end flg_acteco_nodef
from tmp_ingrestrc_antiguedad a
left join ods_v.md_cliente b on a.codclavecic = b.codclavecic
left join tmp_ingrestrc_acteconomica_nodef_aux c on trim(b.codacteconomica) = trim(c.codacteconomica)
left join ods_v.mm_descodactividadeconomica d on trim(b.codacteconomica) = trim(d.codacteconomica);

--variables sapyc: np
drop table tmp_ingrestrc_np_aux2;
create table tmp_ingrestrc_np_aux2 tablespace d_aml_99 as
with tmp_ingrestrc_np_aux as
( select a.*, b.idorigen, b.nbrorigen as origen, b.codtransaccion as escenario, b.nbrtransaccion as desescenario
  from (
     select a.idcaso, case when instr(a.codunicocli,'GR') > 0 then c.codclavecic else d.codclavecic end as codclavecic, a.idresultado as idresultadoeval, a.fecfineval as fecfineval, b."IDRESULTADOSUPERVISOR"
     from s61751.sapy_dmevaluacion a
     left join s61751.sapy_dminvestigacion b on a.idcaso = b.idcaso
     left join ods_v.md_empleadog94 c on trim(substr(a.codunicocli,instr(a.codunicocli,'GR')+2,6)) = trim(c.codmatricula)
     left join ods_v.md_clienteg94 d on trim(a.codunicocli) = trim(d.codunicocli)
  ) a
  left join s61751.sapy_dmalerta b on a.idcaso = b.idcaso
  where idorigen in (2)
)select a.periodo,a.codclavecic, sum(case when b.fecfineval < to_date(to_char(a.periodo||'01'),'yyyymmdd') then 1 else 0 end) as ctdnp
from tmp_ingrestrc_acteconomica_nodef a
left join tmp_ingrestrc_np_aux b on a.codclavecic = b.codclavecic
group by a.periodo,a.codclavecic;

drop table tmp_ingrestrc_np;
create table tmp_ingrestrc_np tablespace d_aml_99 as
select a.*,
case when b.ctdnp > 0 then 1 else 0 end flgnp,
case when b.ctdnp is not null then b.ctdnp else 0 end ctdnp
from tmp_ingrestrc_acteconomica_nodef a
left join tmp_ingrestrc_np_aux2 b on a.periodo = b.periodo and a.codclavecic = b.codclavecic;

--variables sapyc: lsb - 29
drop table tmp_ingrestrc_lsb_aux2;
create table tmp_ingrestrc_lsb_aux2 tablespace d_aml_99 as
with tmp_ingrestrc_lsb_aux as
( select a.*, b.idorigen, b.nbrorigen as origen, b.codtransaccion as escenario, b.nbrtransaccion as desescenario
  from (
     select a.idcaso, case when instr(a.codunicocli,'GR') > 0 then c.codclavecic else d.codclavecic end as codclavecic, a.idresultado as idresultadoeval, a.fecfineval as fecfineval, b."IDRESULTADOSUPERVISOR"
     from s61751.sapy_dmevaluacion a
     left join s61751.sapy_dminvestigacion b on a.idcaso = b.idcaso
     left join ods_v.md_empleadog94 c on trim(substr(a.codunicocli,instr(a.codunicocli,'GR')+2,6)) = trim(c.codmatricula)
     left join ods_v.md_clienteg94 d on trim(a.codunicocli) = trim(d.codunicocli)
  ) a
  left join s61751.sapy_dmalerta b on a.idcaso = b.idcaso
  where idorigen in (29)
)select a.periodo,a.codclavecic, sum(case when b.fecfineval < to_date(to_char(a.periodo||'01'),'yyyymmdd') then 1 else 0 end) as ctdlsb
from tmp_ingrestrc_np a
left join tmp_ingrestrc_lsb_aux b on a.codclavecic = b.codclavecic
group by a.periodo,a.codclavecic;

--var ctd_np_lsb
drop table tmp_ingrestrc_lsb;
create table tmp_ingrestrc_lsb tablespace d_aml_99 as
select a.*,
case when b.ctdlsb > 0 then 1 else 0 end flglsb,
case when b.ctdlsb is not null then b.ctdlsb else 0 end ctdlsb
from tmp_ingrestrc_np a
left join tmp_ingrestrc_lsb_aux2 b on a.periodo = b.periodo and a.codclavecic = b.codclavecic;

--var archivo negativo
drop table tmp_ingrestrc_archnegativo;
create table tmp_ingrestrc_archnegativo tablespace d_aml_99 as
with tmp_ingrestrc_archivonegativo_aux as (
  select distinct a.codclavecic, max(b.destipmotivonegativo) as destipmotivonegativo
  from ods_v.md_motivodetalleclinegativo a
  left join ods_v.md_destipomotivonegativo b on a.tipmotivonegativo = b.tipmotivonegativo
  inner join (
        select codclavecic, max(fecregistrodetallenegativo) as maxfecregistrodetallenegativo
        from ods_v.md_motivodetalleclinegativo
        group by codclavecic
  ) c on a.codclavecic = c.codclavecic and a.fecregistrodetallenegativo = c.maxfecregistrodetallenegativo
  where a.flghistorico = 'N' and a.tipmotivonegativo='013' and a.tipdetallemotivonegativo='001'
  group by a.codclavecic
) select a.*,
  case when b.codclavecic is not null then 1 else 0 end as flgarchivonegativo,
  b.destipmotivonegativo as destipmotivonegativo
  from tmp_ingrestrc_lsb a
  left join tmp_ingrestrc_archivonegativo_aux b on a.codclavecic = b.codclavecic;

drop table tmp_ingrestrc_ctd_nplsb;
create table tmp_ingrestrc_ctd_nplsb tablespace d_aml_99 as
select a.*,ctdnp+ctdlsb as ctd_np_lsb
from tmp_ingrestrc_archnegativo a;

--ctd evaluaciones
drop table tmp_ingrestrc_sapyc;
create table tmp_ingrestrc_sapyc tablespace d_aml_99 as
select a.*
from (
   select a.idcaso, case when instr(a.codunicocli,'GR') > 0 then c.codclavecic else d.codclavecic end as codclavecic, a.idresultado as idresultadoeval, a.fecfineval as fecfineval, b."IDRESULTADOSUPERVISOR"
     from s61751.sapy_dmevaluacion a
     left join s61751.sapy_dminvestigacion b on a.idcaso = b.idcaso
     left join ods_v.md_empleadog94 c on trim(substr(a.codunicocli,instr(a.codunicocli,'GR')+2,6)) = trim(c.codmatricula)
     left join ods_v.md_clienteg94 d on trim(a.codunicocli) = trim(d.codunicocli)
) a;

drop table tmp_ingrestrc_evals;
create table tmp_ingrestrc_evals tablespace d_aml_99 as
with tmp_ingrestrc_evals_aux as
(  select a.periodo,a.codclavecic, sum(case when b.fecfineval < to_date(to_char(a.periodo||'01'),'yyyymmdd') then 1 else 0 end) as ctdeval
  from tmp_ingrestrc_ctd_nplsb a
  left join tmp_ingrestrc_sapyc b on a.codclavecic = b.codclavecic
  group by a.periodo,a.codclavecic
) select a.*,
  case when b.ctdeval is not null then b.ctdeval else 0 end as ctdeval
  from tmp_ingrestrc_ctd_nplsb a
  left join tmp_ingrestrc_evals_aux b on a.periodo = b.periodo and a.codclavecic = b.codclavecic;

--var segmento del cliente
drop table tmp_ingrestrc_segmento;
create table tmp_ingrestrc_segmento tablespace d_aml_99 as
with tmp_ingrestrc_segmento_aux as (
  select distinct trim(subseg.codsubsegmento) as codsubsegmento, subseg.dessubsegmento, trim(seg.codsegmento) as codsegmento, seg.dessegmento
  from ods_v.mm_descodigosubsegmento subseg
  left join ods_v.mm_descodsubseggen subseggen on trim(subseg.codsubseggeneral)=trim(subseggen.codsubseggeneral)
  left join ods_v.mm_descodigosegmento seg on trim(subseggen.codsegmento)=trim(seg.codsegmento)
) select a.*, c.codsubsegmento, c.dessubsegmento, c.codsegmento, c.dessegmento
  from tmp_ingrestrc_evals a
  left join ods_v.md_cliente b on a.codclavecic = b.codclavecic
  left join tmp_ingrestrc_segmento_aux c on trim(b.codsubsegmento) = trim(c.codsubsegmento);

-- var lugar de residencia mas actual
drop table tmp_ingrestrc_lugarresidencia_aux2;
create table tmp_ingrestrc_lugarresidencia_aux2 tablespace d_aml_99 as
with tmp_ingrestrc_lugarresidencia_aux as (
  select codclavecic,max(numdir) as maxnumdir
  from ods_v.mm_direccioncliente
  where
  tipdir in ('D')
  group by codclavecic
) select  distinct b.codclavecic, b.tipdir, c.codubigeo, b.coddistrito, c.descoddistrito, c.codprovincia, d.descodprovincia, d.coddepartamento, e.descoddepartamento
  from tmp_ingrestrc_segmento a
  left join ods_v.mm_direccioncliente b on a.codclavecic = b.codclavecic
  inner join tmp_ingrestrc_lugarresidencia_aux x on b.codclavecic = x.codclavecic and b.numdir = x.maxnumdir
  left join ods_v.mm_distrito c on b.coddistrito = c.coddistrito
  left join ods_v.mm_provincia d on c.codprovincia = d.codprovincia
  left join ods_v.mm_departamento e on d.coddepartamento = e.coddepartamento;

drop table tmp_ingrestrc_lugarresidencia;
create table tmp_ingrestrc_lugarresidencia tablespace d_aml_99 as
select a.*, b.tipdir, b.codubigeo, b.coddistrito, b.descoddistrito, b.codprovincia, b.descodprovincia, b.coddepartamento, b.descoddepartamento
from tmp_ingrestrc_segmento a
left join tmp_ingrestrc_lugarresidencia_aux2 b on a.codclavecic = b.codclavecic;

--var nacionalidad
drop table tmp_ingrestrc_nacionalidad;
create table tmp_ingrestrc_nacionalidad tablespace d_aml_99 as
with tmp_ingrestrc_nacionalidad_pn as (
select distinct a.codclavecic, a.tipper, trim(c.codpaisnacionalidad) as codpaisnacionalidad, trim(d.descodpaisnacionalidad) as descodpaisnacionalidad,
case when trim(c.codpaisnacionalidad) = 'PER' then 0
     when c.codpaisnacionalidad is not null and trim(c.codpaisnacionalidad) <> 'PER' then 1
else null end as flgnacionalidad
from tmp_ingrestrc_lugarresidencia a
inner join ods_v.md_cliente b on a.codclavecic = b.codclavecic
left join ods_v.md_personanatural c on b.codclavecic = c.codclavecic
left join ods_v.mm_descodigopaisnacionalidad d on c.codpaisnacionalidad = d.codpaisnacionalidad
where a.tipper = 'P'
),tmp_ingrestrc_nacionalidad_pj as (
select distinct a.codclavecic, a.tipper, 'PER' as codpaisnacionalidad, 'PERU' as descodpaisnacionalidad, 0 as flgnacionalidad
from tmp_ingrestrc_lugarresidencia a
inner join ods_v.mm_direccioncliente c on a.codclavecic = c.codclavecic
where a.tipper = 'E'
)select a.*,
case when a.tipper = 'P' then b.codpaisnacionalidad else c.codpaisnacionalidad end as codpaisnacionalidad,
case when a.tipper = 'P' then b.descodpaisnacionalidad else c.descodpaisnacionalidad end as descodpaisnacionalidad,
case when a.tipper = 'P' then b.flgnacionalidad else c.flgnacionalidad end as flgnacionalidad
from tmp_ingrestrc_lugarresidencia a
left join tmp_ingrestrc_nacionalidad_pn b on a.codclavecic = b.codclavecic
left join tmp_ingrestrc_nacionalidad_pj c on a.codclavecic = c.codclavecic;

--variables de comportamiento: mto_ingresos_mes, ctd_ingresos_mes
drop table tmp_ingrestrc_varcomportamiento;
create table tmp_ingrestrc_varcomportamiento tablespace d_aml_99 as
with tmp_ingrestrc_varcomp as (
  select periodo, codclavecicbeneficiario as codclavecic,
  sum(mtodolarizado) as mto_ingresos_mes,
  count(periodo) as ctd_ingresos_mes
  from tmp_ingrestrc_trxs_total_vf_m
  group by periodo, codclavecicbeneficiario
)select a.*,b.mto_ingresos_mes,b.ctd_ingresos_mes
from tmp_ingrestrc_nacionalidad a
left join tmp_ingrestrc_varcomp b on a.periodo = b.periodo and a.codclavecic = b.codclavecic;

--perfil total
drop table tmp_ingrestrc_perfi1;
create table tmp_ingrestrc_perfi1 tablespace d_aml_99 as
with tmp_ingrestrc_perfi1_aux as (
     select periodo, codclavecicbeneficiario as codclavecic, sum(mtodolarizado) as mto_ingresos
     from tmp_ingrestrc_trxs_total_vf_m
     group by periodo, codclavecicbeneficiario
) select  a.codclavecic,a.periodo as numperiodo,b.periodo,
  months_between(to_date(a.periodo,'yyyymm'),to_date(b.periodo,'yyyymm')) meses,
  case when b.mto_ingresos is null then 0 else b.mto_ingresos end mto_ingresos
  from tmp_ingrestrc_perfi1_aux a
  inner join tmp_ingrestrc_perfi1_aux b on a.codclavecic=b.codclavecic;

drop table tmp_ingrestrc_perfi2;
create table tmp_ingrestrc_perfi2 tablespace d_aml_99 as
select numperiodo,codclavecic,mto_ingresos
from tmp_ingrestrc_perfi1 a
where numperiodo=periodo;

drop table tmp_ingrestrc_perfi3;
create table tmp_ingrestrc_perfi3 tablespace d_aml_99 as
with temp_tab as(
  select numperiodo,codclavecic,
  avg(nullif(mto_ingresos,0)) as media_depo,stddev(nullif(mto_ingresos,0)) as desv_depo
  from tmp_ingrestrc_perfi1
  where meses<=6 and meses>=1
  group by numperiodo,codclavecic
) select a.*,
  round(nvl(b.media_depo,0),2) media_ingresos,
  round(nvl(b.desv_depo,0),2) desv_ingresos
  from tmp_ingrestrc_perfi2 a
  left join temp_tab b on (a.numperiodo=b.numperiodo and a.codclavecic=b.codclavecic);

-- creación el flg perfil total en tabla cliente mes: flg_perfil_ingresos_3ds
drop table tmp_ingrestrc_perfilingresos;
create table tmp_ingrestrc_perfilingresos tablespace d_aml_99 as
select  a.*, b.media_ingresos, b.desv_ingresos,
case when b.media_ingresos <> 0 and b.desv_ingresos <> 0 and b.media_ingresos+3*b.desv_ingresos<b.mto_ingresos then 1 else 0 end flg_perfil_ingresos_3ds
from   tmp_ingrestrc_varcomportamiento a
left join tmp_ingrestrc_perfi3 b on (a.periodo=b.numperiodo and a.codclavecic=b.codclavecic)
where periodo = to_number(to_char(add_months(sysdate, -6),'yyyymm'));

--mtos redondos :  max_ctdmtosredondos,sum_mtosredondos
drop table tmp_ingrestrc_mtosredondos;
create table tmp_ingrestrc_mtosredondos tablespace d_aml_99 as
with tmp_ingrestrc_mtosredondos_1 as (
  select a.*,
  floor(mtotransaccion) as mtotransaccion_sindecimal, case when mtotransaccion=floor(a.mtotransaccion) then 1 else 0 end flgredondo
  from tmp_ingrestrc_trxs_total_vf_m a
),tmp_ingrestrc_mtosredondos_2 as (
  select periodo,codclavecicbeneficiario as codclavecic,mtotransaccion,
  sum(flgredondo) as ctdredondo,
  sum(case when flgredondo = 1 then mtodolarizado else 0 end) as summtoredondo
  from tmp_ingrestrc_mtosredondos_1
  group by periodo, codclavecicbeneficiario, mtotransaccion
),tmp_ingrestrc_mtosredondos_3 as (
  select periodo,codclavecic,max(ctdredondo) as max_ctdmtosredondos
  from tmp_ingrestrc_mtosredondos_2
  group by periodo, codclavecic
),tmp_ingrestrc_mtosredondos_4 as (
  select periodo,codclavecic,sum(summtoredondo) as sum_mtosredondos
  from tmp_ingrestrc_mtosredondos_2
  group by periodo, codclavecic
)select a.*,
case when b.max_ctdmtosredondos is not null then b.max_ctdmtosredondos else 0 end max_ctdmtosredondos,
case when c.sum_mtosredondos is not null then c.sum_mtosredondos else 0 end sum_mtosredondos
from tmp_ingrestrc_perfilingresos a
left join tmp_ingrestrc_mtosredondos_3 b on a.periodo = b.periodo and a.codclavecic = b.codclavecic
left join tmp_ingrestrc_mtosredondos_4 c on a.periodo = c.periodo and a.codclavecic = c.codclavecic;

--mtos repetidos max
drop table tmpctds;
create table tmpctds tablespace d_aml_99 as
select periodo,codclavecicbeneficiario as codclavecic,mtotransaccion,count(*) as ctd
from tmp_ingrestrc_trxs_total_vf_m
group by periodo,codclavecicbeneficiario,mtotransaccion;

drop table tmpctdsmax;
create table tmpctdsmax tablespace d_aml_99 as
select periodo,codclavecic,max(ctd) as max_ctd
from tmpctds
group by periodo,codclavecic;

--sumamtos ctdmax
drop table tmpctdsycdtsmax;
create table tmpctdsycdtsmax tablespace d_aml_99 as
select a.*, b.max_ctd
from tmpctds a
inner join tmpctdsmax b on a.periodo = b.periodo and a.codclavecic = b.codclavecic and a.ctd = b.max_ctd
order by b.max_ctd desc;

drop table tmpmaxsnorepetidos;
create table tmpmaxsnorepetidos tablespace d_aml_99 as
with tmpx as (
  select periodo, codclavecic, ctd as ctdmaxima, count(*) as ctdmaximos
  from (
  tmpctdsycdtsmax
  )
  group by periodo, codclavecic, ctd
  having count(*) <= 1
)
select b.*, a.mtotransaccion
from tmpctdsycdtsmax a
inner join tmpx b on a.periodo = b.periodo and a.codclavecic = b.codclavecic and a.max_ctd = b.ctdmaxima;

drop table tmpmaxsrepetidos;
create table tmpmaxsrepetidos tablespace d_aml_99 as
select periodo, codclavecic, ctd as ctdmaxima, count(*) as ctdmaximos
from (
tmpctdsycdtsmax
)
group by periodo, codclavecic, ctd
having count(*) > 1;

drop table tmpmaxsrepetidosunicos;
create table tmpmaxsrepetidosunicos tablespace d_aml_99 as
with tmpy as (
  select a.*, b.ctdmaximos
  from tmpctdsycdtsmax a
  inner join tmpmaxsrepetidos b on a.periodo = b.periodo and a.codclavecic = b.codclavecic and a.max_ctd = b.ctdmaxima
  order by a.periodo, a.codclavecic, a.max_ctd
)
select periodo, codclavecic, max_ctd as ctdmaxima, ctdmaximos, max(mtotransaccion) as mtomaxdemaxrepetidos
from tmpy
group by periodo, codclavecic, max_ctd, ctdmaximos;

drop table tmpclientesmtosmaximosunicos;
create table tmpclientesmtosmaximosunicos tablespace d_aml_99 as
select periodo, codclavecic, ctdmaxima, ctdmaximos, mtomaxdemaxrepetidos from tmpmaxsrepetidosunicos union all
select periodo, codclavecic, ctdmaxima, ctdmaximos, mtotransaccion  from tmpmaxsnorepetidos;

drop table tmp_ingrestrc_mtosmaximosrepetidos_aux;
create table tmp_ingrestrc_mtosmaximosrepetidos_aux tablespace d_aml_99 as
select a.periodo, a.codclavecic, a.ctdmaxima,sum(b.mtodolarizado) as mto_maximosrepetidos
from tmpclientesmtosmaximosunicos a
left join tmp_ingrestrc_trxs_total_vf_m b on a.periodo = b.periodo and a.codclavecic = b.codclavecicbeneficiario and a.mtomaxdemaxrepetidos = b.mtotransaccion
group by a.periodo, a.codclavecic, a.ctdmaxima;

--mtomaxdemaxrepetidos ,ctmaxima, mto_maximosrepetidos,
drop table tmp_ingrestrc_mtosmaximosrepetidos;
create table tmp_ingrestrc_mtosmaximosrepetidos tablespace d_aml_99 as
select a.*,
case when b.ctdmaxima is null then 0 else b.ctdmaxima  end ctdmaxima,
case when b.mto_maximosrepetidos is null then 0 else b.mto_maximosrepetidos  end mto_maximosrepetidos
from tmp_ingrestrc_mtosredondos a
left join tmp_ingrestrc_mtosmaximosrepetidos_aux b on a.periodo = b.periodo and a.codclavecic = b.codclavecic ;

--mtos proximos
drop table tmp_ingrestrc_mtosyctdsproximos_aux;
create table tmp_ingrestrc_mtosyctdsproximos_aux tablespace d_aml_99 as
select a.periodo, a.codclavecic, a.mtomaxdemaxrepetidos,
sum(case when a.mtomaxdemaxrepetidos*0.9 < b.mtotransaccion and b.mtotransaccion < a.mtomaxdemaxrepetidos*1.1 then b.mtodolarizado else 0 end) as mto_conotrosproximos,
sum(case when a.mtomaxdemaxrepetidos*0.9 < b.mtotransaccion and b.mtotransaccion < a.mtomaxdemaxrepetidos*1.1 then 1 else 0 end) as ctd_conotrosproximos
from tmpclientesmtosmaximosunicos a
left join tmp_ingrestrc_trxs_total_vf_m b on a.periodo = b.periodo and a.codclavecic = b.codclavecicbeneficiario
group by a.periodo, a.codclavecic, a.mtomaxdemaxrepetidos;

drop table tmp_ingrestrc_mtosyctdsproximos;
create table tmp_ingrestrc_mtosyctdsproximos tablespace d_aml_99 as
select a.*,
case when b.mtomaxdemaxrepetidos is null then 0 else b.mtomaxdemaxrepetidos  end mtomaxdemaxrepetidos,
case when b.mto_conotrosproximos is null then 0 else b.mto_conotrosproximos  end mto_conotrosproximos,
case when b.ctd_conotrosproximos is null then 0 else b.ctd_conotrosproximos  end ctd_conotrosproximos
from tmp_ingrestrc_mtosmaximosrepetidos a
left join tmp_ingrestrc_mtosyctdsproximos_aux b on a.periodo = b.periodo and a.codclavecic = b.codclavecic ;

--tablon final mes 6
drop table tmp_ingrestrc_mtosyctdsproximos_tablon_m6;
create table tmp_ingrestrc_mtosyctdsproximos_tablon_m6 tablespace d_aml_99 as
select * from tmp_ingrestrc_mtosyctdsproximos;

---- ** MES 07 - Abril23 **-----

--Extraer las trx historica de los 7 ultimos meses del mes analisis
drop table tmp_ingrestrc_trxs_total_vf_m;
create table tmp_ingrestrc_trxs_total_vf_m tablespace d_aml_99 as
select  * from  tmp_ingrestrc_trxs_total_vf
where periodo between  to_number(to_char(add_months(sysdate, -13),'yyyymm')) and  to_number(to_char(add_months(sysdate, -7),'yyyymm'));

--Extraer el mes de analisis
drop table tmp_ingrestrc_universo_cli_m;
create table tmp_ingrestrc_universo_cli_m tablespace d_aml_99 as
select  * from  tmp_ingrestrc_universo_cli
where periodo = to_number(to_char(add_months(sysdate, -7),'yyyymm'));

--edad
drop table tmp_ingrestrc_edad;
create table tmp_ingrestrc_edad tablespace d_aml_99 as
with tmp_proc_edad_ppnn_aux as
( select a.codclavecic,a.periodo,c.fecnacimiento, floor(months_between(to_date(to_char(periodo||'01'),'yyyymmdd'), c.fecnacimiento) /12) as edad
  from tmp_ingrestrc_universo_cli_m a
  inner join ods_v.md_cliente b on a.codclavecic = b.codclavecic
  left join ods_v.md_personanatural c on a.codclavecic = c.codclavecic
  where trim(b.tipper) = 'P'
),tmp_proc_edad_ppjj_aux as
(
  select a.codclavecic,a.periodo,c.fecconstitucion, floor(months_between(to_date(to_char(periodo||'01'),'yyyymmdd'), c.fecconstitucion) /12) as edad
  from tmp_ingrestrc_universo_cli_m a
  inner join ods_v.md_cliente b on a.codclavecic = b.codclavecic
  left join ods_v.mm_empresa c on a.codclavecic = c.codclavecic
  where trim(b.tipper) = 'E'
)
select a.periodo, a.codclavecic, case when trim(x.tipper) = 'P' then b.edad else case when trim(x.tipper) = 'E' then c.edad else null end end as edad
  from tmp_ingrestrc_universo_cli_m a
  left join ods_v.md_cliente x on a.codclavecic = x.codclavecic
  left join tmp_proc_edad_ppnn_aux b on a.periodo = b.periodo and a.codclavecic = b.codclavecic
  left join tmp_proc_edad_ppjj_aux c on a.periodo = c.periodo and a.codclavecic = c.codclavecic;

--tipper
drop table tmp_ingrestrc_tipper;
create table tmp_ingrestrc_tipper tablespace d_aml_99 as
select a.*, b.tipper
from tmp_ingrestrc_edad a
inner join ods_v.md_cliente b on a.codclavecic = b.codclavecic;

--antiguedad cliente
drop table tmp_ingrestrc_antiguedad;
create table tmp_ingrestrc_antiguedad tablespace d_aml_99 as
with tmp_proc_antg_fecapertura as
( select codclavecic,min(t.fecapertura) as fecapertura
  from ( select distinct codclavecic,fecapertura from ods_v.md_prestamo
         union all
         select distinct codclavecic,fecapertura from ods_v.md_impac
         union all
         select distinct codclavecic,fecapertura from ods_v.md_saving
         union all
         select distinct codclavecic,fecapertura from ods_v.md_cuentavp) t
  group by codclavecic
),tmp_proc_antig_aux as
(select a.periodo, a.codclavecic, b.fecapertura,
  floor(months_between(to_date(to_char(periodo||'01'),'yyyymmdd'), b.fecapertura) ) as antiguedad
  from tmp_ingrestrc_tipper a
  left join tmp_proc_antg_fecapertura b on a.codclavecic = b.codclavecic
)select a.*, b.antiguedad
  from tmp_ingrestrc_tipper a
  left join tmp_proc_antig_aux b on a.periodo = b.periodo and a.codclavecic = b.codclavecic;

--flg actividad economica no definida
drop table tmp_ingrestrc_acteconomica_nodef_aux;
create table tmp_ingrestrc_acteconomica_nodef_aux tablespace d_aml_99 as
select codacteconomica,desacteconomica,'OTRSERV'as busq
from ods_v.mm_descodactividadeconomica
where upper(desacteconomica) like '%OTR%SERV%'
union
select codacteconomica,desacteconomica,'NO ESPECIF'
from ods_v.mm_descodactividadeconomica
where upper(desacteconomica) like '%NO ESPECIF%'
union
select codacteconomica,desacteconomica,'NO DISPO'
from ods_v.mm_descodactividadeconomica
where upper(desacteconomica) like '%NO DISPO%'
union
select codacteconomica,desacteconomica,'MAYOROTRPROD'
from ods_v.mm_descodactividadeconomica
where upper(desacteconomica) like '%MAYOR%OTR%PROD%'
union
select codacteconomica,desacteconomica,'MENOROTRPROD'
from ods_v.mm_descodactividadeconomica
where upper(desacteconomica) like '%MENOR%OTR%PROD%';

drop table tmp_ingrestrc_acteconomica_nodef;
create table tmp_ingrestrc_acteconomica_nodef tablespace d_aml_99 as
select a.*, b.codacteconomica, d.desacteconomica,
case
    when b.codacteconomica is null then 1
    when c.codacteconomica is not null then 1
    else 0
end flg_acteco_nodef
from tmp_ingrestrc_antiguedad a
left join ods_v.md_cliente b on a.codclavecic = b.codclavecic
left join tmp_ingrestrc_acteconomica_nodef_aux c on trim(b.codacteconomica) = trim(c.codacteconomica)
left join ods_v.mm_descodactividadeconomica d on trim(b.codacteconomica) = trim(d.codacteconomica);

--variables sapyc: np - 2
drop table tmp_ingrestrc_np_aux2;
create table tmp_ingrestrc_np_aux2 tablespace d_aml_99 as
with tmp_ingrestrc_np_aux as
( select a.*, b.idorigen, b.nbrorigen as origen, b.codtransaccion as escenario, b.nbrtransaccion as desescenario
  from (
     select a.idcaso, case when instr(a.codunicocli,'GR') > 0 then c.codclavecic else d.codclavecic end as codclavecic, a.idresultado as idresultadoeval, a.fecfineval as fecfineval, b."IDRESULTADOSUPERVISOR"
     from s61751.sapy_dmevaluacion a
     left join s61751.sapy_dminvestigacion b on a.idcaso = b.idcaso
     left join ods_v.md_empleadog94 c on trim(substr(a.codunicocli,instr(a.codunicocli,'GR')+2,6)) = trim(c.codmatricula)
     left join ods_v.md_clienteg94 d on trim(a.codunicocli) = trim(d.codunicocli)
  ) a
  left join s61751.sapy_dmalerta b on a.idcaso = b.idcaso
  where idorigen in (2)
)select a.periodo,a.codclavecic, sum(case when b.fecfineval < to_date(to_char(a.periodo||'01'),'yyyymmdd') then 1 else 0 end) as ctdnp
from tmp_ingrestrc_acteconomica_nodef a
left join tmp_ingrestrc_np_aux b on a.codclavecic = b.codclavecic
group by a.periodo,a.codclavecic;

drop table tmp_ingrestrc_np;
create table tmp_ingrestrc_np tablespace d_aml_99 as
select a.*,
case when b.ctdnp > 0 then 1 else 0 end flgnp,
case when b.ctdnp is not null then b.ctdnp else 0 end ctdnp
from tmp_ingrestrc_acteconomica_nodef a
left join tmp_ingrestrc_np_aux2 b on a.periodo = b.periodo and a.codclavecic = b.codclavecic;

--variables sapyc: lsb - 29
drop table tmp_ingrestrc_lsb_aux2;
create table tmp_ingrestrc_lsb_aux2 tablespace d_aml_99 as
with tmp_ingrestrc_lsb_aux as
( select a.*, b.idorigen, b.nbrorigen as origen, b.codtransaccion as escenario, b.nbrtransaccion as desescenario
  from (
     select a.idcaso, case when instr(a.codunicocli,'GR') > 0 then c.codclavecic else d.codclavecic end as codclavecic, a.idresultado as idresultadoeval, a.fecfineval as fecfineval, b."IDRESULTADOSUPERVISOR"
     from s61751.sapy_dmevaluacion a
     left join s61751.sapy_dminvestigacion b on a.idcaso = b.idcaso
     left join ods_v.md_empleadog94 c on trim(substr(a.codunicocli,instr(a.codunicocli,'GR')+2,6)) = trim(c.codmatricula)
     left join ods_v.md_clienteg94 d on trim(a.codunicocli) = trim(d.codunicocli)
  ) a
  left join s61751.sapy_dmalerta b on a.idcaso = b.idcaso
  where idorigen in (29)
)select a.periodo,a.codclavecic, sum(case when b.fecfineval < to_date(to_char(a.periodo||'01'),'yyyymmdd') then 1 else 0 end) as ctdlsb
from tmp_ingrestrc_np a
left join tmp_ingrestrc_lsb_aux b on a.codclavecic = b.codclavecic
group by a.periodo,a.codclavecic;

--var ctd_np_lsb
drop table tmp_ingrestrc_lsb;
create table tmp_ingrestrc_lsb tablespace d_aml_99 as
select a.*,
case when b.ctdlsb > 0 then 1 else 0 end flglsb,
case when b.ctdlsb is not null then b.ctdlsb else 0 end ctdlsb
from tmp_ingrestrc_np a
left join tmp_ingrestrc_lsb_aux2 b on a.periodo = b.periodo and a.codclavecic = b.codclavecic;

--var archivo negativo
drop table tmp_ingrestrc_archnegativo;
create table tmp_ingrestrc_archnegativo tablespace d_aml_99 as
with tmp_ingrestrc_archivonegativo_aux as (
  select distinct a.codclavecic, max(b.destipmotivonegativo) as destipmotivonegativo
  from ods_v.md_motivodetalleclinegativo a
  left join ods_v.md_destipomotivonegativo b on a.tipmotivonegativo = b.tipmotivonegativo
  inner join (
        select codclavecic, max(fecregistrodetallenegativo) as maxfecregistrodetallenegativo
        from ods_v.md_motivodetalleclinegativo
        group by codclavecic
  ) c on a.codclavecic = c.codclavecic and a.fecregistrodetallenegativo = c.maxfecregistrodetallenegativo
  where a.flghistorico = 'N' and a.tipmotivonegativo='013' and a.tipdetallemotivonegativo='001'
  group by a.codclavecic
) select a.*,
  case when b.codclavecic is not null then 1 else 0 end as flgarchivonegativo,
  b.destipmotivonegativo as destipmotivonegativo
  from tmp_ingrestrc_lsb a
  left join tmp_ingrestrc_archivonegativo_aux b on a.codclavecic = b.codclavecic;

drop table tmp_ingrestrc_ctd_nplsb;
create table tmp_ingrestrc_ctd_nplsb tablespace d_aml_99 as
select a.*,
ctdnp+ctdlsb as ctd_np_lsb
from tmp_ingrestrc_archnegativo a;

--ctd evaluaciones
drop table tmp_ingrestrc_sapyc;
create table tmp_ingrestrc_sapyc tablespace d_aml_99 as
select a.*
from (
   select a.idcaso, case when instr(a.codunicocli,'GR') > 0 then c.codclavecic else d.codclavecic end as codclavecic, a.idresultado as idresultadoeval, a.fecfineval as fecfineval, b."IDRESULTADOSUPERVISOR"
     from s61751.sapy_dmevaluacion a
     left join s61751.sapy_dminvestigacion b on a.idcaso = b.idcaso
     left join ods_v.md_empleadog94 c on trim(substr(a.codunicocli,instr(a.codunicocli,'GR')+2,6)) = trim(c.codmatricula)
     left join ods_v.md_clienteg94 d on trim(a.codunicocli) = trim(d.codunicocli)
) a;

drop table tmp_ingrestrc_evals;
create table tmp_ingrestrc_evals tablespace d_aml_99 as
with tmp_ingrestrc_evals_aux as
( select a.periodo,a.codclavecic, sum(case when b.fecfineval < to_date(to_char(a.periodo||'01'),'yyyymmdd') then 1 else 0 end) as ctdeval
  from tmp_ingrestrc_ctd_nplsb a
  left join tmp_ingrestrc_sapyc b on a.codclavecic = b.codclavecic
  group by a.periodo,a.codclavecic
) select a.*,
  case when b.ctdeval is not null then b.ctdeval else 0 end as ctdeval
  from tmp_ingrestrc_ctd_nplsb a
  left join tmp_ingrestrc_evals_aux b on a.periodo = b.periodo and a.codclavecic = b.codclavecic;

--var segmento del cliente
drop table tmp_ingrestrc_segmento;
create table tmp_ingrestrc_segmento tablespace d_aml_99 as
with tmp_ingrestrc_segmento_aux as (
  select distinct trim(subseg.codsubsegmento) as codsubsegmento, subseg.dessubsegmento, trim(seg.codsegmento) as codsegmento, seg.dessegmento
  from ods_v.mm_descodigosubsegmento subseg
  left join ods_v.mm_descodsubseggen subseggen on trim(subseg.codsubseggeneral)=trim(subseggen.codsubseggeneral)
  left join ods_v.mm_descodigosegmento seg on trim(subseggen.codsegmento)=trim(seg.codsegmento)
) select a.*, c.codsubsegmento, c.dessubsegmento, c.codsegmento, c.dessegmento
  from tmp_ingrestrc_evals a
  left join ods_v.md_cliente b on a.codclavecic = b.codclavecic
  left join tmp_ingrestrc_segmento_aux c on trim(b.codsubsegmento) = trim(c.codsubsegmento);

-- var lugar de residencia mas actual
drop table tmp_ingrestrc_lugarresidencia_aux2;
create table tmp_ingrestrc_lugarresidencia_aux2 tablespace d_aml_99 as
with tmp_ingrestrc_lugarresidencia_aux as (
  select codclavecic,max(numdir) as maxnumdir
  from ods_v.mm_direccioncliente
  where
  tipdir in ('D')
  group by codclavecic
) select  distinct b.codclavecic, b.tipdir, c.codubigeo, b.coddistrito, c.descoddistrito, c.codprovincia, d.descodprovincia, d.coddepartamento, e.descoddepartamento
  from tmp_ingrestrc_segmento a
  left join ods_v.mm_direccioncliente b on a.codclavecic = b.codclavecic
  inner join tmp_ingrestrc_lugarresidencia_aux x on b.codclavecic = x.codclavecic and b.numdir = x.maxnumdir
  left join ods_v.mm_distrito c on b.coddistrito = c.coddistrito
  left join ods_v.mm_provincia d on c.codprovincia = d.codprovincia
  left join ods_v.mm_departamento e on d.coddepartamento = e.coddepartamento;

drop table tmp_ingrestrc_lugarresidencia;
create table tmp_ingrestrc_lugarresidencia tablespace d_aml_99 as
select a.*, b.tipdir, b.codubigeo, b.coddistrito, b.descoddistrito, b.codprovincia, b.descodprovincia, b.coddepartamento, b.descoddepartamento
from tmp_ingrestrc_segmento a
left join tmp_ingrestrc_lugarresidencia_aux2 b on a.codclavecic = b.codclavecic;

--var nacionalidad
drop table tmp_ingrestrc_nacionalidad;
create table tmp_ingrestrc_nacionalidad tablespace d_aml_99 as
with tmp_ingrestrc_nacionalidad_pn as (
  select distinct a.codclavecic, a.tipper, trim(c.codpaisnacionalidad) as codpaisnacionalidad, trim(d.descodpaisnacionalidad) as descodpaisnacionalidad,
  case when trim(c.codpaisnacionalidad) = 'PER' then 0
       when c.codpaisnacionalidad is not null and trim(c.codpaisnacionalidad) <> 'PER' then 1
       else null end as flgnacionalidad
  from tmp_ingrestrc_lugarresidencia a
    inner join ods_v.md_cliente b on a.codclavecic = b.codclavecic
    left join ods_v.md_personanatural c on b.codclavecic = c.codclavecic
    left join ods_v.mm_descodigopaisnacionalidad d on c.codpaisnacionalidad = d.codpaisnacionalidad
    where a.tipper = 'P'
),tmp_ingrestrc_nacionalidad_pj as (
  select distinct a.codclavecic, a.tipper, 'PER' as codpaisnacionalidad, 'PERU' as descodpaisnacionalidad, 0 as flgnacionalidad
  from tmp_ingrestrc_lugarresidencia a
  inner join ods_v.mm_direccioncliente c on a.codclavecic = c.codclavecic
  where a.tipper = 'E'
)select a.*,
case when a.tipper = 'P' then b.codpaisnacionalidad else c.codpaisnacionalidad end as codpaisnacionalidad,
case when a.tipper = 'P' then b.descodpaisnacionalidad else c.descodpaisnacionalidad end as descodpaisnacionalidad,
case when a.tipper = 'P' then b.flgnacionalidad else c.flgnacionalidad end as flgnacionalidad
from tmp_ingrestrc_lugarresidencia a
left join tmp_ingrestrc_nacionalidad_pn b on a.codclavecic = b.codclavecic
left join tmp_ingrestrc_nacionalidad_pj c on a.codclavecic = c.codclavecic;

--variables de comportamiento: mto_ingresos_mes, ctd_ingresos_mes
drop table tmp_ingrestrc_varcomportamiento;
create table tmp_ingrestrc_varcomportamiento tablespace d_aml_99 as
with tmp_ingrestrc_varcomp as (
  select periodo, codclavecicbeneficiario as codclavecic,
  sum(mtodolarizado) as mto_ingresos_mes,
  count(periodo) as ctd_ingresos_mes
  from tmp_ingrestrc_trxs_total_vf_m
  group by periodo, codclavecicbeneficiario
)
select a.*,b.mto_ingresos_mes,b.ctd_ingresos_mes
from tmp_ingrestrc_nacionalidad a
left join tmp_ingrestrc_varcomp b on a.periodo = b.periodo and a.codclavecic = b.codclavecic;

--perfil total
drop table tmp_ingrestrc_perfi1;
create table tmp_ingrestrc_perfi1 tablespace d_aml_99 as
with tmp_ingrestrc_perfi1_aux as (
    select periodo, codclavecicbeneficiario as codclavecic, sum(mtodolarizado) as mto_ingresos
    from tmp_ingrestrc_trxs_total_vf_m
    group by periodo, codclavecicbeneficiario
) select  a.codclavecic,a.periodo as numperiodo,b.periodo,
  months_between(to_date(a.periodo,'yyyymm'),to_date(b.periodo,'yyyymm')) meses,
  case when b.mto_ingresos is null then 0 else b.mto_ingresos end mto_ingresos
  from tmp_ingrestrc_perfi1_aux a
  inner join tmp_ingrestrc_perfi1_aux b on a.codclavecic=b.codclavecic;

drop table tmp_ingrestrc_perfi2;
create table tmp_ingrestrc_perfi2 tablespace d_aml_99 as
select numperiodo,codclavecic,mto_ingresos
from tmp_ingrestrc_perfi1 a
where numperiodo=periodo;

drop table tmp_ingrestrc_perfi3;
create table tmp_ingrestrc_perfi3 tablespace d_aml_99 as
with temp_tab as(
  select numperiodo,codclavecic,
  avg(nullif(mto_ingresos,0)) as media_depo,stddev(nullif(mto_ingresos,0)) as desv_depo
  from tmp_ingrestrc_perfi1
  where meses<=6 and meses>=1
  group by numperiodo,codclavecic
) select a.*,
  round(nvl(b.media_depo,0),2) media_ingresos,
  round(nvl(b.desv_depo,0),2) desv_ingresos
  from tmp_ingrestrc_perfi2 a
  left join temp_tab b on (a.numperiodo=b.numperiodo and a.codclavecic=b.codclavecic);

-- creación el flg perfil total en tabla cliente mes: flg_perfil_ingresos_3ds
drop table tmp_ingrestrc_perfilingresos;
create table tmp_ingrestrc_perfilingresos tablespace d_aml_99 as
select  a.*, b.media_ingresos, b.desv_ingresos,
case when b.media_ingresos <> 0 and b.desv_ingresos <> 0 and b.media_ingresos+3*b.desv_ingresos<b.mto_ingresos then 1 else 0 end flg_perfil_ingresos_3ds
from   tmp_ingrestrc_varcomportamiento a
left join tmp_ingrestrc_perfi3 b on (a.periodo=b.numperiodo and a.codclavecic=b.codclavecic)
where periodo = to_number(to_char(add_months(sysdate, -7),'yyyymm'));

--mtos redondos :  max_ctdmtosredondos,sum_mtosredondos
drop table tmp_ingrestrc_mtosredondos;
create table tmp_ingrestrc_mtosredondos tablespace d_aml_99 as
with tmp_ingrestrc_mtosredondos_1 as (
  select a.*,
  floor(mtotransaccion) as mtotransaccion_sindecimal, case when mtotransaccion=floor(a.mtotransaccion) then 1 else 0 end flgredondo
  from tmp_ingrestrc_trxs_total_vf_m a
),tmp_ingrestrc_mtosredondos_2 as (
  select periodo,codclavecicbeneficiario as codclavecic,mtotransaccion,
  sum(flgredondo) as ctdredondo,
  sum(case when flgredondo = 1 then mtodolarizado else 0 end) as summtoredondo
  from tmp_ingrestrc_mtosredondos_1
  group by periodo, codclavecicbeneficiario, mtotransaccion
),tmp_ingrestrc_mtosredondos_3 as (
  select periodo,codclavecic,max(ctdredondo) as max_ctdmtosredondos
  from tmp_ingrestrc_mtosredondos_2
  group by periodo, codclavecic
),tmp_ingrestrc_mtosredondos_4 as (
  select periodo,codclavecic,sum(summtoredondo) as sum_mtosredondos
  from tmp_ingrestrc_mtosredondos_2
  group by periodo, codclavecic
)select a.*,
case when b.max_ctdmtosredondos is not null then b.max_ctdmtosredondos else 0 end max_ctdmtosredondos,
case when c.sum_mtosredondos is not null then c.sum_mtosredondos else 0 end sum_mtosredondos
from tmp_ingrestrc_perfilingresos a
left join tmp_ingrestrc_mtosredondos_3 b on a.periodo = b.periodo and a.codclavecic = b.codclavecic
left join tmp_ingrestrc_mtosredondos_4 c on a.periodo = c.periodo and a.codclavecic = c.codclavecic;

--mtos repetidos max
drop table tmpctds;
create table tmpctds tablespace d_aml_99 as
select periodo,codclavecicbeneficiario as codclavecic,mtotransaccion,count(*) as ctd
from tmp_ingrestrc_trxs_total_vf_m
group by periodo,codclavecicbeneficiario,mtotransaccion;

drop table tmpctdsmax;
create table tmpctdsmax tablespace d_aml_99 as
select periodo,codclavecic,max(ctd) as max_ctd
from tmpctds
group by periodo,codclavecic;

--sumamtos ctdmax
drop table tmpctdsycdtsmax;
create table tmpctdsycdtsmax tablespace d_aml_99 as
select a.*, b.max_ctd
from tmpctds a
inner join tmpctdsmax b on a.periodo = b.periodo and a.codclavecic = b.codclavecic and a.ctd = b.max_ctd
order by b.max_ctd desc;

drop table tmpmaxsnorepetidos;
create table tmpmaxsnorepetidos tablespace d_aml_99 as
with tmpx as (
  select periodo, codclavecic, ctd as ctdmaxima, count(*) as ctdmaximos
  from (
  tmpctdsycdtsmax
  )
  group by periodo, codclavecic, ctd
  having count(*) <= 1
)select b.*, a.mtotransaccion
from tmpctdsycdtsmax a
inner join tmpx b on a.periodo = b.periodo and a.codclavecic = b.codclavecic and a.max_ctd = b.ctdmaxima;

drop table tmpmaxsrepetidos;
create table tmpmaxsrepetidos tablespace d_aml_99 as
select periodo, codclavecic, ctd as ctdmaxima, count(*) as ctdmaximos
from (
tmpctdsycdtsmax
)
group by periodo, codclavecic, ctd
having count(*) > 1;

drop table tmpmaxsrepetidosunicos;
create table tmpmaxsrepetidosunicos tablespace d_aml_99 as
with tmpy as (
  select a.*, b.ctdmaximos
  from tmpctdsycdtsmax a
  inner join tmpmaxsrepetidos b on a.periodo = b.periodo and a.codclavecic = b.codclavecic and a.max_ctd = b.ctdmaxima
  order by a.periodo, a.codclavecic, a.max_ctd
)select periodo, codclavecic, max_ctd as ctdmaxima, ctdmaximos, max(mtotransaccion) as mtomaxdemaxrepetidos
from tmpy
group by periodo, codclavecic, max_ctd, ctdmaximos;

drop table tmpclientesmtosmaximosunicos;
create table tmpclientesmtosmaximosunicos tablespace d_aml_99 as
select periodo, codclavecic, ctdmaxima, ctdmaximos, mtomaxdemaxrepetidos from tmpmaxsrepetidosunicos union all
select periodo, codclavecic, ctdmaxima, ctdmaximos, mtotransaccion  from tmpmaxsnorepetidos;

drop table tmp_ingrestrc_mtosmaximosrepetidos_aux;
create table tmp_ingrestrc_mtosmaximosrepetidos_aux tablespace d_aml_99 as
select a.periodo, a.codclavecic, a.ctdmaxima,sum(b.mtodolarizado) as mto_maximosrepetidos
from tmpclientesmtosmaximosunicos a
left join tmp_ingrestrc_trxs_total_vf_m b on a.periodo = b.periodo and a.codclavecic = b.codclavecicbeneficiario and a.mtomaxdemaxrepetidos = b.mtotransaccion
group by a.periodo, a.codclavecic, a.ctdmaxima;

--mtomaxdemaxrepetidos ,ctmaxima, mto_maximosrepetidos,
drop table tmp_ingrestrc_mtosmaximosrepetidos;
create table tmp_ingrestrc_mtosmaximosrepetidos tablespace d_aml_99 as
select a.*,
case when b.ctdmaxima is null then 0 else b.ctdmaxima  end ctdmaxima,
case when b.mto_maximosrepetidos is null then 0 else b.mto_maximosrepetidos  end mto_maximosrepetidos
from tmp_ingrestrc_mtosredondos a
left join tmp_ingrestrc_mtosmaximosrepetidos_aux b on a.periodo = b.periodo and a.codclavecic = b.codclavecic ;

--mtos proximos
drop table tmp_ingrestrc_mtosyctdsproximos_aux;
create table tmp_ingrestrc_mtosyctdsproximos_aux tablespace d_aml_99 as
select a.periodo, a.codclavecic, a.mtomaxdemaxrepetidos,
sum(case when a.mtomaxdemaxrepetidos*0.9 < b.mtotransaccion and b.mtotransaccion < a.mtomaxdemaxrepetidos*1.1 then b.mtodolarizado else 0 end) as mto_conotrosproximos,
sum(case when a.mtomaxdemaxrepetidos*0.9 < b.mtotransaccion and b.mtotransaccion < a.mtomaxdemaxrepetidos*1.1 then 1 else 0 end) as ctd_conotrosproximos
from tmpclientesmtosmaximosunicos a
left join tmp_ingrestrc_trxs_total_vf_m b on a.periodo = b.periodo and a.codclavecic = b.codclavecicbeneficiario
group by a.periodo, a.codclavecic, a.mtomaxdemaxrepetidos;

drop table tmp_ingrestrc_mtosyctdsproximos;
create table tmp_ingrestrc_mtosyctdsproximos tablespace d_aml_99 as
select a.*,
case when b.mtomaxdemaxrepetidos is null then 0 else b.mtomaxdemaxrepetidos  end mtomaxdemaxrepetidos,
case when b.mto_conotrosproximos is null then 0 else b.mto_conotrosproximos  end mto_conotrosproximos,
case when b.ctd_conotrosproximos is null then 0 else b.ctd_conotrosproximos  end ctd_conotrosproximos
from tmp_ingrestrc_mtosmaximosrepetidos a
left join tmp_ingrestrc_mtosyctdsproximos_aux b on a.periodo = b.periodo and a.codclavecic = b.codclavecic ;

--tablon final mes 7
drop table tmp_ingrestrc_mtosyctdsproximos_tablon_m7;
create table tmp_ingrestrc_mtosyctdsproximos_tablon_m7 tablespace d_aml_99 as
select * from tmp_ingrestrc_mtosyctdsproximos;

--tablon final union
drop table tmp_ingrestrc_mtosyctdsproximos_tablon;
create table tmp_ingrestrc_mtosyctdsproximos_tablon tablespace d_aml_99 as
select * from tmp_ingrestrc_mtosyctdsproximos_tablon_m1
union all
select * from tmp_ingrestrc_mtosyctdsproximos_tablon_m2
union all
select * from tmp_ingrestrc_mtosyctdsproximos_tablon_m3
union all
select * from tmp_ingrestrc_mtosyctdsproximos_tablon_m4
union all
select * from tmp_ingrestrc_mtosyctdsproximos_tablon_m5
union all
select * from tmp_ingrestrc_mtosyctdsproximos_tablon_m6
union all
select * from tmp_ingrestrc_mtosyctdsproximos_tablon_m7;

commit;
quit;