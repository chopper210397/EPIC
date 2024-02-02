--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

--tabla salida gremio
create table tmp_grm_salida_modelo
(
codmes	number,
codclavecic	number,
ratio_no_total_sf_hab number,
variacio_1m_total_deuda	number,
outlier number
) tablespace d_aml_99 ;

commit;
quit;