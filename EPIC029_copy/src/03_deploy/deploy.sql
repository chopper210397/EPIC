--PARAMETRO DE CREDENCIALES
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

/*************************************************************************************************
****************************** ESCENARIO TOP INGRESO EFECTIVO BENEFICIARIO SOLES *****************
*************************************************************************************************/

-- key user escenario: plaft
-- fecha:

truncate table epic029;
insert into epic029
select distinct
       sysdate as fecgeneracion, 
       38 as idorigen, 
       a.codunicoclibeneficiario, 
       'EPIC029' as escenario,
       'Top ingreso efectivo beneficiario soles' as desescenario, 
       'ULTIMO MES' AS PERIODO, 
       MTO_RECIBIDO AS TRIGGERING,
       'Esta alerta pertenece al periodo ' || a.periodo ||
       case when n_cluster = 11 then '. Cliente con montos altos, pertenece a Banca Empresa y el solicitante no esta relacionado al beneficiario.'
            when n_cluster = 7 THEN '. Cliente pertenece a Banca Empresa, el solicitante no esta relacionado al beneficiario, y tiene antecedentes de ROS.'
            ELSE '. Cliente con montos altos, pertenece a Banca Persona y el solicitante no esta relacionado al beneficiario.' end as comentario
from tmp_topsolicitante_filtrado a;

quit;
commit;