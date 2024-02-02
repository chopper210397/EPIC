--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

--tabla epic024_pj
truncate table epic024_pj;
insert into epic024_pj
select sysdate as fecgeneracion, 38 as idorigen, a.codunicocli, 'EPIC024' as escenario,
'EPIC024_Estructuracion a traves de Pagos del Exterior' as desescenario, 'ULTIMO MES' as periodo,
case when n_cluster in (-1,1) then round(a.mto_conotrosproximos,2) end as triggering,
case when n_cluster in (1) then
	 'La alerta correspondiente al periodo '||a.periodo||' dado que el cliente '||(a.codunicocli)|| ' tiene un acumulado del monto de ingreso $'||round(a.mto_ingresos_mes,2)|| ' del mes que supera la valla de $30MM.' 
	 when n_cluster in (-1) then
	'La alerta correspondiente al periodo '||a.periodo||' dado que el cliente '||(a.codunicocli)||' tiene las siguientes características: Tiene un acumulado del monto de ingreso $'||round(a.mto_ingresos_mes,2)||' del cual $'||round(a.mto_conotrosproximos,2)|| ' corresponde a ' ||(a.ctd_conotrosproximos)|| ' transacciones repetidas. Adicionalmente el cliente '|| case when a.flg_perfil_ingresos_3ds=1 then ' si ' else ' no ' end ||' sale de su perfil transaccional de ingresos en el mes.'
else 'ERROR' end as comentario
from  tmp_ingresotrc_alertaspj a;

commit;
quit;