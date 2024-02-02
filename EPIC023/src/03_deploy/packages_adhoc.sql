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

truncate table tmp_cvme_alertas;
insert into tmp_cvme_alertas
--create table tmp_cvme_alertas as
select a.*, b.codunicocli, trim(b.apepatcli) || ' ' || trim(b.apematcli) || ' ' || trim(b.nbrcli) as nbrcli
from tmp_cvme_salida_modelo a
left join ods_v.md_clienteg94 b on a.codclavecic = b.codclavecic
where outlier = -1;

-- trxs de las alertas
truncate table tmp_cvme_trx_alertas_aux;
insert into tmp_cvme_trx_alertas_aux
--create table tmp_cvme_trx_alertas_aux as
select
a.numregistro,a.fecdia,a.horinitransaccion,a.horfintransaccion,
a.codsucage,b.nbrsucage,a.codsesion,a.codtransaccionventanilla, c.destransaccionventanilla, a.flgtransaccionaprobada,a.tiproltransaccion,a.codmoneda,a.mtotransaccion,a.mtodolarizado,
a.codclavecic_solicitante, d.codunicocli as codunicocli_solicitante, trim(d.apepatcli) || ' ' || trim(d.apematcli) || ' ' || trim(d.nbrcli) as nbr_solicitante,
a.ordenante
from tmp_cvme_trx_ventanilla a
inner join tmp_cvme_alertas x on a.codclavecic_solicitante = x.codclavecic
left join ods_v.md_agencia b on a.codsucage = b.codsucage
left join ods_v.md_destransaccionventanilla c on a.codtransaccionventanilla = c.codtransaccionventanilla
left join ods_v.md_clienteg94 d on a.codclavecic_solicitante = d.codclavecic;

truncate table tmp_cvme_trx_alertas;
insert into tmp_cvme_trx_alertas
--create table tmp_cvme_trx_alertas as
with tmp_cvme_trx_alertas_aux_ordenante as (
  select a.*,
  e.codclavecic as codclavecic_ordenante, a.ordenante as codunicocli_ordenante
  from tmp_cvme_trx_alertas_aux a
  left join ods_v.md_clienteg94 e on trim(a.ordenante) = trim(e.codunicocli)
),
tmp_cvme_trx_alertas_aux_ordenante_rep as (
  select numregistro, count(*) as ctd from tmp_cvme_trx_alertas_aux_ordenante group by numregistro having count(*)> 1
),
tmp_cvme_trx_alertas_aux_1 as (
  select
  a.numregistro,a.fecdia,a.horinitransaccion,a.horfintransaccion,
  a.codsucage,a.nbrsucage,a.codsesion,a.codtransaccionventanilla,a.destransaccionventanilla,a.flgtransaccionaprobada,a.tiproltransaccion,a.codmoneda,a.mtotransaccion,a.mtodolarizado,
  a.codclavecic_solicitante,a.codunicocli_solicitante,a.nbr_solicitante,
  e.codclavecic as codclavecic_ordenante, a.ordenante as codunicocli_ordenante, trim(e.apepatcli) || ' ' || trim(e.apematcli) || ' ' || trim(e.nbrcli) as nbr_ordenante
  from tmp_cvme_trx_alertas_aux a
  inner join tmp_cvme_trx_alertas_aux_ordenante_rep b on a.numregistro = b.numregistro
  left join ods_v.md_clienteg94 e on trim(a.ordenante) = trim(e.codunicocli)
  where e.flgregeliminado = 'N'
),
tmp_cvme_trx_alertas_aux_2 as (
  select
  a.numregistro,a.fecdia,a.horinitransaccion,a.horfintransaccion,
  a.codsucage,a.nbrsucage,a.codsesion,a.codtransaccionventanilla,a.destransaccionventanilla,a.flgtransaccionaprobada,a.tiproltransaccion,a.codmoneda,a.mtotransaccion,a.mtodolarizado,
  a.codclavecic_solicitante,a.codunicocli_solicitante,a.nbr_solicitante,
  e.codclavecic as codclavecic_ordenante, a.ordenante as codunicocli_ordenante, trim(e.apepatcli) || ' ' || trim(e.apematcli) || ' ' || trim(e.nbrcli) as nbr_ordenante
  from tmp_cvme_trx_alertas_aux a
  left join tmp_cvme_trx_alertas_aux_ordenante_rep b on a.numregistro = b.numregistro
  left join ods_v.md_clienteg94 e on trim(a.ordenante) = trim(e.codunicocli)
  where b.numregistro is null
)
select a.*
from tmp_cvme_trx_alertas_aux_1 a
union all
select a.*
from tmp_cvme_trx_alertas_aux_2 a;


--eecc
--extraccion de los eecc
truncate table tmp_cvme_codclavecics_alertas;
insert into tmp_cvme_codclavecics_alertas
--create table tmp_cvme_codclavecics_alertas as
select distinct codclavecic as codclavecic from tmp_cvme_alertas;

--listar eecc:
truncate table tmp_cvme_inicial;
insert into tmp_cvme_inicial
--create table tmp_cvme_inicial as
select a.codclavecic, codunicocli, tipper,
       case when tipper = 'E' then trim(apepatcli) || trim(apematcli) || trim(nbrcli)
            when tipper = 'P' then trim(apepatcli) || ' ' || trim(apematcli) || ' ' || trim(nbrcli)
       end as nombre
from ods_v.md_cliente a
inner join tmp_cvme_codclavecics_alertas b on a.codclavecic = b.codclavecic
     and a.codclavecic not in (select codclavecic from ods_v.md_empleadog94)
union
select a.codclavecic, codunicocli, 'P', trim(apepatempleado) || ' ' || trim(apematempleado) || ' ' || trim(nbrempleado)
from ods_v.md_empleadog94 a
inner join tmp_cvme_codclavecics_alertas b on a.codclavecic = b.codclavecic;

--create index idx_pagoalsant_eecc_codclavecic on tmp_cvme_inicial (codclavecic) tablespace d_aml_99;
truncate table tmp_cvme_ctas;
insert into tmp_cvme_ctas
--create table tmp_cvme_ctas as
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
     inner join tmp_cvme_inicial b on cta.codclavecic = b.codclavecic
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
     inner join tmp_cvme_inicial b on cta.codclavecic = b.codclavecic
where cta.codsistemaorigen in ('SAV','IMP');

truncate table tmp_cvme_saving;
insert into tmp_cvme_saving
--create table tmp_cvme_saving as
select b.codclavecic, b.codunicocli, b.nombre, a.codclaveopecta, b.codopecta, b.cuentacomercial, a.fecdia, a.hortransaccion, a.desopetransaccionsavingdetalle, f.grupo,
       c.descanal, d.nbrsucage, a.codmoneda, a.mtotransaccion, a.tipcargoabono, round(a.mtotransaccion * e.mtocambioaldolar, 2) as mtodolarizado
from ods_v.hd_movimientosaving a
     inner join tmp_cvme_ctas b on a.codclaveopecta = b.codclaveopecta and b.codsistemaorigen = 'SAV'
     left join ods_v.md_descodigocanal c on a.codcanal = c.codcanal
     left join ods_v.md_agencia d on a.codsucage = d.codsucage
     left join ods_v.hd_tipocambiosaldodiario e on a.fecdia = e.fectipcambio and a.codmoneda = e.codmoneda
     left join s55632.rm_equival_tipope_eecc_tmp f on trim(a.desopetransaccionsavingdetalle) like (trim(f.glosa) || '%')
where a.fecdia between trunc(add_months(sysdate, :intervalo_1),'mm') and trunc(last_day(add_months(sysdate,:intervalo_2)));

truncate table tmp_cvme_impac;
insert into tmp_cvme_impac
--create table tmp_cvme_impac as
select b.codclavecic, b.codunicocli, b.nombre, a.codclaveopecta, b.codopecta, b.cuentacomercial, a.fecdia, a.hortransaccion, a.desopetransaccionimpacdetalle, f.grupo,
       c.descanal, d.nbrsucage, a.codmoneda, a.mtotransaccion, a.tipcargoabono, round(a.mtotransaccion * e.mtocambioaldolar, 2) as mtodolarizado
from ods_v.hd_movimientoimpac a
     inner join tmp_cvme_ctas b on a.codclaveopecta = b.codclaveopecta and b.codsistemaorigen = 'IMP'
     left join ods_v.md_descodigocanal c on a.codcanal = c.codcanal
     left join ods_v.md_agencia d on a.codsucage = d.codsucage
     left join ods_v.hd_tipocambiosaldodiario e on a.fecdia = e.fectipcambio and a.codmoneda = e.codmoneda
     left join s55632.rm_equival_tipope_eecc_tmp f on trim(a.desopetransaccionimpacdetalle) like (trim(f.glosa) || '%')
where a.fecdia between trunc(add_months(sysdate, :intervalo_1),'mm') and trunc(last_day(add_months(sysdate,:intervalo_2)));

truncate table tmp_cvme_eecc_alertas;
insert into tmp_cvme_eecc_alertas
--create table tmp_cvme_eecc_alertas as
select * from tmp_cvme_saving a
union all
select * from tmp_cvme_impac;

commit;
quit;