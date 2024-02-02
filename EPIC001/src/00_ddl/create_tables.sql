--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

--tabla sobre escenario de retiros del exterior
create table tmp_retatmext_salida_modelo
(
periodo number,
codclavecic number,
mto_opepos number,
ctd_opepos number,
mto_opeatm number,
ctd_opeatm number,
flg_paisriesgo number,
flg_ecuador number,
mto_total_ope number,
ctd_total_ope number,
outlier number
) tablespace d_aml_99;

commit;
quit;