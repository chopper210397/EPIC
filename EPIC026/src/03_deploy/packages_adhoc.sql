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

--tabla de alertas
truncate table tmp_hb_alertas;
insert into tmp_hb_alertas
--create table tmp_hb_alertas tablespace d_aml_99 as
select distinct a.*, b.codunicocli,trim(b.apepatcli) || ' ' || trim(b.apematcli) || ' ' || trim(b.nbrcli) as nbr_ordenante
from tmp_hb_salidamodelo a
left join ods_v.md_clienteg94 b on a.codclavecic = b.codclavecic
where outlier = -1;

--extraccion de transacciones
truncate table tmp_hb_pretrx;
insert into tmp_hb_pretrx
--create table tmp_hb_pretrx tablespace d_aml_99 as
select c.codclavecic as codclavecic_ord,a.fecdia,a.hortransaccion,codclavecic_ben,mtodolarizado
from tmp_hb_cli_beneficiario a
inner join ods_v.md_cuentag94 b on a.codopectaorigen=b.codopecta
inner join ods_v.md_clienteg94 c on b.codclavecic=c.codclavecic;

truncate table tmp_hb_trx_alertas;
insert into tmp_hb_trx_alertas
--create table tmp_hb_trx_alertas tablespace d_aml_99 as
select distinct
t.codclavecic_ben,a.codunicocli as codunicocli_ben,trim(b.apepatcli) || ' ' || trim(b.apematcli) || ' ' || trim(b.nbrcli) as nbr_beneficiario,t.fecdia,t.hortransaccion,t.mtodolarizado,
t.codclavecic_ord,a.codunicocli as codunicocli_ord,nbr_ordenante,
'HOMEBANKING' as canal
from tmp_hb_pretrx t
inner join tmp_hb_alertas a on t.codclavecic_ord=a.codclavecic
left join ods_v.md_clienteg94 b on t.codclavecic_ben = b.codclavecic;

--extraccion de los eecc
truncate table tmp_hb_codclavecics_alertas;
insert into tmp_hb_codclavecics_alertas
--create table tmp_hb_codclavecics_alertas tablespace d_aml_99 as
select distinct codclavecic as codclavecic from tmp_hb_alertas;

--listar eecc:
truncate table tmp_hb_inicial;
insert into tmp_hb_inicial
--create table tmp_hb_inicial tablespace d_aml_99 as
select a.codclavecic, codunicocli, tipper,
       case when tipper = 'E' then trim(apepatcli) || trim(apematcli) || trim(nbrcli)
            when tipper = 'P' then trim(apepatcli) || ' ' || trim(apematcli) || ' ' || trim(nbrcli)
       end as nombre
from ods_v.md_cliente a
inner join tmp_hb_codclavecics_alertas b on a.codclavecic = b.codclavecic
     and a.codclavecic not in (select codclavecic from ods_v.md_empleadog94)
union
select a.codclavecic, codunicocli, 'P', trim(apepatempleado) || ' ' || trim(apematempleado) || ' ' || trim(nbrempleado)
from ods_v.md_empleadog94 a
inner join tmp_hb_codclavecics_alertas b on a.codclavecic = b.codclavecic;

truncate table tmp_hb_ctas;
insert into tmp_hb_ctas
--create table tmp_hb_ctas tablespace d_aml_99 as
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
     inner join tmp_hb_inicial b on cta.codclavecic = b.codclavecic
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
     inner join tmp_hb_inicial b on cta.codclavecic = b.codclavecic
where cta.codsistemaorigen in ('SAV','IMP');

truncate table tmp_hb_saving;
insert into tmp_hb_saving
--create table tmp_hb_saving tablespace d_aml_99 as
select b.codclavecic, b.codunicocli, b.nombre, a.codclaveopecta, b.codopecta, b.cuentacomercial, a.fecdia, a.hortransaccion, a.desopetransaccionsavingdetalle, f.grupo,
       c.descanal, d.nbrsucage, a.codmoneda, a.mtotransaccion, a.tipcargoabono, round(a.mtotransaccion * e.mtocambioaldolar, 2) as mtodolarizado
from ods_v.hd_movimientosaving a
     inner join tmp_hb_ctas b on a.codclaveopecta = b.codclaveopecta and b.codsistemaorigen = 'SAV'
     left join ods_v.md_descodigocanal c on a.codcanal = c.codcanal
     left join ods_v.md_agencia d on a.codsucage = d.codsucage
     left join ods_v.hd_tipocambiosaldodiario e on a.fecdia = e.fectipcambio and a.codmoneda = e.codmoneda
     left join s55632.rm_equival_tipope_eecc_tmp f on trim(a.desopetransaccionsavingdetalle) like (trim(f.glosa) || '%')
where a.fecdia between trunc(add_months(sysdate, :intervalo_1),'mm') and trunc(last_day(add_months(sysdate, :intervalo_2)));

truncate table tmp_hb_impac;
insert into tmp_hb_impac
--create table tmp_hb_impac tablespace d_aml_99 as
select b.codclavecic, b.codunicocli, b.nombre, a.codclaveopecta, b.codopecta, b.cuentacomercial, a.fecdia, a.hortransaccion, a.desopetransaccionimpacdetalle, f.grupo,
       c.descanal, d.nbrsucage, a.codmoneda, a.mtotransaccion, a.tipcargoabono, round(a.mtotransaccion * e.mtocambioaldolar, 2) as mtodolarizado
from ods_v.hd_movimientoimpac a
     inner join tmp_hb_ctas b on a.codclaveopecta = b.codclaveopecta and b.codsistemaorigen = 'IMP'
     left join ods_v.md_descodigocanal c on a.codcanal = c.codcanal
     left join ods_v.md_agencia d on a.codsucage = d.codsucage
     left join ods_v.hd_tipocambiosaldodiario e on a.fecdia = e.fectipcambio and a.codmoneda = e.codmoneda
     left join s55632.rm_equival_tipope_eecc_tmp f on trim(a.desopetransaccionimpacdetalle) like (trim(f.glosa) || '%')
where a.fecdia between trunc(add_months(sysdate, :intervalo_1),'mm') and trunc(last_day(add_months(sysdate, :intervalo_2)));

truncate table tmp_hb_eecc_alertas;
insert into tmp_hb_eecc_alertas
--create table tmp_hb_eecc_alertas tablespace d_aml_99 as
select * from tmp_hb_saving a
union all
select * from tmp_hb_impac;

truncate table epic026_pre;
insert into epic026_pre
--create table epic026_pre tablespace d_aml_99 as
select distinct a.codunicocli,a.nbr_ordenante,b.*
from tmp_hb_alertas a
inner join  tmp_hb_data b on a.codclavecic=b.codclavecic;

commit;
quit;