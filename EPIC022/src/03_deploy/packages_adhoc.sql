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

--drop table tmp_clinuevo_alertas;
truncate table tmp_clinuevo_alertas;
insert into tmp_clinuevo_alertas
--create table tmp_clinuevo_alertas tablespace d_aml_99 as
select * from tmp_clinuevo_salida_modelo where outlier = -1;


truncate table tmp_clinuevo_alertas_1 ;
insert into tmp_clinuevo_alertas_1
--create table tmp_clinuevo_alertas_1 tablespace d_aml_99 as
select b.codunicocli,a.codclavecic, a.periodo from tmp_clinuevo_alertas a
left join ods_v.md_clienteg94 b on a.codclavecic=b.codclavecic;

--extraccion de transacciones
--drop table tmp_clinuevo_trxs_alertas_aux;
truncate table tmp_clinuevo_trxs_alertas_aux;
insert into tmp_clinuevo_trxs_alertas_aux
--create table tmp_clinuevo_trxs_alertas_aux tablespace d_aml_99 as
select a.* from tmp_clinuevo_trx a inner join  tmp_clinuevo_alertas b on a.codclaveciccli = b.codclavecic ;

--drop table tmp_clinuevo_trxs_alertas_aux2;
truncate table tmp_clinuevo_trxs_alertas_aux2;
insert into tmp_clinuevo_trxs_alertas_aux2
--create table tmp_clinuevo_trxs_alertas_aux2 tablespace d_aml_99 as
select distinct
a.periodo,a.idtrx,a.numregistro,a.codsucage,a.codclavecicint,a.codclaveopectaint,
b.apepatcliordenante||b.apematcliordenante||b.nbrcliordenante as datoadicionalint,a.codpaisorigen,
a.fecdia,a.hortransaccion,a.codmoneda,a.mtotransaccion,a.mtodolarizado,a.codtransaccion,a.tipotransaccion,a.canal,a.codclaveciccli,a.codclaveopectacli,
b.nbrclibeneficiario as datocli, '' as codpaisdestinocli,
a.flgcash,a.coddepartamento,a.descoddepartamento,a.tipo_zona
from tmp_clinuevo_trxs_alertas_aux a
left join ods_v.hd_documentoemitidoggtt b on a.numregistro = b.coddocggtt
where a.canal = 'DOCUMENTOGGTT'
union all
select distinct
a.periodo,a.idtrx,a.numregistro,a.codsucage,a.codclavecicint,a.codclaveopectaint,
b.nbrclisolicitante as datoadicionalint,a.codpaisorigen,
a.fecdia,a.hortransaccion,a.codmoneda,a.mtotransaccion,a.mtodolarizado,a.codtransaccion,a.tipotransaccion,a.canal,a.codclaveciccli,a.codclaveopectacli,
'' as datocli, '' as codpaisdestinocli,
a.flgcash,a.coddepartamento,a.descoddepartamento,a.tipo_zona
from tmp_clinuevo_trxs_alertas_aux a
left join ods_v.hd_movoperativoremittance b on a.numregistro = b.numoperacionremittance and a.fecdia = b.fecdia and a.hortransaccion = b.hortransaccion
where a.canal = 'REMITTANCE'
union all
select distinct
a.periodo,a.idtrx,a.numregistro,a.codsucage,a.codclavecicint,a.codclaveopectaint,
b.nbrcliordenante as datoadicionalint,b.codctainterbanordenante as codpaisorigen,
a.fecdia,a.hortransaccion,a.codmoneda,a.mtotransaccion,a.mtodolarizado,a.codtransaccion,a.tipotransaccion,a.canal,a.codclaveciccli,a.codclaveopectacli,
b.nbrclibeneficiario as datotarget,b.codctainterbanbeneficiario as codpaisdestinocli,
a.flgcash,a.coddepartamento,a.descoddepartamento,a.tipo_zona
from tmp_clinuevo_trxs_alertas_aux a
left join ods_v.hd_movimientottib b on a.numregistro = b.numsecuencial and a.fecdia = b.fectransaccion and a.hortransaccion = b.hortransaccion
where a.canal = 'TTIB'
union all
select
a.periodo,a.idtrx,a.numregistro,a.codsucage,a.codclavecicint,a.codclaveopectaint,
a.datoadicionalint,a.codpaisorigen,
a.fecdia,a.hortransaccion,a.codmoneda,a.mtotransaccion,a.mtodolarizado,a.codtransaccion,a.tipotransaccion,a.canal,a.codclaveciccli,a.codclaveopectacli,
'' as datocli,'' as codpaisdestinocli,
a.flgcash,a.coddepartamento,a.descoddepartamento,a.tipo_zona
from tmp_clinuevo_trxs_alertas_aux a
where a.canal not in ('TTIB','REMITTANCE','DOCUMENTOGGTT');

--drop table tmp_clinuevo_trxs_alertas_infoclis;
truncate table tmp_clinuevo_trxs_alertas_infoclis;
insert into tmp_clinuevo_trxs_alertas_infoclis
--create table tmp_clinuevo_trxs_alertas_infoclis tablespace d_aml_99 as
select
a.codclavecic,
b.codunicocli ,
trim(b.apepatcli)||' '||trim(b.apematcli)||' '||trim(b.nbrcli) as nbrcli
from (
  select codclavecicint as codclavecic from tmp_clinuevo_trxs_alertas_aux
  union
  select codclaveciccli as codclavecic from tmp_clinuevo_trxs_alertas_aux
) a
left join (select * from ods_v.md_clienteg94 ) b on a.codclavecic = b.codclavecic
where a.codclavecic <> -1;


--drop table tmp_clinuevo_trxs_alertas_infocuentas;
truncate table tmp_clinuevo_trxs_alertas_infocuentas;
insert into tmp_clinuevo_trxs_alertas_infocuentas
--create table tmp_clinuevo_trxs_alertas_infocuentas tablespace d_aml_99 as
select distinct
a.codclaveopecta,
b.codopecta
from (
  select codclaveopectaint as codclaveopecta from tmp_clinuevo_trxs_alertas_aux
  union
  select codclaveopectacli as codclaveopecta from tmp_clinuevo_trxs_alertas_aux
) a
left join (select * from ods_v.md_cuentag94) b on a.codclaveopecta = b.codclaveopecta;

--drop table tmp_clinuevo_trxs_alertas;
truncate table tmp_clinuevo_trxs_alertas;
insert into tmp_clinuevo_trxs_alertas
--create table tmp_clinuevo_trxs_alertas tablespace d_aml_99 as
select a.periodo,a.idtrx,a.numregistro,a.codsucage,
case when a.codclavecicint = -1 then null else a.codclavecicint end as codclavecicorigen,g1.codunicocli as codunicocliorigen,g1.nbrcli as nbrcliorigen,
case when a.codclaveopectaint = -1 then null else a.codclaveopectaint end as codclaveopectaorigen,c1.codopecta as codopectaorigen,
a.datoadicionalint as datoorigen1_nbrcli,a.codpaisorigen as datoorigen2_pais_ctacci,
a.fecdia,a.hortransaccion,a.codmoneda,a.mtotransaccion,a.mtodolarizado,a.codtransaccion,a.tipotransaccion,a.canal,a.codclaveciccli,a.codclaveopectacli,
case when a.codclaveciccli = -1 then null else a.codclaveciccli end as codclavecicdestino,g2.codunicocli as codunicoclidestino,g2.nbrcli as nbrclidestino,
case when a.codclaveopectacli = -1 then null else a.codclaveopectacli end as codclaveopectadestino,c2.codopecta as codopectadestino,
a.datocli as datodestino1_nbrcli,a.codpaisdestinocli as datodestino2_pais_ctacci,
a.flgcash,a.coddepartamento,a.descoddepartamento,a.tipo_zona
from tmp_clinuevo_trxs_alertas_aux2 a
left join tmp_clinuevo_trxs_alertas_infoclis g1 on a.codclavecicint = g1.codclavecic
left join tmp_clinuevo_trxs_alertas_infoclis g2 on a.codclaveciccli = g2.codclavecic
left join tmp_clinuevo_trxs_alertas_infocuentas c1 on a.codclaveopectaint = c1.codclaveopecta
left join tmp_clinuevo_trxs_alertas_infocuentas c2 on a.codclaveopectacli = c2.codclaveopecta;

--extraccion de los eecc
--estado de cuenta
--drop table tmp_clinuevo_codclavecics_alertas;
truncate table tmp_clinuevo_codclavecics_alertas;
insert into tmp_clinuevo_codclavecics_alertas
--create table tmp_clinuevo_codclavecics_alertas tablespace d_aml_99 as
select distinct codclavecic as codclavecic from tmp_clinuevo_alertas;

--listar eecc:
--drop table tmp_clinuevo_inicial;
truncate table tmp_clinuevo_inicial;
insert into tmp_clinuevo_inicial
--create table tmp_clinuevo_inicial tablespace d_aml_99 as
select a.codclavecic, codunicocli, tipper,
       case when tipper = 'E' then trim(apepatcli) || trim(apematcli) || trim(nbrcli)
            when tipper = 'P' then trim(apepatcli) || ' ' || trim(apematcli) || ' ' || trim(nbrcli)
       end as nombre
from ods_v.md_cliente a
inner join tmp_clinuevo_codclavecics_alertas b on a.codclavecic = b.codclavecic
     and a.codclavecic not in (select codclavecic from ods_v.md_empleadog94)
union
select a.codclavecic, codunicocli, 'P', trim(apepatempleado) || ' ' || trim(apematempleado) || ' ' || trim(nbrempleado)
from ods_v.md_empleadog94 a
inner join tmp_clinuevo_codclavecics_alertas b on a.codclavecic = b.codclavecic;

----create index idx_pagoalsant_eecc_codclavecic on tmp_clinuevo_inicial (codclavecic) tablespace d_aml_99;
--drop table tmp_clinuevo_ctas;
truncate table tmp_clinuevo_ctas;
insert into tmp_clinuevo_ctas
--create table tmp_clinuevo_ctas tablespace d_aml_99 as
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
     inner join tmp_clinuevo_inicial b on cta.codclavecic = b.codclavecic
where cta.codsistemaorigen in ('SAV','IMP');

--drop table tmp_clinuevo_saving;
truncate table tmp_clinuevo_saving;
insert into tmp_clinuevo_saving
--create table tmp_clinuevo_saving tablespace d_aml_99 as
select b.codclavecic, b.codunicocli, b.nombre, a.codclaveopecta, b.codopecta, b.cuentacomercial, a.fecdia, a.hortransaccion, a.desopetransaccionsavingdetalle, f.grupo,
       c.descanal, d.nbrsucage, a.codmoneda, a.mtotransaccion, a.tipcargoabono, round(a.mtotransaccion * e.mtocambioaldolar, 2) as mtodolarizado
from ods_v.hd_movimientosaving a
     inner join tmp_clinuevo_ctas b on a.codclaveopecta = b.codclaveopecta and b.codsistemaorigen = 'SAV'
     left join ods_v.md_descodigocanal c on a.codcanal = c.codcanal
     left join ods_v.md_agencia d on a.codsucage = d.codsucage
     left join ods_v.hd_tipocambiosaldodiario e on a.fecdia = e.fectipcambio and a.codmoneda = e.codmoneda
     left join s55632.rm_equival_tipope_eecc_tmp f on trim(a.desopetransaccionsavingdetalle) like (trim(f.glosa) || '%')
where a.fecdia between trunc(add_months(sysdate, :intervalo_1),'mm') and trunc(last_day(add_months(sysdate, :intervalo_2)));


CREATE table tmp_clinuevo_saving_AUX_01 tablespace d_aml_99 as
select b.codclavecic, b.codunicocli, b.nombre, a.codclaveopecta, b.codopecta, b.cuentacomercial, a.fecdia, a.hortransaccion, a.desopetransaccionsavingdetalle, f.grupo,
       c.descanal, d.nbrsucage, a.codmoneda, a.mtotransaccion, a.tipcargoabono, round(a.mtotransaccion * e.mtocambioaldolar, 2) as mtodolarizado
from ods_v.hd_movimientosaving a
     inner join tmp_clinuevo_ctas b on a.codclaveopecta = b.codclaveopecta and b.codsistemaorigen = 'SAV'
     left join ods_v.md_descodigocanal c on a.codcanal = c.codcanal
     left join ods_v.md_agencia d on a.codsucage = d.codsucage
     left join ods_v.hd_tipocambiosaldodiario e on a.fecdia = e.fectipcambio and a.codmoneda = e.codmoneda
     left join s55632.rm_equival_tipope_eecc_tmp f on trim(a.desopetransaccionsavingdetalle) like (trim(f.glosa) || '%')
where a.fecdia between trunc(add_months(sysdate, -2),'mm') and trunc(last_day(add_months(sysdate, -1)));

CREATE table tmp_clinuevo_saving_AUX_02 tablespace d_aml_99 as
select b.codclavecic, b.codunicocli, b.nombre, a.codclaveopecta, b.codopecta, b.cuentacomercial, a.fecdia, a.hortransaccion, a.desopetransaccionsavingdetalle, f.grupo,
       c.descanal, d.nbrsucage, a.codmoneda, a.mtotransaccion, a.tipcargoabono, round(a.mtotransaccion * e.mtocambioaldolar, 2) as mtodolarizado
from ods_v.hd_movimientosaving a
     inner join tmp_clinuevo_ctas b on a.codclaveopecta = b.codclaveopecta and b.codsistemaorigen = 'SAV'
     left join ods_v.md_descodigocanal c on a.codcanal = c.codcanal
     left join ods_v.md_agencia d on a.codsucage = d.codsucage
     left join ods_v.hd_tipocambiosaldodiario e on a.fecdia = e.fectipcambio and a.codmoneda = e.codmoneda
     left join s55632.rm_equival_tipope_eecc_tmp f on trim(a.desopetransaccionsavingdetalle) like (trim(f.glosa) || '%')
where a.fecdia between trunc(add_months(sysdate, -4),'mm') and trunc(last_day(add_months(sysdate, -3)));

CREATE table tmp_clinuevo_saving_AUX_03 tablespace d_aml_99 as
select b.codclavecic, b.codunicocli, b.nombre, a.codclaveopecta, b.codopecta, b.cuentacomercial, a.fecdia, a.hortransaccion, a.desopetransaccionsavingdetalle, f.grupo,
       c.descanal, d.nbrsucage, a.codmoneda, a.mtotransaccion, a.tipcargoabono, round(a.mtotransaccion * e.mtocambioaldolar, 2) as mtodolarizado
from ods_v.hd_movimientosaving a
     inner join tmp_clinuevo_ctas b on a.codclaveopecta = b.codclaveopecta and b.codsistemaorigen = 'SAV'
     left join ods_v.md_descodigocanal c on a.codcanal = c.codcanal
     left join ods_v.md_agencia d on a.codsucage = d.codsucage
     left join ods_v.hd_tipocambiosaldodiario e on a.fecdia = e.fectipcambio and a.codmoneda = e.codmoneda
     left join s55632.rm_equival_tipope_eecc_tmp f on trim(a.desopetransaccionsavingdetalle) like (trim(f.glosa) || '%')
where a.fecdia between trunc(add_months(sysdate, -6),'mm') and trunc(last_day(add_months(sysdate, -5)));

CREATE table tmp_clinuevo_saving_AUX_04 tablespace d_aml_99 as
select b.codclavecic, b.codunicocli, b.nombre, a.codclaveopecta, b.codopecta, b.cuentacomercial, a.fecdia, a.hortransaccion, a.desopetransaccionsavingdetalle, f.grupo,
       c.descanal, d.nbrsucage, a.codmoneda, a.mtotransaccion, a.tipcargoabono, round(a.mtotransaccion * e.mtocambioaldolar, 2) as mtodolarizado
from ods_v.hd_movimientosaving a
     inner join tmp_clinuevo_ctas b on a.codclaveopecta = b.codclaveopecta and b.codsistemaorigen = 'SAV'
     left join ods_v.md_descodigocanal c on a.codcanal = c.codcanal
     left join ods_v.md_agencia d on a.codsucage = d.codsucage
     left join ods_v.hd_tipocambiosaldodiario e on a.fecdia = e.fectipcambio and a.codmoneda = e.codmoneda
     left join s55632.rm_equival_tipope_eecc_tmp f on trim(a.desopetransaccionsavingdetalle) like (trim(f.glosa) || '%')
where a.fecdia between trunc(add_months(sysdate, -7),'mm') and trunc(last_day(add_months(sysdate, -7)));

TRUNCATE table tmp_clinuevo_saving;
INSERT into tmp_clinuevo_saving
--CREATE table tmp_clinuevo_saving tablespace d_aml_99 as
select * from tmp_clinuevo_saving_AUX_01
union all
select * from tmp_clinuevo_saving_AUX_02
union all
select * from tmp_clinuevo_saving_AUX_03
union all
select * from tmp_clinuevo_saving_AUX_04;
commit;

drop table tmp_clinuevo_saving_AUX_01;
drop table tmp_clinuevo_saving_AUX_02;
drop table tmp_clinuevo_saving_AUX_03;
drop table tmp_clinuevo_saving_AUX_04;
commit;

--drop table tmp_clinuevo_impac;
truncate table tmp_clinuevo_impac;
insert into tmp_clinuevo_impac
--create table tmp_clinuevo_impac tablespace d_aml_99 as
select b.codclavecic, b.codunicocli, b.nombre, a.codclaveopecta, b.codopecta, b.cuentacomercial, a.fecdia, a.hortransaccion, a.desopetransaccionimpacdetalle, f.grupo,
       c.descanal, d.nbrsucage, a.codmoneda, a.mtotransaccion, a.tipcargoabono, round(a.mtotransaccion * e.mtocambioaldolar, 2) as mtodolarizado
from ods_v.hd_movimientoimpac a
     inner join tmp_clinuevo_ctas b on a.codclaveopecta = b.codclaveopecta and b.codsistemaorigen = 'IMP'
     left join ods_v.md_descodigocanal c on a.codcanal = c.codcanal
     left join ods_v.md_agencia d on a.codsucage = d.codsucage
     left join ods_v.hd_tipocambiosaldodiario e on a.fecdia = e.fectipcambio and a.codmoneda = e.codmoneda
     left join s55632.rm_equival_tipope_eecc_tmp f on trim(a.desopetransaccionimpacdetalle) like (trim(f.glosa) || '%')
where a.fecdia between trunc(add_months(sysdate, :intervalo_1),'mm') and trunc(last_day(add_months(sysdate, :intervalo_2)));

--drop table tmp_clinuevo_eecc_alertas;
truncate table tmp_clinuevo_eecc_alertas;
insert into tmp_clinuevo_eecc_alertas
--create table tmp_clinuevo_eecc_alertas tablespace d_aml_99 as
select * from tmp_clinuevo_saving a
union all
select * from tmp_clinuevo_impac;

commit;
quit;