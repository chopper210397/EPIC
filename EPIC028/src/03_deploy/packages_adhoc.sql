--PARAMETRO DE CREDENCIALES
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

/*************************************************************************************************
****************************** ESCENARIO YAPE ***************************
*************************************************************************************************/

--Tabla de alertas
truncate table tmp_yape_alertas;
insert into tmp_yape_alertas 
with tmp as(
select a.*,b.codunicocli,trim(b.apepatcli) || ' ' || trim(b.apematcli) || ' ' || trim(b.nbrcli) as nbr_beneficiario
from tmp_yape_salida_modelo a
left join ods_v.md_clienteg94 b on a.codclavecic = b.codclavecic
where outlier=-1
union all
select a.*,b.codunicocli, trim(b.apepatcli) || ' ' || trim(b.apematcli) || ' ' || trim(b.nbrcli) as nbr_beneficiario
from tmp_yape_salida_modelopol a
left join ods_v.md_clienteg94 b on a.codclavecic = b.codclavecic
where outlier=-1
 )
select distinct * 
from tmp;

--Extraccion de transacciones
truncate table tmp_yape_trx_alertas;
insert into tmp_yape_trx_alertas
select distinct
a.codclavecic as codclavecic_ben,a.codunicocli as codunicocli_ben,a.nbr_beneficiario,t.dia_operacion,t.hora,t.monto_ingreso,
t.codclavecic_origen as codclavecic_sol,b.codunicocli as codunicocli_sol,
trim(b.apepatcli) || ' ' || trim(b.apematcli) || ' ' || trim(b.nbrcli) as nbr_solicitante,
'yape' as canal
from tmp_yape_prepep t
inner join tmp_yape_alertas a on t.codclavecic=a.codclavecic
left join ods_v.md_clienteg94 b on t.codclavecic_origen = b.codclavecic;

commit;
quit;