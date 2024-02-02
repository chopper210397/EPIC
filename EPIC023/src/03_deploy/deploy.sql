--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

--tabla epic023

truncate table epic023;
insert into epic023
select
      sysdate as fecgeneracion, 38 as idorigen, codunicocli, 'EPIC023' as escenario,
      'EPIC023 - ESCENARIO DE COMPRA Y VENTA DE MONEDA EXTRANJERA' as desescenario, 'ULTIMO MES' as periodo,
      round(a.mto_total,2) as triggering,
      'La alerta correspondiente al periodo ' || a.periodo || ' es generada porque el cliente que ha realizado operaciones de compra/venta de moneda extranjera por $ ' || round(a.mto_total,2) || ' de los cuales $ ' || round(a.mto_zaed,2) || ' fueron hechos en zona ZAED, correspondiente a ' || round(a.ctd_total,2) || ' operaciones en ventanilla en ' || round(a.ctd_dias,2) || ' dias distintos. ' ||
      case when A.FLG_ACTECO_NODEF=1 or A.CTDEVAL >1 then 'Adicionalmente, ' else '' END ||
      case when A.FLG_ACTECO_NODEF=1 and A.CTDEVAL >1 then 'no se conoce la actividad economica del cliente y ha tenido ' || A.CTDEVAL || ' evaluaciones PLAFT.'
           WHEN A.FLG_ACTECO_NODEF=1 then 'no se conoce la actividad economica del cliente'
           WHEN A.CTDEVAL >1 then 'ha tenido ' || A.CTDEVAL || ' evaluaciones PLAFT.'
      else '' end ||
      case when a.flg_perfil_depositos_3ds=1 then ' Por ultimo, el cliente sale de su perfil transaccional de depositos, es decir, excede a su promedio de depositos totales de los 6 meses anteriores $ ' || round(b.media_depo,2) || ' mas 3 veces la desviacion estandar $ ' || round(b.desv_depo,2) || '.'
      else '' end
      as comentario
from tmp_cvme_alertas a
left join tmp_cvme_perfi3 b on a.periodo = b.numperiodo and a.codclavecic = b.codclavecic;

GRANT SELECT ON EPIC023 TO ROL_VISTASDWHGSTCUM;

--tabla epic023 - documentos
truncate table epic023_doc;
insert into epic023_doc
select distinct
      '\\Pfilep11\lavadoactivos\99_Procesos_BI\0_SapycWeb\PAQUETES_ADHOC\' as ruta,
      '99999999_MODEM_EPIC023_TRXS_' || codunicocli || '.CSV' AS nbrdocumento,
      codunicocli,
      sysdate as fecregistro,
      ' ' as numcaso,
      0 as idanalista
from epic023
union all
select distinct
      '\\Pfilep11\lavadoactivos\99_Procesos_BI\0_SapycWeb\PAQUETES_ADHOC\' as ruta,
      '99999999_MODEM_EPIC023_EECC_' || codunicocli || '.CSV' as nbrdocumento,
      codunicocli,
      sysdate as fecregistro,
      ' ' as numcaso,
      0 as idanalista
from epic023;

grant select on epic023_doc to rol_vistasdwhgstcum;

commit;
quit;