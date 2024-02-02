--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

var intervalo_1 number
exec :intervalo_1 := to_number(&2);
var intervalo_2 number
exec :intervalo_2 := to_number(&3);

select :intervalo_1, :intervalo_2 from dual;


--tabla de fechas de aperturas de productos de todos los clientes
truncate table tmp_clinuevo_antg_fecapertura;
insert into tmp_clinuevo_antg_fecapertura
--create table tmp_clinuevo_antg_fecapertura tablespace d_aml_99 as
   select distinct codclavecic,fecapertura from ods_v.md_prestamo
   union all
   select distinct codclavecic,fecapertura from ods_v.md_impac
   union all
   select distinct codclavecic,fecapertura from ods_v.md_saving
   union all
   select distinct codclavecic,fecapertura from ods_v.md_cuentavp;

--tabla con las fechas de apetura de productos mas antiguos por cliente
truncate table tmp_clinuevo_antg_fecapertura_min;
insert into tmp_clinuevo_antg_fecapertura_min
--create table tmp_clinuevo_antg_fecapertura_min tablespace d_aml_99 as
   select to_number(to_char(trunc(add_months(sysdate,:intervalo_1),'mm'),'yyyymm')) as periodo, codclavecic, min(fecapertura) as minfecapertura
   from tmp_clinuevo_antg_fecapertura
   group by codclavecic
   having min(fecapertura) < trunc(add_months(sysdate,:intervalo_2),'mm');

--universo
truncate table tmp_clinuevo_universo_cli;
insert into tmp_clinuevo_universo_cli
--create table tmp_clinuevo_universo_cli tablespace d_aml_99 as
select b.periodo,b.codclavecic, b.minfecapertura, floor(months_between(last_day(to_date(to_char(b.periodo||'01'),'yyyymmdd')) , b.minfecapertura)) as antiguedadcli
from
	tmp_clinuevo_antg_fecapertura_min b
	inner join ods_v.md_cliente c on b.codclavecic = c.codclavecic
where
	c.tipper = 'P' and
	b.minfecapertura < trunc(add_months(sysdate,:intervalo_2),'mm') and
	months_between(last_day(to_date(to_char(b.periodo||'01'),'yyyymmdd')), b.minfecapertura) < 12;

commit;
quit;