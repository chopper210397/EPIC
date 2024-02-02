--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

--variables sapyc: np - 2
truncate table tmp_escagente_np_aux2;
insert into tmp_escagente_np_aux2
--create table  tmp_escagente_np_aux2 as
select trim(a.codunicocli) as codunicocli, count(*) as ctdnp
from s61751.sapy_dmalerta a
     inner join s61751.sapy_dmevaluacion e on a.idcaso = e.idcaso
where a.idorigen = 2
group by trim(a.codunicocli);

truncate table tmp_escagente_np_solicitantes;
insert into tmp_escagente_np_solicitantes
--create table tmp_escagente_np_solicitantes as
select a.*, case when b.ctdnp is not null then 1 else 0 end flgnp,case when b.ctdnp is not null then b.ctdnp else 0 end ctdnp
from tmp_escagente_solicitantes a
left join ods_v.md_clienteg94 x on a.codclavecicsolicitante = x.codclavecic
left join tmp_escagente_np_aux2 b on trim(x.codunicocli) = trim(b.codunicocli);

--variables sapyc: lsb - 29
truncate table tmp_escagente_lsb_aux2;
insert into tmp_escagente_lsb_aux2
--create table tmp_escagente_lsb_aux2 as
select trim(a.codunicocli) as codunicocli, count(*) as ctdlsb
from s61751.sapy_dmalerta a
     inner join s61751.sapy_dmevaluacion e on a.idcaso = e.idcaso
where a.idorigen = 29
group by trim(a.codunicocli);

truncate table tmp_escagente_lsb_solicitantes;
insert into tmp_escagente_lsb_solicitantes
--create table  tmp_escagente_lsb_solicitantes as
select a.*, case when b.ctdlsb is not null then 1 else 0 end flglsb,case when b.ctdlsb is not null then b.ctdlsb else 0 end ctdlsb
from tmp_escagente_np_solicitantes a
left join ods_v.md_clienteg94 x on a.codclavecicsolicitante = x.codclavecic
left join tmp_escagente_lsb_aux2 b on trim(x.codunicocli) = trim(b.codunicocli);

--variables archivo negativo
truncate table tmp_escagente_archnegativo_solicitantes;
insert into tmp_escagente_archnegativo_solicitantes
--create table tmp_escagente_archnegativo_solicitantes as
with tmp_escagente_archivonegativo_aux as (
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
  from tmp_escagente_lsb_solicitantes a
  left join tmp_escagente_archivonegativo_aux b on a.codclavecicsolicitante = b.codclavecic;

truncate table tmp_escagente_flg_nplsban;
insert into tmp_escagente_flg_nplsban
--create table  tmp_escagente_flg_nplsban as
select codclavecicsolicitante, case when flgnp = 1 or flglsb = 1 or flgarchivonegativo = 1 then 1 else 0 end flgnplsban
from tmp_escagente_archnegativo_solicitantes;

truncate table tmp_escagente_ctd_sol_nplsban;
insert into tmp_escagente_ctd_sol_nplsban
--create table  tmp_escagente_ctd_sol_nplsban as
with tmp_escagente_ctd_sol_nplsban_aux as
(
select  to_number(to_char(a.fecdia,'yyyymm')) as periodo, a.codagenteviabcp,
sum(case when ingresoegresoagente = 'E' then c.flgnplsban else 0 end) as ctd_an_np_lsb,
sum(case when ingresoegresoagente = 'E' and c.flgnplsban = 1 then a.mtodolarizado else 0 end) as mto_an_np_lsb
from tmp_escagente_trx a
left join tmp_escagente_flg_nplsban c on a.codclavecicsolicitante = c.codclavecicsolicitante
group by to_number(to_char(a.fecdia,'yyyymm')), a.codagenteviabcp
) select a.*,
  case when b.ctd_an_np_lsb is null then 0 else b.ctd_an_np_lsb end as ctd_an_np_lsb,
  case when b.mto_an_np_lsb is null then 0 else b.mto_an_np_lsb end as mto_an_np_lsb
  from tmp_escagente_zonazaed a
  left join tmp_escagente_ctd_sol_nplsban_aux b on a.periodo = b.periodo and a.codagenteviabcp = b.codagenteviabcp;

--extraer ctd de evaluaciones del agente
truncate table tmp_escagente_sapyc;
insert into tmp_escagente_sapyc
--create table tmp_escagente_sapyc as
select a.*
from (
   select a.idcaso, a.codunicocli, a.idresultado as idresultadoeval, b.idresultadosupervisor
   from s61751.sapy_dmevaluacion a left join s61751.sapy_dminvestigacion b on a.idcaso = b.idcaso
) a;

truncate table tmp_escagente_evals;
insert into tmp_escagente_evals
--create table tmp_escagente_evals as
with tmp_escagente_evals_aux as
(
  select a.codclavecic, count(*) as ctdevals
  from tmp_escagente_ctd_sol_nplsban a
  left join ods_v.md_clienteg94 x on a.codclavecic = x.codclavecic
  left join tmp_escagente_sapyc b on trim(x.codunicocli) = trim(b.codunicocli)
  where idresultadoeval <> 7
  group by a.codclavecic
)
  select a.*,
  case when b.ctdevals is not null then b.ctdevals else 0 end as ctdeval
  from tmp_escagente_ctd_sol_nplsban a
  left join tmp_escagente_evals_aux b on a.codclavecic = b.codclavecic;

--extraer ctd de evaluaciones de propietarios del agente
--gerentes: gad,gap,gco,gfi,ggr,gsp,gte
--representante legal: rlg
truncate table tmp_escagente_cic_empresas;
insert into tmp_escagente_cic_empresas
--create table tmp_escagente_cic_empresas as
    select distinct a.codclavecic
    from tmp_escagente_evals a
    left join ods_v.md_cliente b on a.codclavecic = b.codclavecic
    where trim(b.tipper) = 'E' ;

truncate table tmp_escagente_rel_empresas;
insert into tmp_escagente_rel_empresas
--create table tmp_escagente_rel_empresas as
    select a.codclavecic as codclavecic_rel,a.codclavecicclirel as codclavecic_emp
    from   ods_v.mm_relacioncliente a
    inner join tmp_escagente_cic_empresas b on a.codclavecicclirel = b.codclavecic
    where  codrel in ('GAD','GAP','GCO','GFI','GGR','GSP','GTE','RLG') or
           codtiprel in ('AC');

truncate table tmp_escagente_rel_empresas_final;
insert into tmp_escagente_rel_empresas_final
--create table tmp_escagente_rel_empresas_final as
  select a.codclavecic_emp, a.codclavecic_rel, b.codunicocli as codunicocli_rel
  from   tmp_escagente_rel_empresas a
       left join ods_v.md_clienteg94 b on a.codclavecic_rel=b.codclavecic;

truncate table tmp_escagente_evals_prop;
insert into tmp_escagente_evals_prop
--create table  tmp_escagente_evals_prop as
with tmp_escagente_evals_aux as
(
  select a.codclavecic_emp, a.codclavecic_rel, count(*) as ctdevals
  from tmp_escagente_rel_empresas_final a
  left join tmp_escagente_sapyc b on trim(a.codunicocli_rel) = trim(b.codunicocli)
  where idresultadoeval <> 7
  group by a.codclavecic_emp, a.codclavecic_rel
),
tmp_escagente_evals_aux2 as
(
  select a.codclavecic_emp, sum(ctdevals) as ctd_evals_prop
  from tmp_escagente_evals_aux a
  group by a.codclavecic_emp
) select a.*,
  case when b.ctd_evals_prop is not null then b.ctd_evals_prop else 0 end as ctd_evals_prop
  from tmp_escagente_evals a
  left join tmp_escagente_evals_aux2 b on a.codclavecic = b.codclavecic_emp;

--extraer tablon final
truncate table tmp_escagente_tablon;
insert into tmp_escagente_tablon
--create table  tmp_escagente_tablon as
select *
from tmp_escagente_evals_prop;

commit;
quit;