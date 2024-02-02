--PARAMETRO DE CREDENCIALES
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

var intervalo_1 number 
exec :intervalo_1 := to_number(&2);

select :intervalo_1 from dual;
/*************************************************************************************************
****************************** ESCENARIO YAPE ***************************
*************************************************************************************************/

alter session disable parallel query;

-- Ingreso

truncate table tmp_yape_trx_ingreso_aux_01;
insert into tmp_yape_trx_ingreso_aux_01
select c.codmes_operacion,a.codclavecic,sum(c.mto_operacion*tc.mtocambioaldolar) as monto_ingreso
from tmp_yape_universo a 
inner join T26030.md_trx_yape_dac_view c on a.codclaveopecta_destino=c.codclaveopecta_destino
left join ods_v.hd_tipocambiosaldodiario tc on c.dia_operacion = tc.fectipcambio
where tc.codmoneda='0001' and c.dia_operacion between trunc(add_months(sysdate,:intervalo_1),'mm') and trunc(last_day(add_months(sysdate,:intervalo_1)))
and c.mto_operacion>0 and a.codclaveopecta_destino is not null
group by c.codmes_operacion,a.codclavecic;

truncate table tmp_yape_trx_ingreso_aux_02;
insert into tmp_yape_trx_ingreso_aux_02
select c.codmes_operacion,a.codclavecic,sum(c.mto_operacion*tc.mtocambioaldolar) as monto_ingreso
from tmp_yape_universo a 
inner join T26030.md_trx_yape_dac_view c on a.codclaveopecta_destino=c.codclaveopecta_destino
left join ods_v.hd_tipocambiosaldodiario tc on c.dia_operacion = tc.fectipcambio
where tc.codmoneda='0001' and c.dia_operacion between trunc(add_months(sysdate,:intervalo_1-1),'mm') and trunc(last_day(add_months(sysdate,:intervalo_1-1)))
and c.mto_operacion>0 and a.codclaveopecta_destino is not null
group by c.codmes_operacion,a.codclavecic;

truncate table tmp_yape_trx_ingreso_aux_03;
insert into tmp_yape_trx_ingreso_aux_03
select c.codmes_operacion,a.codclavecic,sum(c.mto_operacion*tc.mtocambioaldolar) as monto_ingreso
from tmp_yape_universo a 
inner join T26030.md_trx_yape_dac_view c on a.codclaveopecta_destino=c.codclaveopecta_destino
left join ods_v.hd_tipocambiosaldodiario tc on c.dia_operacion = tc.fectipcambio
where tc.codmoneda='0001' and c.dia_operacion between trunc(add_months(sysdate,:intervalo_1-2),'mm') and trunc(last_day(add_months(sysdate,:intervalo_1-2)))
and c.mto_operacion>0 and a.codclaveopecta_destino is not null
group by c.codmes_operacion,a.codclavecic;

truncate table tmp_yape_trx_ingreso_aux_04;
insert into tmp_yape_trx_ingreso_aux_04
select c.codmes_operacion,a.codclavecic,sum(c.mto_operacion*tc.mtocambioaldolar) as monto_ingreso
from tmp_yape_universo a 
inner join T26030.md_trx_yape_dac_view c on a.codclaveopecta_destino=c.codclaveopecta_destino
left join ods_v.hd_tipocambiosaldodiario tc on c.dia_operacion = tc.fectipcambio
where tc.codmoneda='0001' and c.dia_operacion between trunc(add_months(sysdate,:intervalo_1-3),'mm') and trunc(last_day(add_months(sysdate,:intervalo_1-3)))
and c.mto_operacion>0 and a.codclaveopecta_destino is not null
group by c.codmes_operacion,a.codclavecic;

truncate table tmp_yape_trx_ingreso_aux_05;
insert into tmp_yape_trx_ingreso_aux_05
select c.codmes_operacion,a.codclavecic,sum(c.mto_operacion*tc.mtocambioaldolar) as monto_ingreso
from tmp_yape_universo a 
inner join T26030.md_trx_yape_dac_view c on a.codclaveopecta_destino=c.codclaveopecta_destino
left join ods_v.hd_tipocambiosaldodiario tc on c.dia_operacion = tc.fectipcambio
where tc.codmoneda='0001' and c.dia_operacion between trunc(add_months(sysdate,:intervalo_1-4),'mm') and trunc(last_day(add_months(sysdate,:intervalo_1-4)))
and c.mto_operacion>0 and a.codclaveopecta_destino is not null
group by c.codmes_operacion,a.codclavecic;

truncate table tmp_yape_trx_ingreso_aux_06;
insert into tmp_yape_trx_ingreso_aux_06
select c.codmes_operacion,a.codclavecic,sum(c.mto_operacion*tc.mtocambioaldolar) as monto_ingreso
from tmp_yape_universo a 
inner join T26030.md_trx_yape_dac_view c on a.codclaveopecta_destino=c.codclaveopecta_destino
left join ods_v.hd_tipocambiosaldodiario tc on c.dia_operacion = tc.fectipcambio
where tc.codmoneda='0001' and c.dia_operacion between trunc(add_months(sysdate,:intervalo_1-5),'mm') and trunc(last_day(add_months(sysdate,:intervalo_1-5)))
and c.mto_operacion>0 and a.codclaveopecta_destino is not null
group by c.codmes_operacion,a.codclavecic;
 
truncate table tmp_yape_trx_ingreso_;
insert into tmp_yape_trx_ingreso_
select c.codmes_operacion,c.codclavecic, sum(c.monto_ingreso) monto_ingreso
from (
     select * from tmp_yape_trx_ingreso_aux_01
     union all
     select * from tmp_yape_trx_ingreso_aux_02
     union all
     select * from tmp_yape_trx_ingreso_aux_03
     union all
     select * from tmp_yape_trx_ingreso_aux_04
     union all
     select * from tmp_yape_trx_ingreso_aux_05
     union all
     select * from tmp_yape_trx_ingreso_aux_06
     ) c
group by c.codmes_operacion,c.codclavecic;

-- Egreso

truncate table tmp_yape_trx_egreso_aux_01;
insert into tmp_yape_trx_egreso_aux_01
select distinct 
b.codmes_operacion,a.codclavecic,b.hora,(b.mto_operacion*tc.mtocambioaldolar) as mto_operacion,b.dia_operacion,c.codclavecic as codclavecic_egr
from tmp_yape_universo a 
inner join T26030.md_trx_yape_dac_view b on a.codclavecic=b.codclavecic_origen
left join T26030.HD_YAPERO_VIEW c on a.codclaveopecta_destino=c.codclaveopecta_yape
left join ods_v.hd_tipocambiosaldodiario tc on b.dia_operacion = tc.fectipcambio
where tc.codmoneda='0001' and b.dia_operacion between trunc(add_months(sysdate,:intervalo_1),'mm') and trunc(last_day(add_months(sysdate,:intervalo_1)))
and b.mto_operacion>0 and c.codclavecic is not null;

truncate table tmp_yape_trx_egreso_aux_02;
insert into tmp_yape_trx_egreso_aux_02
select distinct 
b.codmes_operacion,a.codclavecic,b.hora,(b.mto_operacion*tc.mtocambioaldolar) as mto_operacion,b.dia_operacion,c.codclavecic as codclavecic_egr
from tmp_yape_universo a 
inner join T26030.md_trx_yape_dac_view b on a.codclavecic=b.codclavecic_origen
left join T26030.HD_YAPERO_VIEW c on a.codclaveopecta_destino=c.codclaveopecta_yape
left join ods_v.hd_tipocambiosaldodiario tc on b.dia_operacion = tc.fectipcambio
where tc.codmoneda='0001' and b.dia_operacion between trunc(add_months(sysdate,:intervalo_1-1),'mm') and trunc(last_day(add_months(sysdate,:intervalo_1-1)))
and b.mto_operacion>0 and c.codclavecic is not null;

truncate table tmp_yape_trx_egreso_aux_03;
insert into tmp_yape_trx_egreso_aux_03
select distinct 
b.codmes_operacion,a.codclavecic,b.hora,(b.mto_operacion*tc.mtocambioaldolar) as mto_operacion,b.dia_operacion,c.codclavecic as codclavecic_egr
from tmp_yape_universo a 
inner join T26030.md_trx_yape_dac_view b on a.codclavecic=b.codclavecic_origen
left join T26030.HD_YAPERO_VIEW c on a.codclaveopecta_destino=c.codclaveopecta_yape
left join ods_v.hd_tipocambiosaldodiario tc on b.dia_operacion = tc.fectipcambio
where tc.codmoneda='0001' and b.dia_operacion between trunc(add_months(sysdate,:intervalo_1-2),'mm') and trunc(last_day(add_months(sysdate,:intervalo_1-2)))
and b.mto_operacion>0 and c.codclavecic is not null;

truncate table tmp_yape_trx_egreso_aux_04;
insert into tmp_yape_trx_egreso_aux_04
select distinct 
b.codmes_operacion,a.codclavecic,b.hora,(b.mto_operacion*tc.mtocambioaldolar) as mto_operacion,b.dia_operacion,c.codclavecic as codclavecic_egr
from tmp_yape_universo a 
inner join T26030.md_trx_yape_dac_view b on a.codclavecic=b.codclavecic_origen
left join T26030.HD_YAPERO_VIEW c on a.codclaveopecta_destino=c.codclaveopecta_yape
left join ods_v.hd_tipocambiosaldodiario tc on b.dia_operacion = tc.fectipcambio
where tc.codmoneda='0001' and b.dia_operacion between trunc(add_months(sysdate,:intervalo_1-3),'mm') and trunc(last_day(add_months(sysdate,:intervalo_1-3)))
and b.mto_operacion>0 and c.codclavecic is not null;

truncate table tmp_yape_trx_egreso_aux_05;
insert into tmp_yape_trx_egreso_aux_05
select distinct 
b.codmes_operacion,a.codclavecic,b.hora,(b.mto_operacion*tc.mtocambioaldolar) as mto_operacion,b.dia_operacion,c.codclavecic as codclavecic_egr
from tmp_yape_universo a 
inner join T26030.md_trx_yape_dac_view b on a.codclavecic=b.codclavecic_origen
left join T26030.HD_YAPERO_VIEW c on a.codclaveopecta_destino=c.codclaveopecta_yape
left join ods_v.hd_tipocambiosaldodiario tc on b.dia_operacion = tc.fectipcambio
where tc.codmoneda='0001' and b.dia_operacion between trunc(add_months(sysdate,:intervalo_1-4),'mm') and trunc(last_day(add_months(sysdate,:intervalo_1-4)))
and b.mto_operacion>0 and c.codclavecic is not null;

truncate table tmp_yape_trx_egreso_aux_06;
insert into tmp_yape_trx_egreso_aux_06
select distinct 
b.codmes_operacion,a.codclavecic,b.hora,(b.mto_operacion*tc.mtocambioaldolar) as mto_operacion,b.dia_operacion,c.codclavecic as codclavecic_egr
from tmp_yape_universo a 
inner join T26030.md_trx_yape_dac_view b on a.codclavecic=b.codclavecic_origen
left join T26030.HD_YAPERO_VIEW c on a.codclaveopecta_destino=c.codclaveopecta_yape
left join ods_v.hd_tipocambiosaldodiario tc on b.dia_operacion = tc.fectipcambio
where tc.codmoneda='0001' and b.dia_operacion between trunc(add_months(sysdate,:intervalo_1-5),'mm') and trunc(last_day(add_months(sysdate,:intervalo_1-5)))
and b.mto_operacion>0 and c.codclavecic is not null;

truncate table tmp_yape_trx_egreso_;
insert into tmp_yape_trx_egreso_
select * from tmp_yape_trx_egreso_aux_01
union all
select * from tmp_yape_trx_egreso_aux_02
union all
select * from tmp_yape_trx_egreso_aux_03
union all
select * from tmp_yape_trx_egreso_aux_04
union all
select * from tmp_yape_trx_egreso_aux_05
union all
select * from tmp_yape_trx_egreso_aux_06;

commit;
quit;