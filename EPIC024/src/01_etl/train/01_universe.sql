
ALTER session disable parallel query

--Ejecución en Novi23 con test de abril23 a oct23 con trx historicas de 202210 - 202310

-----------------------------
--transferencias del exterior
-----------------------------
--extraccion de trxs en ggtt del ext
drop table tmp_ingrestrc_trxs_ggtt;
create table tmp_ingrestrc_trxs_ggtt tablespace d_aml_99 as
select distinct a.coddocggtt,a.numoperacionggtt, a.codsucage, a.fecdia, a.fecemision, a.horemision, a.codtipestadotransaccion, a.codproducto, d.descodproducto,
a.codmoneda, a.mtoimporteoperacion, a.mtoimporteoperacion * tc.mtocambioaldolar as mtodolarizado,
a.codclavecicsolicitante, a.codclavecicordenante, coalesce(b.codclavecic,a.codclavecicbeneficiario) as codclavecicbeneficiario,
a.codswiftbcoemisor, upper(p.nombrepais) as nbrpaisorigen, a.codswiftbcodestino, a.codpaisbcodestino
from ods_v.hd_documentoemitidoggtt a
left join ods_v.md_clienteg94 b on upper(regexp_replace(a.nbrclibeneficiario, '[^A-Z0-9]','')) = upper(regexp_replace(b.apepatcli || b.apematcli || b.nbrcli, '[^A-Z0-9]',''))
left join ods_v.hd_tipocambiosaldodiario tc on a.fecdia = tc.fectipcambio and a.codmoneda = tc.codmoneda
left join ods_v.md_descodigoproducto d on a.codproducto = d.codproducto
left join s55632.md_codigopais p on substr(a.codswiftbcoemisor, 5, 2) = p.codpais2
where a.fecdia between trunc(add_months(sysdate, -13),'mm') and trunc(last_day(add_months(sysdate,-1))) and a.codtipestadotransaccion = '00'
and a.codproducto in ('TRAXRE','TRAXVE');

--extraccion de trxs en remittance del ext
drop table tmp_ingrestrc_trxs_remit;
create table tmp_ingrestrc_trxs_remit tablespace d_aml_99 as
select
a.numoperacionremittance, a.codsucursal, a.fecdia, a.hortransaccion, a.codproducto, d.descodproducto, a.codestadooperemittance,
a.codmoneda, a.mtotransaccion, a.mtotransacciondol,
a.codpaisorigen, a.codswiftinstordenante, a.codswiftbcoordenante, upper(p.nombrepais) as nbrpaisorigen,
b.codclavecic as codclavecicbeneficiario, b.codclaveopecta as codclaveopectabeneficiario
from ods_v.hd_movoperativoremittance  a
inner join ods_v.md_cuentag94 b on a.codclaveopectaafectada = b.codclaveopecta
left join ods_v.md_descodigoproducto d on a.codproducto = d.codproducto
left join s55632.md_codigopais p on substr(coalesce(a.codswiftinstordenante, a.codswiftbcoordenante), 5, 2) = p.codpais2
where a.codproducto in ('TRAXAB','TRAXRE','TRAXVE') and a.codestadooperemittance = '7' and a.fecdia between trunc(add_months(sysdate, -13),'mm') and trunc(last_day(add_months(sysdate,-1)));

--calculo final e integracion de tablas
drop table tmp_ingrestrc_trxs_total;
create table tmp_ingrestrc_trxs_total tablespace d_aml_99 as
    --ggtt
    	select
    		to_number(to_char(t.fecdia,'yyyymm')) as periodo, t.coddocggtt as numtrx, t.codsucage, case when t.codclavecicordenante = 3288453 then -1 else t.codclavecicordenante end as codclavecicordenante, -1 as codclaveopectaordenante,
    		t.nbrpaisorigen,
    		t.fecdia, t.horemision as hortransaccion, t.codmoneda, t.mtoimporteoperacion as mtotransaccion, t.mtodolarizado, to_char(t.codproducto) as codproducto, t.descodproducto, 'GGTT' as fuente,
    		t.codclavecicbeneficiario, -1 as codclaveopectabeneficiario,
			t.codswiftbcoemisor as bancoemisor
    	from
    		tmp_ingrestrc_trxs_ggtt t
		where t.mtodolarizado > 100
    union
    --remittance del exterior
    	select
    		to_number(to_char(t.fecdia,'yyyymm')) as periodo, t.numoperacionremittance as numtrx, t.codsucursal as codsucage, -1 as codclavecicordenante, -1 as codclaveopectaordenante,
    		t.nbrpaisorigen,
    		t.fecdia, t.hortransaccion, t.codmoneda, t.mtotransaccion, t.mtotransacciondol as mtodolarizado, to_char(t.codproducto) as codproducto, t.descodproducto, 'REMITTANCE' as fuente,
    		t.codclavecicbeneficiario,t.codclaveopectabeneficiario,
			t.codswiftbcoordenante as bancoemisor
    	from
    		tmp_ingrestrc_trxs_remit t
		where t.mtotransacciondol > 100;

--eliminar los de lista blanca
drop table tmp_ingrestrc_trxs_total_vf;
create table tmp_ingrestrc_trxs_total_vf tablespace d_aml_99 as
		select a.* from tmp_ingrestrc_trxs_total a
		left join s55632.rm_cumplimientolistablanca_tmp b on a.codclavecicbeneficiario=b.codclavecic
		where b.codclavecic is null;

--Universo de clientes de los 7 ultimos meses para el test (abril23 a oct23)
drop table tmp_ingrestrc_universo_cli;
create table tmp_ingrestrc_universo_cli tablespace d_aml_99 as
select distinct a.periodo, a.codclavecicbeneficiario as codclavecic
from tmp_ingrestrc_trxs_total_vf a
where a.periodo between  to_number(to_char(add_months(sysdate, -7),'yyyymm')) and  to_number(to_char(add_months(sysdate, -1),'yyyymm'));

commit;
quit;