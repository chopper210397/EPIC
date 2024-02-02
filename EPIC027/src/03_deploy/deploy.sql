--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

--tabla epic027
truncate table epic027;
insert into epic027
--create table epic027 tablespace d_aml_99 as
select
      sysdate as fecgeneracion, 38 as idorigen, codunicocli, 'EPIC027' as escenario,
      'EPIC027 - ESCENARIO OUTLIERS GREMIO' as desescenario, 'ULTIMO MES' as periodo,
       round(deuda_sf_sin_hip,2)*mtocambioaldolar as triggering,
     'LA ALERTA CORRESPONDIENTE AL PERIODO ' || codmes || ' EL CLIENTE GREMIO PRESENTA UNA DEUDA EN EL SISTEMA FINANCIERO CORRESPONDIENTE A $ ' || round(deuda_sf_sin_hip,2)*mtocambioaldolar || '. SIN EMBARGO, SU INGRESO COMO PAGO DE HABERES ES DE $ ' || round(ingreso_haberes,2)*mtocambioaldolar || ' SIENDO EL RATIO DE SU DEUDA DEL SISTEMA FINANCIERO Y EL INGRESO DE HABERES DE ' || ratio_no_total_sf_hab || '. EN EL PRESENTE MES EL CLIENTE PRESENTA UNA DIFERENCIA SIGNIFICATIVA DE SUS PAGOS RESPECTO AL MES ANTERIOR DE $ '|| round(variacio_1m_total_deuda,2)*mtocambioaldolar || '.'
     as comentario
from tmp_grm_alertas  a
left join tmp_grm_tipocambio b on a.codmes=b.numperiodo;

grant select on epic027 to rol_vistasdwhgstcum;

--tabla epic027 - documentos
truncate table epic027_doc;
insert into epic027_doc
--create table epic027_doc tablespace d_aml_99 as
select distinct
      '\\Pfilep11\lavadoactivos\99_Procesos_BI\0_SapycWeb\PAQUETES_ADHOC\' as ruta,
      '99999999_MODEM_EPIC027_TRXS_' || codunicocli || '.CSV' as nbrdocumento,
      codunicocli,
      sysdate as fecregistro,
      ' ' as numcaso,
      0 as idanalista
from epic027
union all
select distinct
      '\\Pfilep11\lavadoactivos\99_Procesos_BI\0_SapycWeb\PAQUETES_ADHOC\' as ruta,
      '99999999_MODEM_EPIC027_EECC_' || codunicocli || '.CSV' as nbrdocumento,
      codunicocli,
      sysdate as fecregistro,
      ' ' as numcaso,
      0 as idanalista
from epic027;

grant select on epic027_doc to rol_vistasdwhgstcum;

commit;
quit;