--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

var intervalo_1 number
exec :intervalo_1 := to_number(&2);

select :intervalo_1 from dual;

--tabla epic020
--create table epic020  as
truncate table epic020;
insert into epic020
	select
			sysdate as fecgeneracion, 38 as idorigen,codunicocli,'EPIC020' as escenario,
			'EPIC020 - ESCENARIO DE EGRESOS PARA BANCAS CORP., EMPR. E INSTIT.' as desescenario,
			'ULTIMO MES' as periodo, round(mto_egresos, 2) as triggering,
			'La alerta correspondiente al periodo ' || to_char(trunc(add_months(sysdate, :intervalo_1),'mm'),'monyyyy') || ' es generada porque'||
			case
				when cluster_kmeans=6 then ' el '||pctje_ext||' del monto total de egresos '||mto_egresos||' es hacia el exterior. Adicionalmente la empresa tiene un representante legal, accionista o gerente de nacionalidad extranjera y sale de su perfil transaccional de egresis, es decir, excede a su promedio de egresos totales de los 6 meses anteriores '||media_dep||' mas 3 veces la desviacion estandar '||desv_dep||'.'
				when cluster_kmeans=8 then
							case
								when ctd_dias_debajolava02>0 and flg_perfil_3desvt=1 then ' en '||ctd_dias_debajolava02||' dias del mes se realizaron 3 operaciones por debajo del limite LAVA cada uno (). La empresa cuenta con un monto total de egresos  de '||mto_egresos||' y adicionalmente la empresa tiene un representante legal, accionista o gerente evaluado como ROS y sale de su perfil transaccional de egresos, es decir, excede a su promedio de egresos totales de los 6 meses anteriores '||media_dep||' mas 3 veces la desviacion estandar '||desv_dep||'.'
								when ctd_dias_debajolava02=0 and flg_perfil_3desvt=0 then ' la empresa cuenta con un monto total de egresos  de '||mto_egresos||' y adicionalmente la empresa tiene un representante legal, accionista o gerente evaluado como ROS.'
								when ctd_dias_debajolava02>0 and flg_perfil_3desvt=0 then ' en '||ctd_dias_debajolava02||' dias del mes se realizaron 3 operaciones por debajo del limite LAVA cada uno (). La empresa cuenta con un monto total de egresos  de '||mto_egresos||' y dicionalmente la empresa tiene un representante legal, accionista o gerente evaluado como ROS.'
								else ' la empresa cuenta con un monto total de egresos  de '||mto_egresos||' y adicionalmente la empresa tiene un representante legal, accionista o gerente evaluado como ROS y sale de su perfil transaccional de egresos, es decir, excede a su promedio de egresos totales de los 6 meses anteriores '||media_dep||' mas 3 veces la desviacion estandar '||desv_dep||'.'
							end
				else
					case
						when flg_perfil_3desvt=1 then ' la empresa tiene un representante legal, accionista o gerente de nacionalidad extranjera y tiene ROS. La empresa cuenta con un monto de egresos de '||mto_egresos||' que sale de su perfil transaccional de egresos, es decir, excede a su promedio de egresos totales de los 6 meses anteriores '||media_dep||' mas 3 veces la desviacion estandar '||desv_dep||'.'
						else ' la empresa tiene un representante legal, accionista o gerente de nacionalidad extranjera y tiene ROS, la empresa cuenta con un monto de egresos de '||mto_egresos||'.'
					end
			end  as comentario
	from tmp_egbcacei_alertas ;

grant select on epic020 to rol_vistasdwhgstcum;

--tabla epic020 - documentos
--create table epic020_doc  as
truncate table epic020_doc;
insert into epic020_doc
	select distinct
		  '\\Pfilep11\lavadoactivos\99_Procesos_BI\0_SapycWeb\PAQUETES_ADHOC\' as ruta,
		  '99999999_MODEM_EPIC020_TRXS_' || codunicocli || '.CSV' as nbrdocumento,
		  codunicocli,
		  sysdate as fecregistro,
		  ' ' as numcaso,
		  0 as idanalista
	from epic020
	union all
	select distinct
		  '\\Pfilep11\lavadoactivos\99_Procesos_BI\0_SapycWeb\PAQUETES_ADHOC\' as ruta,
		  '99999999_MODEM_EPIC020_EECC_' || codunicocli || '.CSV' as nbrdocumento,
		  codunicocli,
		  sysdate as fecregistro,
		  ' ' as numcaso,
		  0 as idanalista
	from epic020;

grant select on epic020_doc to rol_vistasdwhgstcum;

commit;
quit;