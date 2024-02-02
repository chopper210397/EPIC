--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

create table tmp_ingcashbcacei_outputmodel
(
periodo number,
codclavecic number,
mto_ingreso number,
num_ingreso number,
antiguedadcliente number,
mto_ctas_recientes number,
por_cash number,
flg_perfil number,
flg_an_lsb_np number,
flg_act_eco number,
ctd_dias_debajolava02 number,
porc_cash_mesanterior number,
flg_rel_an_lsb_np number,
flg_acteco_plaft number,
flg_marcasensible_plaft number,
outlier number
)tablespace d_aml_99;

commit;
quit;