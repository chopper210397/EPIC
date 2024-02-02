--PARAMETRO DE CREDENCIALES
@&1

set echo on
whenever sqlerror exit sql.sqlcode

alter session disable parallel query;

/*************************************************************************************************
****************************** Escenario estimador de ingresos ***********************************
*************************************************************************************************/

-- creado por: Celeste Cabanillas
-- key user escenario: plaft
/*************************************************************************************************/

--Tabla epic030
truncate table epic030;
insert into epic030
select 
      sysdate as fecgeneracion, 38 as idorigen, codunicocli, 'EPIC030' as escenario,
      'EPIC030 - ESCENARIO ESTIMADOR DE INGRESOS' as desescenario, 'ULTIMO MES' as periodo,
       round(mto_ingreso,2) as triggering, 	  
     'LA ALERTA CORRESPONDIENTE AL PERIODO ' || codmes || ' ES GENERADA PORQUE EL CLIENTE RECIBIO $ ' || round(mto_ingreso,2) || ' DE INGRESOS EN CUENTAS, LO CUAL REPRESENTA ' || ROUND(MTO_INGRESO/MTO_ESTIMADOR,2) || ' VECES MAS LO PRONOSTICADO POR EL ESTIMADOR DE INGRESO $ ' || ROUND(MTO_ESTIMADOR,2) || ', ADICIONALMENTE EL MONTO EN CUENTA FUE REALIZADO A TRAVES DE '|| ROUND(CTD_INGRESO,2) || ' OPERACIONES.'
      || case when flg_perfil_depositos_3ds=1 then 'ADICIONALMENTE, EL CLIENTE SI SALE DE SU PERFIL TRANSACCIONAL DE INGRESOS COMPARADO CON LOS 06 ULTIMOS MESES PREVIOS Y CUENTA CON ' 
	  else 'ADICIONALMENTE, EL CLIENTE NO SALE DE SU PERFIL TRANSACCIONAL DE INGRESOS COMPARADO CON LOS 06 ULTIMOS MESES PREVIOS Y CUENTA CON ' end || ctdeval || ' EVALUACIONES PREVIAS.' 
      as comentario 
from tmp_esting_alertas;  

grant select on epic030 to rol_vistasdwhgstcum;

--Tabla epic030 - documentos
truncate table epic030_doc;
insert into epic030_doc 
select distinct
      '\\pfilep11\lavadoactivos\99_procesos_bi\0_sapycweb\paquetes_adhoc\' as ruta,
      '99999999_modem_epic030_eecc_' || codunicocli || '.csv' as nbrdocumento,
      codunicocli,
      sysdate as fecregistro,
      ' ' as numcaso,
      0 as idanalista
from epic030;

grant select on epic030_doc to rol_vistasdwhgstcum;

commit;
quit;