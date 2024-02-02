--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

--tabla epic026
truncate table epic026;
insert into epic026
--create table epic026 tablespace d_aml_99 as
select
    sysdate as fecgeneracion, 38 as idorigen, codunicocli, 'EPIC026' as escenario,
    'EPIC026 - ESCENARIO HOMEBANKING' as desescenario, 'ULTIMO MES' as periodo,
    round(mtodolarizado,2) as triggering,
	'LA ALERTA CORRESPONDE AL PERIODO ' || periodo || ' LA ALERTA SE GENERA DADO QUE EL CLIENTE ' ||nbr_ordenante||' CON CODUNICOCLI ' || codunicocli|| ' HA REALIZADO EGRESOS POR UN MONTO ACUMULADO DE $ ' || mtodolarizado || ' EN EL CANAL HBK EN  ' || ctd_oper || ' OPERACIONES, '
	 ||' DICHAS OPERACIONES LAS REALIZÓ EN ' || ctd_dias || ' DÍA(S) DEL MES, BENEFICIANDO A ' || ctd_beneficiario ||' PERSONA(S) .EL MONTO ACUMULADO DE EGRESOS POR ESTE CANAL EN EL MES ANTERIOR FUE DE $ '||
	round(mtodolarizado_ant,2)|| ' Y '|| 'EL CLIENTE REGISTRA TRANSFERENCIAS AL EXTERIOR A PAÍSES DE ALTO RIESGO POR UN TOTAL EN EL MES DE $ '|| paisriesgo_monto||'. ADEMÁS, EL CLIENTE CON PROFESIÓN '
	||trim(descodprofesion)|| ' ,'|| case when flg_perfil_3ds=1 then 'SI' else 'NO' end ||' SALE EN ESTE ÚLTIMO MES, FUERA DE SU PERFIL TRANSACCIONAL COMPARADO CON LOS ÚLTIMOS 06 MESES, '||case when flgarchivonegativo=1 then 'SI' else 'NO' end || ' ESTÁ REGISTRADO EN ARCHIVO NEGATIVO, '
	|| case when flglsb=1 then 'SI' else 'NO' end || ' PRESENTA LSB, ' || case when flgnp=1 then 'SI' else 'NO' end || ' PRESENTA NOTICIAS PERIODISTICAS' ||
	case when ctdeval > 0 then ' Y EL CLIENTE CUENTA CON ' || ctdeval || ' EVALUACIONES PLAFT PREVIAS.'   else '.' end
  as comentario
from epic026_pre;

grant select on epic026 to rol_vistasdwhgstcum;

--tabla epic026 - documentos
truncate table epic026_doc;
insert into epic026_doc
--create table epic026_doc tablespace d_aml_99 as
select distinct
      '\\Pfilep11\lavadoactivos\99_Procesos_BI\0_SapycWeb\PAQUETES_ADHOC\' as ruta,
      '99999999_MODEM_EPIC026_TRXS_' || codunicocli || '.CSV' as nbrdocumento,
      codunicocli,
      sysdate as fecregistro,
      ' ' as numcaso,
      0 as idanalista
from epic026
union all
select distinct
      '\\Pfilep11\lavadoactivos\99_Procesos_BI\0_SapycWeb\PAQUETES_ADHOC\' AS RUTA,
      '99999999_MODEM_EPIC026_EECC_' || codunicocli || '.CSV' as nbrdocumento,
      codunicocli,
      sysdate as fecregistro,
      ' ' as numcaso,
      0 as idanalista
from epic026;

grant select on epic026_doc to rol_vistasdwhgstcum;

commit;
quit;