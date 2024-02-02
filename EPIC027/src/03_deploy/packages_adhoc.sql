--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

var intervalo_1 number
exec :intervalo_1 := to_number(&2);
var intervalo_2 number
exec :intervalo_2 := to_number(&3);
var intervalo_3 number
exec :intervalo_3 := to_number(&4);

select :intervalo_1, :intervalo_2, :intervalo_3 from dual;

--tabla de alertas
truncate table tmp_grm_alertas;
insert into tmp_grm_alertas
--create table tmp_grm_alertas tablespace d_aml_99 as
select distinct a.codmes,c.codunicocli,a.codclavecic, a.deuda_sf_sin_hip,a.ingreso_haberes,a.ratio_no_total_sf_hab,a.variacio_1m_total_deuda
from tmp_grm_universo_comercial a
inner join tmp_grm_salida_modelo b on a.codclavecic = b.codclavecic and a.codmes=b.codmes
left join ods_v.md_clienteg94 c on a.codclavecic = c.codclavecic
where b.outlier=-1 and b.codmes= (select max(codmes) from tmp_grm_universo_comercial);

--dolar
truncate table tmp_grm_tipocambio;
insert into tmp_grm_tipocambio
--create table tmp_grm_tipocambio tablespace d_aml_99 as
with tmp as (
select codmoneda,mtocambioalnuevosol,mtocambioaldolar,fectipcambio,
to_number(to_char(fectipcambio,'yyyymm')) numperiodo
from ods_v.hd_tipocambiosaldodiario
where codmoneda='0001' and
      fectipcambio between trunc(add_months(sysdate,:intervalo_1),'mm') and
      trunc(last_day(add_months(sysdate,:intervalo_2)))
      order by fectipcambio desc
      ),tmp2 as
      (
      select a.*,row_number() over (partition by a.numperiodo order by a.fectipcambio desc) as col
      from tmp a
      )
      select * from tmp2 where col=1;

--datos de la deuda
truncate table tmp_grm_trx_alertas_predata;
insert into tmp_grm_trx_alertas_predata
--create table tmp_grm_trx_alertas_predata tablespace d_aml_99 as
select b.* from
tmp_grm_alertas a inner join tmp_grm_universo_comercial b on a.codclavecic=b.codclavecic;

truncate table tmp_grm_trx_alertas_data;
insert into tmp_grm_trx_alertas_data
--create table tmp_grm_trx_alertas_data tablespace d_aml_99 as
select a.codmes,a.codclavecic, c.codunicocli , trim(c.apepatcli) || ' ' || trim(c.apematcli) || ' ' || trim(c.nbrcli) as nbrgremio,
descodpuesto as puesto ,
deuda_total_bcp*mtocambioaldolar as monto_deuda_bcp,
deuda_total_ibk*mtocambioaldolar monto_deuda_interbank,
deuda_total_scotia*mtocambioaldolar monto_deuda_scotiabank,
deuda_total_conti*mtocambioaldolar monto_deuda_bbva,
deuda_total_otros*mtocambioaldolar monto_deuda_otros,
ingreso_haberes*mtocambioaldolar haberes,
deuda_hipotecario_bcp*mtocambioaldolar as deuda_hipotecario_bcp,
deuda_vehicular_bcp*mtocambioaldolar as deuda_vehicular_bcp,
deuda_cef_bcp*mtocambioaldolar as deuda_cef_bcp,
deuda_tc_bcp*mtocambioaldolar as deuda_tarjetacredito_bcp
from tmp_grm_trx_alertas_predata a
left join ods_v.md_clienteg94 c on a.codclavecic = c.codclavecic
left join tmp_grm_tipocambio d on a.codmes=d.numperiodo;

--extraccion de los eecc
truncate table tmp_grm_codclavecics_alertas;
insert into tmp_grm_codclavecics_alertas
--create table tmp_grm_codclavecics_alertas tablespace d_aml_99 as
select distinct codclavecic as codclavecic from tmp_grm_alertas;

--listar eecc:
truncate table tmp_grm_inicial;
insert into tmp_grm_inicial
--create table tmp_grm_inicial tablespace d_aml_99 as
select a.codclavecic, codunicocli, tipper,
       case when tipper = 'E' then trim(apepatcli) || trim(apematcli) || trim(nbrcli)
            when tipper = 'P' then trim(apepatcli) || ' ' || trim(apematcli) || ' ' || trim(nbrcli)
       end as nombre
from ods_v.md_cliente a
inner join tmp_grm_codclavecics_alertas b on a.codclavecic = b.codclavecic
     and a.codclavecic not in (select codclavecic from ods_v.md_empleadog94)
union
select a.codclavecic, codunicocli, 'P', trim(apepatempleado) || ' ' || trim(apematempleado) || ' ' || trim(nbrempleado)
from ods_v.md_empleadog94 a
inner join tmp_grm_codclavecics_alertas b on a.codclavecic = b.codclavecic;

----create index idx_pagoalsant_eecc_codclavecic on tmp_grm_inicial (codclavecic) tablespace d_aml_99;
truncate table tmp_grm_ctas;
insert into tmp_grm_ctas
--create table tmp_grm_ctas tablespace d_aml_99 as
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
from ods_v.md_cuenta cta
     inner join tmp_grm_inicial b on cta.codclavecic = b.codclavecic
where cta.codsistemaorigen in ('SAV','IMP')
      and cta.codclaveopecta not in (select codclaveopecta from ods_v.md_cuentag94)
union
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
     inner join tmp_grm_inicial b on cta.codclavecic = b.codclavecic
where cta.codsistemaorigen in ('SAV','IMP');

----create index idx_pagoalsant_eecc_ctas on tmp_grm_ctas (codclaveopecta) tablespace d_aml_99;
truncate table tmp_grm_saving;
insert into tmp_grm_saving
--create table tmp_grm_saving tablespace d_aml_99 as
select b.codclavecic, b.codunicocli, b.nombre, a.codclaveopecta, b.codopecta, b.cuentacomercial, a.fecdia, a.hortransaccion, a.desopetransaccionsavingdetalle, f.grupo,
       c.descanal, d.nbrsucage, a.codmoneda, a.mtotransaccion, a.tipcargoabono, round(a.mtotransaccion * e.mtocambioaldolar, 2) as mtodolarizado
from ods_v.hd_movimientosaving a
     inner join tmp_grm_ctas b on a.codclaveopecta = b.codclaveopecta and b.codsistemaorigen = 'SAV'
     left join ods_v.md_descodigocanal c on a.codcanal = c.codcanal
     left join ods_v.md_agencia d on a.codsucage = d.codsucage
     left join ods_v.hd_tipocambiosaldodiario e on a.fecdia = e.fectipcambio and a.codmoneda = e.codmoneda
     left join s55632.rm_equival_tipope_eecc_tmp f on trim(a.desopetransaccionsavingdetalle) like (trim(f.glosa) || '%')
where a.fecdia between trunc(add_months(sysdate, :intervalo_3),'mm') and trunc(last_day(add_months(sysdate,:intervalo_2)));

truncate table tmp_grm_impac;
insert into tmp_grm_impac
--create table tmp_grm_impac tablespace d_aml_99 as
select b.codclavecic, b.codunicocli, b.nombre, a.codclaveopecta, b.codopecta, b.cuentacomercial, a.fecdia, a.hortransaccion, a.desopetransaccionimpacdetalle, f.grupo,
       c.descanal, d.nbrsucage, a.codmoneda, a.mtotransaccion, a.tipcargoabono, round(a.mtotransaccion * e.mtocambioaldolar, 2) as mtodolarizado
from ods_v.hd_movimientoimpac a
     inner join tmp_grm_ctas b on a.codclaveopecta = b.codclaveopecta and b.codsistemaorigen = 'IMP'
     left join ods_v.md_descodigocanal c on a.codcanal = c.codcanal
     left join ods_v.md_agencia d on a.codsucage = d.codsucage
     left join ods_v.hd_tipocambiosaldodiario e on a.fecdia = e.fectipcambio and a.codmoneda = e.codmoneda
     left join s55632.rm_equival_tipope_eecc_tmp f on trim(a.desopetransaccionimpacdetalle) like (trim(f.glosa) || '%')
where a.fecdia between trunc(add_months(sysdate, :intervalo_3),'mm') and trunc(last_day(add_months(sysdate,:intervalo_2)));

truncate table tmp_grm_eecc_alertas;
insert into tmp_grm_eecc_alertas
--create table tmp_grm_eecc_alertas tablespace d_aml_99 as
select * from tmp_grm_saving a
union all
select * from tmp_grm_impac;

commit;
quit;