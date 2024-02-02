--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

var intervalo_1 number
exec :intervalo_1 := to_number(&2);

select :intervalo_1;

--extraer montos y cantidades de depositos cash, retiros cash y trxs sin cta agente
truncate table tmp_escagente_varagrupadas;
insert into tmp_escagente_varagrupadas
--create table tmp_escagente_varagrupadas as
select  to_number(to_char(a.fecdia,'yyyymm')) as periodo, a.codagenteviabcp, b.codclavecic, a.codclaveopectaagente,
sum(case when ingresoegresoagente = 'E' then a.mtodolarizado else 0 end) as mto_cash_depo,
sum(case when ingresoegresoagente = 'E' then 1 else 0 end) as ctd_cash_depo,
sum(case when ingresoegresoagente = 'I' then a.mtodolarizado else 0 end) as mto_cash_ret,
sum(case when ingresoegresoagente = 'I' then 1 else 0 end) as ctd_cash_ret,
sum(case when ingresoegresoagente = '.' then 1 else 0 end) as ctd_trxs_sinctaagente
from tmp_escagente_trx a
left join ods_v.md_cuenta b on a.codclaveopectaagente = b.codclaveopecta
group by to_number(to_char(a.fecdia,'yyyymm')), a.codagenteviabcp, b.codclavecic, a.codclaveopectaagente;

--extraer antiguedad
truncate table tmp_escagente_antiguedad;
insert into tmp_escagente_antiguedad
--create table tmp_escagente_antiguedad as
with tmp_proc_antig_aux as
(
select a.periodo,a.codagenteviabcp,b.fecapertura,
  floor(months_between(last_day(to_date(to_char(periodo||'01'),'yyyymmdd')), b.fecapertura) ) as antiguedad
  from tmp_escagente_varagrupadas a
  left join ods_v.md_impac b on a.codclaveopectaagente = b.codclaveopecta
)
select a.*, b.fecapertura, b.antiguedad
  from tmp_escagente_varagrupadas a
  left join tmp_proc_antig_aux b on a.periodo = b.periodo and a.codagenteviabcp = b.codagenteviabcp
  where b.antiguedad > 0;

--extraer actividad economica no definida
truncate table tmp_escagente_acteconomica_nodef_aux;
insert into tmp_escagente_acteconomica_nodef_aux
--create table tmp_escagente_acteconomica_nodef_aux as
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

truncate table tmp_escagente_acteconomica_nodef;
insert into tmp_escagente_acteconomica_nodef
--create table tmp_escagente_acteconomica_nodef as
   select a.*, b.codacteconomica, d.desacteconomica,
         case
             when b.codacteconomica is null then 1
             when c.codacteconomica is not null then 1
             else 0
         end flg_acteco_nodef
  from tmp_escagente_antiguedad a
    left join ods_v.md_cliente b on a.codclavecic = b.codclavecic
    left join tmp_escagente_acteconomica_nodef_aux c on trim(b.codacteconomica) = trim(c.codacteconomica)
    left join ods_v.mm_descodactividadeconomica d on trim(b.codacteconomica) = trim(d.codacteconomica);

--extraer perfil de montos cash sobre los 6 ultimos meses
truncate table tmp_escagente_perfi1;
insert into tmp_escagente_perfi1
--create table tmp_escagente_perfi1 as
select  a.codagenteviabcp,a.periodo as numperiodo,b.periodo,
months_between(to_date(a.periodo,'yyyymm'),to_date(b.periodo,'yyyymm')) meses,
case when b.mto_cash_depo is null then 0 else b.mto_cash_depo end mto_cash_depo
from tmp_escagente_acteconomica_nodef a
inner join tmp_escagente_acteconomica_nodef b on (a.codagenteviabcp=b.codagenteviabcp);

truncate table tmp_escagente_perfi2;
insert into tmp_escagente_perfi2
--create table tmp_escagente_perfi2 as
select numperiodo,codagenteviabcp,mto_cash_depo
from tmp_escagente_perfi1 a
where numperiodo=periodo;

truncate table tmp_escagente_perfi3;
insert into tmp_escagente_perfi3
--create table  tmp_escagente_perfi3 as
with temp_tab as(
  select numperiodo,codagenteviabcp,
  avg(nullif(mto_cash_depo,0)) as media_cash_depo,stddev(nullif(mto_cash_depo,0)) as desv_cash_depo
  from tmp_escagente_perfi1
  where meses<=6 and meses>=1
  group by numperiodo,codagenteviabcp
) select a.*,
  round(nvl(b.media_cash_depo,0),2) media_cash_depo,round(nvl(b.desv_cash_depo,0),2) desv_cash_depo
  from tmp_escagente_perfi2 a
  left join temp_tab b on (a.numperiodo=b.numperiodo and a.codagenteviabcp=b.codagenteviabcp);

truncate table tmp_escagente_perfil_mtocashdepo;
insert into tmp_escagente_perfil_mtocashdepo
--create table tmp_escagente_perfil_mtocashdepo as
select  a.*,
case when b.media_cash_depo <> 0 and b.desv_cash_depo <> 0 and b.media_cash_depo+3*b.desv_cash_depo<b.mto_cash_depo then 1 else 0 end flg_perfil_cash_depo_3ds
from   tmp_escagente_acteconomica_nodef a
left join tmp_escagente_perfi3 b on (a.periodo=b.numperiodo and a.codagenteviabcp=b.codagenteviabcp)
where a.periodo = to_number(to_char(add_months(sysdate, :intervalo_1),'yyyymm'));

--EXTRAER TRXS FUERA DE HORARIO
truncate table tmp_escagente_fuera_horario;
insert into tmp_escagente_fuera_horario
--create table tmp_escagente_fuera_horario as
with tmp_escagente_fuera_horario_aux as
(
  select to_number(to_char(a.fecdia,'yyyymm')) as periodo, a.codagenteviabcp,
  sum(case when hortransaccion > 230000 or hortransaccion < 060000 then 1 else 0 end) as ctd_trxsfuerahorario
  from tmp_escagente_trx a
  where hortransaccion > 230000 or hortransaccion < 060000
  group by to_number(to_char(a.fecdia,'yyyymm')), a.codagenteviabcp
) select  a.*, case when b.ctd_trxsfuerahorario is null then 0 else b.ctd_trxsfuerahorario end as ctd_trxsfuerahorario
  from tmp_escagente_perfil_mtocashdepo a
  left join tmp_escagente_fuera_horario_aux b on a.periodo = b.periodo and a.codagenteviabcp = b.codagenteviabcp;

--extraer promedio de trxs de depositos por dia en el mes y ctd de dias donde hubo depositos
truncate table tmp_escagente_prom_dias_depo;
insert into tmp_escagente_prom_dias_depo
--create table  tmp_escagente_prom_dias_depo as
with tmp_escagente_promdias_depo_1 as
(
select to_number(to_char(a.fecdia,'yyyymm')) as periodo, a.fecdia, a.codagenteviabcp, count(*) as ctddepodiarios
from tmp_escagente_trx a
where ingresoegresoagente = 'E'
group by to_number(to_char(a.fecdia,'yyyymm')), a.fecdia, a.codagenteviabcp
),
tmp_escagente_promdias_depo_2 as
(
select periodo, codagenteviabcp, round(avg(ctddepodiarios),2) as prom_depodiarios, count(*) as ctd_diasdepo
from tmp_escagente_promdias_depo_1 a
group by periodo, codagenteviabcp
)
select a.*,
case when b.prom_depodiarios is null then 0 else b.prom_depodiarios end as prom_depodiarios,
case when b.ctd_diasdepo is null then 0 else b.ctd_diasdepo end as ctd_diasdepo
from tmp_escagente_fuera_horario a
left join tmp_escagente_promdias_depo_2 b on a.periodo = b.periodo and a.codagenteviabcp = b.codagenteviabcp;

--extraer promedio de trxs de retiros por dia en el mes y ctd de dias donde hubo retiros
truncate table tmp_escagente_prom_dias_ret;
insert into tmp_escagente_prom_dias_ret
--create table  tmp_escagente_prom_dias_ret as
with tmp_escagente_promdias_ret_1 as
(
select to_number(to_char(a.fecdia,'yyyymm')) as periodo, a.fecdia, a.codagenteviabcp, count(*) as ctdretdiarios
from tmp_escagente_trx a
where ingresoegresoagente = 'I'
group by to_number(to_char(a.fecdia,'yyyymm')), a.fecdia, a.codagenteviabcp
),
tmp_escagente_promdias_ret_2 as
(
select periodo, codagenteviabcp, round(avg(ctdretdiarios),2) as prom_retdiarios, count(*) as ctd_diasret
from tmp_escagente_promdias_ret_1 a
group by periodo, codagenteviabcp
)
select a.*,
case when b.prom_retdiarios is null then 0 else b.prom_retdiarios end as prom_retdiarios,
case when b.ctd_diasret is null then 0 else b.ctd_diasret end as ctd_diasret
from tmp_escagente_prom_dias_depo a
left join tmp_escagente_promdias_ret_2 b on a.periodo = b.periodo and a.codagenteviabcp = b.codagenteviabcp;

--extraer zona zaed donde se realizo la trx
truncate table tmp_escagente_zonazaed;
insert into tmp_escagente_zonazaed
--create table tmp_escagente_zonazaed as
with tmp_escagente_codsucage as (
select distinct a.codagenteviabcp,a.codsucage from ods_v.md_agenteviabcp a
)
select a.*,b.codsucage,d.coddepartamento,e.descoddepartamento,
case when trim(d.coddepartamento) in ('10','42','46','48') then 2
when trim(d.coddepartamento) in ('30') then 1 else 3 end tipo_zona
from tmp_escagente_prom_dias_ret a
left join tmp_escagente_codsucage b on a.codagenteviabcp = b.codagenteviabcp
left join ods_v.md_agencia c on trim(b.codsucage) = trim(c.codsucage)
left join ods_v.mm_distrito d on trim(c.coddistrito) = trim(d.coddistrito)
left join ods_v.mm_departamento e on trim(d.coddepartamento) = trim(e.coddepartamento);

--extraer ctd y monto de solicitantes que han tenido np lsb o arch negativo
--extraer lista solicitantes
truncate table tmp_escagente_solicitantes;
insert into tmp_escagente_solicitantes
--create table tmp_escagente_solicitantes as
select codclavecicsolicitante
from tmp_escagente_trx
group by codclavecicsolicitante;

commit;
quit;