--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

/*************************************************************************************************
****************************** Escenario estimador de ingresos ***************************
*************************************************************************************************/

-- creado por: Celeste Cabanillas
-- key user escenario: plaft

alter session disable parallel query;

--------------------------------------------gremio
truncate table tmp_esting_gremio;
insert into tmp_esting_gremio
select codclavecic
from ods_v.md_empleadog94 
where flgregeliminado = 'N' and codclavecic <>0 and codclavecic is not null
and codpuesto not in ('00001477','00001478');

--------------------------------------------segmento
truncate table tmp_esting_segmentobanca;
insert into tmp_esting_segmentobanca
select distinct subseg.codsubsegmento, subseg.dessubsegmento, seg.codsegmento, seg.dessegmento
from ods_v.mm_descodigosubsegmento subseg
left join ods_v.mm_descodsubseggen subseggen on trim(subseg.codsubseggeneral)=trim(subseggen.codsubseggeneral)
left join ods_v.mm_descodigosegmento seg on trim(subseggen.codsegmento)=trim(seg.codsegmento);

-------------------------------------universo exclusiva + consumo
truncate table tmp_esting_universo_00;
insert into tmp_esting_universo_00
select a.codclavecic,
a.tipper
from ods_v.md_cliente a
inner join tmp_esting_segmentobanca b on a.codsubsegmento = b.codsubsegmento
where  a.flgregeliminado='N' and b.dessegmento in ('CONSUMO','EXCLUSIVA') and trim(a.codsubsegmento)<> 'G1N';

truncate table tmp_esting_universo;
insert into tmp_esting_universo
select a.*
from tmp_esting_universo_00 a
left join tmp_esting_gremio b on a.codclavecic=b.codclavecic
where b.codclavecic is null;

commit;
quit;
