--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

var intervalo_1 number
exec :intervalo_1 := to_number(&2);

select :intervalo_1 from dual;

--extraer profesion
truncate table tmp_hb_profesion;
insert into tmp_hb_profesion
--create table tmp_hb_profesion tablespace d_aml_99 as
select a.*,b.codprofesion, c.descodprofesion,
case when trim(c.descodprofesion) like ('%TEC%') or trim(b.codprofesion) in ('130','142','146','150','151','152','153','174','207','410','613','618','701','705','706','707','710','804','806','807','810','850') then 1
when c.descodprofesion is null or trim(b.codprofesion) in ('999') then 2 else 3 end catprofesion
from tmp_hb_cli a
left join ods_v.mm_personanatural b on a.codclavecic=b.codclavecic
left join ods_v.mm_descodigoprofesion c on trim(b.codprofesion)=trim(c.codprofesion)
where tipper='E'
union
select a.*, b.codprofesion, c.descodprofesion,
case when trim(c.descodprofesion) like ('%TEC%') or trim(b.codprofesion) in ('130','142','146','150','151','152','153','174','207','410','613','618','701','705','706','707','710','804','806','807','810','850') then 1
when c.descodprofesion is null or trim(b.codprofesion) in ('999') then 2 else 0 end catprofesion
from tmp_hb_cli a
left join ods_v.mm_personanatural b on a.codclavecic=b.codclavecic
left join ods_v.mm_descodigoprofesion c on trim(b.codprofesion)=trim(c.codprofesion)
where tipper='P';

--categorizacion de la actividad economica
-- actividades economicas grupos de interes
truncate table tmp_hb_acteco_no_definidas ;
insert into tmp_hb_acteco_no_definidas
--create table  tmp_hb_acteco_no_definidas tablespace d_aml_99 as
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

truncate table tmp_hb_actecocli ;
insert into tmp_hb_actecocli
--create table tmp_hb_actecocli tablespace d_aml_99 as
   select a.*,
         case
             when c.busq in ('NO ESPECIF','NO DISPO') then 1
             when c.busq in ('OTRSERV') then 2
			 when c.busq in ('MAYOROTRPROD','MENOROTRPROD') then 3
             else  0
         end act_economica_gruposinteres
  from tmp_hb_profesion a
    left join ods_v.md_clienteg94 b on a.codclavecic = b.codclavecic
    left join tmp_hb_acteco_no_definidas c on b.codacteconomica = c.codacteconomica;

--variables sapyc: np - 2
--drop table tmp_hb_np_aux2;
truncate table tmp_hb_np_aux2 ;
insert into tmp_hb_np_aux2
--create table tmp_hb_np_aux2 tablespace d_aml_99 as
with tmp_hb_np_aux as
(
  select a.*, b.idorigen, b.nbrorigen as origen, b.codtransaccion as escenario, b.nbrtransaccion as desescenario
  from (
     select a.idcaso, case when instr(a.codunicocli,'GR') > 0 then c.codclavecic else d.codclavecic end as codclavecic, a.idresultado as idresultadoeval, a.fecfineval as fecfineval, b.IDRESULTADOSUPERVISOR
     from s61751.sapy_dmevaluacion a
     left join s61751.sapy_dminvestigacion b on a.idcaso = b.idcaso
     left join ods_v.md_empleadog94 c on trim(substr(a.codunicocli,instr(a.codunicocli,'GR')+2,6)) = trim(c.codmatricula)
     left join ods_v.md_clienteg94 d on trim(a.codunicocli) = trim(d.codunicocli)
  ) a
  left join s61751.sapy_dmalerta b on a.idcaso = b.idcaso
  where idorigen in (2)
)
select a.periodo,a.codclavecic, sum(case when b.fecfineval < to_date(to_char(a.periodo||'01'),'yyyymmdd') then 1 else 0 end) as ctdnp
from tmp_hb_actecocli a
left join tmp_hb_np_aux b on a.codclavecic = b.codclavecic
group by a.periodo,a.codclavecic;

--drop table  tmp_hb_np;
truncate table tmp_hb_np ;
insert into tmp_hb_np
--create table tmp_hb_np tablespace d_aml_99 as
select a.*,
case when b.ctdnp > 0 then 1 else 0 end flgnp,
case when b.ctdnp is not null then b.ctdnp else 0 end ctdnp
from tmp_hb_actecocli a
left join tmp_hb_np_aux2 b on a.periodo = b.periodo and a.codclavecic = b.codclavecic;

--variables sapyc: lsb - 29
--drop table tmp_hb_lsb_aux2;
truncate table tmp_hb_lsb_aux2 ;
insert into tmp_hb_lsb_aux2
--create table tmp_hb_lsb_aux2 tablespace d_aml_99 as
with tmp_hb_lsb_aux as
(
  select a.*, b.idorigen, b.nbrorigen as origen, b.codtransaccion as escenario, b.nbrtransaccion as desescenario
  from (
     select a.idcaso, case when instr(a.codunicocli,'GR') > 0 then c.codclavecic else d.codclavecic end as codclavecic, a.idresultado as idresultadoeval, a.fecfineval as fecfineval, b.idresultadosupervisor
     from s61751.sapy_dmevaluacion a
     left join s61751.sapy_dminvestigacion b on a.idcaso = b.idcaso
     left join ods_v.md_empleadog94 c on trim(substr(a.codunicocli,instr(a.codunicocli,'GR')+2,6)) = trim(c.codmatricula)
     left join ods_v.md_clienteg94 d on trim(a.codunicocli) = trim(d.codunicocli)
  ) a
  left join s61751.sapy_dmalerta b on a.idcaso = b.idcaso
  where idorigen in (29)
) select a.periodo,a.codclavecic, sum(case when b.fecfineval < to_date(to_char(a.periodo||'01'),'yyyymmdd') then 1 else 0 end) as ctdlsb
from tmp_hb_actecocli a
left join tmp_hb_lsb_aux b on a.codclavecic = b.codclavecic
group by a.periodo,a.codclavecic;

--drop table tmp_hb_lsb;
truncate table tmp_hb_lsb ;
insert into tmp_hb_lsb
--create table tmp_hb_lsb tablespace d_aml_99 as
select distinct a.*,
case when b.ctdlsb > 0 then 1 else 0 end flglsb,
case when b.ctdlsb is not null then b.ctdlsb else 0 end ctdlsb
from tmp_hb_np a
left join tmp_hb_lsb_aux2 b on a.periodo = b.periodo and a.codclavecic = b.codclavecic;

--archivo negativo
truncate table tmp_hb_archnegativo ;
insert into tmp_hb_archnegativo
--create table tmp_hb_archnegativo tablespace d_aml_99 as
with tmp_hb_archivonegativo_aux as (
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
  from tmp_hb_lsb a
  left join tmp_hb_archivonegativo_aux b on a.codclavecic = b.codclavecic;

--drop table  tmp_hb_flg_ctd_nplsban;
truncate table tmp_hb_flg_ctd_nplsban ;
insert into tmp_hb_flg_ctd_nplsban
--create table tmp_hb_flg_ctd_nplsban tablespace d_aml_99 as
select a.*,
case when flgnp = 1 or flglsb = 1 or flgarchivonegativo = 1 then 1 else 0 end flgnplsban,
ctdnp+ctdlsb+flgarchivonegativo as ctd_an_np_lsb
from tmp_hb_archnegativo a;

--ctd evaluaciones
truncate table tmp_hb_sapyc ;
insert into tmp_hb_sapyc
--create table tmp_hb_sapyc tablespace d_aml_99 as
select a.*
from (
   select a.idcaso, case when instr(a.codunicocli,'GR') > 0 then c.codclavecic else d.codclavecic end as codclavecic, a.idresultado as idresultadoeval, a.fecfineval as fecfineval, b.idresultadosupervisor
     from s61751.sapy_dmevaluacion a
     left join s61751.sapy_dminvestigacion b on a.idcaso = b.idcaso
     left join ods_v.md_empleadog94 c on trim(substr(a.codunicocli,instr(a.codunicocli,'GR')+2,6)) = trim(c.codmatricula)
     left join ods_v.md_clienteg94 d on trim(a.codunicocli) = trim(d.codunicocli)
) a;

truncate table tmp_hb_evals ;
insert into tmp_hb_evals
--create table tmp_hb_evals tablespace d_aml_99 as
with tmp_hb_evals_aux as
(
  select a.periodo,a.codclavecic, sum(case when b.fecfineval < to_date(to_char(a.periodo||'01'),'yyyymmdd') then 1 else 0 end) as ctdeval
  from tmp_hb_flg_ctd_nplsban a
  left join tmp_hb_sapyc b on a.codclavecic = b.codclavecic
  where idresultadoeval <> 7
  group by a.periodo,a.codclavecic
)
  select a.*,
  case when b.ctdeval is not null then b.ctdeval else 0 end as ctdeval
  from tmp_hb_flg_ctd_nplsban a
  left join tmp_hb_evals_aux b on a.periodo = b.periodo and a.codclavecic = b.codclavecic;

--perfil total
truncate table tmp_hb_trxperfil;
insert into tmp_hb_trxperfil
--create table tmp_hb_trxperfil tablespace d_aml_99 as
select periodo,c.codclavecic,sum(mtodolarizado) mtodolarizado,sum(ctd_oper) ctd_oper,c.tipper
from tmp_hb_trx a
left join ods_v.md_cuentag94 b on a.codopectaorigen=b.codopecta
left join ods_v.md_clienteg94 c on b.codclavecic=c.codclavecic
where c.codclavecic is not null and c.codclavecic not in (select codclavecic from s55632.rm_cumplimientolistablanca_tmp)
group by periodo,c.codclavecic,c.tipper;

truncate table tmp_hb_perfi1 ;
insert into tmp_hb_perfi1
--create table tmp_hb_perfi1 tablespace d_aml_99 as
select  a.codclavecic,a.periodo as numperiodo,b.periodo,
  months_between(to_date(a.periodo,'yyyymm'),to_date(b.periodo,'yyyymm')) meses,
  case when b. mtodolarizado is null then 0 else b. mtodolarizado end  mtodolarizado
  from tmp_hb_trxperfil a
  inner join tmp_hb_trxperfil b on a.codclavecic=b.codclavecic;

truncate table tmp_hb_perfi2 ;
insert into tmp_hb_perfi2
--create table tmp_hb_perfi2 tablespace d_aml_99 as
select numperiodo,codclavecic, mtodolarizado
from tmp_hb_perfi1 a
where numperiodo=periodo;


truncate table tmp_hb_perfi3 ;
insert into tmp_hb_perfi3
--create table tmp_hb_perfi3 tablespace d_aml_99 as
with temp_tab as(
  select numperiodo,codclavecic,
  avg(nullif( mtodolarizado,0)) as media_depo,stddev(nullif( mtodolarizado,0)) as desv_depo
  from tmp_hb_perfi1
  where meses<=6 and meses>=1
  group by numperiodo,codclavecic
) select a.*,
  round(nvl(b.media_depo,0),2) media_depo,
  round(nvl(b.desv_depo,0),2) desv_depo
  from tmp_hb_perfi2 a
  left join temp_tab b on (a.numperiodo=b.numperiodo and a.codclavecic=b.codclavecic);

truncate table tmp_hb_perfildepositos ;
insert into tmp_hb_perfildepositos
--create table tmp_hb_perfildepositos tablespace d_aml_99 as
select  a.*,
case when b.media_depo <> 0 and b.desv_depo <> 0 and b.media_depo+3*b.desv_depo<b. mtodolarizado then 1 else 0 end flg_perfil_3ds
from   tmp_hb_evals a
left join tmp_hb_perfi3 b on (a.periodo=b.numperiodo and a.codclavecic=b.codclavecic);

--beneficiarios x mes
truncate table tmp_hb_beneficiario ;
insert into tmp_hb_beneficiario
--create table tmp_hb_beneficiario tablespace d_aml_99 as
select t.fecdia,t.hortransaccion,codopectadestino,codopectaorigen,t.mtotransaccion * tc.mtocambioaldolar as mtodolarizado
from ods_v.hd_movhomebankingtransaccion t
left join ods_v.hd_tipocambiosaldodiario tc on t.fecdia = tc.fectipcambio and t.codmoneda = tc.codmoneda
where  tipresultadotransaccion = 'OK' and
t.fecdia between trunc(add_months(sysdate,:intervalo_1),'mm') and trunc(last_day(add_months(sysdate,:intervalo_1))) and
codopehbctr in ('TRAN_N','TRANS_OBCO_L','TRANSEXT','PCRBK_TER','EMIS','D_TRAN','PAMEX_TER','TRAN_OBCO');

truncate table tmp_hb_cli_beneficiario ;
insert into tmp_hb_cli_beneficiario
--create table tmp_hb_cli_beneficiario tablespace d_aml_99 as
select a.fecdia,a.hortransaccion,a.codopectaorigen,c.codclavecic as codclavecic_ben,mtodolarizado
from tmp_hb_beneficiario a
left join ods_v.md_cuentag94 b on a.codopectadestino=b.codopecta
left join ods_v.md_clienteg94 c on b.codclavecic=c.codclavecic
where c.codclavecic is not null and c.codclavecic not in (select codclavecic from s55632.rm_cumplimientolistablanca_tmp);

truncate table tmp_hb_cli_ctdben ;
insert into tmp_hb_cli_ctdben
--create table tmp_hb_cli_ctdben tablespace d_aml_99 as
select c.codclavecic,count(distinct(a.codclavecic_ben)) as ctd_beneficiario,count(distinct(a.fecdia)) as ctd_dias
from tmp_hb_cli_beneficiario a
inner join ods_v.md_cuentag94 b on a.codopectaorigen=b.codopecta
inner join ods_v.md_clienteg94 c on b.codclavecic=c.codclavecic
where c.codclavecic is not null and c.codclavecic not in (select codclavecic from s55632.rm_cumplimientolistablanca_tmp)
group by c.codclavecic;

truncate table tmp_hb_cli_var;
insert into tmp_hb_cli_var
--create table tmp_hb_cli_var tablespace d_aml_99 as
select distinct a.*,b.ctd_beneficiario,b.ctd_dias
from tmp_hb_perfildepositos a
left join tmp_hb_cli_ctdben b on a.codclavecic=b.codclavecic;

--indice de concentracion
truncate table tmp_hb_indice  ;
insert into tmp_hb_indice
--create table tmp_hb_indice tablespace d_aml_99 as
with tmp as(
select a.fecdia,b.codclavecic as codclavecic_ord
from tmp_hb_cli_beneficiario a
left join ods_v.md_cuentag94 b on a.codopectaorigen=b.codopecta
left join ods_v.md_clienteg94 c on b.codclavecic=c.codclavecic
where c.codclavecic is not null and c.codclavecic not in (select codclavecic from s55632.rm_cumplimientolistablanca_tmp)
)
select to_number(to_char(fecdia,'yyyymm')) periodo,round(30/(count(distinct fecdia)),2) as indice_concentrador,codclavecic_ord
from tmp
group by to_number(to_char(fecdia,'yyyymm')),codclavecic_ord;

--varianza mes anterior
truncate table tmp_hb_ratio ;
insert into tmp_hb_ratio
--create table tmp_hb_ratio tablespace d_aml_99 as
with tmpa as(
select  codclavecic,periodo,mtodolarizado
from tmp_hb_trxperfil
where to_date(to_char(periodo||'01'),'yyyymmdd')=trunc(add_months(sysdate,:intervalo_1),'mm')
),
tmpb as
(
select  codclavecic,periodo,mtodolarizado
from tmp_hb_trxperfil
where to_date(to_char(periodo||'01'),'yyyymmdd')=trunc(add_months(sysdate,:intervalo_1),'mm')
)
select distinct a.codclavecic,a.periodo,
case when a.mtodolarizado=0 or b.mtodolarizado=0 or a.mtodolarizado is null or b.mtodolarizado is null then 0
else round((a.mtodolarizado/b.mtodolarizado),2) end  ratio,b.mtodolarizado mtodolarizado_ant
from tmpa a
left join tmpb b on a.codclavecic=b.codclavecic;

--paises de alto riesgo
truncate table tmp_hb_exterior ;
insert into tmp_hb_exterior
--create table tmp_hb_exterior tablespace d_aml_99 as
select t.fecdia,hortransaccion,codopectaorigen,t.mtotransaccion * tc.mtocambioaldolar as mtodolarizado,codopectadestino,nbrbeneficiario,apepatbeneficiario,apematbeneficiario
from ods_v.hd_movhomebankingtransaccion t
left join ods_v.hd_tipocambiosaldodiario tc on t.fecdia = tc.fectipcambio and t.codmoneda = tc.codmoneda
where  tipresultadotransaccion = 'OK' and
t.fecdia between trunc(add_months(sysdate,:intervalo_1),'mm') and trunc(last_day(add_months(sysdate,:intervalo_1))) and
codopehbctr='TRANSEXT';

truncate table tmp_hb_extcli ;
insert into tmp_hb_extcli
--create table tmp_hb_extcli tablespace d_aml_99 as
select c.codclavecic,a.fecdia,a.hortransaccion,a.codopectaorigen,a.mtodolarizado
from tmp_hb_exterior a
left join ods_v.md_cuentag94 b on a.codopectaorigen=b.codopecta
left join ods_v.md_clienteg94 c on b.codclavecic=c.codclavecic
where c.codclavecic is not null and c.codclavecic not in (select codclavecic from s55632.rm_cumplimientolistablanca_tmp);

truncate table tmp_hb_banni  ;
insert into tmp_hb_banni
--create table tmp_hb_banni tablespace d_aml_99 as
with tmp as (
select distinct c.codclavecic,c.fecdia,mtodolarizado,codpaisbeneficiario
from ods_v.hd_movimientobanni a
inner join ods_v.md_operacionban b on a.codclaveopecta = b.codclaveopecta and a.fecdia=b.fecactivacion
inner join tmp_hb_extcli c on b.codclavecic=c.codclavecic and a.fecdia=b.fecdia and mtooperaciondol=mtodolarizado)
select to_number(to_char(fecdia,'yyyymm')) as periodo,codclavecic,sum(mtodolarizado) as paisriesgo_monto
from tmp where codpaisbeneficiario in ( select codpais3 from s55632.md_codigopais where obs_gafi = 'Y')
group by to_number(to_char(fecdia,'yyyymm')),codclavecic;

--consolidado
truncate table tmp_hb_data;
insert into tmp_hb_data
--create table tmp_hb_data tablespace d_aml_99 as
select distinct a.periodo,a.codclavecic,round(mtodolarizado,2) as mtodolarizado,a.tipper,
a.flgarchivonegativo,
case when a.ctdeval is null then 0 else a.ctdeval end ctdeval,
case when a.ctd_oper is null then 0 else a.ctd_oper end ctd_oper,
a.descodprofesion,
a.flg_perfil_3ds,a.flglsb,a.flgnp,
case when a.ctd_beneficiario is null then 0 else a.ctd_beneficiario end ctd_beneficiario,
case when a.ctd_dias is null then 0 else a.ctd_dias end ctd_dias,
case when b.mtodolarizado_ant is null then 0 else mtodolarizado_ant end mtodolarizado_ant
,b.ratio,
case when c.indice_concentrador is null then 0 else c.indice_concentrador end indice_concentrador,
case when d.paisriesgo_monto is null then 0 else round(d.paisriesgo_monto,2) end paisriesgo_monto
from tmp_hb_cli_var  a
left join tmp_hb_ratio b on a.codclavecic=b.codclavecic and a.periodo=b.periodo
left join tmp_hb_indice c on a.codclavecic=c.codclavecic_ord and a.periodo=c.periodo
left join tmp_hb_banni d on a.codclavecic=d.codclavecic and a.periodo=d.periodo;

commit;
quit;