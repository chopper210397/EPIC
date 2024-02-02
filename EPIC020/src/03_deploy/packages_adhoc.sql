--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

truncate table tmp_egbcacei_alertasmodel;
insert into tmp_egbcacei_alertasmodel
--create table tmp_egbcacei_alertasmodel as
	select a.*,b.cluster_kmeans
	from tmp_egbcacei_cliemes_egretot10 a
		 inner join tmp_egbcacei_outputmodel b on a.codclavecic=b.codclavecic;

--create table tmp_egbcacei_cic_alertasmodel as
truncate table tmp_egbcacei_cic_alertasmodel;
insert into tmp_egbcacei_cic_alertasmodel
	select distinct codclavecic
	from tmp_egbcacei_alertasmodel;

--create table tmp_egbcacei_alertas as
truncate table tmp_egbcacei_alertas;
insert into tmp_egbcacei_alertas
  select distinct
         c.apepatcli  as apepatcli,
         c.apematcli  as apematcli,
         c.nbrcli  as nbrcli,
         c.codunicocli  as codunicocli,
         a.*
  from tmp_egbcacei_alertasmodel a
       left join ods_v.md_clienteg94 c on a.codclavecic=c.codclavecic;

--egbcacei
--create table tmp_egbcacei_cic_alertasmodel_ini as
truncate table tmp_egbcacei_cic_alertasmodel_ini;
insert into tmp_egbcacei_cic_alertasmodel_ini
	select a.codclavecic, codunicocli, tipper,
		   trim(apepatcli) || trim(apematcli) || trim(nbrcli) as nombre
	from ods_v.md_clienteg94 a
		inner join tmp_egbcacei_cic_alertasmodel b on a.codclavecic = b.codclavecic;

--create table tmp_egbcacei_ctas_alert as
truncate table tmp_egbcacei_ctas_alert;
insert into tmp_egbcacei_ctas_alert
	select cta.codclavecic, b.codunicocli, b.nombre, cta.codclaveopecta, codsistemaorigen, codopecta,
		   case when cta.codsistemaorigen = 'SAV' then
				substr(codopecta,1,3) || '-' ||
				trim(to_char(mod(to_number(substr(codopecta,5,16)),100000000), '00000009')) || '-' ||
				substr(codmoneda,1,1) || '-' ||
				trim(to_char(
				case when substr(codopecta,1,3) in ('191','192','193','194') then
					mod(to_number(substr(codopecta,13,2)) + to_number(substr(codopecta,15,2)) +
					to_number(substr(codopecta,17,2)) + to_number(substr(codopecta,19,2)), 100)
				else
					mod(-20 + to_number(substr(codopecta,1,1)) + to_number(substr(codopecta,2,2)) + to_number(substr(codopecta,13,2)) +
					to_number(substr(codopecta,15,2)) + to_number(substr(codopecta,17,2)) + to_number(substr(codopecta,19,2)), 100)
				end, '09'))
		   when cta.codsistemaorigen = 'IMP' then
				substr(codopecta,1,3) || '-' ||
				trim(to_char(mod(to_number(substr(codopecta,5,16)),10000000), '0000009')) || '-' ||
				substr(codmoneda,1,1) || '-' ||
				trim(to_char(
				case when substr(codopecta,1,3) in ('191','192','193','194') and codmoneda='0001' then
							mod(to_number(substr(codopecta,14,2)) + to_number(substr(codopecta,16,2)) +
							to_number(substr(codopecta,18,2)) + to_number(substr(codopecta,20,1))*10, 100)
						when substr(codopecta,1,3) in ('191','192','193','194') and codmoneda='1001' then
							mod(to_number(substr(codopecta,14,2)) + to_number(substr(codopecta,16,2)) +
							to_number(substr(codopecta,18,2)) + to_number(substr(codopecta,20,1))*10+10, 100)
						when substr(codopecta,1,3) not in ('191','192','193','194') and codmoneda='0001' then
							mod(to_number(substr(codopecta,1,1)) + to_number(substr(codopecta,2,2)) + to_number(substr(codopecta,14,2)) +
					  to_number(substr(codopecta,16,2)) + to_number(substr(codopecta,18,2)) + to_number(substr(codopecta,20,1))*10, 100)
						when substr(codopecta,1,3) not in ('191','192','193','194') and codmoneda='1001' then
							mod(10 + to_number(substr(codopecta,1,1)) + to_number(substr(codopecta,2,2)) + to_number(substr(codopecta,14,2)) +
					  to_number(substr(codopecta,16,2)) + to_number(substr(codopecta,18,2)) + to_number(substr(codopecta,20,1))*10, 100)
					   end, '09'))
			end as cuentacomercial
	from ods_v.md_cuentag94 cta
		 inner join tmp_egbcacei_cic_alertasmodel_ini b on cta.codclavecic = b.codclavecic
	where cta.codsistemaorigen in ('SAV','IMP');

truncate table tmp_egbcacei_sav_alertas_aux_01;
insert into tmp_egbcacei_sav_alertas
	select b.codclavecic, b.codunicocli, b.nombre, a.codclaveopecta, b.codopecta, b.cuentacomercial, a.fecdia, a.hortransaccion, a.desopetransaccionsavingdetalle, f.grupo,
		   c.descanal, d.nbrsucage, a.codmoneda, a.mtotransaccion, a.tipcargoabono, round(a.mtotransaccion * e.mtocambioaldolar, 2) as mtodolarizado
	from ods_v.hd_movimientosaving a
		 inner join tmp_egbcacei_ctas_alert b on a.codclaveopecta = b.codclaveopecta and b.codsistemaorigen = 'SAV'
		 left join ods_v.md_descodigocanal c on a.codcanal = c.codcanal
		 left join ods_v.md_agencia d on a.codsucage = d.codsucage
		 left join ods_v.hd_tipocambiosaldodiario e on a.fecdia = e.fectipcambio and a.codmoneda = e.codmoneda
		 left join s55632.tmp_equival_tipope_eecc f on trim(a.desopetransaccionsavingdetalle) like (trim(f.glosa) || '%')
	where a.fecdia between trunc(add_months(sysdate, -2),'mm') and trunc(last_day(add_months(sysdate,-1)));

create table tmp_egbcacei_sav_alertas_aux_02 as
	select b.codclavecic, b.codunicocli, b.nombre, a.codclaveopecta, b.codopecta, b.cuentacomercial, a.fecdia, a.hortransaccion, a.desopetransaccionsavingdetalle, f.grupo,
		   c.descanal, d.nbrsucage, a.codmoneda, a.mtotransaccion, a.tipcargoabono, round(a.mtotransaccion * e.mtocambioaldolar, 2) as mtodolarizado
	from ods_v.hd_movimientosaving a
		 inner join tmp_egbcacei_ctas_alert b on a.codclaveopecta = b.codclaveopecta and b.codsistemaorigen = 'SAV'
		 left join ods_v.md_descodigocanal c on a.codcanal = c.codcanal
		 left join ods_v.md_agencia d on a.codsucage = d.codsucage
		 left join ods_v.hd_tipocambiosaldodiario e on a.fecdia = e.fectipcambio and a.codmoneda = e.codmoneda
		 left join s55632.tmp_equival_tipope_eecc f on trim(a.desopetransaccionsavingdetalle) like (trim(f.glosa) || '%')
	where a.fecdia between trunc(add_months(sysdate, -4),'mm') and trunc(last_day(add_months(sysdate,-3)));

create table tmp_egbcacei_sav_alertas_aux_03 as
	select b.codclavecic, b.codunicocli, b.nombre, a.codclaveopecta, b.codopecta, b.cuentacomercial, a.fecdia, a.hortransaccion, a.desopetransaccionsavingdetalle, f.grupo,
		   c.descanal, d.nbrsucage, a.codmoneda, a.mtotransaccion, a.tipcargoabono, round(a.mtotransaccion * e.mtocambioaldolar, 2) as mtodolarizado
	from ods_v.hd_movimientosaving a
		 inner join tmp_egbcacei_ctas_alert b on a.codclaveopecta = b.codclaveopecta and b.codsistemaorigen = 'SAV'
		 left join ods_v.md_descodigocanal c on a.codcanal = c.codcanal
		 left join ods_v.md_agencia d on a.codsucage = d.codsucage
		 left join ods_v.hd_tipocambiosaldodiario e on a.fecdia = e.fectipcambio and a.codmoneda = e.codmoneda
		 left join s55632.tmp_equival_tipope_eecc f on trim(a.desopetransaccionsavingdetalle) like (trim(f.glosa) || '%')
	where a.fecdia between trunc(add_months(sysdate, -6),'mm') and trunc(last_day(add_months(sysdate,-5)));

--create table tmp_egbcacei_sav_alertas as
truncate table tmp_egbcacei_sav_alertas;
insert into tmp_egbcacei_sav_alertas
select * from tmp_egbcacei_sav_alertas_aux_01
union all
select * from tmp_egbcacei_sav_alertas_aux_02
union all
select * from tmp_egbcacei_sav_alertas_aux_03;

drop table tmp_egbcacei_sav_alertas_aux_01;
drop table tmp_egbcacei_sav_alertas_aux_02;
drop table tmp_egbcacei_sav_alertas_aux_03;


create table tmp_egbcacei_imp_alertas_aux_01 as
	select b.codclavecic, b.codunicocli, b.nombre, a.codclaveopecta, b.codopecta, b.cuentacomercial, a.fecdia, a.hortransaccion, a.desopetransaccionimpacdetalle, f.grupo,
		   c.descanal, d.nbrsucage, a.codmoneda, a.mtotransaccion, a.tipcargoabono, round(a.mtotransaccion * e.mtocambioaldolar, 2) as mtodolarizado
	from ods_v.hd_movimientoimpac a
		 inner join tmp_egbcacei_ctas_alert b on a.codclaveopecta = b.codclaveopecta and b.codsistemaorigen = 'IMP'
		 left join ods_v.md_descodigocanal c on a.codcanal = c.codcanal
		 left join ods_v.md_agencia d on a.codsucage = d.codsucage
		 left join ods_v.hd_tipocambiosaldodiario e on a.fecdia = e.fectipcambio and a.codmoneda = e.codmoneda
		 left join s55632.tmp_equival_tipope_eecc f on trim(a.desopetransaccionimpacdetalle) like (trim(f.glosa) || '%')
	where a.fecdia between trunc(add_months(sysdate, -2),'mm') and trunc(last_day(add_months(sysdate, -1)));

create table tmp_egbcacei_imp_alertas_aux_02 as
	select b.codclavecic, b.codunicocli, b.nombre, a.codclaveopecta, b.codopecta, b.cuentacomercial, a.fecdia, a.hortransaccion, a.desopetransaccionimpacdetalle, f.grupo,
		   c.descanal, d.nbrsucage, a.codmoneda, a.mtotransaccion, a.tipcargoabono, round(a.mtotransaccion * e.mtocambioaldolar, 2) as mtodolarizado
	from ods_v.hd_movimientoimpac a
		 inner join tmp_egbcacei_ctas_alert b on a.codclaveopecta = b.codclaveopecta and b.codsistemaorigen = 'IMP'
		 left join ods_v.md_descodigocanal c on a.codcanal = c.codcanal
		 left join ods_v.md_agencia d on a.codsucage = d.codsucage
		 left join ods_v.hd_tipocambiosaldodiario e on a.fecdia = e.fectipcambio and a.codmoneda = e.codmoneda
		 left join s55632.tmp_equival_tipope_eecc f on trim(a.desopetransaccionimpacdetalle) like (trim(f.glosa) || '%')
	where a.fecdia between trunc(add_months(sysdate, -2),'mm') and trunc(last_day(add_months(sysdate, -1)));

create table tmp_egbcacei_imp_alertas_aux_03 as
	select b.codclavecic, b.codunicocli, b.nombre, a.codclaveopecta, b.codopecta, b.cuentacomercial, a.fecdia, a.hortransaccion, a.desopetransaccionimpacdetalle, f.grupo,
		   c.descanal, d.nbrsucage, a.codmoneda, a.mtotransaccion, a.tipcargoabono, round(a.mtotransaccion * e.mtocambioaldolar, 2) as mtodolarizado
	from ods_v.hd_movimientoimpac a
		 inner join tmp_egbcacei_ctas_alert b on a.codclaveopecta = b.codclaveopecta and b.codsistemaorigen = 'IMP'
		 left join ods_v.md_descodigocanal c on a.codcanal = c.codcanal
		 left join ods_v.md_agencia d on a.codsucage = d.codsucage
		 left join ods_v.hd_tipocambiosaldodiario e on a.fecdia = e.fectipcambio and a.codmoneda = e.codmoneda
		 left join s55632.tmp_equival_tipope_eecc f on trim(a.desopetransaccionimpacdetalle) like (trim(f.glosa) || '%')
	where a.fecdia between trunc(add_months(sysdate, -2),'mm') and trunc(last_day(add_months(sysdate, -1)));

--create table tmp_egbcacei_imp_alertas as
truncate table tmp_egbcacei_imp_alertas;
insert into tmp_egbcacei_imp_alertas
select * from tmp_egbcacei_imp_alertas_aux_01
union all
select * from tmp_egbcacei_imp_alertas_aux_02
union all
select * from tmp_egbcacei_imp_alertas_aux_03;

drop table tmp_egbcacei_imp_alertas_aux_01;
drop table tmp_egbcacei_imp_alertas_aux_02;
drop table tmp_egbcacei_imp_alertas_aux_03;

--create table tmp_egbcacei_eecc_alertas as
truncate table tmp_egbcacei_eecc_alertas;
insert into tmp_egbcacei_eecc_alertas
	select * from tmp_egbcacei_sav_alertas a
	union all
	select * from tmp_egbcacei_imp_alertas;

--transacciones
--create table tmp_egbcacei_trx_egresosclie  as
truncate table tmp_egbcacei_trx_egresosclie;
insert into tmp_egbcacei_trx_egresosclie
  with tmp as
  (
      select distinct
               c.apepatcli as apepatcli_ben,
               c.apematcli as apematcli_ben,
               c.nbrcli as nbrcli_ben,
               c.codunicocli as codunicocli_ben,
               a.*
      from   tmp_egbcacei_trx a
           left join ods_v.md_clienteg94 c on a.codclavecic_ben=c.codclavecic
      where  a.codclavecic_ben in (select * from tmp_egbcacei_cic_alertasmodel)
  )
  select distinct
          coalesce (b.codunicocli,c.codunicocli ) as codunicocli_sol,
          coalesce (b.apepatcli,c.apepatcli ) as apepatcli_sol,
          coalesce (b.apematcli,c.apematcli ) as apematcli_sol,
          coalesce (b.nbrcli,c.nbrcli ) as nbrcli_sol,a.codclavecic_sol,a.codopecta_sol,
          a.codunicocli_ben,a.apepatcli_ben,a.apematcli_ben,a.nbrcli_ben,a.codclavecic_ben,a.codopecta_ben,
          a.fecdia,a.hortransaccion,a.codmoneda,a.mtotransaccion,a.mto_dolarizado,a.tipo_transaccion,a.canal
  from tmp a
       left join ods_v.md_cliente b on a.codclavecic_sol=b.codclavecic
       left join ods_v.md_clienteg94 c on a.codclavecic_ben=c.codclavecic;

commit;
quit;