--PARAMETRO DE CREDENCIALES
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

-- ============================ tabla de alertas ============================

truncate table tmp_epic032_alertas;
insert into tmp_epic032_alertas
select
    a.*
from tmp_epic032_outputmodel a;

--tabla epic003
--create table epic003 tablespace d_aml_99 as
truncate table epic032;
insert into epic032
select
    sysdate                                     as fecgeneracion,
    38                                          as idorigen,
    codunicocli_limpio                          as codunicocli,
    'EPIC032'                                   as escenario,
    'EPIC032 - Remesas del Exterior'            as desescenario,
    'ULTIMO MES'                                as periodo,
    round(monto_total,2)                         as triggering,
    'La alerta correspondiente al periodo ' || a.periodo ||
    ' es generada dado que el '||
    case
        when flg_cliente=1 then
            'cliente ha recibido un monto total de $ '||a.monto_total||' en '||a.ctd_trx||
            ' remesas del exterior, dichas remesas fueron remitidas por '||a.ctd_ordenantes||
            ' ordenantes, '
        else 
            'no cliente ha recibido un monto total de $ '||a.monto_total||' en'||a.ctd_trx||
            ' remesas del exterior, dichas remesas fueron remitidas por'||a.ctd_ordenantes||
            ' ordenantes, '
    end ||
    case when flg_familiar_apellido=1 then
            'con un aparente vinculo familiar con el beneficiario. El cliente '
        else 
            'sin un aparente vinculo familiar con el beneficiario. El cliente '
    end ||
    case when flg_perfil=1 then
            'sale fuera de su perfil transaccional de remesas, '
        else 
            'no sale fuera de su perfil transaccional de remesas, '
    end ||
    case when flg_lsb_np=1 then
            'tiene registrado NP/LSB, '
        else 
            'no tiene registrado NP/LSB, '
    end ||
    case when flg_an=1 then
            'registra AN '
        else 
            'no registra AN '
    end ||
    case when flg_ros=1 then
            'y registra ros. Como informacion complementaria indicar el '||porcentaje_ctd||
            ' de las remesas se acumulan en una semana del mes.'
        else 
            'y no registra ros. Como informacion complementaria indicar el '||porcentaje_ctd||
            ' de las remesas se acumulan en una semana del mes.'
    end as comentario
from tmp_epic032_alertas a;

grant select on epic032 to rol_vistasdwhgstcum;

--TABLA EPIC032 - DOCUMENTOS
truncate table epic032_doc;
insert into epic032_doc
--create table epic032_doc tablespace d_aml_99 as
select distinct '\\pfilep11\lavadoactivos\99_procesos_bi\0_sapycweb\documentos\' as ruta,
        '99999999_modem_epic032_trxs_' || codunicocli || '.csv'          as nbrdocumento,
        codunicocli,
        sysdate                                                          as fecregistro,
        ' '                                                              as numcaso,
        0                                                                as idanalista
from epic032;

grant select on epic032_doc to rol_vistasdwhgstcum;

commit;
spool off

quit;