--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

--tabla epic021
truncate table epic021;
insert into epic021
select
      sysdate as fecgeneracion, 38 as idorigen, codunicocli, 'EPIC021' as escenario,
      'EPIC021 - ESCENARIO DE AGENTES' as desescenario, 'ULTIMO MES' as periodo,
      round(a.mto_cash_depo,2) as triggering,
      case when rf_pred = -1 then 'LA ALERTA CORRESPONDIENTE AL PERIODO ' || a.periodo || ' ES GENERADA PORQUE EL AGENTE RECIBE UNA CANTIDAD SIGNIFICATIVA DE DEPOSITOS EN  EFECTIVO $' || round(a.mto_cash_depo,2) || '. ADICIONALMENTE, HUBO ' || ctd_an_np_lsb || ' OPERACIONES DE DEPOSITO REALIZADAS POR PERSONAS MARCADAS COMO AN/LSB/NP' || case when ctd_evals_prop > 0 then ' Y EL PROPIETARIO DEL AGENTE CUENTA CON ' || ctd_evals_prop || ' EVALUACIONES PLAFT PREVIAS.' else '.' end
           when rf_pred = 6 then 'LA ALERTA CORRESPONDIENTE AL PERIODO ' || a.periodo || ' ES GENERADA PORQUE EL AGENTE SE ENCUENTRA EN UNA ZONA ZAED Y SALE DE SU PERFIL TRANSACCIONAL DE DEPOSITOS, ES DECIR, EXCEDE A SU PROMEDIO DE DEPOSITOS TOTALES DE LOS 6 MESES ANTERIORES $' || round(b.media_cash_depo,2) || ' MAS 3 VECES LA DESVIACION ESTANDAR $' || round(b.desv_cash_depo,2) || '. EL MONTO DE DEPOSITOS RECIBIDO EN ESTE PERIODO FUE DE $' || round(a.mto_cash_depo,2) || '.'
           when rf_pred = 7 then 'LA ALERTA CORRESPONDIENTE AL PERIODO ' || a.periodo || ' ES GENERADA PORQUE EL AGENTE SE ENCUENTRA EN UNA ZONA ZAED Y SALE DE SU PERFIL TRANSACCIONAL DE DEPOSITOS, ES DECIR, EXCEDE A SU PROMEDIO DE DEPOSITOS TOTALES DE LOS 6 MESES ANTERIORES $' || round(b.media_cash_depo,2) || ' MAS 3 VECES LA DESVIACION ESTANDAR $' || round(b.desv_cash_depo,2) || '. ADICIONALMENTE, EL AGENTE NO TIENE UNA ACTIVIDAD ECONOMICA CONOCIDA Y EL MONTO DE DEPOSITOS RECIBIDO EN ESTE PERIODO FUE DE $' || round(a.mto_cash_depo,2) || '.'
      else 'ERROR' end as comentario
from tmp_escagente_alertas a
left join tmp_escagente_perfi3 b on a.periodo = b.numperiodo and a.codagenteviabcp = b.codagenteviabcp;

grant select on epic021 to rol_vistasdwhgstcum;

--tabla epic021 - documentos
truncate table epic021_doc;
insert into epic021_doc
select distinct
      '\\Pfilep11\lavadoactivos\99_Procesos_BI\0_SapycWeb\PAQUETES_ADHOC\' AS RUTA,
      '99999999_MODEM_EPIC021_TRXS_' || codunicocli || '.csv' as nbrdocumento,
      codunicocli,
      sysdate as fecregistro,
      ' ' as numcaso,
      0 as idanalista
from epic021
union all
select distinct
      '\\Pfilep11\lavadoactivos\99_Procesos_BI\0_SapycWeb\PAQUETES_ADHOC\' AS RUTA,
      '99999999_MODEM_EPIC021_EECC_' || codunicocli || '.csv' as nbrdocumento,
      codunicocli,
      sysdate as fecregistro,
      ' ' as numcaso,
      0 as idanalista
from epic021;

grant select on epic021_doc to rol_vistasdwhgstcum;

commit;
quit;