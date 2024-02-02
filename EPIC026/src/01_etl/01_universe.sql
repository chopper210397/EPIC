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

--canal homebanking universo
truncate table tmp_hb_trx;
insert into tmp_hb_trx
--create table tmp_hb_trx tablespace d_aml_99 as
select to_number(to_char(t.fecdia,'yyyymm')) as periodo,codopectaorigen,sum(t.mtotransaccion * tc.mtocambioaldolar) as mtodolarizado,count(t.mtotransaccion) as ctd_oper
from ods_v.hd_movhomebankingtransaccion t
left join ods_v.hd_tipocambiosaldodiario tc on t.fecdia = tc.fectipcambio and t.codmoneda = tc.codmoneda
where  upper(tipresultadotransaccion) = 'OK' and
t.fecdia between trunc(add_months(sysdate,:intervalo_1),'mm') and trunc(last_day(add_months(sysdate,:intervalo_2))) and
upper(codopehbctr) in ('TRAN_N','TRANS_OBCO_L','TRANSEXT','PCRBK_TER','EMIS','D_TRAN','PAMEX_TER','TRAN_OBCO')
group by to_number(to_char(t.fecdia,'yyyymm')),codopectaorigen;

truncate table tmp_hb_trx_1  ;
insert into tmp_hb_trx_1
--create table tmp_hb_trx_1 tablespace d_aml_99 as
select to_number(to_char(t.fecdia,'yyyymm')) as periodo,t.fecdia,t.hortransaccion,codopectaorigen,codopectadestino,codunicoclibeneficiario,
trim(apepatbeneficiario)||' '||trim(apematbeneficiario)||' '||trim(nbrbeneficiario)as nombrebeneficiario,(t.mtotransaccion * tc.mtocambioaldolar) as mtodolarizado
from ods_v.hd_movhomebankingtransaccion t
left join ods_v.hd_tipocambiosaldodiario tc on t.fecdia = tc.fectipcambio and t.codmoneda = tc.codmoneda
where  upper(tipresultadotransaccion) = 'OK' and
t.fecdia between trunc(add_months(sysdate,:intervalo_2),'mm') and trunc(last_day(add_months(sysdate,:intervalo_2))) and
codopehbctr in ('TRAN_N','TRANS_OBCO_L','TRANSEXT','PCRBK_TER','EMIS','D_TRAN','PAMEX_TER','TRAN_OBCO');

truncate table tmp_trx_epic026 ;
insert into tmp_trx_epic026
--create table tmp_trx_epic026 tablespace d_aml_99 as
select periodo,a.fecdia,a.hortransaccion,codopectaorigen,c.codclavecic as codclavecicorigen,c.codunicocli as codunicocliorigen,
trim(apepatcli)||' '||trim(apematcli)||' '||trim(nbrcli) as nombreorigen,codopectadestino,codunicoclibeneficiario, nombrebeneficiario,mtodolarizado from tmp_hb_trx_1 a
left join ods_v.md_cuentag94 b on a.codopectaorigen=b.codopecta
left join ods_v.md_clienteg94 c on b.codclavecic=c.codclavecic;

truncate table tmp_hb_cli;
insert into tmp_hb_cli
--create table tmp_hb_cli tablespace d_aml_99 as
select periodo,c.codclavecic,sum(mtodolarizado) mtodolarizado,sum(ctd_oper) ctd_oper,c.tipper
from tmp_hb_trx a
left join ods_v.md_cuentag94 b on a.codopectaorigen=b.codopecta
left join ods_v.md_clienteg94 c on b.codclavecic=c.codclavecic
where c.codclavecic is not null and c.codclavecic not in (select codclavecic from s55632.rm_cumplimientolistablanca_tmp)
and to_date(to_char(periodo||'01'),'yyyymmdd')=trunc(add_months(sysdate,:intervalo_2),'mm')
group by periodo,c.codclavecic,c.tipper;

commit;
quit;