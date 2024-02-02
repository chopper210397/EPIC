--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

--tabla epic024_pn
truncate table epic024_pn;
insert into epic024_pn
select sysdate as fecgeneracion, 38 as idorigen, a.codunicocli, 'EPIC024' as escenario,
'EPIC024_Estructuracion a traves de Pagos del Exterior' as desescenario, 'ULTIMO MES' as periodo,
case when n_cluster in (-1,1) then round(a.mto_conotrosproximos,2) end as triggering,
case when n_cluster in (1) then
    'La alerta correspondiente al periodo '||a.periodo||' dado que el cliente '||(a.codunicocli)|| ' tiene un acumulado del monto de ingreso $'||round(a.mto_ingresos_mes,2)|| ' del mes que supera la valla de $1MM.' 
	 when n_cluster in (-1) then
	'La alerta correspondiente al periodo '||a.periodo||' dado que el cliente '||(a.codunicocli)||' tiene las siguientes características: Tiene un acumulado del monto de ingreso $'||round(a.mto_ingresos_mes,2)||' del cual $'||round(a.mto_conotrosproximos,2)|| ' corresponde a ' ||(a.ctd_conotrosproximos)|| ' transacciones repetidas. Adicionalmente el cliente ' || case when a.flg_perfil_ingresos_3ds=1 then ' si ' else ' no ' end || ' sale de su perfil transaccional de ingresos en el mes.'
else 'ERROR' end as comentario
from  tmp_ingresotrc_alertaspn a;

--union de tabla de alertas pn y pj
truncate table epic024;
insert into epic024
select * from epic024_pn
union all
select * from epic024_pj;

grant select on epic024 to rol_vistasdwhgstcum;

--tabla epic024 - documentos
truncate table epic024_doc;
insert into epic024_doc
select distinct
      '\\Pfilep11\lavadoactivos\99_Procesos_BI\0_SapycWeb\PAQUETES_ADHOC\' AS RUTA,
      '99999999_modem_epic024_pn_trxs_' || codunicocli || '.CSV' as nbrdocumento,
      codunicocli,
      sysdate as fecregistro,
      ' ' as numcaso,
      0 as idanalista
from epic024_pn
union all
select distinct
      '\\pfilep11\lavadoactivos\99_procesos_bi\0_sapycweb\paquetes_adhoc\' as ruta,
      '99999999_modem_epic024_pj_trxs_' || codunicocli || '.csv' as nbrdocumento,
      codunicocli,
      sysdate as fecregistro,
      ' ' as numcaso,
      0 as idanalista
from epic024_pj;

grant select on epic024_doc to rol_vistasdwhgstcum;

commit;
quit;