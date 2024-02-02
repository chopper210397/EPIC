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

--Universo
 
truncate table tmp_yape_universo;
insert into tmp_yape_universo 
select distinct codmes_operacion,codclavecic,codclaveopecta_destino
from T26030.md_trx_yape_dac_view a
inner join T26030.HD_YAPERO_VIEW b on a.codclaveopecta_destino=b.codclaveopecta_yape
left join ods_v.hd_tipocambiosaldodiario tc on a.dia_operacion = tc.fectipcambio
where tc.codmoneda='0001' and a.dia_operacion between trunc(add_months(sysdate,:intervalo_1),'mm') and trunc(last_day(add_months(sysdate,:intervalo_1)) )
and codclaveopecta_destino is not null
group by codclavecic,codmes_operacion,codclaveopecta_destino
having sum(a.mto_operacion*mtocambioaldolar)>1000 and b.codclavecic is not null ; 

commit;
quit;
