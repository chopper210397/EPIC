--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

--tabla de alertas
create table tmp_escagente_alertas as
select distinct a.*, b.codunicocli
from tmp_escagente_salida_modelo a
left join ods_v.md_clienteg94 b on a.codclavecic = b.codclavecic
where rf_pred = -1
union all
select distinct a.*, b.codunicocli
from tmp_escagente_salida_modelo a
left join ods_v.md_clienteg94 b on a.codclavecic = b.codclavecic
where rf_pred in (6,7) and mto_cash_depo > 50000 ;

create table tmp_escagente_trx_1 as
select  to_number(to_char(a.fecdia,'yyyymm')) as periodo, a.codagenteviabcp, b.codclavecic,c.codunicocli,
trim(c.apepatcli)||' '||trim(c.apematcli)||' '||trim(c.nbrcli)as nombre, b.codopecta as codopectaagente,a.ingresoegresoagente,
a.fecdia,a.hortransaccion,a.tiptransaccionagenteviabcp,h.destiptransaccionagenteviabcp,a.tipesttransaccionagenteviabcp,a.codmoneda,a.mtotransaccion,a.mtodolarizado,
a.codclavecicsolicitante,d.codunicocli as codunicoclisolicitante,
trim(d.apepatcli)||' '||trim(d.apematcli)||' '||trim(d.nbrcli)as nombresolicitante,e.codopecta as codopectasolicitante,
a.datosolicitante,a.codclavecicbeneficiario,f.codunicocli as codunicoclibeneficiario,
trim(f.apepatcli)||' '||trim(f.apematcli)||' '||trim(f.nbrcli)as nombrebeneficiario,g.codopecta as codopectabeneficiario,
a.datobeneficiario, a.tipprocedenciadescargogiro,a.codprestamo
from tmp_escagente_trx a
left join ods_v.md_cuenta b on a.codclaveopectaagente = b.codclaveopecta
left join ods_v.md_clienteg94 c on b.codclavecic= c.codclavecic
left join ods_v.md_clienteg94 d on a.codclavecicsolicitante= d.codclavecic
left join ods_v.md_cuenta e on a.codclaveopectasolicitante = e.codclaveopecta
left join ods_v.md_clienteg94 f on a.codclavecicbeneficiario= f.codclavecic
left join ods_v.md_cuenta g on a.codclaveopectabeneficiario = g.codclaveopecta
left join ods_v.md_destipotranagenteviabcp h on a.tiptransaccionagenteviabcp = h.tiptransaccionagenteviabcp
inner join tmp_escagente_alertas i on a.codagenteviabcp=i.codagenteviabcp and a.codclaveopectaagente=i.codclaveopectaagente
where to_number(to_char(a.fecdia,'yyyymm')) = (select max(periodo) from tmp_escagente_alertas) and ingresoegresoagente = 'E' ;

--extraccion de transacciones
--datos de agente
create table tmp_escagente_trx_alertas_dataagente as
select a.numregistro,
a.codagenteviabcp, d.codclavecic as codclavecicagente, d.codunicocli as codunicocliagente, trim(d.apepatcli) || ' ' || trim(d.apematcli) || ' ' || trim(d.nbrcli) as nbragente, a.codclaveopectaagente, b.codopecta as codopectaagente,
a.fecdia, a.hortransaccion,
a.tiptransaccionagenteviabcp, e.destiptransaccionagenteviabcp, a.tipesttransaccionagenteviabcp,
a.codmoneda, a.mtotransaccion, a.mtodolarizado,
a.codclavecicsolicitante, a.codclaveopectasolicitante, a.datosolicitante,
a.codclavecicbeneficiario, a.codclaveopectabeneficiario, a.datobeneficiario,
a.ingresoegresoagente, a.tipprocedenciadescargogiro, a.codprestamo
from tmp_escagente_trx a
left join ods_v.md_cuenta b on a.codclaveopectaagente = b.codclaveopecta
inner join tmp_escagente_alertas c on a.codagenteviabcp = c.codagenteviabcp
left join ods_v.md_cliente d on b.codclavecic = d.codclavecic
left join ods_v.md_destipotranagenteviabcp e on a.tiptransaccionagenteviabcp = e.tiptransaccionagenteviabcp;

--data de solicitante y beneficiario
create table tmp_escagente_trx_alertas as
select a.numregistro,
a.codagenteviabcp, a.codclavecicagente, a.codunicocliagente, a.nbragente, a.codclaveopectaagente, a.codopectaagente,
a.fecdia, a.hortransaccion,
a.tiptransaccionagenteviabcp, a.destiptransaccionagenteviabcp, a.tipesttransaccionagenteviabcp,
a.codmoneda, a.mtotransaccion, a.mtodolarizado,
a.codclavecicsolicitante, b.codunicocli as codunicoclisolicitante, trim(b.apepatcli) || ' ' || trim(b.apematcli) || ' ' || trim(b.nbrcli) as nbrsolicitante, a.codclaveopectasolicitante, c.codopecta as codopectasolicitante, a.datosolicitante,
a.codclavecicbeneficiario, d.codunicocli as codunicoclibeneficiario, trim(d.apepatcli) || ' ' || trim(d.apematcli) || ' ' || trim(d.nbrcli) as nbrbeneficiario, a.codclaveopectabeneficiario, e.codopecta as codopectabeneficiario, a.datobeneficiario,
a.ingresoegresoagente,a.tipprocedenciadescargogiro,a.codprestamo
from tmp_escagente_trx_alertas_dataagente a
left join ods_v.md_clienteg94 b on a.codclavecicsolicitante = b.codclavecic
left join ods_v.md_cuenta c on a.codclaveopectasolicitante = c.codclaveopecta
left join ods_v.md_clienteg94 d on a.codclavecicbeneficiario = d.codclavecic
left join ods_v.md_cuenta e on a.codclaveopectabeneficiario = e.codclaveopecta;

--extraccion de los eecc
create table tmp_escagente_codclavecics_alertas as
select distinct codclavecic as codclavecic from tmp_escagente_alertas;

--listar eecc:
create table tmp_escagente_inicial as
select a.codclavecic, codunicocli, tipper,
       case when tipper = 'E' then trim(apepatcli) || trim(apematcli) || trim(nbrcli)
            when tipper = 'P' then trim(apepatcli) || ' ' || trim(apematcli) || ' ' || trim(nbrcli)
       end as nombre
from ods_v.md_cliente a
inner join tmp_escagente_codclavecics_alertas b on a.codclavecic = b.codclavecic
     and a.codclavecic not in (select codclavecic from ods_v.md_empleadog94)
union
select a.codclavecic, codunicocli, 'P', Trim(apepatempleado) || ' ' || trim(apematempleado) || ' ' || trim(nbrempleado)
from ods_v.md_empleadog94 a
inner join tmp_escagente_codclavecics_alertas b on a.codclavecic = b.codclavecic;

create table tmp_escagente_ctas as
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
     inner join tmp_escagente_inicial b on cta.codclavecic = b.codclavecic
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
       when cta.codsistemaorigen = 'imp' then
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
     inner join tmp_escagente_inicial b on cta.codclavecic = b.codclavecic
where cta.codsistemaorigen in ('SAV','IMP');

create table tmp_escagente_saving as
select b.codclavecic, b.codunicocli, b.nombre, a.codclaveopecta, b.codopecta, b.cuentacomercial, a.fecdia, a.hortransaccion, a.desopetransaccionsavingdetalle, f.grupo,
       c.descanal, d.nbrsucage, a.codmoneda, a.mtotransaccion, a.tipcargoabono, round(a.mtotransaccion * e.mtocambioaldolar, 2) as mtodolarizado
from ods_v.hd_movimientosaving a
     inner join tmp_escagente_ctas b on a.codclaveopecta = b.codclaveopecta and b.codsistemaorigen = 'SAV'
     left join ods_v.md_descodigocanal c on a.codcanal = c.codcanal
     left join ods_v.md_agencia d on a.codsucage = d.codsucage
     left join ods_v.hd_tipocambiosaldodiario e on a.fecdia = e.fectipcambio and a.codmoneda = e.codmoneda
     left join s55632.rm_equival_tipope_eecc_tmp f on trim(a.desopetransaccionsavingdetalle) like (trim(f.glosa) || '%')
where a.fecdia between trunc(add_months(sysdate, -7),'mm') and trunc(last_day(add_months(sysdate,-1)));

create table tmp_escagente_impac as
select b.codclavecic, b.codunicocli, b.nombre, a.codclaveopecta, b.codopecta, b.cuentacomercial, a.fecdia, a.hortransaccion, a.desopetransaccionimpacdetalle, f.grupo,
       c.descanal, d.nbrsucage, a.codmoneda, a.mtotransaccion, a.tipcargoabono, round(a.mtotransaccion * e.mtocambioaldolar, 2) as mtodolarizado
from ods_v.hd_movimientoimpac a
     inner join tmp_escagente_ctas b on a.codclaveopecta = b.codclaveopecta and b.codsistemaorigen = 'IMP'
     left join ods_v.md_descodigocanal c on a.codcanal = c.codcanal
     left join ods_v.md_agencia d on a.codsucage = d.codsucage
     left join ods_v.hd_tipocambiosaldodiario e on a.fecdia = e.fectipcambio and a.codmoneda = e.codmoneda
     left join s55632.rm_equival_tipope_eecc_tmp f on trim(a.desopetransaccionimpacdetalle) like (trim(f.glosa) || '%')
where a.fecdia between trunc(add_months(sysdate, -7),'mm') and trunc(last_day(add_months(sysdate,-1)));

create table tmp_escagente_eecc_alertas as
select * from tmp_escagente_saving a
union all
select * from tmp_escagente_impac;

commit;
quit;