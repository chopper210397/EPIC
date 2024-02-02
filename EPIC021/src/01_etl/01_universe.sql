--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

create table tmp_escagente_trx_aux_1_11 as
select a.numregistro, a.codagenteviabcp, a.codclavetarjeta, a.fecdia, a.hortransaccion,a.tiptransaccionagenteviabcp,
a.tipesttransaccionagenteviabcp, a.codmoneda,
case when a.tiptransaccionagenteviabcp in ('16') then a.mtooperacionadelantosueldo else a.mtotransaccion end mtotransaccion,
a.codclavecic, a.codunicocli as cliente, a.codclaveopectacargo,  a.codclaveopectaabono,
a.codprestamo, a.codclavecicadelantosueldo, a.tipprocedenciadescargogiro, a.codunicocliordenante as ordenante, a.codunicoclibeneficiario as beneficiario,   a.codidentificadortranbim,
a.codunicocliordenantettib as ordenantettib, a.codctainterbanordenantettib as ctaordenantettib,
a.codunicoclibeneficiariottib as benefttib, a.codctainterbanbeneficiariottib as ctabenefttib, codclavecucordenante,codclavecucbeneficiario,codclavecucordenantettib,codclavecucbeneficiariottib
, a.mtotransaccion * d.mtocambioaldolar as mtodolarizado
from ods_v.hd_movimientoagenteviabcp a
left join ods_v.hd_tipocambiosaldodiario d on a.fecdia = d.fectipcambio and a.codmoneda = d.codmoneda
where a.fecdia between  trunc(add_months(sysdate, -2),'mm') and trunc(last_day(add_months(sysdate,-1)))
and a.tiptransaccionagenteviabcp in ('03','04','05','08','09','11','13','14','15','16','20','22','23')
and a.tipesttransaccionagenteviabcp = 'P'
and a.mtotransaccion * d.mtocambioaldolar > 29.62;

create table tmp_escagente_trx_aux_1_22 as
select a.numregistro, a.codagenteviabcp, a.codclavetarjeta, a.fecdia, a.hortransaccion,a.tiptransaccionagenteviabcp,
a.tipesttransaccionagenteviabcp, a.codmoneda,
case when a.tiptransaccionagenteviabcp in ('16') then a.mtooperacionadelantosueldo else a.mtotransaccion end mtotransaccion,
a.codclavecic, a.codunicocli as cliente, a.codclaveopectacargo,  a.codclaveopectaabono,
a.codprestamo, a.codclavecicadelantosueldo, a.tipprocedenciadescargogiro, a.codunicocliordenante as ordenante, a.codunicoclibeneficiario as beneficiario,   a.codidentificadortranbim,
a.codunicocliordenantettib as ordenantettib, a.codctainterbanordenantettib as ctaordenantettib,
a.codunicoclibeneficiariottib as benefttib, a.codctainterbanbeneficiariottib as ctabenefttib, codclavecucordenante,codclavecucbeneficiario,codclavecucordenantettib,codclavecucbeneficiariottib
, a.mtotransaccion * d.mtocambioaldolar as mtodolarizado
from ods_v.hd_movimientoagenteviabcp a
left join ods_v.hd_tipocambiosaldodiario d on a.fecdia = d.fectipcambio and a.codmoneda = d.codmoneda
where a.fecdia between  trunc(add_months(sysdate, -4),'mm') and trunc(last_day(add_months(sysdate,-3)))
and a.tiptransaccionagenteviabcp in ('03','04','05','08','09','11','13','14','15','16','20','22','23')
and a.tipesttransaccionagenteviabcp = 'P'
and a.mtotransaccion * d.mtocambioaldolar > 29.62;

create table tmp_escagente_trx_aux_1_33 as
select a.numregistro, a.codagenteviabcp, a.codclavetarjeta, a.fecdia, a.hortransaccion,a.tiptransaccionagenteviabcp,
a.tipesttransaccionagenteviabcp, a.codmoneda,
case when a.tiptransaccionagenteviabcp in ('16') then a.mtooperacionadelantosueldo else a.mtotransaccion end mtotransaccion,
a.codclavecic, a.codunicocli as cliente, a.codclaveopectacargo,  a.codclaveopectaabono,
a.codprestamo, a.codclavecicadelantosueldo, a.tipprocedenciadescargogiro, a.codunicocliordenante as ordenante, a.codunicoclibeneficiario as beneficiario,   a.codidentificadortranbim,
a.codunicocliordenantettib as ordenantettib, a.codctainterbanordenantettib as ctaordenantettib,
a.codunicoclibeneficiariottib as benefttib, a.codctainterbanbeneficiariottib as ctabenefttib, codclavecucordenante,codclavecucbeneficiario,codclavecucordenantettib,codclavecucbeneficiariottib
, a.mtotransaccion * d.mtocambioaldolar as mtodolarizado
from ods_v.hd_movimientoagenteviabcp a
left join ods_v.hd_tipocambiosaldodiario d on a.fecdia = d.fectipcambio and a.codmoneda = d.codmoneda
where a.fecdia between  trunc(add_months(sysdate, -7),'mm') and trunc(last_day(add_months(sysdate,-5)))
and a.tiptransaccionagenteviabcp in ('03','04','05','08','09','11','13','14','15','16','20','22','23')
and a.tipesttransaccionagenteviabcp = 'P'
and a.mtotransaccion * d.mtocambioaldolar > 29.62;

rename tmp_escagente_trx_aux_1_11 to tmp_escagente_trx_aux_1;

insert into  tmp_escagente_trx_aux_1
select * from tmp_escagente_trx_aux_1_22;

drop table tmp_escagente_trx_aux_1_22;

insert into  tmp_escagente_trx_aux_1
select * from tmp_escagente_trx_aux_1_33;

drop table tmp_escagente_trx_aux_1_33;

--truncate table tmp_escagente_trx_aux_2;
--insert into tmp_escagente_trx_aux_2
create table tmp_escagente_trx_aux_2 as
select a.*,x.codclaveopecta as codclaveopectaagente
from tmp_escagente_trx_aux_1 a
left join ods_v.md_agenteviabcp x on trim(a.codagenteviabcp) = trim(x.codagenteviabcp);

drop table tmp_escagente_trx_aux_1;

--truncate table tmp_escagente_trx_aux_3;
--insert into tmp_escagente_trx_aux_3
create table tmp_escagente_trx_aux_3 as
select a.*,b.codclavecic as codclaveciccargo
from tmp_escagente_trx_aux_2 a
left join ods_v.md_cuenta b on a.codclaveopectacargo = b.codclaveopecta;

drop table tmp_escagente_trx_aux_2;

--truncate table tmp_escagente_trx_aux_4;
--insert into tmp_escagente_trx_aux_4
create table tmp_escagente_trx_aux_4 as
select a.*,c.codclavecic as codclavecicabono
from tmp_escagente_trx_aux_3 a
left join ods_v.md_cuenta c on a.codclaveopectaabono = c.codclaveopecta;

drop table tmp_escagente_trx_aux_3;

--truncate table tmp_escagente_trx_aux_5;
--insert into tmp_escagente_trx_aux_5
create table tmp_escagente_trx_aux_5 as
select a.*,d.codclavecic as codclavecicordenante
from tmp_escagente_trx_aux_4 a
left join ods_v.md_cliente d on a.codclavecucordenante = d.codclavecuc and d.flgregeliminado = 'N';

drop table tmp_escagente_trx_aux_4;

--truncate table tmp_escagente_trx_aux_6;
--insert into tmp_escagente_trx_aux_6
create table tmp_escagente_trx_aux_6 as
select a.*, e.codclavecic as codclavecicbeneficiario
from tmp_escagente_trx_aux_5 a
left join ods_v.md_cliente e on a.codclavecucbeneficiario = e.codclavecuc and e.flgregeliminado = 'N';

drop table tmp_escagente_trx_aux_5;

--truncate table tmp_escagente_trx_aux_7;
--insert into tmp_escagente_trx_aux_7
create table tmp_escagente_trx_aux_7 as
select a.*, h.codclavecic as codclavecicordenantettib
from tmp_escagente_trx_aux_6 a
left join ods_v.md_cliente h on a.codclavecucordenantettib = h.codclavecuc and h.flgregeliminado = 'N';

drop table tmp_escagente_trx_aux_6;

--truncate table tmp_escagente_trx_aux;
--insert into tmp_escagente_trx_aux
create table tmp_escagente_trx_aux as
select a.numregistro, a.codagenteviabcp, codclaveopectaagente, a.codclavetarjeta, a.fecdia, a.hortransaccion,a.tiptransaccionagenteviabcp,
a.tipesttransaccionagenteviabcp, a.codmoneda,
a.mtotransaccion,
a.mtodolarizado,
a.codclavecic, a.cliente, a.codclaveciccargo, a.codclaveopectacargo, a.codclavecicabono, a.codclaveopectaabono,
a.codprestamo, a.codclavecicadelantosueldo, a.tipprocedenciadescargogiro, a.ordenante, a.codclavecicordenante,
a.beneficiario, a.codclavecicbeneficiario,  a.codidentificadortranbim,
a.codclavecicordenantettib, a.ordenantettib,  a.ctaordenantettib,
i.codclavecic as codclavecicbeneficiariottib, a.benefttib,  a.ctabenefttib
from tmp_escagente_trx_aux_7 a
left join ods_v.md_cliente i on a.codclavecucbeneficiariottib = i.codclavecuc and i.flgregeliminado = 'N';

drop table tmp_escagente_trx_aux_7;

--campos del solicitante, beneficiario y agente
truncate table tmp_escagente_trx;
insert into tmp_escagente_trx
--create table tmp_escagente_trx as
select  a.numregistro, a.codagenteviabcp, a.codclavetarjeta, a.fecdia, a.hortransaccion, a.tiptransaccionagenteviabcp, a.tipesttransaccionagenteviabcp,
a.codmoneda, a.mtotransaccion, a.mtodolarizado,
--campos del solicitante
case
     when a.tiptransaccionagenteviabcp in ('05','15') then a.codclavecic
     when a.tiptransaccionagenteviabcp in ('03','04') then coalesce(a.codclaveciccargo, d.codclavecic)
     when a.tiptransaccionagenteviabcp in ('09','11') then a.codclavecicordenante
     when a.tiptransaccionagenteviabcp in ('13','14') then c.codclavecic
     when a.tiptransaccionagenteviabcp in ('16') then a.codclavecicadelantosueldo
     when a.tiptransaccionagenteviabcp in ('23') then coalesce(a.codclavecicordenantettib,a.codclaveciccargo)
else null
end
as codclavecicsolicitante,
case
     when a.tiptransaccionagenteviabcp in ('03','04','23') then a.codclaveopectacargo
     when a.tiptransaccionagenteviabcp in ('13','14') then b.codclaveopecta
else null
end
as codclaveopectasolicitante,
case
     when a.tiptransaccionagenteviabcp in ('05','13','15') then a.cliente
     when a.tiptransaccionagenteviabcp in ('09','11') then a.ordenante
     when a.tiptransaccionagenteviabcp in ('22') then a.codidentificadortranbim
     when a.tiptransaccionagenteviabcp in ('23') then a.ctaordenantettib
else null
end
as datosolicitante,
--campos del beneficiario beneficiario
case
     when a.tiptransaccionagenteviabcp in ('03','05') then a.codclavecicabono
     when a.tiptransaccionagenteviabcp in ('09','11') then a.codclavecicbeneficiario
     when a.tiptransaccionagenteviabcp in ('23') then a.codclavecicbeneficiariottib
else null
end
as codclavecicbeneficiario,
case
     when a.tiptransaccionagenteviabcp in ('03','05') then a.codclaveopectaabono
else null
end
as codclaveopectabeneficiario,
case
     when a.tiptransaccionagenteviabcp in ('09','11') then a.beneficiario
     when a.tiptransaccionagenteviabcp in ('23') then a.ctabenefttib
else null
end
as datobeneficiario,
--campos del agente
a.codclaveopectaagente,
case
     when a.tiptransaccionagenteviabcp in ('05','09','13','15') then 'E'
     when a.tiptransaccionagenteviabcp in ('04','11','14','22') then 'I'
     when a.tiptransaccionagenteviabcp in ('03','16','23') then '.'
else null
end
as ingresoegresoagente,
a.tipprocedenciadescargogiro,
a.codprestamo
from tmp_escagente_trx_aux a
left join ods_v.md_tarjetavp b on a.codclavetarjeta = b.codclavetarjeta
left join ods_v.md_cuenta c on b.codclaveopecta = c.codclaveopecta
left join ods_v.md_tarjetadebito d on a.codclavetarjeta = d.codclavetarjetadebito;

commit;
quit;