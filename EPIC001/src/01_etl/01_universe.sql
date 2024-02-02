--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

var intervalo_1 number
exec :intervalo_1 := to_number(&2);

select :intervalo_1from dual;

-----------------------------------------------------------------------------------|| cambiar fecha  ||----------------
---------universo
--drop table tmp_retatmext_pos_egresos_univ;
--create table tmp_retatmext_pos_egresos_univ tablespace d_aml_99 as
truncate table tmp_retatmext_pos_egresos_univ;
insert into tmp_retatmext_pos_egresos_univ
select b.codclavecic,a.codclavetarjetadebito,a.numreferenciatransaccion,a.fecdia as fecdiaret,a.hortransaccion as hortransaccionret,a.flgvalida,
a.tiporigen,a.codmoneda,a.tipopepos,a.flgextorno,a.desciudadestablecimiento,a.codpaisestablecimiento,a.codmonedatransaccion,a.mtotransaccion,a.codmonedavisa,a.mtotransaccionvisa,
a.codclaveopectaafectada
from ods_v.hd_movimientopos a
left join ods_v.md_cuenta b on a.codclaveopectaafectada = b.codclaveopecta
left join s55632.rm_paisesaltoriesgo c on trim(a.codpaisestablecimiento) = trim(c.codpais2)
where a.tipopepos in ('0','1','5') and
a.fecdia between trunc(add_months(sysdate, :intervalo_1),'mm') and trunc(last_day(add_months(sysdate, :intervalo_1))) and a.flgvalida = 'S' and a.codpaisestablecimiento <> 'PE';

----codclavecic
--drop table tmp_retatmext_univ_cod;
--create table tmp_retatmext_univ_cod tablespace d_aml_99 as
truncate table tmp_retatmext_univ_cod;
insert into tmp_retatmext_univ_cod
select distinct to_number(to_char(fecdiaret,'yyyymm')) as periodo,codclavecic
from tmp_retatmext_pos_egresos_univ;

commit;
quit;