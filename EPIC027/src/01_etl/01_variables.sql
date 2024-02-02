--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

var intervalo_1 number
exec :intervalo_1 := to_number(&2);

select :intervalo_1 from dual;

-- universo
--extraer universo de gremios (4 meses)
--drop table tmp_grm_universo;
truncate table tmp_grm_universo;
insert into tmp_grm_universo
--create table tmp_grm_universo tablespace d_aml_99 as
select codmes, codclavecic,tipper,tipcli,codsectorista,tipbanca,codacteconomica,codsubsegmento,flgregeliminado,fecregeliminado
from ods_v.hm_cliente
where
trim(codsubsegmento) = 'G1N'
and flgregeliminado = 'N'
and codmes >= to_char(add_months(sysdate,:intervalo_1),'yyyymm')--202203
and tipper = 'P';

--drop table tmp_grm_universo_1;
truncate table tmp_grm_universo_1 ;
insert into tmp_grm_universo_1
--create table tmp_grm_universo_1 tablespace d_aml_99  as
select
       a.codmes,
       a.codclavecic,
       b.codempsistemafinancierodeuda,
       max(b.tipclasifriesgoempsistemafinan)  as clasificacion_sbs ,
       case when b.codempsistemafinancierodeuda  = '00001' then b.mtodeudatotaldirectasolrcc end as deuda_total_bcp,
       case when b.codempsistemafinancierodeuda  = '00002' then b.mtodeudatotaldirectasolrcc end as deuda_total_ibk,
       case when b.codempsistemafinancierodeuda  = '00004' then b.mtodeudatotaldirectasolrcc end as deuda_total_scotia,
       case when b.codempsistemafinancierodeuda  = '00006' then b.mtodeudatotaldirectasolrcc end as deuda_total_conti,
       case when b.codempsistemafinancierodeuda  not in  ('00006','00004','00002','00001') then sum(b.mtodeudatotaldirectasolrcc) end as deuda_total_otros
from tmp_grm_universo a
left join ods_v.hm_deudorsbsrcc b on a.codclavecic = b.codclavecic and a.codmes = to_char(add_months(to_date(b.codmes,'yyyymm'),1),'yyyymm')
      group by
       a.codmes,
       a.codclavecic,
       b.codempsistemafinancierodeuda ,
       case when b.codempsistemafinancierodeuda  = '00001' then b.mtodeudatotaldirectasolrcc end ,
       case when b.codempsistemafinancierodeuda  = '00002' then b.mtodeudatotaldirectasolrcc end ,
       case when b.codempsistemafinancierodeuda  = '00004' then b.mtodeudatotaldirectasolrcc end ,
       case when b.codempsistemafinancierodeuda  = '00006' then b.mtodeudatotaldirectasolrcc end;

--drop table tmp_grm_universo_2;
truncate table tmp_grm_universo_2 ;
insert into tmp_grm_universo_2
--create table tmp_grm_universo_2 tablespace d_aml_99 as
select
       a.codmes,
       a.codclavecic,
       sum(a.deuda_total_bcp) deuda_total_bcp,
       sum(a.deuda_total_ibk) deuda_total_ibk,
       sum(a.deuda_total_scotia) deuda_total_scotia,
       sum(a.deuda_total_conti) deuda_total_conti,
       sum(a.deuda_total_otros) deuda_total_otros,
       count(1) as n_deudas
from tmp_grm_universo_1 a
     group by
     a.codmes,
     a.codclavecic;

--==============================================================================================================================
-- calculando el ingreso
--==============================================================================================================================
--drop table tmp_grm_universo_3;
truncate table tmp_grm_universo_3 ;
insert into tmp_grm_universo_3
--create table tmp_grm_universo_3 tablespace d_aml_99 as
select
       a.*,
       (nvl(a.deuda_total_bcp,0)+
        nvl(a.deuda_total_ibk,0)+
        nvl(a.deuda_total_scotia,0)+
        nvl(a.deuda_total_conti,0)+
        nvl(a.deuda_total_otros,0)) as deuda_total_sf,
       ((case when a.deuda_total_bcp is not null then 1 else 0 end) +
        (case when a.deuda_total_ibk is not null then 1 else 0 end) +
        (case when a.deuda_total_scotia is not null then 1 else 0 end) +
        (case when a.deuda_total_conti is not null then 1 else 0 end) +
        (case when a.deuda_total_otros is not null then 1 else 0 end)
       )   as n_entidades,
       b.ing_pdh_act as ingreso_haberes,
       b.prom_ing_phd_6m_ant_e as prom_ingre_haberes_6um
from  tmp_grm_universo_2 a left join proy_rbp.hm_ing_pdh_var_13456 b on a.codclavecic = b.codclavecic and a.codmes = b.codmes;

--==============================================================================================================================
-- pegando la deuda de sus productos
--==============================================================================================================================
--drop table tmp_grm_universo_4;
truncate table tmp_grm_universo_4 ;
insert into tmp_grm_universo_4
--create table tmp_grm_universo_4 tablespace d_aml_99 as
select
       a.*,
       0 ctd_hip, --case when b.ctd_hip is null then 0 else b.ctd_hip  end as ctd_hip,
       0 ctd_veh, --case when c.ctd_veh is null then 0 else c.ctd_veh  end as ctd_veh,
       0 ctd_cef, --case when d.ctd_cef is null then 0 else d.ctd_cef  end as ctd_cef,
       0 ctd_tc, --case when e.ctd_tc is null then 0 else e.ctd_tc  end as ctd_tc,
       b.mtoprincipal_soles as deuda_hipotecario_bcp,
       c.mtoprincipal_soles as deuda_vehicular_bcp,
       d.mtoprincipal_soles as deuda_cef_bcp,
       e.mtoprincipal_soles as deuda_tc_bcp
from   tmp_grm_universo_3 a
       left join  proy_rbp.hm_mtz_port_hipotecario_driver b on a.codclavecic = b.codclavecic and a.codmes = b.codmes
       left join  proy_rbp.hm_mtz_port_vehicular_driver c on a.codclavecic = c.codclavecic and a.codmes = c.codmes
       left join  proy_rbp.hm_mtz_port_consumo_driver d on a.codclavecic = d.codclavecic and a.codmes = d.codmes
       left join  proy_rbp.hm_mtz_port_tarjetas_driver e on a.codclavecic = e.codclavecic and a.codmes = e.codmes ;

--drop table tmp_grm_universo_5;
truncate table tmp_grm_universo_5 ;
insert into tmp_grm_universo_5
--create table tmp_grm_universo_5 tablespace d_aml_99 as
select
       codclavecic,
       codmes,
       ctd_hip,
       ctd_veh,
       ctd_cef,
       ctd_tc,
       sum(nvl(a.deuda_hipotecario_bcp,0)) as   deuda_hipotecario_bcp,
       sum(nvl(a.deuda_vehicular_bcp,0)) as   deuda_vehicular_bcp,
       sum(nvl(a.deuda_cef_bcp,0)) as   deuda_cef_bcp,
       sum(nvl(a.deuda_tc_bcp,0)) as   deuda_tc_bcp
from tmp_grm_universo_4 a
     group by
       codclavecic,
       codmes,
       ctd_hip,
       ctd_veh,
       ctd_cef,
       ctd_tc;

--drop table tmp_grm_universo_6;
truncate table tmp_grm_universo_6 ;
insert into tmp_grm_universo_6
--create table tmp_grm_universo_6 tablespace d_aml_99 as
select
       a.*,
       b.deuda_hipotecario_bcp,
       b.deuda_vehicular_bcp,
       b.deuda_cef_bcp,
       b.deuda_tc_bcp,
       b.ctd_hip,
       b.ctd_veh,
       b.ctd_cef,
       b.ctd_tc
from tmp_grm_universo_3 a left join tmp_grm_universo_5 b on a.codclavecic = b.codclavecic and a.codmes = b.codmes;

--==============================================================================================================================
-- agregando puesto y sacando ratios
--==============================================================================================================================
--drop table tmp_grm_empleados;
truncate table tmp_grm_empleados ;
insert into tmp_grm_empleados
--create table tmp_grm_empleados tablespace d_aml_99 as
select
       codclavecic,
       max(fecingresoempleado) fecingresoempleado,
       max(fecdia) fecdia
       from ods_v.md_empleadog94 group by
       codclavecic;

--drop table tmp_grm_universo_7;
truncate table tmp_grm_universo_7 ;
insert into tmp_grm_universo_7
--create table tmp_grm_universo_7 tablespace d_aml_99 as
select
       a.*,
       case when c.descodpuesto is null then 'SIN INF.' else c.descodpuesto end as descodpuesto
from tmp_grm_universo_6 a
     left join  tmp_grm_empleados x on a.codclavecic = x.codclavecic
     left join ods_v.md_empleadog94 b on x.codclavecic = b.codclavecic and x.fecingresoempleado = b.fecingresoempleado and x.fecdia = b.fecdia
     left join ods_v.md_puesto c on b.codpuesto = c.codpuesto;

--drop table tmp_grm_universo_8;
truncate table tmp_grm_universo_8 ;
insert into tmp_grm_universo_8
--create table tmp_grm_universo_8 tablespace d_aml_99 as
select
       a.*,
       a.deuda_total_sf-a.deuda_hipotecario_bcp as deuda_sf_sin_hip,
       case when nvl(a.ingreso_haberes,0) = 0  then -1 else
       a.deuda_total_sf/a.ingreso_haberes end as ratio_total_sf_hab,
       case when nvl(a.ingreso_haberes,0) = 0  then -1 else
       round(((a.deuda_total_sf-a.deuda_hipotecario_bcp)/a.ingreso_haberes),2) end as ratio_no_total_sf_hab,
       b.deuda_total_bcp-a.deuda_total_bcp as variacion_1m_bcp,
       b.deuda_total_ibk-a.deuda_total_ibk as variacion_1m_ibk,
       b.deuda_total_scotia-a.deuda_total_scotia as variacion_1m_scotia,
       b.deuda_total_conti-a.deuda_total_conti as  variacion_1m_conti,
       case when (b.deuda_total_sf-a.deuda_total_sf) is null then 0 else
	(b.deuda_total_sf-a.deuda_total_sf) end as variacio_1m_total_deuda,
       c.deuda_total_bcp-a.deuda_total_bcp as variacion_2m_bcp,
       c.deuda_total_ibk-a.deuda_total_ibk as variacion_2m_ibk,
       c.deuda_total_scotia-a.deuda_total_scotia as variacion_2m_scotia,
       c.deuda_total_conti-a.deuda_total_conti as  variacion_2m_conti,
       c.deuda_total_sf-a.deuda_total_sf as variacio_2m_total_deuda,
       d.deuda_total_bcp-a.deuda_total_bcp as variacion_3m_bcp,
       d.deuda_total_ibk-a.deuda_total_ibk as variacion_3m_ibk,
       d.deuda_total_scotia-a.deuda_total_scotia as variacion_3m_scotia,
       d.deuda_total_conti-a.deuda_total_conti as  variacion_3m_conti,
       d.deuda_total_sf-a.deuda_total_sf as variacio_3m_total_deuda
from tmp_grm_universo_7 a
     left join tmp_grm_universo_7 b on a.codclavecic = b.codclavecic and  a.codmes = to_char(add_months(to_date(b.codmes,'yyyymm'),1),'yyyymm')*1
     left join tmp_grm_universo_7 c on a.codclavecic = c.codclavecic and  a.codmes = to_char(add_months(to_date(c.codmes,'yyyymm'),2),'yyyymm')*1
     left join tmp_grm_universo_7 d on a.codclavecic = d.codclavecic and  a.codmes = to_char(add_months(to_date(d.codmes,'yyyymm'),3),'yyyymm')*1;

--==============================================================================================================================
-- preparandp base a exportar
--==============================================================================================================================
truncate table tmp_grm_universo_comercial ;
insert into tmp_grm_universo_comercial
--create table tmp_grm_universo_comercial tablespace d_aml_99 as
select
*
from tmp_grm_universo_8 a where a.descodpuesto like 'ASESOR%'
     or a.descodpuesto like 'PROMOTOR%'
     or a.descodpuesto like 'FUNCIONARIO%';

commit;
quit;