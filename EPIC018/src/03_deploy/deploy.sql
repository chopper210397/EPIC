--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

--tabla epic018
truncate table epic018;
insert into epic018
--create table epic018 tablespace d_aml_99 as
	select
		  sysdate as fecgeneracion, 38 as idorigen, codunicocli, 'EPIC018' as escenario,
		  'EPIC018 - ESCENARIO DE INGRESOS CASH' AS desescenario,
			'ULTIMO MES' as periodo, round(mto_ingreso,2) as triggering,
			'LA ALERTA PERTENECE AL MES DE ' ||numperiodo || ' Y ES GENERADA PORQUE EL CLIENTE RECIBIÓ $/ '||mto_ingreso||' DE INGRESOS CASH PROVENIENTE DE '||num_ingreso||
			' OPERACIONES Y QUE REPRESENTA EL '||ROUND(por_cash,2)||'% DEL TOTAL DE INGRESOS EN EL MES .'||'$'||mto_ctas_recientes||
			' FUERON RECIBIDAS EN CUENTAS RECIENTES (ANTIGUEDAD MENOR A 12 MESES). ADICIONALMENTE EL CLIENTE '||case when flg_act_eco=1  then 'SI ' else 'NO ' end
			||'PERTENECE A UNA ACTIVIDAD ECONOMICA DE RIESGO.'||'EL CLIENTE '||case when ctd_dias_debajolava02>0  then 'SI ' else 'NO ' end ||'HA REALIZADO MAS DE 3 OPERACIONES DIARIAS POR DEBAJO DE LAVA DURANTE '
			||ctd_dias_debajolava02||' DÍA(S) EN EL ÚLTIMO MES.POR ULTIMO EL CLIENTE '
			||case when flg_perfil=1  then 'SI ' else 'NO ' end ||'SALE DE SU PERFIL TRANSACCIONAL DE INGRESOS COMPARADO CON LOS 06 ÚLTIMOS MESES PREVIOS Y '||
			case when flg_an_lsb_np=1  then 'SI ' else 'NO ' end ||'FUE REPORTADO POR AN/LSB O NP.'
 as comentario
	from tmp_ingcashbcacei_alertas ;

grant select on epic018 to rol_vistasdwhgstcum;

--tabla epic018 - documentos
truncate table epic018_doc;
insert into epic018_doc
--create table epic018_doc tablespace d_aml_99  as
	select distinct
		  '\\Pfilep11\lavadoactivos\99_Procesos_BI\0_SapycWeb\PAQUETES_ADHOC\' as ruta,
		  '99999999_MODEM_EPIC018_TRXS_' || codunicocli || '.CSV' as nbrdocumento,
		  codunicocli,
		  sysdate as fecregistro,
		  ' ' as numcaso,
		  0 as idanalista
	from epic018
	union all
	select distinct
		  '\\Pfilep11\lavadoactivos\99_Procesos_BI\0_SapycWeb\PAQUETES_ADHOC\' as ruta,
		  '99999999_MODEM_EPIC018_EECC_' || codunicocli || '.CSV' as nbrdocumento,
		  codunicocli,
		  sysdate as fecregistro,
		  ' ' as numcaso,
		  0 as idanalista
	from epic018;

grant select on epic018_doc to rol_vistasdwhgstcum;

commit;
quit;