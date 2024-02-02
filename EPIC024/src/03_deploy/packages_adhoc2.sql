--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

--tabla de alertas pn
truncate table tmp_ingresotrc_alertaspn;
insert into tmp_ingresotrc_alertaspn
select a.*, b.codunicocli, trim(b.apepatcli) || ' ' || trim(b.apematcli) || ' ' || trim(b.nbrcli) as nbrclibeneficiario
from tmp_ingresotrc_salida_modelopn a
left join ods_v.md_clienteg94 b on a.codclavecic = b.codclavecic
where a.n_cluster in (-1,1);

-- trxs de las alertas
truncate table tmp_trx_epic024_pn;
insert into tmp_trx_epic024_pn
select a.periodo, a.codclavecic,
b.codsucage,
codclavecicordenante,
c.codunicocli as codunicocliordenante,
trim(c.apepatcli)||' '||trim(c.apematcli)||' '||trim(c.nbrcli) as nombreordenante,
e.codopecta as codopectaordenante,
b.bancoemisor,
b.nbrpaisorigen,
b.fecdia,
b.hortransaccion,
b.codmoneda,
mtotransaccion,
mtodolarizado,
case when a.mtomaxdemaxrepetidos*0.9 < b.mtotransaccion and b.mtotransaccion < a.mtomaxdemaxrepetidos*1.1 then b.mtodolarizado else 0 end mto_conotrosproximos,
b.codproducto,
b.descodproducto,
b.codclavecicbeneficiario,
d.codunicocli as codunicoclibeneficiario,
trim(d.apepatcli)||' '||trim(d.apematcli)||' '||trim(d.nbrcli) as nombrebeneficiario,
f.codopecta as codopectabeneficiario
from tmpclientesmtosmaximosunicos a
left join tmp_ingrestrc_trxs_total_vf b on a.periodo = b.periodo and a.codclavecic = b.codclavecicbeneficiario
left join tmp_ingresotrc_alertaspn g on a.codclavecic=g.codclavecic
left join ods_v.md_clienteg94 c on b.codclavecicordenante=c.codclavecic
left join ods_v.md_clienteg94 d on b.codclavecicbeneficiario=d.codclavecic
left join ods_v.md_cuentag94 e on b.codclaveopectaordenante=e.codclaveopecta
left join ods_v.md_cuentag94 f on b.codclaveopectabeneficiario= f.codclaveopecta
where a.periodo = (select max(periodo) from tmpclientesmtosmaximosunicos);

commit;
quit;