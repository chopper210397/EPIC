--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

--universo de clientes
truncate table tmp_cvme_universo_cli;
insert into tmp_cvme_universo_cli
--create table tmp_cvme_universo_cli as
with tmp_cvme_cli_aux as (
  select to_number(to_char(a.fecdia,'yyyymm')) as periodo, a.solicitante, b.codclavecic
  from tmp_cvme_trx_ventanilla_ord a
  left join ods_v.md_clienteg94 b on trim(a.solicitante) = trim(b.codunicocli)
  group by to_number(to_char(a.fecdia,'yyyymm')), a.solicitante, b.codclavecic
),
tmp_cvme_cli_aux_2 as (
  select periodo, solicitante, count(*) as ctd
  from tmp_cvme_cli_aux
  group by periodo,solicitante
  having count(*) > 1
) select distinct a.periodo,a.solicitante, a.codclavecic
  from tmp_cvme_cli_aux a
  left join tmp_cvme_cli_aux_2 b on a.periodo = b.periodo and trim(a.solicitante) = trim(b.solicitante)
  where a.codclavecic is not null and a.codclavecic <> 0 and (b.periodo is null or b.solicitante is null);

--ajuste del universo de trxs segun el universo de clientes
truncate table tmp_cvme_trx_ventanilla;
insert into tmp_cvme_trx_ventanilla
--create table tmp_cvme_trx_ventanilla as
select a.numregistro,a.fecdia,a.horinitransaccion,a.horfintransaccion,a.codsucage,a.codsesion,a.codtransaccionventanilla,a.flgtransaccionaprobada,a.tiproltransaccion,a.codmoneda,a.mtotransaccion,a.mtodolarizado,
a.codclaveopecta,a.codclaveopectadestino,b.codclavecic as codclavecic_solicitante, a.ordenante
from tmp_cvme_trx_ventanilla_ord a
inner join tmp_cvme_universo_cli b on to_number(to_char(a.fecdia,'yyyymm')) = b.periodo and trim(a.solicitante) = trim(b.solicitante);

commit;
quit;