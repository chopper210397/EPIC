--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

create table tmp_hb_salidamodelo
(
periodo number,
codclavecic number,
tipper char(1),
flgarchivonegativo number,
mtodolarizado number,
paisriesgo_monto number,
ctd_beneficiario number,
ctdeval number,
indice_concentrador	number,
ratio number,
outlier number
) tablespace d_aml_99;

commit;
quit;