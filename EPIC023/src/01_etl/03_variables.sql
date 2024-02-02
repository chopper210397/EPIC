--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

var intervalo_1 number
exec :intervalo_1 := to_number(&2);
var intervalo_2 number
exec :intervalo_2 := to_number(&3);

select :intervalo_1, :intervalo_2 from dual;

--extraer edad
truncate table tmp_cvme_edad;
insert into tmp_cvme_edad
--create table tmp_cvme_edad as
with tmp_proc_edad_ppnn_aux as
(
  select a.codclavecic,a.periodo,c.fecnacimiento, floor(months_between(to_date(to_char(periodo||'01'),'yyyymmdd'), c.fecnacimiento) /12) as edad
  from tmp_cvme_universo_cli a
  inner join ods_v.md_cliente b on a.codclavecic = b.codclavecic
  left join ods_v.md_personanatural c on a.codclavecic = c.codclavecic
  where trim(b.tipper) = 'P'
),
tmp_proc_edad_ppjj_aux as
(
  select a.codclavecic,a.periodo,c.fecconstitucion, floor(months_between(to_date(to_char(periodo||'01'),'yyyymmdd'), c.fecconstitucion) /12) as edad
  from tmp_cvme_universo_cli a
  inner join ods_v.md_cliente b on a.codclavecic = b.codclavecic
  left join ods_v.mm_empresa c on a.codclavecic = c.codclavecic
  where trim(b.tipper) = 'E'
)
select a.periodo, a.codclavecic, case when trim(x.tipper) = 'P' then b.edad else case when trim(x.tipper) = 'E' then c.edad else null end end as edad
from tmp_cvme_universo_cli a
left join ods_v.md_cliente x on a.codclavecic = x.codclavecic
left join tmp_proc_edad_ppnn_aux b on a.periodo = b.periodo and a.codclavecic = b.codclavecic
left join tmp_proc_edad_ppjj_aux c on a.periodo = c.periodo and a.codclavecic = c.codclavecic;

--tipper
truncate table tmp_cvme_tipper;
insert into tmp_cvme_tipper
--create table tmp_cvme_tipper as
select a.*, b.tipper
from tmp_cvme_edad a
inner join ods_v.md_cliente b on a.codclavecic = b.codclavecic;

--extraer profesion
truncate table tmp_cvme_profesion;
insert into tmp_cvme_profesion
--create table tmp_cvme_profesion as
select a.*, b.codprofesion, c.descodprofesion,
case when trim(c.descodprofesion) like ('%TEC%') or trim(b.codprofesion) in ('130','142','146','150','151','152','153','174','207','410','613','618','701','705','706','707','710','804','806','807','810','850') then 1
when c.descodprofesion is null or trim(b.codprofesion) in ('999') then 2 else 3 end catprofesion
from tmp_cvme_tipper a
left join ods_v.mm_personanatural b on a.codclavecic=b.codclavecic
left join ods_v.mm_descodigoprofesion c on trim(b.codprofesion)=trim(c.codprofesion);

--antiguedad
truncate table tmp_cvme_antiguedad;
insert into tmp_cvme_antiguedad
--create table tmp_cvme_antiguedad as
with tmp_proc_antg_fecapertura as
(
  select codclavecic,min(t.fecapertura) as fecapertura
  from ( select distinct codclavecic,fecapertura from ods_v.md_prestamo
         union all
         select distinct codclavecic,fecapertura from ods_v.md_impac
         union all
         select distinct codclavecic,fecapertura from ods_v.md_saving
         union all
         select distinct codclavecic,fecapertura from ods_v.md_cuentavp )  t
  group by codclavecic
),
tmp_proc_antig_aux as
(
select a.periodo, a.codclavecic, b.fecapertura,
  floor(months_between(to_date(to_char(periodo||'01'),'yyyymmdd'), b.fecapertura) ) as antiguedad
  from tmp_cvme_profesion a
  left join tmp_proc_antg_fecapertura b on a.codclavecic = b.codclavecic
)
select a.*, b.fecapertura, b.antiguedad
  from tmp_cvme_profesion a
  left join tmp_proc_antig_aux b on a.periodo = b.periodo and a.codclavecic = b.codclavecic;

--flg no cliente
truncate table tmp_cvme_segmentobanca;
insert into tmp_cvme_segmentobanca
--create table tmp_cvme_segmentobanca as
select distinct subseg.codsubsegmento, subseg.dessubsegmento, seg.codsegmento, seg.dessegmento
from ods_v.mm_descodigosubsegmento subseg
left join ods_v.mm_descodsubseggen subseggen on trim(subseg.codsubseggeneral)=trim(subseggen.codsubseggeneral)
left join ods_v.mm_descodigosegmento seg on trim(subseggen.codsegmento)=trim(seg.codsegmento);

truncate table tmp_cvme_flgnocliente;
insert into tmp_cvme_flgnocliente
--create table tmp_cvme_flgnocliente as
select a.*, b.tipcli, b.codsubsegmento, c.dessubsegmento, c.codsegmento, c.dessegmento,
case when trim(c.codsegmento) = 'SN' then 1
when trim(c.codsegmento) = '.' and b.tipcli = 'NC' then 1
else 0 end as flgnocliente
from tmp_cvme_antiguedad a
left join ods_v.md_cliente b on a.codclavecic = b.codclavecic
left join tmp_cvme_segmentobanca c on trim(b.codsubsegmento) = trim(c.codsubsegmento);

--flg actividad economica no definida
truncate table tmp_cvme_acteconomica_nodef_aux;
insert into tmp_cvme_acteconomica_nodef_aux
--create table tmp_cvme_acteconomica_nodef_aux as
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

truncate table tmp_cvme_acteconomica_nodef;
insert into tmp_cvme_acteconomica_nodef
--create table tmp_cvme_acteconomica_nodef as
   select a.*, b.codacteconomica, d.desacteconomica,
         case
             when b.codacteconomica is null then 1
             when c.codacteconomica is not null then 1
             else 0
         end flg_acteco_nodef
  from tmp_cvme_flgnocliente a
    left join ods_v.md_cliente b on a.codclavecic = b.codclavecic
    left join tmp_cvme_acteconomica_nodef_aux c on trim(b.codacteconomica) = trim(c.codacteconomica)
    left join ods_v.mm_descodactividadeconomica d on trim(b.codacteconomica) = trim(d.codacteconomica);

--variables sapyc: np - 2
truncate table tmp_cvme_np_aux2;
insert into tmp_cvme_np_aux2
--create table tmp_cvme_np_aux2 as
with tmp_cvme_np_aux as
(
  select a.*, b.idorigen, b.nbrorigen as origen, b.codtransaccion as escenario, b.nbrtransaccion as desescenario
  from (
     select a.idcaso, case when instr(a.codunicocli,'GR') > 0 then c.codclavecic else d.codclavecic end as codclavecic, a.idresultado as idresultadoeval, a.fecfineval as fecfineval, b."IDRESULTADOSUPERVISOR"
     from S61751.sapy_dmevaluacion a
     left join S61751.sapy_dminvestigacion b on a.idcaso = b.idcaso
     left join ods_v.md_empleadog94 c on trim(substr(a.codunicocli,instr(a.codunicocli,'GR')+2,6)) = trim(c.codmatricula)
     left join ods_v.md_clienteg94 d on trim(a.codunicocli) = trim(d.codunicocli)
  ) a
  left join S61751.sapy_dmalerta b on a.idcaso = b.idcaso
  where idorigen in (2)
)
select a.periodo,a.codclavecic, sum(case when b.fecfineval < to_date(to_char(a.periodo||'01'),'yyyymmdd') then 1 else 0 end) as ctdnp
from tmp_cvme_acteconomica_nodef a
left join tmp_cvme_np_aux b on a.codclavecic = b.codclavecic
group by a.periodo,a.codclavecic;

truncate table tmp_cvme_np;
insert into tmp_cvme_np
--create table tmp_cvme_np as
select a.*,
case when b.ctdnp > 0 then 1 else 0 end flgnp,
case when b.ctdnp is not null then b.ctdnp else 0 end ctdnp
from tmp_cvme_acteconomica_nodef a
left join tmp_cvme_np_aux2 b on a.periodo = b.periodo and a.codclavecic = b.codclavecic;

--variables sapyc: lsb - 29
truncate table tmp_cvme_lsb_aux2;
insert into tmp_cvme_lsb_aux2
--create table tmp_cvme_lsb_aux2 as
with tmp_cvme_lsb_aux as
(
  select a.*, b.idorigen, b.nbrorigen as origen, b.codtransaccion as escenario, b.nbrtransaccion as desescenario
  from (
     select a.idcaso, case when instr(a.codunicocli,'GR') > 0 then c.codclavecic else d.codclavecic end as codclavecic, a.idresultado as idresultadoeval, a.fecfineval as fecfineval, b."IDRESULTADOSUPERVISOR"
     from s61751.sapy_dmevaluacion a
     left join s61751.sapy_dminvestigacion b on a.idcaso = b.idcaso
     left join ods_v.md_empleadog94 c on trim(substr(a.codunicocli,instr(a.codunicocli,'GR')+2,6)) = trim(c.codmatricula)
     left join ods_v.md_clienteg94 d on trim(a.codunicocli) = trim(d.codunicocli)
  ) a
  left join s61751.sapy_dmalerta b on a.idcaso = b.idcaso
  where idorigen in (29)
) select a.periodo,a.codclavecic, sum(case when b.fecfineval < to_date(to_char(a.periodo||'01'),'yyyymmdd') then 1 else 0 end) as ctdlsb
from tmp_cvme_acteconomica_nodef a
left join tmp_cvme_lsb_aux b on a.codclavecic = b.codclavecic
group by a.periodo,a.codclavecic;

truncate table tmp_cvme_lsb;
insert into tmp_cvme_lsb
--create table tmp_cvme_lsb as
select a.*,
case when b.ctdlsb > 0 then 1 else 0 end flglsb,
case when b.ctdlsb is not null then b.ctdlsb else 0 end ctdlsb
from tmp_cvme_np a
left join tmp_cvme_lsb_aux2 b on a.periodo = b.periodo and a.codclavecic = b.codclavecic;

--archivo negativo
truncate table tmp_cvme_archnegativo;
insert into tmp_cvme_archnegativo
--create table tmp_cvme_archnegativo as
with tmp_cvme_archivonegativo_aux as (
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
  from tmp_cvme_lsb a
  left join tmp_cvme_archivonegativo_aux b on a.codclavecic = b.codclavecic;

truncate table tmp_cvme_flg_ctd_nplsban;
insert into tmp_cvme_flg_ctd_nplsban
--create table tmp_cvme_flg_ctd_nplsban as
select a.*,
case when flgnp = 1 or flglsb = 1 or flgarchivonegativo = 1 then 1 else 0 end flgnplsban,
ctdnp+ctdlsb+flgarchivonegativo as ctd_an_np_lsb
from tmp_cvme_archnegativo a;

--ctd evaluaciones
truncate table tmp_cvme_sapyc;
insert into tmp_cvme_sapyc
--create table tmp_cvme_sapyc as
select a.*
from (
   select a.idcaso, case when instr(a.codunicocli,'GR') > 0 then c.codclavecic else d.codclavecic end as codclavecic, a.idresultado as idresultadoeval, a.fecfineval as fecfineval, b.idresultadosupervisor
     from s61751.sapy_dmevaluacion a
     left join s61751.sapy_dminvestigacion b on a.idcaso = b.idcaso
     left join ods_v.md_empleadog94 c on trim(substr(a.codunicocli,instr(a.codunicocli,'GR')+2,6)) = trim(c.codmatricula)
     left join ods_v.md_clienteg94 d on trim(a.codunicocli) = trim(d.codunicocli)
) a;

truncate table tmp_cvme_evals;
insert into tmp_cvme_evals
--create table tmp_cvme_evals as
with tmp_cvme_evals_aux as
(
  select a.periodo,a.codclavecic, sum(case when b.fecfineval < to_date(to_char(a.periodo||'01'),'yyyymmdd') then 1 else 0 end) as ctdeval
  from tmp_cvme_flg_ctd_nplsban a
  left join tmp_cvme_sapyc b on a.codclavecic = b.codclavecic
  where idresultadoeval <> 7
  group by a.periodo,a.codclavecic
)
  select a.*,
  case when b.ctdeval is not null then b.ctdeval else 0 end as ctdeval
  from tmp_cvme_flg_ctd_nplsban a
  left join tmp_cvme_evals_aux b on a.periodo = b.periodo and a.codclavecic = b.codclavecic;

--cantidad de ordenantes distintos
truncate table tmp_cvme_ordenantes;
insert into tmp_cvme_ordenantes
--create table tmp_cvme_ordenantes as
with tmp_cvme_ordenantes_aux_1 as
(
  select distinct to_number(to_char(a.fecdia,'yyyymm')) as periodo,ordenante, codclavecic
  from tmp_cvme_trx_ventanilla a
  left join ods_v.md_clienteg94 b on trim(a.ordenante) = trim(b.codunicocli)
),
tmp_cvme_ordenantes_aux_2 as
(
  select periodo, ordenante, count(*) as ctd
  from tmp_cvme_ordenantes_aux_1
  group by periodo, ordenante
  having count(*) > 1
) select a.*
  from tmp_cvme_ordenantes_aux_1 a
  left join tmp_cvme_ordenantes_aux_2 b on a.periodo = b.periodo and trim(a.ordenante) = trim(b.ordenante)
  where a.codclavecic is not null and (b.periodo is null or b.ordenante is null);

truncate table tmp_cvme_ctd_ordenantes_distintos;
insert into tmp_cvme_ctd_ordenantes_distintos
--create table tmp_cvme_ctd_ordenantes_distintos as
with tmp_cvme_ctd_ordenantes_distintos_aux as
(
  select distinct to_number(to_char(a.fecdia,'yyyymm')) as periodo, a.codclavecic_solicitante, b.codclavecic
  from tmp_cvme_trx_ventanilla a
  left join tmp_cvme_ordenantes b on to_number(to_char(a.fecdia,'yyyymm')) = b.periodo and trim(a.ordenante) = trim(b.ordenante)
  where b.codclavecic is not null
),
  tmp_cvme_ctd_ordenantes_distintos_aux_2 as (
  select periodo, codclavecic_solicitante, count(*) as ctd_ordenates_distintos
  from tmp_cvme_ctd_ordenantes_distintos_aux
  group by periodo, codclavecic_solicitante
) select a.*,
  case when b.ctd_ordenates_distintos is not null then b.ctd_ordenates_distintos else 0 end as ctd_ordenates_distintos
  from tmp_cvme_evals a
  left join tmp_cvme_ctd_ordenantes_distintos_aux_2 b on a.periodo = b.periodo and a.codclavecic = b.codclavecic_solicitante ;

--variables transaccionales
--41 cargo compra-me cambio de moneda compra me
--169 abono venta-me cambio de moneda venta me
--176 cargo compra-om transacci�n para realizar compras de moneda extranjera en otra m
--179 abono venta-om transacci�n para realizar ventas de moneda extranjera en otra m.
truncate table tmp_cvme_var_agrupadas_aux;
insert into tmp_cvme_var_agrupadas_aux
--create table tmp_cvme_var_agrupadas_aux as
select to_number(to_char(a.fecdia,'yyyymm')) as periodo,codclavecic_solicitante,
  sum(a.mtodolarizado) as mto_total,
  sum(case when a.codtransaccionventanilla in (41,176) then a.mtodolarizado else 0 end) as mto_compra,
  sum(case when a.codtransaccionventanilla in (169,179) then a.mtodolarizado else 0 end) as mto_venta,
  count(*) as ctd_total,
  sum(case when a.codtransaccionventanilla in (41,176) then 1 else 0 end) as ctd_compra,
  sum(case when a.codtransaccionventanilla in (169,179) then 1 else 0 end) as ctd_venta,
  sum(case when trim(d.coddepartamento) in ('10','42','46','48') then a.mtodolarizado else 0 end) as mto_zaed,
  sum(case when trim(d.coddepartamento) in ('10','42','46','48') then 1 else 0 end) as ctd_zaed
  from tmp_cvme_trx_ventanilla  a
  left join ods_v.md_agencia c on trim(a.codsucage) = trim(c.codsucage) or trim(a.codsucage) = trim(c.codofi)
  left join ods_v.mm_distrito d on trim(c.coddistrito) = trim(d.coddistrito)
  left join ods_v.mm_departamento e on trim(d.coddepartamento) = trim(e.coddepartamento)
  group by to_number(to_char(a.fecdia,'yyyymm')),codclavecic_solicitante;

truncate table tmp_trx_epic023;
insert into tmp_trx_epic023
select numregistro,
a.fecdia,
a.horinitransaccion,
a.horfintransaccion,
a.codsucage,
a.codsesion,
a.codtransaccionventanilla,
c.destransaccionventanilla,
flgtransaccionaprobada,
tiproltransaccion,
a.codmoneda,
a.mtotransaccion,
a.mtodolarizado,
b.codopecta,
e.codopecta as codopectadestino,
codclavecic_solicitante,
d.codunicocli as codunicoclisolicitante,
trim(d.apepatcli)||' '||trim(d.apematcli)||' '||trim(d.nbrcli) as nombresolicitante,
f.codclavecic as codclavecic_ordenante,
f.codunicocli as codunicocliordenante,
trim(f.apepatcli)||' '||trim(f.apematcli)||' '||trim(f.nbrcli) as nombreordenante
from tmp_cvme_trx_ventanilla a
left join ods_v.md_destransaccionventanilla c on a.codtransaccionventanilla = c.codtransaccionventanilla
left join ods_v.md_clienteg94 d on a.codclavecic_solicitante = d.codclavecic
left join ods_v.md_cuentag94 b on a.codclaveopecta=b.codclaveopecta
left join ods_v.md_cuentag94 e on a.codclaveopectadestino= e.codclaveopecta
left join ods_v.md_clienteg94 f on a.ordenante = f.codunicocli
where
a.fecdia between trunc(add_months(sysdate, :intervalo_2),'mm') and trunc(last_day(add_months(sysdate,:intervalo_2)));

truncate table tmp_cvme_var_agrupadas;
insert into tmp_cvme_var_agrupadas
--create table tmp_cvme_var_agrupadas as
select a.*,
  case when b.mto_total is null then 0 else b.mto_total end as mto_total,
  case when b.mto_compra is null then 0 else b.mto_compra end as mto_compra,
  case when b.mto_venta is null then 0 else b.mto_venta end as mto_venta,
  case when b.ctd_total is null then 0 else b.ctd_total end as ctd_total,
  case when b.ctd_compra is null then 0 else b.ctd_compra end as ctd_compra,
  case when b.ctd_venta is null then 0 else b.ctd_venta end as ctd_venta,
  case when b.mto_zaed is null then 0 else b.mto_zaed end as mto_zaed,
  case when b.ctd_zaed is null then 0 else b.ctd_zaed end as ctd_zaed
  from tmp_cvme_ctd_ordenantes_distintos a
  left join tmp_cvme_var_agrupadas_aux b on a.periodo = b.periodo and a.codclavecic = b.codclavecic_solicitante;

--cantidad de dias cv
truncate table tmp_cvme_ctddias;
insert into tmp_cvme_ctddias
--create table tmp_cvme_ctddias as
with tmp_cvme_ctddias_aux as (
  select periodo, codclavecic_solicitante, count(*) as ctd
  from (
    select to_number(to_char(fecdia,'yyyymm')) as periodo, fecdia, codclavecic_solicitante
    from tmp_cvme_trx_ventanilla
    group by to_number(to_char(fecdia,'yyyymm')), fecdia, codclavecic_solicitante
  ) a
  group by periodo, codclavecic_solicitante
) select a.*,
  case when b.ctd is null then 0 else b.ctd end as ctd_dias
  from tmp_cvme_var_agrupadas a
  left join tmp_cvme_ctddias_aux b on a.periodo = b.periodo and a.codclavecic = b.codclavecic_solicitante;

--flg perfil
--extraer codclavecics del universo de clientes
truncate table tmp_cvme_codclavecics_cli;
insert into tmp_cvme_codclavecics_cli
--create table tmp_cvme_codclavecics_cli as
select distinct codclavecic
from tmp_cvme_ctddias;

truncate table tmp_cvme_cuentas_cli;
insert into tmp_cvme_cuentas_cli
--create table tmp_cvme_cuentas_cli as
select a.codclavecic, b.codclaveopecta, trim(b.codopecta) as codopecta
from tmp_cvme_codclavecics_cli a
inner join ods_v.md_cuenta  b on a.codclavecic = b.codclavecic
where b.flgregeliminado = 'N' and
trim(codsistemaorigen) in ('BAN','IMP','SAV','RT','GT');

--extraccion de trxs en canal agente
---extraccion de int-cli
--extraccion en agente - tranydep;
truncate table tmp_cvme_trx_age_int_cli_trandep;
insert into tmp_cvme_trx_age_int_cli_trandep
--create table tmp_cvme_trx_age_int_cli_trandep as
select distinct a.numregistro, a.fecdia, a.codagenteviabcp, x.codsucage, x.codubigeo, a.hortransaccion,a.tiptransaccionagenteviabcp, a.tipesttransaccionagenteviabcp, a.codmoneda, a.mtotransaccion, a.codclavecic, c.codclavecic as codclavecicg94, a.codclaveopectacargo, a.codclaveopectaabono,
b.codclavecic as codclaveciccli, b.codclaveopecta as codclaveopectacli
from S61751.TMP_movagente_i a--ods_v.hd_movimientoagenteviabcp a
inner join tmp_cvme_cuentas_cli b on a.codclaveopectaabono = b.codclaveopecta
left join ods_v.md_clienteg94 c on trim(a.codunicocli) = trim(c.codunicocli)
left join ods_v.md_agenteviabcp x on trim(a.codagenteviabcp) = trim(x.codagenteviabcp)
where  a.tiptransaccionagenteviabcp in ('03','05') and a.tipesttransaccionagenteviabcp = 'P' and a.fecdia between  trunc(add_months(sysdate, :intervalo_1),'mm') and trunc(last_day(add_months(sysdate,:intervalo_2)))
union all
select distinct a.numregistro, a.fecdia, a.codagenteviabcp, x.codsucage, x.codubigeo, a.hortransaccion,a.tiptransaccionagenteviabcp, a.tipesttransaccionagenteviabcp, a.codmoneda, a.mtotransaccion, a.codclavecic, c.codclavecic as codclavecicg94, a.codclaveopectacargo, a.codclaveopectaabono,
b.codclavecic as codclaveciccli, b.codclaveopecta as codclaveopectacli
from S61751.TMP_movagente_p a--ods_v.hd_movimientoagenteviabcp a
inner join tmp_cvme_cuentas_cli b on a.codclaveopectaabono = b.codclaveopecta
left join ods_v.md_clienteg94 c on trim(a.codunicocli) = trim(c.codunicocli)
left join ods_v.md_agenteviabcp x on trim(a.codagenteviabcp) = trim(x.codagenteviabcp)
where  a.tiptransaccionagenteviabcp in ('03','05') and a.tipesttransaccionagenteviabcp = 'P' and a.fecdia between  trunc(add_months(sysdate, :intervalo_1),'mm') and trunc(last_day(add_months(sysdate,:intervalo_2)));

--extraccion de trxs en canal cajero
---extraccion de int-cli
--extraccion en cajero - tranydep;
truncate table tmp_cvme_trx_caj_int_cli_trandep;
insert into tmp_cvme_trx_caj_int_cli_trandep
--create table tmp_cvme_trx_caj_int_cli_trandep as
with tmp as (
	select distinct a.numregistro, a.fecdia, a.hortransaccion, a.codtrancajero, a.flgvalida, a.codclavecic,
		a.codmonedatran, a.mtotransaccionsol, a.mtotransaccionme, c.codclaveopecta as codclaveopectahacia,
		c.codclavecic as codclaveciccli, c.codclaveopecta as codclaveopectacli,
		trim(a.codopectadesde) as codopectadesde, trim(a.codcajero) as codcajero
	from  ods_v.hd_movimientocajero a
		inner join tmp_cvme_cuentas_cli c on trim(a.codopectahacia) = c.codopecta
	where
		a.fecdia between  trunc(add_months(sysdate, :intervalo_1),'mm') and trunc(last_day(add_months(sysdate,:intervalo_2))) and
		codtrancajero in ('40','20') and
		flgvalida = 'S'
)
select distinct a.numregistro, a.codcajero, x.codsucage, x.codubigeo, a.fecdia, a.hortransaccion, a.codtrancajero, a.flgvalida, a.codclavecic,
	a.codmonedatran, a.mtotransaccionsol, a.mtotransaccionme, d.codclaveopecta as codclaveopectadesde, a.codclaveopectahacia,
	a.codclaveciccli, a.codclaveopectacli
from tmp a
left join ods_v.md_cuentag94 d on a.codopectadesde = trim(d.codopecta)
left join ods_v.md_cajero x on a.codcajero = trim(x.codcajero);

--extraccion de trxs en canal banca movil
---extraccion de int-cli
--extraccion en banca movil - tran ;
truncate table tmp_cvme_trx_bcamov_int_cli_tran;
insert into tmp_cvme_trx_bcamov_int_cli_tran
--create table tmp_cvme_trx_bcamov_int_cli_tran as
select distinct a.numtransaccionbcamovil,a.fectransaccion, a.hortransaccion,a.flgtransaccionvalida, a.tiptransaccionbcamovil, a.codmonedatransaccion, a.mtotransaccion, a.codclaveopectaorigen, a.codclaveopectadestino,
b.codclavecic as codclaveciccli, b.codclaveopecta as codclaveopectacli
from  S61751.TMP_movbcamovil_i a
inner join tmp_cvme_cuentas_cli b on a.codclaveopectadestino = b.codclaveopecta
where tiptransaccionbcamovil in (2) and a.fectransaccion between  trunc(add_months(sysdate, :intervalo_1),'mm') and trunc(last_day(add_months(sysdate,:intervalo_2)))
union all
select distinct a.numtransaccionbcamovil,a.fectransaccion, a.hortransaccion,a.flgtransaccionvalida, a.tiptransaccionbcamovil, a.codmonedatransaccion, a.mtotransaccion, a.codclaveopectaorigen, a.codclaveopectadestino,
b.codclavecic as codclaveciccli, b.codclaveopecta as codclaveopectacli
from  S61751.TMP_movbcamovil_p a
inner join tmp_cvme_cuentas_cli b on a.codclaveopectadestino = b.codclaveopecta
where tiptransaccionbcamovil in (2) and a.fectransaccion between  trunc(add_months(sysdate, :intervalo_1),'mm') and trunc(last_day(add_months(sysdate,:intervalo_2)));

--extraccion de trxs en canal homebanking
---extraccion de int-cli
create table tm_cvme_trx_hbk_int_cli_tran_1 as
select distinct a.codinternotransaccionhb, a.fecdia, a.hortransaccion, a.codopehbctr, a.tipresultadotransaccion,
a.mtotransaccion, a.codmoneda, a.codopectadestino,codopectaorigen
from
    ods_v.hd_movhomebankingtransaccion a
where a.codopehbctr in ('D_TRAN','TRAN_N','TRAN')
      and a.tipresultadotransaccion = 'OK' and a.fecdia between  trunc(add_months(sysdate, -7),'mm') and trunc(last_day(add_months(sysdate,-1)));

create table tm_cvme_trx_hbk_int_cli_tran_2 as
select distinct a.*,b.codclaveopecta as codclaveopectadestino
from
    tm_cvme_trx_hbk_int_cli_tran_1 a
    inner join ods_v.md_cuentag94 b on trim(a.codopectadestino) = trim(b.codopecta);

create table tm_cvme_trx_hbk_int_cli_tran_3 as
select distinct a.*,c.codclavecic as codclaveciccli, c.codclaveopecta as codclaveopectacli
from
    tm_cvme_trx_hbk_int_cli_tran_2 a
    inner join tmp_cvme_cuentas_cli c on a.codclaveopectadestino = c.codclaveopecta;

create table tm_cvme_trx_hbk_int_cli_tran_4 as
select distinct a.*,d.codclaveopecta as codclaveopectaorigen
from
    tm_cvme_trx_hbk_int_cli_tran_3 a
    inner join ods_v.md_cuentag94 d on trim(a.codopectaorigen) = trim(d.codopecta);

drop table  tmp_cvme_trx_hbk_int_cli_tran;
create table tmp_cvme_trx_hbk_int_cli_tran as
select distinct a.codinternotransaccionhb, a.fecdia, a.hortransaccion, a.codopehbctr, a.tipresultadotransaccion, a.mtotransaccion, a.codmoneda, a.codclaveopectaorigen, a.codclaveopectadestino,
a.codclaveciccli, a.codclaveopectacli
from
    tm_cvme_trx_hbk_int_cli_tran_4 a;

drop table tm_cvme_trx_hbk_int_cli_tran_1;
drop table tm_cvme_trx_hbk_int_cli_tran_2;
drop table tm_cvme_trx_hbk_int_cli_tran_3;
drop table tm_cvme_trx_hbk_int_cli_tran_4;

--extraccion de trxs en canal ventanilla
truncate table tmp_cvme_trx_ventanilla_ini;
insert into tmp_cvme_trx_ventanilla_ini
--create table tmp_cvme_trx_ventanilla_ini as
select
a.codinternotransaccion as numregistro,
a.fecdia,
a.horinitransaccion,
a.horfintransaccion,
a.codsucage,
a.codsesion,
a.codtransaccionventanilla,
a.flgtransaccionaprobada,
case when a.mtotransaccioncta <> 0 then a.codmonedacta else a.codmonedatransaccion end as codmoneda,
case when a.mtotransaccioncta <> 0 then a.mtotransaccioncta else a.mtotransaccion end as mtotransaccion,
a.codclaveopecta,
a.codclaveopectadestino
from ods_v.hd_transaccionventanilla a
where fecdia between  trunc(add_months(sysdate, :intervalo_1),'mm') and trunc(last_day(add_months(sysdate,:intervalo_2))) and
  codtransaccionventanilla in (60,62,63,159,186,187,188) and flgtransaccionaprobada = 'S';

---extraccion de int-cli
truncate table tmp_cvme_trx_vent_int_cli_trandep;
insert into tmp_cvme_trx_vent_int_cli_trandep
--create table tmp_cvme_trx_vent_int_cli_trandep as
select distinct
    a.numregistro, a.codsucage, a.fecdia, a.horinitransaccion, a.horfintransaccion, a.codtransaccionventanilla, a.flgtransaccionaprobada, a.codmoneda, a.mtotransaccion, c.codclavecic as codclavecicg94, a.codclaveopecta, a.codclaveopectadestino,
    d.codclavecic as codclaveciccli, d.codclaveopecta as codclaveopectacli
from tmp_cvme_trx_ventanilla_ini a
    left join ods_v.hd_movlavadodineroventanilla b on a.fecdia = b.fecdia and a.codsucage = b.codsucage and a.codsesion = b.codsesion and (b.codunicoclisolicitante <> '0000000000001' or b.codunicocliordenante <> '0000000000001')
    left join ods_v.md_clienteg94 c on coalesce(b.codunicoclisolicitante, b.codunicocliordenante) = trim(c.codunicocli)
    inner join tmp_cvme_cuentas_cli d on a.codclaveopectadestino = d.codclaveopecta
where a.codtransaccionventanilla in (60,62,63,159,186,187,188);

--extraccion de trxs en ggtt
truncate table tmp_cvme_docggtt;
insert into tmp_cvme_docggtt
--create table tmp_cvme_docggtt as
select distinct a.coddocggtt,a.numoperacionggtt, a.codsucage, a.fecdia, a.fecemision, a.horemision, a.codtipestadotransaccion, a.codproducto, a.codmoneda, a.mtoimporteoperacion, a.codclavecicsolicitante, a.codclavecicordenante, a.codclavecicbeneficiario, b.codclavecic as codclavecicbeneficiario_chqgen, a.codswiftbcoemisor, a.codswiftbcodestino, a.codpaisbcodestino
from ods_v.hd_documentoemitidoggtt a
left join ods_v.md_clienteg94 b on upper(regexp_replace(a.nbrclibeneficiario, '[^A-Z0-9]','')) = upper(regexp_replace(b.apepatcli || b.apematcli || b.nbrcli, '[^A-Z0-9]',''))
where a.fecdia between  trunc(add_months(sysdate, :intervalo_1),'mm') and trunc(last_day(add_months(sysdate,:intervalo_2))) and a.codtipestadotransaccion = '00';

--extraccion de int-cli
--extraccion de todo menos cheques de gerencia
truncate table tmp_cvme_trx_ggtt_nochqgen_int_cli;
insert into tmp_cvme_trx_ggtt_nochqgen_int_cli
--create table tmp_cvme_trx_ggtt_nochqgen_int_cli as
select distinct a.coddocggtt,a.numoperacionggtt, a.codsucage, a.fecdia, a.fecemision, a.horemision, a.codtipestadotransaccion, a.codproducto, a.codmoneda, a.mtoimporteoperacion, a.codclavecicsolicitante, a.codclavecicordenante, a.codclavecicbeneficiario, a.codswiftbcoemisor, a.codswiftbcodestino, a.codpaisbcodestino,
b.codclavecic as codclaveciccli
from
tmp_cvme_docggtt a
inner join tmp_cvme_codclavecics_cli b on a.codclavecicbeneficiario = b.codclavecic
where codproducto <> 'CHQGER';

--extraccion cheques de gerencia
truncate table tmp_cvme_trx_ggtt_chqgen_int_cli;
insert into tmp_cvme_trx_ggtt_chqgen_int_cli
--create table tmp_cvme_trx_ggtt_chqgen_int_cli as
select distinct a.coddocggtt,a.numoperacionggtt, a.codsucage, a.fecdia, a.fecemision, a.horemision, a.codtipestadotransaccion, a.codproducto, a.codmoneda, a.mtoimporteoperacion, a.codclavecicsolicitante, a.codclavecicordenante, a.codclavecicbeneficiario, a.codclavecicbeneficiario_chqgen, a.codswiftbcoemisor, a.codswiftbcodestino, a.codpaisbcodestino,
b.codclavecic as codclaveciccli
from
    tmp_cvme_docggtt a
    inner join tmp_cvme_codclavecics_cli b on a.codclavecicbeneficiario_chqgen = b.codclavecic
    where codproducto = 'CHQGER';

--extraccion de trxs en tabla transferencias del exterior
truncate table tmp_cvme_trx_remitt_int_cli_delext;
insert into tmp_cvme_trx_remitt_int_cli_delext
--create table tmp_cvme_trx_remitt_int_cli_delext as
select
a.numoperacionremittance, a.codsucursal, a.fecdia, a.hortransaccion, a.codproducto, a.codestadooperemittance, a.codmoneda, a.mtotransaccion, a.mtotransacciondol,-1 as codclaveopectaorigen, a.codclaveopectaafectada, a.codpaisorigen, a.codswiftinstordenante, a.codswiftbcoordenante,
b.codclavecic as codclaveciccli, b.codclaveopecta as codclaveopectacli
from ods_v.hd_movoperativoremittance  a
inner join tmp_cvme_cuentas_cli b on a.codclaveopectaafectada = b.codclaveopecta
where codproducto in ('TRAXAB','TRAXRE','TRAXVE') and codestadooperemittance = '7' and fecdia between  trunc(add_months(sysdate, :intervalo_1),'mm') and trunc(last_day(add_months(sysdate,:intervalo_2)));

--extraccion de transerencias interbancarias
--extraccion de int-cli
truncate table tmp_cvme_trx_ttib_int_cli_ttib;
insert into tmp_cvme_trx_ttib_int_cli_ttib
--create table tmp_cvme_trx_ttib_int_cli_ttib as
select distinct
a.numsecuencial, a.fectransaccion, a.hortransaccion, a.codopetransaccionttib, a.tipestttib, a.codmoneda, a.mtotransaccion, a.codctainterbanordenante, a.codclaveopectaordenante, a.codctainterbanbeneficiario, a.codclaveopectabeneficiario,
b.codclavecic as codclaveciccli, b.codclaveopecta as codclaveopectacli
from ods_v.hd_movimientottib a
inner join tmp_cvme_cuentas_cli b on a.codclaveopectabeneficiario = b.codclaveopecta
where a.tipestttib = '00' and a.codopetransaccionttib not in (223,221) and a.fectransaccion between trunc(add_months(sysdate, :intervalo_1),'mm') and trunc(last_day(add_months(sysdate,:intervalo_2)));
-----------------------------------------------------------------------------------------------------------------------

--consolidacion de trxs
truncate table tmp_cvme_int_cli;
insert into tmp_cvme_int_cli
--create table tmp_cvme_int_cli as
    --agente
      select
          t.numregistro, t.codsucage, l.codclavecic as codclavecicint,l.codclaveopecta as codclaveopectaint,
          ' ' as datoadicionalint,' ' as codpaisorigen,
          t.fecdia, t.hortransaccion, t.codmoneda, t.mtotransaccion, t.mtotransaccion * tc.mtocambioaldolar as mtodolarizado, to_char(t.tiptransaccionagenteviabcp) as codtransaccion, d.destiptransaccionagenteviabcp as tipotransaccion, 'AGENTE' as canal,
          t.codclaveciccli, t.codclaveopectacli
      from
          tmp_cvme_trx_age_int_cli_trandep t
          inner join ods_v.md_cuenta l on t.codclaveopectacargo = l.codclaveopecta
          left join ods_v.hd_tipocambiosaldodiario tc on t.fecdia = tc.fectipcambio and t.codmoneda = tc.codmoneda
          left join ods_v.md_destipotranagenteviabcp d on t.tiptransaccionagenteviabcp = d.tiptransaccionagenteviabcp
          where  t.tiptransaccionagenteviabcp = '03'
      union
      select
          t.numregistro, t.codsucage, t.codclavecicg94 as codclavecicint, -1 as codclaveopectaint,
          ' ' as datoadicionalint,' ' as codpaisorigen,
          t.fecdia, t.hortransaccion, t.codmoneda, t.mtotransaccion, t.mtotransaccion * tc.mtocambioaldolar as mtodolarizado, to_char(t.tiptransaccionagenteviabcp) as codtransaccion, d.destiptransaccionagenteviabcp as tipotransaccion, 'AGENTE' as canal,
          t.codclaveciccli,t.codclaveopectacli
      from
          tmp_cvme_trx_age_int_cli_trandep t
          left join ods_v.hd_tipocambiosaldodiario tc on t.fecdia = tc.fectipcambio and t.codmoneda = tc.codmoneda
          left join ods_v.md_destipotranagenteviabcp d on t.tiptransaccionagenteviabcp = d.tiptransaccionagenteviabcp
      where t.tiptransaccionagenteviabcp = '05' and t.codclavecicg94 is not null
      union
    --cajero
      select
          t.numregistro, t.codsucage, l.codclavecic as codclavecicint,t.codclaveopectadesde as codclaveopectaint,
          ' ' as datoadicionalint,' ' as codpaisorigen,
          t.fecdia, t.hortransaccion, t.codmonedatran, case when t.codmonedatran = '0001' then t.mtotransaccionsol else t.mtotransaccionme end as mtotransaccion, (case when t.codmonedatran = '0001' then t.mtotransaccionsol else t.mtotransaccionme end) * tc.mtocambioaldolar as mtodolarizado, to_char(t.codtrancajero) as codtransaccion, d.descodtrancajero as tipotransaccion, 'CAJERO' as canal,
          t.codclaveciccli,t.codclaveopectacli
      from
          tmp_cvme_trx_caj_int_cli_trandep t
          inner join ods_v.md_cuenta l on t.codclaveopectadesde = l.codclaveopecta
          left join ods_v.hd_tipocambiosaldodiario tc on t.fecdia = tc.fectipcambio and t.codmonedatran = tc.codmoneda
          left join ods_v.mm_descodigotransaccioncajero d on t.codtrancajero = d.codtrancajero
      where t.codtrancajero in ('40')
      union
      select
          t.numregistro, t.codsucage, t.codclavecic as codclavecicint,-1 as codclaveopectaint,
          ' ' as datoadicionalint,' ' as codpaisorigen,
          t.fecdia, t.hortransaccion, t.codmonedatran, case when t.codmonedatran = '0001' then t.mtotransaccionsol else t.mtotransaccionme end as mtotransaccion, (case when t.codmonedatran = '0001' then t.mtotransaccionsol else t.mtotransaccionme end) * tc.mtocambioaldolar as mtodolarizado, to_char(t.codtrancajero) as codtransaccion, d.descodtrancajero as tipotransaccion, 'CAJERO' AS CANAL,
          t.codclaveciccli, t.codclaveopectacli
      from
          tmp_cvme_trx_caj_int_cli_trandep t
          left join ods_v.hd_tipocambiosaldodiario tc on t.fecdia = tc.fectipcambio and t.codmonedatran = tc.codmoneda
          left join ods_v.mm_descodigotransaccioncajero d on t.codtrancajero = d.codtrancajero
      where t.codtrancajero in ('20') and t.codclavecic <> 0
      union
    --banca movil
      select
          to_char(t.numtransaccionbcamovil) as numtransaccionbcamovil, '' as codsucage, l.codclavecic as codclavecicint,l.codclaveopecta as codclaveopectaint,
          ' ' as datoadicionalint,' ' as codpaisorigen,
          t.fectransaccion, t.hortransaccion, t.codmonedatransaccion as codmoneda, t.mtotransaccion, t.mtotransaccion * tc.mtocambioaldolar as mtodolarizado, to_char(t.tiptransaccionbcamovil) as codtransaccion, d.destiptransaccionbcamovil as tipotransaccion, 'BANCA MOVIL' as canal,
          t.codclaveciccli,t.codclaveopectacli
      from
          tmp_cvme_trx_bcamov_int_cli_tran t
          inner join ods_v.md_cuenta l on t.codclaveopectaorigen = l.codclaveopecta
          left join ods_v.hd_tipocambiosaldodiario tc on t.fectransaccion = tc.fectipcambio and t.codmonedatransaccion = tc.codmoneda
          left join ods_v.mm_destiptransaccionbcamovil d on t.tiptransaccionbcamovil = d.tiptransaccionbcamovil
      union
    --homebanking
      select
          t.codinternotransaccionhb, '' as codsucage, l.codclavecic as codclavecicint,t.codclaveopectaorigen as codclaveopectaint,
          ' ' as datoadicionalint,' ' as codpaisorigen,
          t.fecdia, t.hortransaccion, t.codmoneda, t.mtotransaccion, t.mtotransaccion * tc.mtocambioaldolar as mtodolarizado, to_char(t.codopehbctr) as codtransaccion, d.descodopehbctr as tipotransaccion, 'HOMEBANKING' as canal,
          t.codclaveciccli, t.codclaveopectacli
      from
          tmp_cvme_trx_hbk_int_cli_tran t
          inner join ods_v.md_cuenta  l on t.codclaveopectaorigen = l.codclaveopecta
          left join ods_v.hd_tipocambiosaldodiario tc on t.fecdia = tc.fectipcambio and t.codmoneda = tc.codmoneda
          left join ods_v.md_descodigoopehbctr d on t.codopehbctr = d.codopehbctr
      union
    --ventanilla
      select
          to_char(t.numregistro) as numregistro, t.codsucage, t.codclavecicg94 as codclavecicint, -1 as codclaveopectaint,
          ' ' as datoadicionalint,' ' as codpaisorigen,
          t.fecdia, t.horinitransaccion, t.codmoneda, t.mtotransaccion, t.mtotransaccion * tc.mtocambioaldolar as mtodolarizado, to_char(t.codtransaccionventanilla) as codtransaccion, d.destransaccionventanilla as tipotransaccion, 'VENTANILLA' as canal,
          t.codclaveciccli,t.codclaveopectacli
      from
          tmp_cvme_trx_vent_int_cli_trandep t
          left join ods_v.hd_tipocambiosaldodiario tc on t.fecdia = tc.fectipcambio and t.codmoneda = tc.codmoneda
          left join ods_v.md_destransaccionventanilla d on t.codtransaccionventanilla = d.codtransaccionventanilla
      where t.codtransaccionventanilla in (60,62,63) and t.codclavecicg94 is not null
      union
      select
          to_char(t.numregistro) as numregistro, t.codsucage, l.codclavecic as codclavecicint,l.codclaveopecta as codclaveopectaint,
          ' ' as datoadicionalint,' ' as codpaisorigen,
          t.fecdia, t.horinitransaccion, t.codmoneda, t.mtotransaccion, t.mtotransaccion * tc.mtocambioaldolar as mtodolarizado, to_char(t.codtransaccionventanilla) as codtransaccion, d.destransaccionventanilla as tipotransaccion, 'VENTANILLA' as canal,
          t.codclaveciccli,t.codclaveopectacli
      from
          tmp_cvme_trx_vent_int_cli_trandep t
          inner join ods_v.md_cuenta l on t.codclaveopecta = l.codclaveopecta
          left join ods_v.hd_tipocambiosaldodiario tc on t.fecdia = tc.fectipcambio and t.codmoneda = tc.codmoneda
          left join ods_v.md_destransaccionventanilla d on t.codtransaccionventanilla = d.codtransaccionventanilla
      where t.codtransaccionventanilla in (159,186,187,188)
      union
    --ggtt
    	select
    		t.coddocggtt, t.codsucage, case when t.codclavecicordenante = 3288453 then -1 else t.codclavecicordenante end as codclavecicint, -1 as codclaveopectaint,
    		' ' as datoadicionalint, upper(p.nombrepais) as codpaisorigen,
    		t.fecdia, t.horemision, t.codmoneda, t.mtoimporteoperacion, t.mtoimporteoperacion * tc.mtocambioaldolar as mtodolarizado, to_char(t.codproducto) as codtransaccion, d.descodproducto as tipotransaccion, 'DOCUMENTOGGTT' as canal,
    		t.codclaveciccli, -1 as codclaveopectacli
    	from
    		tmp_cvme_trx_ggtt_nochqgen_int_cli t
    		left join ods_v.hd_tipocambiosaldodiario tc on t.fecdia = tc.fectipcambio and t.codmoneda = tc.codmoneda
    		left join ods_v.md_descodigoproducto d on t.codproducto = d.codproducto
    		left join s55632.md_codigopais p on substr(t.codswiftbcoemisor, 5, 2) = p.codpais2
      union
    	select
    		t.coddocggtt, t.codsucage, case when t.codclavecicordenante = 3288453 then -1 else t.codclavecicordenante end as codclavecicint, -1 as codclaveopectaint,
    		' ' as datoadicionalint, upper(p.nombrepais) as codpaisorigen,
    		t.fecdia, t.horemision, t.codmoneda, t.mtoimporteoperacion, t.mtoimporteoperacion * tc.mtocambioaldolar as mtodolarizado, to_char(t.codproducto) as codtransaccion, d.descodproducto as tipotransaccion, 'DOCUMENTOGGTT' as canal,
    		t.codclaveciccli, -1 as codclaveopectacli
    	from
    		tmp_cvme_trx_ggtt_chqgen_int_cli t
    		left join ods_v.hd_tipocambiosaldodiario tc on t.fecdia = tc.fectipcambio and t.codmoneda = tc.codmoneda
    		left join ods_v.md_descodigoproducto d on t.codproducto = d.codproducto
    		left join s55632.md_codigopais p on substr(t.codswiftbcoemisor, 5, 2) = p.codpais2
      union
    --remittance del exterior
    	select
    		t.numoperacionremittance, t.codsucursal, -1 as codclavecicint,-1 as codclaveopectaint,
    		' ' as datoadicionalint, upper(p.nombrepais) as codpaisorigen,
    		t.fecdia, t.hortransaccion, t.codmoneda, t.mtotransaccion, t.mtotransacciondol as mtodolarizado, to_char(t.codproducto) as codtransaccion, d.descodproducto as tipotransaccion, 'REMITTANCE' as canal,
    		t.codclaveciccli,t.codclaveopectacli
    	from
    		tmp_cvme_trx_remitt_int_cli_delext t
    		left join ods_v.md_descodigoproducto d on t.codproducto = d.codproducto
    		left join s55632.md_codigopais p on substr(coalesce(t.codswiftinstordenante, t.codswiftbcoordenante), 5, 2) = p.codpais2
      union
      --ttib
    	select
    		t.numsecuencial, '' as codsucage, -1 as codclavecicint, -1 as codclaveopectaint,
        ' ' as datoadicionalint, ' ' as codpaisdestino,
    		t.fectransaccion, t.hortransaccion, t.codmoneda, t.mtotransaccion, t.mtotransaccion * tc.mtocambioaldolar as mtodolarizado, to_char(t.codopetransaccionttib) as codtransaccion, d.destipoperacionttib as tipotransaccion, 'TTIB' as canal,
    		t.codclaveciccli, t.codclaveopectacli
    	from
    		tmp_cvme_trx_ttib_int_cli_ttib t
        left join ods_v.hd_tipocambiosaldodiario tc on t.fectransaccion = tc.fectipcambio and t.codmoneda = tc.codmoneda
        left join ods_v.md_destipoperacionttib d on t.codopetransaccionttib = d.tipoperacionttib;

--consolidacion
truncate table tmp_cvme_depositos;
insert into tmp_cvme_depositos
--create table tmp_cvme_depositos as
select to_number(to_char(fecdia, 'yyyymm')) as periodo,numregistro,codclaveciccli,fecdia,hortransaccion,mtodolarizado,canal,codtransaccion,tipotransaccion
from tmp_cvme_int_cli a
where codclavecicint <> codclaveciccli ;

--perfil total
truncate table tmp_cvme_perfi1;
insert into tmp_cvme_perfi1
--create table tmp_cvme_perfi1 as
with tmp_cvme_perfi1_aux as (
     select periodo, codclaveciccli as codclavecic,sum(mtodolarizado) as mto_depositos
     from tmp_cvme_depositos
     group by periodo, codclaveciccli
) select  a.codclavecic,a.periodo as numperiodo,b.periodo,
  months_between(to_date(a.periodo,'yyyymm'),to_date(b.periodo,'yyyymm')) meses,
  case when b.mto_depositos is null then 0 else b.mto_depositos end mto_depositos
  from tmp_cvme_perfi1_aux a
  inner join tmp_cvme_perfi1_aux b on a.codclavecic=b.codclavecic;

truncate table tmp_cvme_perfi2;
insert into tmp_cvme_perfi2
--create table tmp_cvme_perfi2 as
select numperiodo,codclavecic,mto_depositos
from tmp_cvme_perfi1 a
where numperiodo=periodo;

truncate table tmp_cvme_perfi3;
insert into tmp_cvme_perfi3
--create table tmp_cvme_perfi3 as
with temp_tab as(
  select numperiodo,codclavecic,
  avg(nullif(mto_depositos,0)) as media_depo,stddev(nullif(mto_depositos,0)) as desv_depo
  from tmp_cvme_perfi1
  where meses<=6 and meses>=1
  group by numperiodo,codclavecic
) select a.*,
  round(nvl(b.media_depo,0),2) media_depo,
  round(nvl(b.desv_depo,0),2) desv_depo
  from tmp_cvme_perfi2 a
  left join temp_tab b on (a.numperiodo=b.numperiodo and a.codclavecic=b.codclavecic);

-- creaci�n el flg perfil total en tabla cliente mes
truncate table tmp_cvme_perfildepositos;
insert into tmp_cvme_perfildepositos
--create table tmp_cvme_perfildepositos as
select  a.*,
case when b.mto_depositos is null then 0 else b.mto_depositos end mto_depositos,
case when b.media_depo <> 0 and b.desv_depo <> 0 and b.media_depo+3*b.desv_depo<b.mto_depositos then 1 else 0 end flg_perfil_depositos_3ds
from   tmp_cvme_ctddias a
left join tmp_cvme_perfi3 b on (a.periodo=b.numperiodo and a.codclavecic=b.codclavecic)
where periodo = to_number(to_char(add_months(sysdate, :intervalo_2),'yyyymm'));

--cerca a limite
truncate table tmp_cvme_ctdtrxlimite;
insert into tmp_cvme_ctdtrxlimite
--create table tmp_cvme_ctdtrxlimite as
with tmp_cvme_ctdtrxlimite_aux as (
  select d.coddepartamento, e.descoddepartamento,
  case when
       (trim(d.coddepartamento) in ('48') and mtodolarizado between 2500 and 3000) or
       (trim(d.coddepartamento) in ('10','42','46') and mtodolarizado between 7000 and 7500) or
       (trim(d.coddepartamento) not in ('10','42','46','48') and mtodolarizado between 9000 and 10000)
  then 1 else 0 end as limite_zaed_nozaed,
  b.*
  from tmp_cvme_trx_ventanilla b
  left join ods_v.md_agencia c on trim(b.codsucage) = trim(c.codsucage)
  left join ods_v.mm_distrito d on trim(c.coddistrito) = trim(d.coddistrito)
  left join ods_v.mm_departamento e on trim(d.coddepartamento) = trim(e.coddepartamento)
),
tmp_cvme_ctdtrxlimite_aux_2 as (
  select to_number(to_char(fecdia,'yyyymm')) as periodo, codclavecic_solicitante as codclavecic, sum(limite_zaed_nozaed) as ctd_trx_lim
  from tmp_cvme_ctdtrxlimite_aux
  group by to_number(to_char(fecdia,'yyyymm')), codclavecic_solicitante
)
  select a.*,
  case when b.ctd_trx_lim is null then 0 else b.ctd_trx_lim end as ctd_trx_lim
  from tmp_cvme_perfildepositos a
  left join tmp_cvme_ctdtrxlimite_aux_2 b on a.periodo = b.periodo and a.codclavecic = b.codclavecic;

--tablon y filtro de lista blanca cumplimiento
truncate table tmp_cvme_tablon;
insert into tmp_cvme_tablon
--create table tmp_cvme_tablon as
select a.*
from tmp_cvme_ctdtrxlimite a
left join s55632.rm_cumplimientolistablanca_tmp b on a.codclavecic = b.codclavecic
where b.codclavecic is null;

commit;
quit;