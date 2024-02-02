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

--extraer codclavecics del universo de clientes
truncate table tmp_clinuevo_codclavecics_cli;
insert into tmp_clinuevo_codclavecics_cli
--create table tmp_clinuevo_codclavecics_cli tablespace d_aml_99 as
select distinct codclavecic
from tmp_clinuevo_universo_cli;

truncate table tmp_clinuevo_cuentas_cli;
insert into tmp_clinuevo_cuentas_cli
--create table tmp_clinuevo_cuentas_cli tablespace d_aml_99 as
select a.codclavecic, b.codclaveopecta
from tmp_clinuevo_codclavecics_cli a
inner join ods_v.md_cuenta  b on a.codclavecic = b.codclavecic
where
trim(codsistemaorigen) in ('BAN','IMP','SAV','RT','GT');

--extraccion de trxs en canal agente
---extraccion de int-cli
--extraccion en agente - tranydep;
truncate table tmp_clinuevo_trx_age_int_cli_trandep;
insert into tmp_clinuevo_trx_age_int_cli_trandep
--create table tmp_clinuevo_trx_age_int_cli_trandep tablespace d_aml_99 as
select distinct a.numregistro, a.fecdia, a.codagenteviabcp, x.codsucage, x.codubigeo, a.hortransaccion,a.tiptransaccionagenteviabcp, a.tipesttransaccionagenteviabcp, a.codmoneda, a.mtotransaccion, a.codclavecic, c.codclavecic as codclavecicg94, a.codclaveopectacargo, a.codclaveopectaabono,
b.codclavecic as codclaveciccli, b.codclaveopecta as codclaveopectacli
from t23377.tmp_movagente_i a --ods_v.hd_movimientoagenteviabcp a
inner join tmp_clinuevo_cuentas_cli b on a.codclaveopectaabono = b.codclaveopecta
left join ods_v.md_clienteg94 c on trim(a.codunicocli) = trim(c.codunicocli)
left join ods_v.md_agenteviabcp x on trim(a.codagenteviabcp) = trim(x.codagenteviabcp)
where  a.tiptransaccionagenteviabcp in ('03','05') and a.tipesttransaccionagenteviabcp = 'P' and a.fecdia between trunc(add_months(sysdate, :intervalo_1),'mm') and trunc(last_day(add_months(sysdate,:intervalo_2)))
union all
select distinct a.numregistro, a.fecdia, a.codagenteviabcp, x.codsucage, x.codubigeo, a.hortransaccion,a.tiptransaccionagenteviabcp, a.tipesttransaccionagenteviabcp, a.codmoneda, a.mtotransaccion, a.codclavecic, c.codclavecic as codclavecicg94, a.codclaveopectacargo, a.codclaveopectaabono,
b.codclavecic as codclaveciccli, b.codclaveopecta as codclaveopectacli
from t23377.tmp_movagente_p a --ods_v.hd_movimientoagenteviabcp a
inner join tmp_clinuevo_cuentas_cli b on a.codclaveopectaabono = b.codclaveopecta
left join ods_v.md_clienteg94 c on trim(a.codunicocli) = trim(c.codunicocli)
left join ods_v.md_agenteviabcp x on trim(a.codagenteviabcp) = trim(x.codagenteviabcp)
where  a.tiptransaccionagenteviabcp in ('03','05') and a.tipesttransaccionagenteviabcp = 'P' and a.fecdia between trunc(add_months(sysdate, :intervalo_1),'mm') and trunc(last_day(add_months(sysdate,:intervalo_2)));

--extraccion de trxs en canal cajero
---extraccion de int-cli
--extraccion en cajero - tranydep;
create table tmp_clinuevo_trx_caj_int_cli_trandep_1 tablespace d_aml_99 as
select distinct a.numregistro, a.codcajero, a.fecdia, a.hortransaccion, a.codtrancajero, a.flgvalida, a.codclavecic, a.codmonedatran,
a.mtotransaccionsol, a.mtotransaccionme, codopectahacia, codopectadesde
from  ods_v.hd_movimientocajero a
where codtrancajero in ('40','20') and flgvalida = 'S' and a.fecdia between trunc(add_months(sysdate, -7),'mm') and trunc(last_day(add_months(sysdate,-1)));

create table tmp_clinuevo_trx_caj_int_cli_trandep_2 tablespace d_aml_99 as
select distinct a.*, b.codclaveopecta as codclaveopectahacia
from  tmp_clinuevo_trx_caj_int_cli_trandep_1 a
inner join ods_v.md_cuentag94 b on trim(a.codopectahacia) = trim(b.codopecta);

create table tmp_clinuevo_trx_caj_int_cli_trandep_3 tablespace d_aml_99 as
select distinct a.*, c.codclavecic as codclaveciccli, c.codclaveopecta as codclaveopectacli
from  tmp_clinuevo_trx_caj_int_cli_trandep_2 a
inner join tmp_clinuevo_cuentas_cli c on a.codclaveopectahacia = c.codclaveopecta;

create table tmp_clinuevo_trx_caj_int_cli_trandep_4 tablespace d_aml_99 as
select distinct a.*,d.codclaveopecta as codclaveopectadesde
from  tmp_clinuevo_trx_caj_int_cli_trandep_3 a
left join ods_v.md_cuentag94 d on trim(a.codopectadesde) = trim(d.codopecta);

create table tmp_clinuevo_trx_caj_int_cli_trandep_5 tablespace d_aml_99 as
select distinct a.*,x.codsucage, x.codubigeo
from  tmp_clinuevo_trx_caj_int_cli_trandep_4 a
left join ods_v.md_cajero x on trim(a.codcajero) = trim(x.codcajero);

--drop table tmp_clinuevo_trx_caj_int_cli_trandep;
truncate table tmp_clinuevo_trx_caj_int_cli_trandep;
insert into tmp_clinuevo_trx_caj_int_cli_trandep
--create table tmp_clinuevo_trx_caj_int_cli_trandep tablespace d_aml_99 as
select distinct a.numregistro, a.codcajero, a.codsucage, a.codubigeo, a.fecdia, a.hortransaccion, a.codtrancajero,
a.flgvalida, a.codclavecic, a.codmonedatran, a.mtotransaccionsol, a.mtotransaccionme, codclaveopectadesde,
codclaveopectahacia,
codclaveciccli, codclaveopectacli
from  tmp_clinuevo_trx_caj_int_cli_trandep_5 a;

drop table tmp_clinuevo_trx_caj_int_cli_trandep_5;
drop table tmp_clinuevo_trx_caj_int_cli_trandep_4;
drop table tmp_clinuevo_trx_caj_int_cli_trandep_3;
drop table tmp_clinuevo_trx_caj_int_cli_trandep_2;
drop table tmp_clinuevo_trx_caj_int_cli_trandep_1;

--extraccion de trxs en canal banca movil
---extraccion de cli-int
--extraccion en banca movil - tran;
---extraccion de int-cli
--extraccion en banca movil - tran;
truncate table tmp_clinuevo_trx_bcamov_int_cli_tran;
insert into tmp_clinuevo_trx_bcamov_int_cli_tran
--create table tmp_clinuevo_trx_bcamov_int_cli_tran tablespace d_aml_99 as
select distinct a.numtransaccionbcamovil,a.fectransaccion, a.hortransaccion,a.flgtransaccionvalida, a.tiptransaccionbcamovil, a.codmonedatransaccion, a.mtotransaccion, a.codclaveopectaorigen, a.codclaveopectadestino,
b.codclavecic as codclaveciccli, b.codclaveopecta as codclaveopectacli
from t23377.tmp_movbcamovil_i a
inner join tmp_clinuevo_cuentas_cli b on a.codclaveopectadestino = b.codclaveopecta
where tiptransaccionbcamovil in (2) and flgtransaccionvalida = 'S' and a.fectransaccion between trunc(add_months(sysdate, :intervalo_1),'mm') and trunc(last_day(add_months(sysdate,:intervalo_2)))
union all
select distinct a.numtransaccionbcamovil,a.fectransaccion, a.hortransaccion,a.flgtransaccionvalida, a.tiptransaccionbcamovil, a.codmonedatransaccion, a.mtotransaccion, a.codclaveopectaorigen, a.codclaveopectadestino,
b.codclavecic as codclaveciccli, b.codclaveopecta as codclaveopectacli
from t23377.tmp_movbcamovil_p a
inner join tmp_clinuevo_cuentas_cli b on a.codclaveopectadestino = b.codclaveopecta
where tiptransaccionbcamovil in (2) and flgtransaccionvalida = 'S' and a.fectransaccion between trunc(add_months(sysdate, :intervalo_1),'mm') and trunc(last_day(add_months(sysdate,:intervalo_2)));

--extraccion de trxs en canal homebanking
---extraccion de int-cli
create table tmp_clinuevo_trx_hbk_int_cli_tran_1 tablespace d_aml_99 as
select distinct a.codinternotransaccionhb, a.fecdia, a.hortransaccion, a.codopehbctr, a.tipresultadotransaccion, a.mtotransaccion, a.codmoneda,codopectaorigen, codopectadestino
from  ods_v.hd_movhomebankingtransaccion a
where a.codopehbctr in ('D_TRAN','TRAN_N','TRAN')
      and a.tipresultadotransaccion = 'OK' and a.fecdia between trunc(add_months(sysdate, -7),'mm') and trunc(last_day(add_months(sysdate,-1)));

create table tmp_clinuevo_trx_hbk_int_cli_tran_2 tablespace d_aml_99 as
select distinct a.*, b.codclaveopecta as codclaveopectadestino
from  tmp_clinuevo_trx_hbk_int_cli_tran_1 a
inner join ods_v.md_cuentag94 b on trim(a.codopectadestino) = trim(b.codopecta);

create table tmp_clinuevo_trx_hbk_int_cli_tran_3 tablespace d_aml_99 as
select distinct a.*, c.codclavecic as codclaveciccli, c.codclaveopecta as codclaveopectacli
from  tmp_clinuevo_trx_hbk_int_cli_tran_2 a
inner join tmp_clinuevo_cuentas_cli c on a.codclaveopectadestino = c.codclaveopecta;

create table tmp_clinuevo_trx_hbk_int_cli_tran_4 tablespace d_aml_99 as
select distinct a.*, d.codclaveopecta as codclaveopectaorigen
from  tmp_clinuevo_trx_hbk_int_cli_tran_3 a
left join ods_v.md_cuentag94 d on trim(a.codopectaorigen) = trim(d.codopecta);

--drop table tmp_clinuevo_trx_hbk_int_cli_tran;

truncate table tmp_clinuevo_trx_hbk_int_cli_tran;
insert into tmp_clinuevo_trx_hbk_int_cli_tran
--create table tmp_clinuevo_trx_hbk_int_cli_tran tablespace d_aml_99 as
select distinct a.codinternotransaccionhb, a.fecdia, a.hortransaccion, a.codopehbctr, a.tipresultadotransaccion, a.mtotransaccion, a.codmoneda,codclaveopectaorigen, codclaveopectadestino,
codclaveciccli, codclaveopectacli
from  tmp_clinuevo_trx_hbk_int_cli_tran_4 a;

drop table tmp_clinuevo_trx_hbk_int_cli_tran_4;
drop table tmp_clinuevo_trx_hbk_int_cli_tran_3;
drop table tmp_clinuevo_trx_hbk_int_cli_tran_2;
drop table tmp_clinuevo_trx_hbk_int_cli_tran_1;

--extraccion de trxs en canal ventanilla
truncate table tmp_clinuevo_trx_ventanilla_ini;
insert into tmp_clinuevo_trx_ventanilla_ini
--create table tmp_clinuevo_trx_ventanilla_ini tablespace d_aml_99 as
  select
  a.codinternotransaccion as numregistro,
  a.fecdia,
  a.horinitransaccion,
  a.horfintransaccion,
  a.codsucage,
  a.codsesion,
  a.codtransaccionventanilla,
  a.flgtransaccionaprobada,
  a.codmonedatransaccion as codmoneda,
  case when a.mtotransaccioncta <> 0 then a.mtotransaccioncta else a.mtotransaccion end as mtotransaccion,
  a.codclaveopecta,
  a.codclaveopectadestino
from ods_v.hd_transaccionventanilla a
where fecdia between trunc(add_months(sysdate, :intervalo_1),'mm') and trunc(last_day(add_months(sysdate,:intervalo_2))) and
codtransaccionventanilla in (60,62,63,159,186,187,188) and flgtransaccionaprobada = 'S';

---extraccion de int-cli
truncate table tmp_clinuevo_trx_vent_int_cli_trandep;
insert into tmp_clinuevo_trx_vent_int_cli_trandep
--create table tmp_clinuevo_trx_vent_int_cli_trandep tablespace d_aml_99 as
select distinct
    a.numregistro, a.codsucage, a.fecdia, a.horinitransaccion, a.horfintransaccion, a.codtransaccionventanilla, a.flgtransaccionaprobada, a.codmoneda, a.mtotransaccion, c.codclavecic as codclavecicg94, a.codclaveopecta, a.codclaveopectadestino,
    d.codclavecic as codclaveciccli, d.codclaveopecta as codclaveopectacli
from tmp_clinuevo_trx_ventanilla_ini a
    left join ods_v.hd_movlavadodineroventanilla b on a.fecdia = b.fecdia and a.codsucage = b.codsucage and a.codsesion = b.codsesion and (b.codunicoclisolicitante <> '0000000000001' or b.codunicocliordenante <> '0000000000001')
    left join ods_v.md_clienteg94 c on coalesce(b.codunicoclisolicitante, b.codunicocliordenante) = trim(c.codunicocli)
    inner join tmp_clinuevo_cuentas_cli d on a.codclaveopectadestino = d.codclaveopecta
where a.codtransaccionventanilla in (60,62,63,159,186,187,188);

--extraccion de trxs en ggtt
truncate table tmp_clinuevo_docggtt;
insert into tmp_clinuevo_docggtt
--create table tmp_clinuevo_docggtt tablespace d_aml_99 as
select distinct a.coddocggtt,a.numoperacionggtt, a.codsucage, a.fecdia, a.fecemision, a.horemision, a.codtipestadotransaccion, a.codproducto, a.codmoneda, a.mtoimporteoperacion, a.codclavecicsolicitante, a.codclavecicordenante, a.codclavecicbeneficiario, b.codclavecic as codclavecicbeneficiario_chqgen, a.codswiftbcoemisor, a.codswiftbcodestino, a.codpaisbcodestino
from ods_v.hd_documentoemitidoggtt a
left join ods_v.md_clienteg94 b on upper(regexp_replace(a.nbrclibeneficiario, '[^A-Z0-9]','')) = upper(regexp_replace(b.apepatcli || b.apematcli || b.nbrcli, '[^A-Z0-9]',''))
where a.fecdia between trunc(add_months(sysdate, :intervalo_1),'mm') and trunc(last_day(add_months(sysdate,:intervalo_2))) and a.codtipestadotransaccion = '00';

--extraccion de int-cli
--extraccion de todo menos cheques de gerencia
truncate table tmp_clinuevo_trx_ggtt_nochqgen_int_cli;
insert into tmp_clinuevo_trx_ggtt_nochqgen_int_cli
--create table tmp_clinuevo_trx_ggtt_nochqgen_int_cli tablespace d_aml_99 as
select distinct a.coddocggtt,a.numoperacionggtt, a.codsucage, a.fecdia, a.fecemision, a.horemision, a.codtipestadotransaccion, a.codproducto, a.codmoneda, a.mtoimporteoperacion, a.codclavecicsolicitante, a.codclavecicordenante, a.codclavecicbeneficiario, a.codswiftbcoemisor, a.codswiftbcodestino, a.codpaisbcodestino,
b.codclavecic as codclaveciccli
from tmp_clinuevo_docggtt a inner join tmp_clinuevo_codclavecics_cli b on a.codclavecicbeneficiario = b.codclavecic where codproducto <> 'CHQGER';

--extraccion cheques de gerencia
truncate table tmp_clinuevo_trx_ggtt_chqgen_int_cli;
insert into tmp_clinuevo_trx_ggtt_chqgen_int_cli
--create table tmp_clinuevo_trx_ggtt_chqgen_int_cli tablespace d_aml_99 as
select distinct a.coddocggtt,a.numoperacionggtt, a.codsucage, a.fecdia, a.fecemision, a.horemision, a.codtipestadotransaccion, a.codproducto, a.codmoneda, a.mtoimporteoperacion, a.codclavecicsolicitante, a.codclavecicordenante, a.codclavecicbeneficiario, a.codclavecicbeneficiario_chqgen, a.codswiftbcoemisor, a.codswiftbcodestino, a.codpaisbcodestino,
b.codclavecic as codclaveciccli
from tmp_clinuevo_docggtt a inner join tmp_clinuevo_codclavecics_cli b on a.codclavecicbeneficiario_chqgen = b.codclavecic where codproducto = 'CHQGER';

--extraccion de trxs en tabla transferencias del exterior
truncate table tmp_clinuevo_trx_remitt_int_cli_delext;
insert into tmp_clinuevo_trx_remitt_int_cli_delext
--create table tmp_clinuevo_trx_remitt_int_cli_delext tablespace d_aml_99 as
select
a.numoperacionremittance, a.codsucursal, a.fecdia, a.hortransaccion, a.codproducto, a.codestadooperemittance, a.codmoneda, a.mtotransaccion, a.mtotransacciondol,-1 as codclaveopectaorigen, a.codclaveopectaafectada, a.codpaisorigen, a.codswiftinstordenante, a.codswiftbcoordenante,
b.codclavecic as codclaveciccli, b.codclaveopecta as codclaveopectacli
from ods_v.hd_movoperativoremittance  a
inner join tmp_clinuevo_cuentas_cli b on a.codclaveopectaafectada = b.codclaveopecta
where codproducto in ('TRAXAB','TRAXRE','TRAXVE') and codestadooperemittance = '7' and fecdia between trunc(add_months(sysdate, :intervalo_1),'mm') and trunc(last_day(add_months(sysdate,:intervalo_2)));

--extraccion de transerencias interbancarias
--extraccion de int-cli
truncate table tmp_clinuevo_trx_ttib_int_cli_ttib;
insert into tmp_clinuevo_trx_ttib_int_cli_ttib
--create table tmp_clinuevo_trx_ttib_int_cli_ttib tablespace d_aml_99 as
select distinct
a.numsecuencial, a.fectransaccion, a.hortransaccion, a.codopetransaccionttib, a.tipestttib, a.codmoneda, a.mtotransaccion, a.codctainterbanordenante, a.codclaveopectaordenante, a.codctainterbanbeneficiario, a.codclaveopectabeneficiario,
b.codclavecic as codclaveciccli, b.codclaveopecta as codclaveopectacli
from ods_v.hd_movimientottib a
inner join tmp_clinuevo_cuentas_cli b on a.codclaveopectabeneficiario = b.codclaveopecta
where a.tipestttib = '00' and a.codopetransaccionttib not in (223,221) and a.fectransaccion between trunc(add_months(sysdate, :intervalo_1),'mm') and trunc(last_day(add_months(sysdate,:intervalo_2)));

--consolidacion de trxs
truncate table tmp_clinuevo_int_cli;
insert into tmp_clinuevo_int_cli
--create table tmp_clinuevo_int_cli tablespace d_aml_99 as
    --agente
      select
          t.numregistro, t.codsucage, l.codclavecic as codclavecicint,l.codclaveopecta as codclaveopectaint,
          ' ' as datoadicionalint,' ' as codpaisorigen,
          t.fecdia, t.hortransaccion, t.codmoneda, t.mtotransaccion, t.mtotransaccion * tc.mtocambioaldolar as mtodolarizado, to_char(t.tiptransaccionagenteviabcp) as codtransaccion, d.destiptransaccionagenteviabcp as tipotransaccion, 'AGENTE' as canal,
          t.codclaveciccli, t.codclaveopectacli
      from
          tmp_clinuevo_trx_age_int_cli_trandep t
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
          tmp_clinuevo_trx_age_int_cli_trandep t
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
          tmp_clinuevo_trx_caj_int_cli_trandep t
          inner join ods_v.md_cuenta l on t.codclaveopectadesde = l.codclaveopecta
          left join ods_v.hd_tipocambiosaldodiario tc on t.fecdia = tc.fectipcambio and t.codmonedatran = tc.codmoneda
          left join ods_v.mm_descodigotransaccioncajero d on t.codtrancajero = d.codtrancajero
      where t.codtrancajero in ('40')
      union
      select
          t.numregistro, t.codsucage, t.codclavecic as codclavecicint,-1 as codclaveopectaint,
          ' ' as datoadicionalint,' ' as codpaisorigen,
          t.fecdia, t.hortransaccion, t.codmonedatran, case when t.codmonedatran = '0001' then t.mtotransaccionsol else t.mtotransaccionme end as mtotransaccion, (case when t.codmonedatran = '0001' then t.mtotransaccionsol else t.mtotransaccionme end) * tc.mtocambioaldolar as mtodolarizado, to_char(t.codtrancajero) as codtransaccion, d.descodtrancajero as tipotransaccion, 'CAJERO' as canal,
          t.codclaveciccli, t.codclaveopectacli
      from
          tmp_clinuevo_trx_caj_int_cli_trandep t
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
          tmp_clinuevo_trx_bcamov_int_cli_tran t
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
          tmp_clinuevo_trx_hbk_int_cli_tran t
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
          tmp_clinuevo_trx_vent_int_cli_trandep t
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
          tmp_clinuevo_trx_vent_int_cli_trandep t
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
    		tmp_clinuevo_trx_ggtt_nochqgen_int_cli t
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
    		tmp_clinuevo_trx_ggtt_chqgen_int_cli t
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
    		tmp_clinuevo_trx_remitt_int_cli_delext t
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
    		tmp_clinuevo_trx_ttib_int_cli_ttib t
        left join ods_v.hd_tipocambiosaldodiario tc on t.fectransaccion = tc.fectipcambio and t.codmoneda = tc.codmoneda
        left join ods_v.md_destipoperacionttib d on t.codopetransaccionttib = d.tipoperacionttib;

--consolidacion
--tabla final de transacciones
truncate table tmp_clinuevo_trxs_aux;
insert into tmp_clinuevo_trxs_aux
--create table tmp_clinuevo_trxs_aux tablespace d_aml_99 as
select
      cast(to_char(fecdia, 'yyyymm') as int) as periodo,rownum as idtrx,a.*,
      case when canal = 'VENTANILLA' and trim(codtransaccion) in ('60','62','63') then 1
				        when canal = 'AGENTE' and trim(codtransaccion) in ('05') then 1
				        when canal = 'CAJERO' and trim(codtransaccion) in ('20') then 1 else 0 end flgcash
from tmp_clinuevo_int_cli a
where codclavecicint <> codclaveciccli and mtodolarizado > 100;

truncate table tmp_clinuevo_trx;
insert into tmp_clinuevo_trx
--create table tmp_clinuevo_trx tablespace d_aml_99 as
select a.*,
d.coddepartamento, e.descoddepartamento,
case when trim(d.coddepartamento) in ('10','42','46','48') then 'ZAED'
when trim(d.coddepartamento) in ('30') then 'LIMA' else 'OTROS' end tipo_zona
from tmp_clinuevo_trxs_aux a
inner join tmp_clinuevo_universo_cli b on a.periodo = b.periodo and a.codclaveciccli = b.codclavecic
left join ods_v.md_agencia c on trim(a.codsucage) = trim(c.codsucage) or trim(a.codsucage) = trim(c.codofi)
left join ods_v.mm_distrito d on trim(c.coddistrito) = trim(d.coddistrito)
left join ods_v.mm_departamento e on trim(d.coddepartamento) = trim(e.coddepartamento);

commit;
quit;