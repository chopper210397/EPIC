--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode

var intervalo_1 number 
exec :intervalo_1 := to_number(&2);

select :intervalo_1 from dual;

alter session disable parallel query;

/*************************************************************************************************
****************************** Escenario estimador de ingresos ***********************************
*************************************************************************************************/

-- creado por: Celeste Cabanillas
-- key user escenario: plaft
/*************************************************************************************************/

--tabla de alertas
truncate table tmp_esting_alertas;
insert into tmp_esting_alertas
select distinct a.*,c.codunicocli,trim(apepatcli) || trim(apematcli) || trim(nbrcli) as nbr_cli
from tmp_esting_tablon a
inner join tmp_esting_salida_modelo b on a.codclavecic = b.codclavecic
left join ods_v.md_clienteg94 c on a.codclavecic = c.codclavecic
where b.outlier=-1; 

--------------------------------------------------------------------cambiar fecha -------------------------------------------------------------------
--tabla de trx
truncate table tmp_trx_epic030  ;
insert into tmp_trx_epic030 
select 
codclavecic_sol,c.codunicocli as codunicocli_sol,trim(c.apepatcli)||' '||trim(c.apematcli)||' '||trim(c.nbrcli) as nombre_sol,
codopecta_sol,codclavecic_ben,d.codunicocli as codunicocli_ben,
trim(d.apepatcli)||' '||trim(d.apematcli)||' '||trim(d.nbrcli) as nombre_ben,
codopecta_ben,a.fecdia,a.hortransaccion,a.codmoneda,a.mtotransaccion,
a.mto_dolarizado,tipo_transaccion,canal,
codpaisorigen 
from tmp_esting_trx a
inner join tmp_esting_alertas b on a.codclavecic_ben=b.codclavecic
left join ods_v.md_clienteg94 c on a.codclavecic_sol=c.codclavecic
left join ods_v.md_clienteg94 d on a.codclavecic_ben=d.codclavecic
where a.fecdia between trunc(add_months(sysdate,:intervalo_1),'mm') and trunc(last_day(add_months(sysdate,:intervalo_1)));

truncate table tmp_esting_trx_alertas;
insert into tmp_esting_trx_alertas
select 
codclavecic_sol,c.codunicocli codunicocli_sol,trim(c.apepatcli) || trim(c.apematcli) || trim(c.nbrcli) as nbr_cli_sol,
codclavecic_ben,b.codunicocli codunicocli_ben,nbr_cli as nbr_cli_ben ,
a.fecdia,a.hortransaccion,a.codmoneda,a.mtotransaccion,a.mto_dolarizado,a.tipo_transaccion,a.canal,
a.codpaisorigen
from tmp_esting_trx a 
inner join tmp_esting_alertas b on a.codclavecic_ben=b.codclavecic
left join ods_v.md_clienteg94 c on a.codclavecic_sol=c.codclavecic
where a.fecdia between trunc(add_months(sysdate, :intervalo_1),'mm') and trunc(last_day(add_months(sysdate,:intervalo_1))); 

commit;
quit;
