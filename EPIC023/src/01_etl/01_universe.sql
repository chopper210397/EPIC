--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

create table tmp_cvme_trx_ventanilla_uni_aux_1_aux_01 as
select
  a.codinternotransaccion as numregistro,
  a.fecdia,
  a.horinitransaccion,
  a.horfintransaccion,
  a.codsucage,
  a.codsesion,
  a.codtransaccionventanilla,
  a.flgtransaccionaprobada,
  a.tiproltransaccion,
  mtotransaccioncta,
  case when a.mtotransaccioncta <> 0 then a.codmonedacta else a.codmonedatransaccion end as codmoneda,
  case when a.mtotransaccioncta <> 0 then a.mtotransaccioncta else a.mtotransaccion end as mtotransaccion,
  a.codclaveopecta,
  codmonedacta,
  codmonedatransaccion,
  a.codclaveopectadestino
from ods_v.hd_transaccionventanilla a
where
  a.fecdia between  trunc(add_months(sysdate, -2),'mm') and trunc(last_day(add_months(sysdate,-1))) and
  a.codtransaccionventanilla in (41,169,176,179) and a.flgtransaccionaprobada = 'S';

create table tmp_cvme_trx_ventanilla_uni_aux_1_aux_02 as
select
  a.codinternotransaccion as numregistro,
  a.fecdia,
  a.horinitransaccion,
  a.horfintransaccion,
  a.codsucage,
  a.codsesion,
  a.codtransaccionventanilla,
  a.flgtransaccionaprobada,
  a.tiproltransaccion,
  mtotransaccioncta,
  case when a.mtotransaccioncta <> 0 then a.codmonedacta else a.codmonedatransaccion end as codmoneda,
  case when a.mtotransaccioncta <> 0 then a.mtotransaccioncta else a.mtotransaccion end as mtotransaccion,
  a.codclaveopecta,
  codmonedacta,
  codmonedatransaccion,
  a.codclaveopectadestino
from ods_v.hd_transaccionventanilla a
where
  a.fecdia between  trunc(add_months(sysdate, -4),'mm') and trunc(last_day(add_months(sysdate,-3))) and
  a.codtransaccionventanilla in (41,169,176,179) and a.flgtransaccionaprobada = 'S';

create table tmp_cvme_trx_ventanilla_uni_aux_1_aux_03 as
select
  a.codinternotransaccion as numregistro,
  a.fecdia,
  a.horinitransaccion,
  a.horfintransaccion,
  a.codsucage,
  a.codsesion,
  a.codtransaccionventanilla,
  a.flgtransaccionaprobada,
  a.tiproltransaccion,
  mtotransaccioncta,
  case when a.mtotransaccioncta <> 0 then a.codmonedacta else a.codmonedatransaccion end as codmoneda,
  case when a.mtotransaccioncta <> 0 then a.mtotransaccioncta else a.mtotransaccion end as mtotransaccion,
  a.codclaveopecta,
  codmonedacta,
  codmonedatransaccion,
  a.codclaveopectadestino
from ods_v.hd_transaccionventanilla a
where
  a.fecdia between  trunc(add_months(sysdate, -6),'mm') and trunc(last_day(add_months(sysdate,-5))) and
  a.codtransaccionventanilla in (41,169,176,179) and a.flgtransaccionaprobada = 'S';

create table tmp_cvme_trx_ventanilla_uni_aux_1_aux_04 as
select
  a.codinternotransaccion as numregistro,
  a.fecdia,
  a.horinitransaccion,
  a.horfintransaccion,
  a.codsucage,
  a.codsesion,
  a.codtransaccionventanilla,
  a.flgtransaccionaprobada,
  a.tiproltransaccion,
  mtotransaccioncta,
  case when a.mtotransaccioncta <> 0 then a.codmonedacta else a.codmonedatransaccion end as codmoneda,
  case when a.mtotransaccioncta <> 0 then a.mtotransaccioncta else a.mtotransaccion end as mtotransaccion,
  a.codclaveopecta,
  codmonedacta,
  codmonedatransaccion,
  a.codclaveopectadestino
from ods_v.hd_transaccionventanilla a
where
  a.fecdia between  trunc(add_months(sysdate, -7),'mm') and trunc(last_day(add_months(sysdate,-7))) and
  a.codtransaccionventanilla in (41,169,176,179) and a.flgtransaccionaprobada = 'S';

drop table tmp_cvme_trx_ventanilla_uni_aux_1;
insert into tmp_cvme_trx_ventanilla_uni_aux_1
select * from tmp_cvme_trx_ventanilla_uni_aux_1_aux_01
union all
select * from tmp_cvme_trx_ventanilla_uni_aux_1_aux_02
union all
select * from tmp_cvme_trx_ventanilla_uni_aux_1_aux_03
union all
select * from tmp_cvme_trx_ventanilla_uni_aux_1_aux_04;
commit;

truncate table tmp_cvme_trx_ventanilla_uni_aux;
insert into tmp_cvme_trx_ventanilla_uni_aux
--create table tmp_cvme_trx_ventanilla_uni_aux as
select
  a.numregistro,
  a.fecdia,
  a.horinitransaccion,
  a.horfintransaccion,
  a.codsucage,
  a.codsesion,
  a.codtransaccionventanilla,
  a.flgtransaccionaprobada,
  a.tiproltransaccion,
  a.codmoneda,
  a.mtotransaccion,
  case when a.mtotransaccioncta <> 0 then a.mtotransaccioncta else a.mtotransaccion end*b.mtocambioaldolar as mtodolarizado,
  a.codclaveopecta,
  a.codclaveopectadestino,
  b.codunicoclisolicitante as solicitante
from tmp_cvme_trx_ventanilla_uni_aux_1 a
left join ods_v.hd_movlavadodineroventanilla b on a.fecdia = b.fecdia and a.codsucage = b.codsucage and a.codsesion = b.codsesion
left join ods_v.hd_tipocambiosaldodiario b on a.fecdia = b.fectipcambio and a.codmoneda = b.codmoneda
where
  case when a.mtotransaccioncta <> 0 then a.mtotransaccioncta else a.mtotransaccion end*b.mtocambioaldolar > 100;

--ajuste del solicitante
truncate table tmp_cvme_trx_ventanilla_sol;
insert into tmp_cvme_trx_ventanilla_sol
--create table tmp_cvme_trx_ventanilla_sol as
select
numregistro,fecdia,horinitransaccion,horfintransaccion,codsucage,codsesion,codtransaccionventanilla,flgtransaccionaprobada,tiproltransaccion,codmoneda,mtotransaccion,mtodolarizado,
codclaveopecta,codclaveopectadestino,max(solicitante) as solicitante
from tmp_cvme_trx_ventanilla_uni_aux a
group by numregistro,fecdia,horinitransaccion,horfintransaccion,codsucage,codsesion,codtransaccionventanilla,flgtransaccionaprobada,tiproltransaccion,codmoneda,mtotransaccion,mtodolarizado,
codclaveopecta,codclaveopectadestino;

--ajuste del ordenante
truncate table tmp_cvme_trx_ventanilla_ord_aux;
insert into tmp_cvme_trx_ventanilla_ord_aux
--create table tmp_cvme_trx_ventanilla_ord_aux as
select
a.*, b.codunicocliordenante as ordenante
from tmp_cvme_trx_ventanilla_sol a
left join (
  select fecdia,codsucage,codsesion,codunicocliordenante,codtransaccionventanilla
  from ods_v.hd_movlavadodineroventanilla
  where codtransaccionventanilla in (41,169,176,179)
) b on a.fecdia = b.fecdia and a.codsucage = b.codsucage and a.codsesion = b.codsesion;

truncate table tmp_cvme_trx_ventanilla_ord;
insert into tmp_cvme_trx_ventanilla_ord
--create table tmp_cvme_trx_ventanilla_ord as
select
a.numregistro,a.fecdia,a.horinitransaccion,a.horfintransaccion,a.codsucage,a.codsesion,a.codtransaccionventanilla,a.flgtransaccionaprobada,a.tiproltransaccion,a.codmoneda,a.mtotransaccion,a.mtodolarizado,
a.codclaveopecta,codclaveopectadestino,solicitante, max(ordenante) as ordenante
from tmp_cvme_trx_ventanilla_ord_aux a
where trim(tiproltransaccion) = 'F'
group by a.numregistro,a.fecdia,a.horinitransaccion,a.horfintransaccion,a.codsucage,a.codsesion,a.codtransaccionventanilla,a.flgtransaccionaprobada,a.tiproltransaccion,a.codmoneda,a.mtotransaccion,a.mtodolarizado,
a.codclaveopecta,a.codclaveopectadestino,a.solicitante;

commit;
quit;