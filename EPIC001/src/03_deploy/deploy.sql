--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

--tabla epic001
--create table  epic001 tablespace d_aml_99 as
truncate table epic001;
insert into epic001
select
      sysdate as fecgeneracion, 38 as idorigen, codunicocli, 'EPIC001' as escenario,
      'EPIC001 - ESCENARIO DE DEPOSITOS DE EFECTIVO SEGUIDO POR RETIRO EN DOLARES EN EL EXTERIOR' as desescenario, 'ULTIMO MES' as periodo,
      ROUND(A.MTO_TOTAL_OPE,2) as triggering,
      'LA ALERTA CORRESPONDIENTE AL PERIODO ' || A.PERIODO || ' ES GENERADA PORQUE EL CLIENTE REALIZO RETIROS/CONSUMOS
      EN EL EXTERIOR POR UN MONTO DE S/.' || ROUND(A.MTO_TOTAL_OPE,2) || ' EN '|| A.CTD_TOTAL_OPE|| ' OPERACIONES.'||
      case when A.FLG_PAISRIESGO=1 then 'ADICIONALMENTE PRESENTA OPERACIONES REALIZADAS EN UN PAIS DE ALTO RIESGO.' else '' end
      as comentario
from tmp_retatmext_alertas a;

grant select on epic001 to rol_vistasdwhgstcum;

--tabla epic001 - documentos
--create table  epic001_doc tablespace d_aml_99 as
truncate table epic001_doc;
insert into epic001_doc
select distinct
      '\\Pfilep11\lavadoactivos\99_Procesos_BI\0_SapycWeb\PAQUETES_ADHOC\' as ruta,
      '99999999_MODEM_EPIC001_TRXS_' || codunicocli || '.CSV' as nbrdocumento,
      codunicocli,
      sysdate as fecregistro,
      ' ' as numcaso,
      0 as idanalista
from epic001
union all
select distinct
      '\\PFILEP11\LAVADOACTIVOS\99_PROCESOS_BI\0_SAPYCWEB\DOCUMENTOS\' as ruta,
      '99999999_MODEM_EPIC001_EECC_' || codunicocli || '.CSV' AS nbrdocumento,
      codunicocli,
      sysdate as fecregistro,
      ' ' as numcaso,
      0 as idanalista
from epic001;

grant select on epic001_doc to rol_vistasdwhgstcum;

commit;
quit;