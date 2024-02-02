--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

var intervalo_1 number
exec :intervalo_1 := to_number(&2);

select :intervalo_1 from dual;

/***********************************************************************************************
**************** EPIC024: Estructuración a través de Pagos del Exterior  ************************
************************************************************************************************/

-- Creado por: Ashly Aguilar
-- Key user escenario: Plaft
-- Fecha:05/12/2023
-- Descripcion: Etl para la extracion de transferencias del exterior realizados por ggtt y remittance

-- ************************************ UNIVERSO ***************************************************
-- **************** Scripts para la creacion del universo ******************************************
-- Creacion del universo de las trx realizadas por ggtt y remittance
-- Periodo es mensual

--Extraccion de trxs en ggtt del ext
truncate table tmp_ingrestrc_trxs_ggtt;
insert into tmp_ingrestrc_trxs_ggtt
select distinct a.coddocggtt,a.numoperacionggtt, a.codsucage, a.fecdia, a.fecemision, a.horemision, a.codtipestadotransaccion, a.codproducto, d.descodproducto,
a.codmoneda, a.mtoimporteoperacion, a.mtoimporteoperacion * tc.mtocambioaldolar as mtodolarizado,
a.codclavecicsolicitante, a.codclavecicordenante, coalesce(b.codclavecic,a.codclavecicbeneficiario) as codclavecicbeneficiario,
a.codswiftbcoemisor, upper(p.nombrepais) as nbrpaisorigen, a.codswiftbcodestino, a.codpaisbcodestino
from ods_v.hd_documentoemitidoggtt a
left join ods_v.md_clienteg94 b on upper(regexp_replace(a.nbrclibeneficiario, '[^A-Z0-9]','')) = upper(regexp_replace(b.apepatcli || b.apematcli || b.nbrcli, '[^A-Z0-9]',''))
left join ods_v.hd_tipocambiosaldodiario tc on a.fecdia = tc.fectipcambio and a.codmoneda = tc.codmoneda
left join ods_v.md_descodigoproducto d on a.codproducto = d.codproducto
left join s55632.md_codigopais p on substr(a.codswiftbcoemisor, 5, 2) = p.codpais2
where a.fecdia between trunc(add_months(sysdate, :intervalo_1-6),'mm') and trunc(last_day(add_months(sysdate,:intervalo_1))) and a.codtipestadotransaccion = '00'
and a.codproducto in ('TRAXRE','TRAXVE');

--Extraccion de trxs en remittance del ext
truncate table tmp_ingrestrc_trxs_remit;
insert into tmp_ingrestrc_trxs_remit
select
a.numoperacionremittance, a.codsucursal, a.fecdia, a.hortransaccion, a.codproducto, d.descodproducto, a.codestadooperemittance,
a.codmoneda, a.mtotransaccion, a.mtotransacciondol,
a.codpaisorigen, a.codswiftinstordenante, a.codswiftbcoordenante, upper(p.nombrepais) as nbrpaisorigen,
b.codclavecic as codclavecicbeneficiario, b.codclaveopecta as codclaveopectabeneficiario
from ods_v.hd_movoperativoremittance  a
inner join ods_v.md_cuentag94 b on a.codclaveopectaafectada = b.codclaveopecta
left join ods_v.md_descodigoproducto d on a.codproducto = d.codproducto
left join s55632.md_codigopais p on substr(coalesce(a.codswiftinstordenante, a.codswiftbcoordenante), 5, 2) = p.codpais2
where a.codproducto in ('TRAXAB','TRAXRE','TRAXVE') and a.codestadooperemittance = '7' and a.fecdia between trunc(add_months(sysdate, :intervalo_1-6),'mm') and trunc(last_day(add_months(sysdate,:intervalo_1)));

--Calculo final e integracion de tablas
truncate table tmp_ingrestrc_trxs_total;
insert into tmp_ingrestrc_trxs_total
select
    to_number(to_char(t.fecdia,'yyyymm')) as periodo, t.coddocggtt as numtrx, t.codsucage, case when t.codclavecicordenante = 3288453 then -1 else t.codclavecicordenante end as codclavecicordenante, -1 as codclaveopectaordenante,
    t.nbrpaisorigen,
    t.fecdia, t.horemision as hortransaccion, t.codmoneda, t.mtoimporteoperacion as mtotransaccion, t.mtodolarizado, to_char(t.codproducto) as codproducto, t.descodproducto, 'GGTT' as fuente,
    t.codclavecicbeneficiario, -1 as codclaveopectabeneficiario, t.codswiftbcoemisor as bancoemisor
from tmp_ingrestrc_trxs_ggtt t
where t.mtodolarizado > 100
union
select
    to_number(to_char(t.fecdia,'yyyymm')) as periodo, t.numoperacionremittance as numtrx, t.codsucursal as codsucage, -1 as codclavecicordenante, -1 as codclaveopectaordenante,
    t.nbrpaisorigen,
    t.fecdia, t.hortransaccion, t.codmoneda, t.mtotransaccion, t.mtotransacciondol as mtodolarizado, to_char(t.codproducto) as codproducto, t.descodproducto, 'REMITTANCE' as fuente,
    t.codclavecicbeneficiario,t.codclaveopectabeneficiario, t.codswiftbcoordenante as bancoemisor
from tmp_ingrestrc_trxs_remit t
where t.mtotransacciondol > 100;

--Universo de trx historica de los 7 últimos meses del mes de analisis que no pertenecen a los de lista blanca
truncate table tmp_ingrestrc_trxs_total_vf;
insert into tmp_ingrestrc_trxs_total_vf
select a.* from tmp_ingrestrc_trxs_total a
left join s55632.rm_cumplimientolistablanca_tmp b on a.codclavecicbeneficiario=b.codclavecic
where b.codclavecic is null;

--Universo de clientes mes de analisis
truncate table tmp_ingrestrc_universo_cli;
insert into tmp_ingrestrc_universo_cli
select distinct a.periodo, a.codclavecicbeneficiario as codclavecic
from tmp_ingrestrc_trxs_total_vf a
where a.periodo =  to_number(to_char(add_months(sysdate,:intervalo_1),'yyyymm'));

commit;
quit;