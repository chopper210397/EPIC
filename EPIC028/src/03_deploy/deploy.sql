--PARAMETRO DE CREDENCIALES
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

/*************************************************************************************************
****************************** ESCENARIO YAPE ***************************
*************************************************************************************************/

--Tabla epic028
truncate table epic028;
insert into epic028 
select 
    sysdate as fecgeneracion, 
    38 as idorigen, codunicocli, 
    'EPIC028' as escenario,
    'EPIC028 - ESCENARIO YAPE' as desescenario, 
    'ULTIMO MES' as periodo, 
    round(monto_ingreso,2) as triggering,  
	'La alerta corresponde al periodo ' || codmes_operacion || ' es generada porque el cliente recibio depositos a su yape por $' || round(monto_ingreso,2) || 
    ' a través de ' || ctd_ingreso || ' operaciones de deposito ' || ctd_ope_dist_ing ||' personas distintas. En el mismo periodo, realizó un total de ' || 
    ctd_egreso || ' envios yape por un monto de $' || ROUND(MTO_EGR,2)|| '. Adicionalmente, el cliente'|| 
    case when flg_policia=1 then ' SI' else ' NO' end ||' es policia y ' || case when flg_cuenta_yapecard=1 then 'SI' else 'NO' end ||
	' esta registrado como yapecard. El cliente '|| case when flg_perfil_3ds=1 then 'SI' else 'NO' end ||
    ' sale de su perfil transaccional de yape comparado con los 6 ultimos meses previos. Además '|| case when flgarchivonegativo=1 then 'SI' else 'NO' end || 
    ' está registrado en AN, ' || case when flglsb=1 then 'SI' else 'NO' end || ' presenta lsb' ||
	case when ctd_alertas_prev > 0 then ' y el cliente cuenta con ' || ctd_alertas_prev || ' evaluaciones plaft previas.'   
    else 'error' end as comentario
from tmp_yape_alertas ;

grant select on epic028 to rol_vistasdwhgstcum;

--TABLA EPIC028 - DOCUMENTOS

truncate table epic028_doc;
insert into epic028_doc 
select distinct
      '\\pfilep11\lavadoactivos\99_procesos_bi\0_sapycweb\paquetes_adhoc\' as ruta,
      '99999999_modem_epic028_trxs_' || codunicocli || '.csv' as nbrdocumento,
      codunicocli,
      sysdate as fecregistro,
      ' ' as numcaso,
      0 as idanalista
from epic028
union all
select distinct
      '\\pfilep11\lavadoactivos\99_procesos_bi\0_sapycweb\paquetes_adhoc\' as ruta,
      '99999999_modem_epic028_eecc_' || codunicocli || '.csv' as nbrdocumento,
      codunicocli,
      sysdate as fecregistro,
      ' ' as numcaso,
      0 as idanalista
from epic028;

grant select on epic028_doc to rol_vistasdwhgstcum;

commit;
quit;