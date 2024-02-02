--PARAMETRO DE CREDENCIALES
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

var intervalo_1 number 
exec :intervalo_1 := to_number(&2);

select :intervalo_1 from dual;
/*************************************************************************************************
****************************** ESCENARIO YAPE ***************************
*************************************************************************************************/

alter session disable parallel query;

truncate table tmp_yape_prepep;
insert into tmp_yape_prepep
select c.codmes_operacion,a.codclavecic,c.hora,c.mto_operacion*tc.mtocambioaldolar as monto_ingreso,c.dia_operacion,c.codclavecic_origen,
c.tip_cuenta_destino
from tmp_yape_universo a 
inner join T26030.md_trx_yape_dac_view c on a.codclaveopecta_destino=c.codclaveopecta_destino
left join ods_v.hd_tipocambiosaldodiario tc on c.dia_operacion = tc.fectipcambio
where tc.codmoneda='0001' and c.dia_operacion between trunc(add_months(sysdate,:intervalo_1),'mm') and trunc(last_day(add_months(sysdate,:intervalo_1)))
and c.mto_operacion>0 and a.codclaveopecta_destino is not null;

--Flg relacionado
truncate table tmp_yape_pep;
insert into tmp_yape_pep
 with tmp as (
 select distinct codmes_operacion,codclavecic,sum(monto_ingreso) monto_ingreso,count(monto_ingreso) as ctd_ingreso
 from tmp_yape_prepep 
 group by codmes_operacion,codclavecic ),
 tmp2 as (
 select codclavecic,sum(mto_operacion) as mto_egr,count(mto_operacion) as ctd_egreso
 from tmp_yape_trx_egreso_ 
 where codmes_operacion= (select max(codmes_operacion) from tmp_yape_trx_egreso_)
 group by codclavecic),
 tmp3 as (
 select  a.*,b.mto_egr,b.ctd_egreso
 from tmp a 
 left join tmp2 b on a.codclavecic=b.codclavecic)
select  a.*,
case when trim(tipmarcacli) in ('p','e') then 1 else 0 end flg_pep,
case when trim(tipmarcacli) in ('s','q') then 1 else 0 end flg_pep_rel,
tipper
 from tmp3 a
 left join ods_v.md_clienteg94 b on a.codclavecic=b.codclavecic;
 
--Act economica
truncate table tmp_yape_acteco_no_definidas;
insert into tmp_yape_acteco_no_definidas
  select codacteconomica,desacteconomica,'OTRSERV'as busq 
  from ods_v.mm_descodactividadeconomica 
  where upper(desacteconomica) like '%OTR%SERV%' 
        union 
  select codacteconomica,desacteconomica,'NO ESPECIF' as busq
  from ods_v.mm_descodactividadeconomica 
  where upper(desacteconomica) like '%NO ESPECIF%' 
        union 
  select codacteconomica,desacteconomica,'NO DISPO' as busq
  from ods_v.mm_descodactividadeconomica 
  where upper(desacteconomica) like '%NO DISPO%'
         union 
  select codacteconomica,desacteconomica,'MAYOROTRPROD' as busq
  from ods_v.mm_descodactividadeconomica 
  where upper(desacteconomica) like '%MAYOR%OTR%PROD%' 
         union 
  select codacteconomica,desacteconomica,'MENOROTRPROD'  as busq
  from ods_v.mm_descodactividadeconomica 
  where upper(desacteconomica) like '%MENOR%OTR%PROD%';

truncate table tmp_yape_actecocli;
insert into tmp_yape_actecocli
   select distinct a.*,     
         case 
             when c.busq in ('NO ESPECIF','NO DISPO') then 1 
             when c.busq in ('OTRSERV') then 2
			 when c.busq in ('MAYOROTRPROD','MENOROTRPROD') then 3
             else  null
         end act_economica_gruposinteres 
  from tmp_yape_pep a
    left join ods_v.md_clienteg94 b on a.codclavecic = b.codclavecic
    left join tmp_yape_acteco_no_definidas c on b.codacteconomica = c.codacteconomica;
	
--Extraer profesion
truncate table tmp_yape_profesion;
insert into tmp_yape_profesion
select a.*, b.codprofesion, c.descodprofesion,
case when trim(c.descodprofesion) like ('%TEC%') or 
trim(b.codprofesion) in ('130','142','146','150','151','152','153','174','207','410','613','618','701','705','706','707','710','804','806','807','810','850') then 1
when trim(b.codprofesion) in ('999') then 2 
when trim(b.codprofesion) is null then null
else 3 end catprofesion
from tmp_yape_actecocli a
left join ods_v.mm_personanatural b on a.codclavecic=b.codclavecic
left join ods_v.mm_descodigoprofesion c on trim(b.codprofesion)=trim(c.codprofesion)
where tipper='E'
  union
select a.*, b.codprofesion, c.descodprofesion,
case when trim(c.descodprofesion) like ('%TEC%') or 
trim(b.codprofesion) in ('130','142','146','150','151','152','153','174','207','410','613','618','701','705','706','707','710','804','806','807','810','850') then 1
when trim(b.codprofesion) in ('999') then 2 
when trim(b.codprofesion) is null then null
else 0 end catprofesion
from tmp_yape_actecocli a
left join ods_v.mm_personanatural b on a.codclavecic=b.codclavecic
left join ods_v.mm_descodigoprofesion c on trim(b.codprofesion)=trim(c.codprofesion)
where tipper='P';

truncate table tmp_md_historia;
insert into tmp_md_historia
select distinct codclavecic,fecapertura from ods_v.md_prestamo 
union all
select distinct codclavecic,fecapertura from ods_v.md_impac 
union all
select distinct codclavecic,fecapertura from ods_v.md_saving 
union all
select distinct codclavecic,fecapertura from ods_v.md_cuentavp;

--Antiguedad
truncate table tmp_yape_antiguedad;
insert into tmp_yape_antiguedad
with tmp_proc_antg_fecapertura as 
(
  select codclavecic,min(t.fecapertura) as fecapertura
  from ( select codclavecic,fecapertura  from tmp_md_historia)  t 
  group by codclavecic
),
tmp_proc_antig_aux as 
( 
select a.codmes_operacion, a.codclavecic, b.fecapertura,
  floor(months_between(to_date(to_char(codmes_operacion||'01'),'yyyymmdd'), b.fecapertura) ) as antiguedad
  from tmp_yape_pep a
  left join tmp_proc_antg_fecapertura b on a.codclavecic = b.codclavecic
)
select distinct a.*, b.fecapertura, b.antiguedad
  from tmp_yape_profesion a
  left join tmp_proc_antig_aux b on a.codmes_operacion = b.codmes_operacion and a.codclavecic = b.codclavecic;
  

---NP
truncate table tmp_yape_np_aux2;
insert into tmp_yape_np_aux2
with tmp_yape_np_aux as 
(
  select a.*, b.idorigen, b.nbrorigen , b.codtransaccion, b.nbrtransaccion
  from (
     select a.idcaso, 
     case when instr(a.codunicocli,'GR') > 0 
     then c.codclavecic else d.codclavecic end as codclavecic, a.idresultado as idresultadoeval, a.fecfineval as fecfineval, b.idresultadosupervisor
     from s61751.sapy_dmevaluacion a
     left join s61751.sapy_dminvestigacion b on a.idcaso = b.idcaso
     left join ods_v.md_empleadog94 c on trim(substr(a.codunicocli,instr(a.codunicocli,'GR')+2,6)) = trim(c.codmatricula)
     left join ods_v.md_clienteg94 d on trim(a.codunicocli) = trim(d.codunicocli)
  ) a
  left join s61751.sapy_dmalerta b on a.idcaso = b.idcaso
  where idorigen in (2)     
)
select a.codmes_operacion as codmes_operacion,a.codclavecic, sum(case when b.fecfineval < to_date(to_char(a.codmes_operacion||'01'),'yyyymmdd') then 1 else 0 end) as ctdnp
from tmp_yape_antiguedad a 
left join tmp_yape_np_aux b on a.codclavecic = b.codclavecic 
group by a.codmes_operacion,a.codclavecic;
    
truncate table tmp_yape_np;
insert into tmp_yape_np
select a.codclavecic,a.codmes_operacion,a.act_economica_gruposinteres,
case when b.ctdnp > 0 then 1 else 0 end flgnp,
case when b.ctdnp is not null then b.ctdnp else 0 end ctdnp
from tmp_yape_antiguedad a
left join tmp_yape_np_aux2 b on a.codmes_operacion = b.codmes_operacion and a.codclavecic = b.codclavecic;

--Variables sapyc: lsb - 29
truncate table tmp_yape_lsb_aux2;
insert into tmp_yape_lsb_aux2
with tmp_yape_lsb_aux as 
(
  select a.*, b.idorigen, b.nbrorigen , b.codtransaccion, b.nbrtransaccion
  from (
     select a.idcaso, 
     case when instr(a.codunicocli,'GR') > 0 
     then c.codclavecic else d.codclavecic end as codclavecic, a.idresultado as idresultadoeval, a.fecfineval as fecfineval, b.idresultadosupervisor
     from s61751.sapy_dmevaluacion a
     left join s61751.sapy_dminvestigacion b on a.idcaso = b.idcaso
     left join ods_v.md_empleadog94 c on trim(substr(a.codunicocli,instr(a.codunicocli,'GR')+2,6)) = trim(c.codmatricula)
     left join ods_v.md_clienteg94 d on trim(a.codunicocli) = trim(d.codunicocli)
  ) a
  left join s61751.sapy_dmalerta b on a.idcaso = b.idcaso
  where idorigen in (29)   
) select a.codmes_operacion ,a.codclavecic, sum(case when b.fecfineval < to_date(to_char(a.codmes_operacion||'01'),'yyyymmdd') then 1 else 0 end) as ctdlsb
from tmp_yape_actecocli a 
left join tmp_yape_lsb_aux b on a.codclavecic = b.codclavecic 
group by a.codmes_operacion,a.codclavecic;

truncate table tmp_yape_lsb;
insert into tmp_yape_lsb
select a.codclavecic,a.codmes_operacion,a.act_economica_gruposinteres,a.flgnp,a.ctdnp,
case when b.ctdlsb > 0 then 1 else 0 end flglsb,
case when b.ctdlsb is not null then b.ctdlsb else 0 end ctdlsb
from tmp_yape_np a
left join tmp_yape_lsb_aux2 b on a.codmes_operacion = b.codmes_operacion and a.codclavecic = b.codclavecic;

--Archivo negativo
truncate table tmp_yape_archnegativo;
insert into tmp_yape_archnegativo
with tmp_yape_archivonegativo_aux as (
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
  from tmp_yape_lsb a
  left join tmp_yape_archivonegativo_aux b on a.codclavecic = b.codclavecic;
  
--NP+AN+LSB  
truncate table tmp_yape_flg_ctd_nplsban;
insert into tmp_yape_flg_ctd_nplsban
select a.*, 
case when flgnp = 1 or flglsb = 1 or flgarchivonegativo = 1 then 1 else 0 end flgnplsban,
ctdnp+ctdlsb+flgarchivonegativo as ctd_an_np_lsb
from tmp_yape_archnegativo a;

--Tipo de cuenta
truncate table tmp_yape_antcta;
insert into tmp_yape_antcta
with tmp_proc_antg_fecapertura as 
(
  select codclavecic,min(t.fecha_afiliacion) as fecapertura,tip_cta
  from ( select distinct codclavecic,fecha_afiliacion,tip_cta from T26030.HD_YAPERO_VIEW )  t 
  where codclavecic is not null and codclavecic<>0
  group by codclavecic,tip_cta
),
tmp_proc_antig_aux as 
( 
select a.codmes_operacion, a.codclavecic, b.fecapertura,
  floor(months_between(to_date(to_char(codmes_operacion||'01'),'yyyymmdd'), b.fecapertura) ) as antiguedad_yape,tip_cta
  from tmp_yape_flg_ctd_nplsban a
  left join tmp_proc_antg_fecapertura b on a.codclavecic = b.codclavecic
)
select a.*,tip_cta,antiguedad_yape
  from tmp_yape_flg_ctd_nplsban a
  left join tmp_proc_antig_aux b on a.codmes_operacion = b.codmes_operacion and a.codclavecic = b.codclavecic;
  
truncate table tmp_yape_tipocuenta;
insert into tmp_yape_tipocuenta
with tmp as (
select distinct codclavecic,
case when tip_cta in ('CORRIENTE','AHORROS','BCP_CORRIENTE') then 1
else 0 end flg_cuenta_bcp,
case when tip_cta='OTROS' then 1
else 0 end flg_cuenta_otrosbancos,
case when tip_cta='YAPE_CARD' then 1
else 0 end flg_cuenta_yapecard
from tmp_yape_antcta a)
select codclavecic,sum(flg_cuenta_bcp)flg_cuenta_bcp,
sum(flg_cuenta_otrosbancos) flg_cuenta_otrosbancos,
sum(flg_cuenta_yapecard)flg_cuenta_yapecard
from tmp
group by codclavecic;

--Cantidad de ordenantes distintos----ingreso
truncate table tmp_yape_ord;
insert into tmp_yape_ord
select codmes_operacion,codclavecic,count(distinct(codclavecic_origen)) as ctd_ope_dist_ing
from tmp_yape_prepep 
group by codmes_operacion,codclavecic;

--Cantidad de ordenantes distintos-----egreso
truncate table tmp_yape_sol;
insert into tmp_yape_sol
select codmes_operacion,codclavecic,count(distinct(codclavecic_egr)) as ctd_ope_dist_egr
from tmp_yape_trx_egreso_ 
group by codmes_operacion,codclavecic;

-------------------------

--Perfil total
truncate table tmp_yape_perfi1 ;
insert into tmp_yape_perfi1
select  a.codclavecic,a.codmes_operacion as numperiodo,b.codmes_operacion,
  months_between(to_date(a.codmes_operacion,'yyyymm'),to_date(b.codmes_operacion,'yyyymm')) meses,
  case when b. monto_ingreso is null then 0 else b. monto_ingreso end  mtodolarizado
  from tmp_yape_trx_ingreso_ a 
  inner join tmp_yape_trx_ingreso_ b on a.codclavecic=b.codclavecic;

truncate table tmp_yape_perfi2 ;
insert into tmp_yape_perfi2 
select numperiodo,codclavecic, mtodolarizado
from tmp_yape_perfi1 a
where numperiodo=codmes_operacion;

truncate table tmp_yape_perfi3 ;
insert into tmp_yape_perfi3 
with temp_tab as( 
  select numperiodo,codclavecic,
  avg(nullif( mtodolarizado,0)) as media_depo,stddev(nullif( mtodolarizado,0)) as desv_depo
  from tmp_yape_perfi1
  where meses<=6 and meses>=1
  group by numperiodo,codclavecic
) select a.*,
  round(nvl(b.media_depo,0),2) media_depo,
  round(nvl(b.desv_depo,0),2) desv_depo
  from tmp_yape_perfi2 a
  left join temp_tab b on (a.numperiodo=b.numperiodo and a.codclavecic=b.codclavecic);

truncate table tmp_yape_perfildepositos ;
insert into tmp_yape_perfildepositos
select distinct  a.*,
case when b.media_depo <> 0 and b.desv_depo <> 0 and b.media_depo+3*b.desv_depo<b. mtodolarizado then 1 else 0 end flg_perfil_3ds
from   tmp_yape_flg_ctd_nplsban a 
left join tmp_yape_perfi3 b on (a.codmes_operacion=b.numperiodo and a.codclavecic=b.codclavecic);

--Ctd alertas
truncate table tmp_yape_ctdalertas ;
insert into tmp_yape_ctdalertas
with tmp as (
 select distinct b.codclavecic,idalerta, to_number(to_char(a.fecgeneracion,'yyyymm')) as periodo
 from  s61751.sapy_dmevaluacion a 
 inner join ods_v.md_empleadog94 b on substr(a.codunicocli,7,6)=b.codmatricula
 inner join s61751.sapy_dmalerta c on a.idcaso=c.idcaso
 inner join s61751.sapy_dmcaso d on a.idcaso=d.idcaso
 inner join s61751.sapy_empresa e on e.idempresa=d.idempresa
 where a.codunicocli like'%GR%' and e.nbrempresa='BCP'
 union all 
 select distinct  b.codclavecic,idalerta,to_number(to_char(a.fecgeneracion,'yyyymm')) as periodo
 from s61751.sapy_dmevaluacion a
 inner join ods_v.md_clienteg94 b on a.codunicocli=b.codunicocli
 inner join s61751.sapy_dmalerta c on a.idcaso=c.idcaso
 inner join s61751.sapy_dmcaso d on a.idcaso=d.idcaso
 inner join s61751.sapy_empresa e on e.idempresa=d.idempresa
 where a.codunicocli not like'%GR%' and e.nbrempresa='BCP')
 select codclavecic,periodo,count(idalerta) as ctd_alertas_prev
 from tmp
 group by  codclavecic,periodo;
 
--Flg policia
truncate table tmp_yape_policias ;
insert into tmp_yape_policias
	with tmp as (
	select distinct(z.codclavecic),descodprofesion from 
	ods_v.md_clienteg94 z 
	left join ods_v.mm_personanatural b on z.codclavecic=b.codclavecic
	left join ods_v.mm_descodigoprofesion a on trim(b.codprofesion)=trim(a.codprofesion) 
	where descodprofesion like '%POLICIA%' and z.flgregeliminado='N' and tipper='E'
 union all 
	select distinct(z.codclavecic),descodprofesion  from 
	ods_v.md_clienteg94 z 
	left join ods_v.mm_personanatural b on z.codclavecic=b.codclavecic
	left join ods_v.mm_descodigoprofesion a on trim(b.codprofesion)=trim(a.codprofesion)
	where descodprofesion like '%POLICIA%' and z.flgregeliminado='N' and tipper='P' )
	select distinct codclavecic from tmp;
 
truncate table tmp_yape_flgpolicia ;
insert into tmp_yape_flgpolicia
	select distinct  a.*,
	case when b.codclavecic is not null then 1 else 0 end flg_policia
	from tmp_yape_perfildepositos a
	left join tmp_yape_policias b on a.codclavecic=b.codclavecic;

--Antiguedad yape
truncate table tmp_yape_antyape ;
insert into tmp_yape_antyape
with tmp_proc_antg_fecapertura as 
(
  select codclavecic,min(t.fecha_afiliacion) as fecapertura
  from ( select distinct codclavecic,fecha_afiliacion from T26030.HD_YAPERO_VIEW )  t 
  group by codclavecic
),
tmp_proc_antig_aux as 
( 
select a.codmes_operacion, a.codclavecic, b.fecapertura,
  floor(months_between(to_date(to_char(codmes_operacion||'01'),'yyyymmdd'), b.fecapertura) ) as ant_yape
  from tmp_yape_flgpolicia a
  left join tmp_proc_antg_fecapertura b on a.codclavecic = b.codclavecic
)
select a.*,b.ant_yape
  from tmp_yape_flgpolicia a
  left join tmp_proc_antig_aux b on a.codmes_operacion = b.codmes_operacion and a.codclavecic = b.codclavecic;

-- Tablon final
truncate table tmp_yape_tablonfinal ;
insert into tmp_yape_tablonfinal	
   select distinct univ.codclavecic,
	univ.codmes_operacion,
	case when univ.act_economica_gruposinteres is null then 4 else univ.act_economica_gruposinteres end act_economica_gruposinteres,
	univ.flgnp,
	univ.ctdnp,
	univ.flglsb,
	univ.ctdlsb,
	univ.flgarchivonegativo,
	univ.destipmotivonegativo,
	univ.flgnplsban,
	univ.ctd_an_np_lsb,
	univ.flg_perfil_3ds,
	univ.flg_policia,
	case when univ.ant_yape is null or univ.ant_yape<0 then 0 else univ.ant_yape end ant_yape,
	case when monto_ingreso is null then 0 else monto_ingreso end monto_ingreso,
	case when ctd_ingreso is null then 0 else ctd_ingreso end ctd_ingreso,
	case when mto_egr is null then 0 else mto_egr end mto_egr,
	case when ctd_egreso is null then 0 else ctd_egreso end ctd_egreso,
	flg_pep,
	flg_pep_rel,
	tipper,codprofesion,
	descodprofesion,
	case when catprofesion is null then 4 else catprofesion end catprofesion,
	tip.flg_cuenta_yapecard,
	case when ord.ctd_ope_dist_ing is null then 0 else ord.ctd_ope_dist_ing end ctd_ope_dist_ing,
	case when antiguedad is null or antiguedad<0 then 0 else antiguedad end antiguedad,
	case when sol.ctd_ope_dist_egr is null then 0 else sol.ctd_ope_dist_egr end ctd_ope_dist_egr,
	case when alert.ctd_alertas_prev is null then 0 else alert.ctd_alertas_prev end ctd_alertas_prev
	from tmp_yape_antyape univ
	left join tmp_yape_tipocuenta tip on univ.codclavecic=tip.codclavecic
	left join tmp_yape_ord ord on univ.codclavecic=ord.codclavecic
	left join tmp_yape_sol sol on univ.codclavecic=sol.codclavecic
	left join tmp_yape_ctdalertas alert on univ.codclavecic=alert.codclavecic and alert.periodo=univ.codmes_operacion
    left join tmp_yape_antiguedad anti on univ.codclavecic=anti.codclavecic and anti.codmes_operacion=univ.codmes_operacion;

commit;
quit;