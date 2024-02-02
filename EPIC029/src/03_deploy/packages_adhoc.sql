--PARAMETRO DE CREDENCIALES
@&1

set echo on
whenever sqlerror exit sql.sqlcode
/*************************************************************************************************
****************************** ESCENARIO TOP INGRESO EFECTIVO BENEFICIARIO SOLES *****************
*************************************************************************************************/
alter session disable parallel query;

truncate table tmp_topsolicitante_filtrado;
insert into tmp_topsolicitante_filtrado
select b.codunicoclibeneficiario, a.codclavecicbeneficiario, a.periodo, a.n_cluster, sum(a.mtotransaccion) as mto_recibido
from tmp_topsolicitante_output a
	inner join tmp_topsolicitante_previa b on a.fecdia = b.fecdia and a.codsucage = b.codsucage and a.codsesion = b.codsesion 
                                                and a.codinternotransaccion = b.codinternotransaccion
where a.n_cluster in (7,11,15,18)
group by b.codunicoclibeneficiario, a.codclavecicbeneficiario, a.periodo, a.n_cluster;

truncate table tmp_topsolicitante_alerta ;
insert into tmp_topsolicitante_alerta
select a.periodo,a.codunicoclibeneficiario as codunicocli, a.codclavecicbeneficiario as codclavecic 
from tmp_topsolicitante_filtrado a;

truncate table tmp_trx_epic029;
insert into tmp_trx_epic029
select distinct
a.periodo,
a.fecdia,
a.horinitransaccion,
a.codsucage,
a.codsesion,
a.codinternotransaccion,
a.codtransaccionventanilla,
destransaccionventanilla,
codctacomercial,
a.mtotransaccion,
codunicoclisolicitante,
nbrclientesolicitante,
bancasolicitante,
codunicoclibeneficiario,
nbrclientebeneficiario,
bancabeneficiario,
codterminal,
b.n_cluster
from  tmp_topsolicitante_trx a
left join (select b.codunicocli,a.* from tmp_topsolicitante_output a
left join ods_v.md_clienteg94 b on a.codclavecicbeneficiario=b.codclavecic where n_cluster in (7,11,15,18) ) b on 
a.codunicoclibeneficiario=b.codunicocli and a.mtotransaccion=b.mtotransaccion
where n_cluster in (7,11,15,18);

quit;
commit;