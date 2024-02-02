--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

--tabla epic022
truncate table epic022;
insert into epic022
--create table epic022 tablespace d_aml_99 as
select
      sysdate as fecgeneracion, 38 as idorigen, c.codunicocli, 'EPIC022' as escenario,
      'EPIC022 - CLIENTE NUEVO CON ALTOS DEPOSITOS EN EFECTIVO' as desescenario, 'ULTIMO MES' as periodo,
      ROUND(A.MTO_TOTAL,2) as triggering,
      'La alerta correspondiente al periodo ' || a.periodo || ' es generada porque el cliente tiene una antigüedad de ' || a.antiguedadcli || ' meses y ' ||
      'recibe depósitos en por  $ ' || a.mto_total || ' de los cuales $ ' || a.mto_total_cash || ' fueron en efectivo y realizados mediante ' || a.ctd_total_cash || ' operaciones.' ||
      case when a.mto_chqgen > 0 then ' Adicionalmente, tuvo operaciones por $ ' || a.mto_chqgen || ' a través de cheques de gerencia' else '' end
      as comentario
from tmp_clinuevo_alertas a
     left join ods_v.md_clienteg94 c on a.codclavecic = c.codclavecic;
grant select on epic022 to rol_vistasdwhgstcum;

--tabla epic022 - documentos
truncate table epic022_doc;
insert into epic022_doc
--create table epic022_doc tablespace d_aml_99 as
select distinct
      '\\PFILEP11\LAVADOACTIVOS\99_PROCESOS_BI\0_SAPYCWEB\DOCUMENTOS\' as ruta,
      '99999999_MODEM_EPIC022_TRXS_' || codunicocli || '.CSV' as nbrdocumento,
      codunicocli,
      sysdate as fecregistro,
      ' ' as numcaso,
      0 as idanalista
from epic022
union all
select distinct
      '\\PFILEP11\LAVADOACTIVOS\99_PROCESOS_BI\0_SAPYCWEB\DOCUMENTOS\' as ruta,
      '99999999_MODEM_EPIC022_EECC_' || codunicocli || '.CSV' AS nbrdocumento,
      codunicocli,
      sysdate as fecregistro,
      ' ' as numcaso,
      0 as idanalista
from epic022;

grant select on epic022_doc to rol_vistasdwhgstcum;

commit;
quit;