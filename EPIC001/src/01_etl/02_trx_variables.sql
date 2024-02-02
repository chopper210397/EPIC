--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

var intervalo_1 number
exec :intervalo_1 := to_number(&2);

select :intervalo_1, from dual;

-----------------------------------------------------------------------------------|| cambiar fecha  ||----------------
---------------atm
truncate table tmp_retatmext_depositoatm;
insert into tmp_retatmext_depositoatm
--create table tmp_retatmext_depositoatm tablespace d_aml_99  as
select distinct b.codclavecic,a.fecdia,a.mtotransaccionvisa,a.hortransaccion
from ods_v.hd_movimientopos a
left join ods_v.md_cuentag94 b on a.codclaveopectaafectada = b.codclaveopecta
inner join tmp_retatmext_pos_egresos_univ c on b.codclavecic = c.codclavecic
where a.codretorno = '00' and a.tiporigen = '2' and a.tipmedioelectronico in( '1','0') and  a.fecdia between trunc(add_months(sysdate, :intervalo_1),'mm') and last_day(trunc(add_months(sysdate, :intervalo_1))) and a.codpaisestablecimiento <> 'PE'
and a.flgvalida = 'S' and a.flgextorno='N';

truncate table tmp_retatmext_depositoatm_agr;
insert into tmp_retatmext_depositoatm_agr
--create table tmp_retatmext_depositoatm_agr tablespace d_aml_99  as
select to_number(to_char(a.fecdia,'yyyymm')) as periodo,a.codclavecic,sum(a.mtotransaccionvisa ) as mto_opeatm,
count(a.mtotransaccionvisa) as ctd_opeatm
from tmp_retatmext_depositoatm a
group by to_number(to_char(a.fecdia,'yyyymm')),codclavecic;

-----------------------------------------------------------------------------------|| cambiar fecha  ||----------------
----------------pos
truncate table tmp_retatmext_depositopos ;
insert into tmp_retatmext_depositopos
--create table tmp_retatmext_depositopos tablespace d_aml_99  as
select distinct b.codclavecic,a.fecdia,a.mtotransaccionvisa,a.hortransaccion
from ods_v.hd_movimientopos a
left join ods_v.md_cuentag94 b on a.codclaveopectaafectada = b.codclaveopecta
inner join tmp_retatmext_pos_egresos_univ c on b.codclavecic = c.codclavecic
where a.codretorno = '00' and a.tiporigen = '2' and a.tipmedioelectronico in( '2','4','5') and  a.fecdia between trunc(add_months(sysdate, :intervalo_1),'mm') and last_day(trunc(add_months(sysdate, :intervalo_1))) and a.codpaisestablecimiento <> 'PE'
and a.flgvalida = 'S' and a.flgextorno='N' and  c.codclavecic<>0;

truncate table tmp_retatmext_depositopos_agr;
insert into tmp_retatmext_depositopos_agr
--create table tmp_retatmext_depositopos_agr tablespace d_aml_99  as
select to_number(to_char(a.fecdia,'yyyymm')) as periodo,
	a.codclavecic,
	sum(a.mtotransaccionvisa)  as mto_opepos,
	count(a.mtotransaccionvisa) as ctd_opepos
from tmp_retatmext_depositopos a
group by to_number(to_char(a.fecdia,'yyyymm')),codclavecic;

truncate table tmp_retatmext_pos_atm;
insert into  tmp_retatmext_pos_atm
--create table tmp_retatmext_pos_atm tablespace d_aml_99  as
select distinct a.*,
	case when c.mto_opepos is null then 0 else round(c.mto_opepos,2) end mto_opepos,
	case when c.ctd_opepos is null then 0 else c.ctd_opepos end ctd_opepos,
	case when b.mto_opeatm is null then 0 else round(b.mto_opeatm,2) end mto_opeatm,
	case when b.ctd_opeatm is null then 0 else b.ctd_opeatm end ctd_opeatm
from tmp_retatmext_univ_cod a
left join tmp_retatmext_depositoatm_agr b on a.codclavecic = b.codclavecic
left join tmp_retatmext_depositopos_agr c on a.codclavecic = c.codclavecic
where a.codclavecic is not null and a.codclavecic<>0;

---------------trx pos + atm
truncate table tmp_retatmext_trx_tablon;
insert into tmp_retatmext_trx_tablon
--create table tmp_retatmext_trx_tablon tablespace d_aml_99  as
with tmp as (
select codclavecic,fecdia,hortransaccion,mtotransaccionvisa,'ATM' canal
from tmp_retatmext_depositoatm
union all
select codclavecic,fecdia,hortransaccion,mtotransaccionvisa,'POS' canal
from tmp_retatmext_depositopos  )
	select a.*
	from tmp a
	inner join tmp_retatmext_univ_cod b on a.codclavecic=b.codclavecic;

----detalle pais del univ
truncate table tmp_retatmext_nbrpais;
insert into tmp_retatmext_nbrpais
--create table tmp_retatmext_nbrpais tablespace d_aml_99  as
	select distinct a.*,b.nombrepais,b.codpais2
	from tmp_retatmext_pos_egresos_univ a
	left join s55632.rm_paisesaltoriesgo b on a.codpaisestablecimiento = b.codpais2;

-------ecuador y riesgo pais
truncate table tmp_retatmext_riesgopais;
insert into tmp_retatmext_riesgopais
--create table tmp_retatmext_riesgopais tablespace d_aml_99  as
	with tmp as (
	select codclavecic,
	case when codpais2='EC' then 1 else 0 end flg_ecuador,
	case when codpais2 is null then 0 else 1 end flg_paisriesgo
	 from tmp_retatmext_nbrpais)
	 select distinct codclavecic, max(flg_ecuador) flg_ecuador,max(flg_paisriesgo) flg_paisriesgo
	 from tmp
	 group by codclavecic;

-------tablon final
truncate table tmp_retatmext_tablon_final;
insert into tmp_retatmext_tablon_final
--create table tmp_retatmext_tablon_final tablespace d_aml_99  as
select a.*,
case when b.flg_paisriesgo is null then 0 else b.flg_paisriesgo end flg_paisriesgo,
case when b.flg_ecuador is null then 0 else b.flg_ecuador end flg_ecuador
from tmp_retatmext_pos_atm a
left join tmp_retatmext_riesgopais b on a.codclavecic = b.codclavecic ;

commit;
quit;