--PARAMETRO DE CREDENCIALES
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

var intervalo_1 number 
exec :intervalo_1 := to_number(&2);

select :intervalo_1 from dual;
/*************************************************************************************************
****************************** ESCENARIO TOP INGRESO EFECTIVO BENEFICIARIO SOLES *****************
*************************************************************************************************/

-- key user escenario: plaft
-- fecha:

alter session disable parallel query;

truncate table tmp_topsolicitante_trx;
insert into tmp_topsolicitante_trx
select
	periodo, fecdia, horinitransaccion, a.codsucage, codsesion, a.codinternotransaccion, a.codtransaccionventanilla, b.destransaccionventanilla,
	case when a.codtransaccionventanilla in (184, 84) then numcheque
		when a.codtransaccionventanilla = 133 then codctacomercialdestino
		when codctacomercial <> '00000000000000000000' then codctacomercial end codctacomercial,
	mtotransaccioncta as mtotransaccion, a.codunicoclisolicitante,
	case when not(codunicoclisolicitante is null) then substr(codunicoclisolicitante,5,8) end idcsolicitante,
	case when not(codunicoclisolicitante is null) then substr(codunicoclisolicitante,13,1) end tipdocsolicitante,
	b.nbrcliente as nbrclientesolicitante, d.destipbanca as bancasolicitante, a.codunicoclibeneficiario,
	case when not(codunicoclibeneficiario is null) then substr(codunicoclibeneficiario,5,8) end idcbeneficiario,
	case when not(codunicoclibeneficiario is null) then substr(codunicoclibeneficiario,13,1) end tipdocbeneficiario,
	c.nbrcliente as nbrclientebeneficiario, e.destipbanca as bancabeneficiario, aa.codterminal, aa.codmatricula
from
	t23377.efesol_trxparticipe a
	inner join t23377.efesol_trxparticipe2 aa on a.codinternotransaccion = aa.codinternotransaccion and a.codsucage = aa.codsucage
	inner join t23377.efe_detransaccionventanilla b on (a.codtransaccionventanilla=b.codtransaccionventanilla)
	left join t23377.efesol_cliente b on a.codunicoclisolicitante=b.codunicocli
	left join t23377.efesol_cliente c on a.codunicoclibeneficiario=c.codunicocli
	left join ods_v.mm_destipobanca d on d.tipbanca=b.tipbanca
	left join ods_v.mm_destipobanca e on e.tipbanca=c.tipbanca
where
	a.fecdia between trunc(add_months(sysdate, :intervalo_1),'mm') and trunc(last_day(add_months(sysdate,:intervalo_1))) and
  a.mtotransaccioncta >= 200000;


--obtenemos el universo de cliente Bex Digital
truncate table tmp_topsolicitante_clientes_bed_sindac;
insert into tmp_topsolicitante_clientes_bed_sindac
SELECT 
       C.CODCLAVECIC, C.CODINTERNOCOMPUTACIONAL, C.CODSECTOR, C.CODSECTORISTA, 
       O.NOMBRE AS DESSECTORISTA, C.CODSUBSEGMENTO, C.TIPCLI, O.EQUIPO AS AGENCIA, O.REGION
FROM ODS_V.MD_CLIENTE C 
INNER JOIN USRPLAMIN.GC_ORGANICO_CMP_VIEW O ON TRIM(C.CODSECTORISTA) = O.MATRICULA AND O.CANALVTA = 'BEX_DIGITAL' AND SUBSTR(O.MATRICULA,1 ,2) != 'RB' AND O.CODMES = TO_NUMBER(TO_CHAR(SYSDATE-1, 'YYYYMM'));
COMMIT;



truncate table tmp_topsolicitante_previa;
insert into tmp_topsolicitante_previa
select distinct
       c.codclavecic as codclavecicbeneficiario, b.codclavecic as codclavecicsolicitante, a.periodo, a.fecdia, a.horinitransaccion, a.codsucage, a.codsesion,
       a.codinternotransaccion, a.codtransaccionventanilla, a.destransaccionventanilla, c.codacteconomica as actv_beneficiario, c.tipper as tipper_beneficiario,
       case when g.codmatricula is null then 0 else 1 end as flg_ffnn_beneficiario, case when e.codmatricula is null then 0 else 1 end as flg_ffnn_solicitante,
       c.tipbanca as tipbanca_beneficiario, b.tipbanca as tipbanca_solicitante, a.mtotransaccion, b.tipper as tipper_solicitante,
       a.codunicoclisolicitante, a.codunicoclibeneficiario
from tmp_topsolicitante_trx a
     left join ods_v.md_clienteg94 b on a.codunicoclisolicitante = b.codunicocli
     left join ods_v.md_clienteg94 c on a.codunicoclibeneficiario = c.codunicocli
     left join tmp_topsolicitante_clientes_bed_sindac d on b.codclavecic = d.codclavecic
     left join ods_v.md_empleadog94 e on trim(coalesce(d.codsectorista, b.codsectorista)) = trim(e.codmatricula)
     left join tmp_topsolicitante_clientes_bed_sindac f on c.codclavecic = f.codclavecic
     left join ods_v.md_empleadog94 g on trim(coalesce(f.codsectorista, c.codsectorista)) = trim(g.codmatricula);

truncate table tmp_topsolicitante_spool;
insert into tmp_topsolicitante_spool
select distinct
       a.codclavecicbeneficiario, a.codclavecicsolicitante, a.periodo, a.fecdia, a.horinitransaccion, a.codsucage, a.codsesion,
       a.codinternotransaccion, a.codtransaccionventanilla, a.destransaccionventanilla, a.actv_beneficiario, a.tipper_beneficiario,
       a.flg_ffnn_beneficiario, a.flg_ffnn_solicitante, a.tipbanca_beneficiario, a.tipbanca_solicitante, a.mtotransaccion, a.tipper_solicitante,
       b.destipbanca as desbanca_beneficiario, c.destipbanca as desbanca_solicitante, d.fecconstitucion as fecons_beneficiario, e.fecconstitucion as fecons_sol,
       case when dn1.codclavecic is null then 0 else 1 end as flg_an_beneficiario, case when dn2.codclavecic is null then 0 else 1 end as flg_an_solicitante,
       case when rel.codclavecic is null then 0 else 1 end as flg_rel, case when r1.codunicocli is null then 0 else 1 end as flg_ros_ben,
       case when r2.codunicocli is null then 0 else 1 end as flg_ros_sol
from tmp_topsolicitante_previa a
     left join ods_v.mm_destipobanca b on a.tipbanca_beneficiario = b.tipbanca
     left join ods_v.mm_destipobanca c on a.tipbanca_solicitante = c.tipbanca
     left join ods_v.mm_empresa d on a.codclavecicbeneficiario = d.codclavecic
     left join ods_v.mm_empresa e on a.codclavecicsolicitante = e.codclavecic
     left join ods_v.md_clientenegativo an1 on a.codclavecicbeneficiario = an1.codclavecic and an1.tipestclinegativo <> 'H'
     left join ods_v.md_motivodetalleclinegativo dn1 on an1.codclavecic = dn1.codclavecic and dn1.tipmotivonegativo = '013'
     left join ods_v.md_clientenegativo an2 on a.codclavecicsolicitante = an2.codclavecic and an2.tipestclinegativo <> 'H'
     left join ods_v.md_motivodetalleclinegativo dn2 on an2.codclavecic = dn2.codclavecic and dn2.tipmotivonegativo = '013'
     left join ods_v.md_relacioncliente rel on a.codclavecicbeneficiario = rel.codclavecic and a.codclavecicsolicitante = rel.codclavecicclirel
     left join s61751.sapy_dminvestigacion r1 on a.codunicoclibeneficiario = r1.codunicocli and r1.idresultadosupervisor = 2
     left join s61751.sapy_dminvestigacion r2 on a.codunicoclisolicitante = r2.codunicocli and r2.idresultadosupervisor = 2;

commit;
quit;