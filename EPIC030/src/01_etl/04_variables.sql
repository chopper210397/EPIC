--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode

var intervalo_1 number 
exec :intervalo_1 := to_number(&2);

select :intervalo_1 from dual;

alter session disable parallel query;

/*************************************************************************************************
****************************** ESCENARIO ESTIMADOR DE INGRESOS ***********************************
*************************************************************************************************/

-- creado por: Celeste Cabanillas
-- key user escenario: plaft
/*************************************************************************************************/

-------------------------------Estimador
----------------------------------------------------------------------mes de la alerta---------------------------------------------------------
truncate table tmp_esting_banca_estimador;
insert into tmp_esting_banca_estimador
select
a.codmes,
b.codclavecic,
a.mtomejoringresoajustadosol mto_estimador,
a.codfuenteingresoactual cod_estimador
from ods_v.hm_ingresoconsolidadoclientepn a
inner join tmp_esting_universo  b on a.codclavecic=b.codclavecic
where a.codmes=to_char(trunc(last_day(add_months(sysdate,:intervalo_1))),'yyyymm');

------------------------------actividad economica+
truncate table tmp_esting_banca_no_definidas;
insert into tmp_esting_banca_no_definidas
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
  
truncate table tmp_esting_banca_acteco;
insert into tmp_esting_banca_acteco
   select a.*,
         case 
             when c.busq in ('NO ESPECIF','NO DISPO','OTRSERV','MAYOROTRPROD','MENOROTRPROD') then 1
             else  0
         end flg_act_eco
  from tmp_esting_universo a
    left join ods_v.md_clienteg94 b on a.codclavecic = b.codclavecic
    left join tmp_esting_banca_no_definidas c on b.codacteconomica = c.codacteconomica;
    
-----------------------------profesion 
truncate table tmp_esting_banca_profesion;
insert into tmp_esting_banca_profesion
select a.codclavecic,a.flg_act_eco,b.codprofesion, c.descodprofesion,
case when trim(c.descodprofesion) like ('%TEC%') or c.descodprofesion is null or trim(b.codprofesion) 
in ('130','142','146','150','151','152','153','174','207','410','613','618','701','705','706','707','710','804','806','807','810','850','999') 
then 1
else 0 end flg_prof
from tmp_esting_banca_acteco a
left join ods_v.mm_personanatural b on a.codclavecic=b.codclavecic
left join ods_v.mm_descodigoprofesion c on trim(b.codprofesion)=trim(c.codprofesion);

-------------------------------
truncate table tmp_esting_sapyc;
insert into tmp_esting_sapyc
select a.*
from (
   select a.idcaso, case when instr(a.codunicocli,'GR') > 0 then c.codclavecic else d.codclavecic end as codclavecic, 
   a.idresultado as idresultadoeval, a.fecfineval as fecfineval, b.idresultadosupervisor
     from s61751.sapy_dmevaluacion a
     left join s61751.sapy_dminvestigacion b on a.idcaso = b.idcaso
     left join ods_v.md_empleadog94 c on trim(substr(a.codunicocli,instr(a.codunicocli,'GR')+2,6)) = trim(c.codmatricula)
     left join ods_v.md_clienteg94 d on trim(a.codunicocli) = trim(d.codunicocli)
) a;

truncate table tmp_esting_evals;
insert into tmp_esting_evals
with tmp_esting_evals_aux as
(
  select a.codmes,a.codclavecic, sum(case when b.fecfineval < to_date(to_char(a.codmes||'01'),'yyyymmdd') then 1 else 0 end) as ctdeval
  from tmp_esting_banca_estimador a
  left join tmp_esting_sapyc b on a.codclavecic = b.codclavecic
  where idresultadoeval <> 7
  group by a.codmes,a.codclavecic
)
  select a.*,
  case when b.ctdeval is not null then b.ctdeval else 0 end as ctdeval
  from tmp_esting_banca_estimador a
  left join tmp_esting_evals_aux b on a.codmes = b.codmes and a.codclavecic = b.codclavecic;

truncate table tmp_esting_ingresos;
insert into tmp_esting_ingresos
select to_number(to_char(fecdia, 'yyyymm')) as periodo,codclavecic_ben,sum(mto_dolarizado) mto_ingreso,count(mto_dolarizado) ctd_ingreso
from tmp_esting_trx
group by to_number(to_char(fecdia, 'yyyymm')), codclavecic_ben;

--perfil total
truncate table tmp_esting_perfi1;
insert into tmp_esting_perfi1
select  a.codclavecic_ben,a.periodo as numperiodo,b.periodo,
months_between(to_date(a.periodo,'yyyymm'),to_date(b.periodo,'yyyymm')) meses,
case when b.mto_ingreso is null then 0 else b.mto_ingreso end mto_ingreso
from tmp_esting_ingresos a
inner join tmp_esting_ingresos b on a.codclavecic_ben=b.codclavecic_ben;

truncate table tmp_esting_perfi2;
insert into tmp_esting_perfi2
select numperiodo,codclavecic_ben,mto_ingreso
from tmp_esting_perfi1 a
where numperiodo=periodo;

truncate table tmp_esting_perfi3;
insert into tmp_esting_perfi3
with temp_tab as(
	select numperiodo,codclavecic_ben,
	avg(nullif(mto_ingreso,0)) as media_depo,stddev(nullif(mto_ingreso,0)) as desv_depo
	from tmp_esting_perfi1
	where meses<=6 and meses>=1
	group by numperiodo,codclavecic_ben
) select a.*,
	round(nvl(b.media_depo,0),2) media_depo,
	round(nvl(b.desv_depo,0),2) desv_depo
	from tmp_esting_perfi2 a
	left join temp_tab b on (a.numperiodo=b.numperiodo and a.codclavecic_ben=b.codclavecic_ben);

--------------------------------------------------------------------------cambiar fecha ------------------------------------------------------------------------------------------
--creación el flg perfil total en tabla cliente mes
truncate table tmp_esting_perfilingresos;
insert into tmp_esting_perfilingresos
select a.periodo,a.codclavecic_ben,a.ctd_ingreso,
case when b.mto_ingreso is null then 0 else b.mto_ingreso end mto_ingreso,
case when b.media_depo <> 0 and b.desv_depo <> 0 and b.media_depo+3*b.desv_depo<b.mto_ingreso then 1 else 0 end flg_perfil_depositos_3ds
from   tmp_esting_ingresos a
left join tmp_esting_perfi3 b on (a.periodo=b.numperiodo and a.codclavecic_ben=b.codclavecic_ben)
where periodo = to_number(to_char(add_months(sysdate, :intervalo_1),'yyyymm'));

--dolar
truncate table tmp_esting_tipocambio;
insert into tmp_esting_tipocambio
with tmp as (
select codmoneda,mtocambioalnuevosol,mtocambioaldolar,fectipcambio,
to_number(to_char(fectipcambio,'yyyymm')) numperiodo
from ods_v.hd_tipocambiosaldodiario
where codmoneda='0001' and
fectipcambio=trunc(last_day(add_months(sysdate,:intervalo_1)))
      order by fectipcambio desc
      ),tmp2 as
      (
      select a.*,row_number() over (partition by a.numperiodo order by a.fectipcambio desc) as col
      from tmp a
      )
      select * from tmp2 where col=1;

--=======================================================tablon final ========================================================================================================================v
truncate table tmp_esting_tablon;
insert into tmp_esting_tablon
select distinct
a.codmes,
a.codclavecic,
round(a.mto_estimador * d.mtocambioaldolar,2) mto_estimador, --se usa para el ratio
a.ctdeval, --se usa
c.ctd_ingreso, --se usa
round(c.mto_ingreso,2) mto_ingreso, --se usa para el ratio
c.flg_perfil_depositos_3ds --se usa
from  tmp_esting_evals a
left join tmp_esting_banca_profesion b on a.codclavecic = b.codclavecic
left join tmp_esting_perfilingresos c on a.codmes = c.periodo and a.codclavecic = c.codclavecic_ben
left join tmp_esting_tipocambio d on a.codmes = d.numperiodo
where mto_ingreso>10000;

commit;
quit;