--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

drop table tmp_esting_gremio;
drop table tmp_esting_segmentobanca;
drop table tmp_esting_universo_00;
drop table tmp_esting_universo;
drop table tmp_esting_univctasclie;
drop table tmp_esting_agen_ben;
drop table tmp_esting_agen_sol;
drop table tmp_esting_trx_agente;
drop table tmp_esting_remittance_ben;
drop table tmp_esting_trx_remittance;
drop table tmp_esting_cajero_ben;
drop table tmp_esting_cajero_sol;
drop table tmp_esting_trx_cajero;
drop table tmp_esting_hm_ben;
drop table tmp_esting_trx_hm;
drop table tmp_esting_vent_ben;
drop table tmp_esting_ventanilla_sol;
drop table tmp_esting_trx_ventanilla;
drop table tmp_esting_telcre_ben;
drop table tmp_esting_trx_telcre;
drop table tmp_esting_ggtt_ben;
drop table tmp_esting_trx_ggtt;
drop table tmp_esting_bancamovil_ben;
drop table tmp_esting_trx_bancamovil;
drop table tmp_esting_trx;
drop table tmp_esting_banca_estimador;
drop table tmp_esting_banca_no_definidas;
drop table tmp_esting_banca_acteco;
drop table tmp_esting_banca_profesion;
drop table tmp_esting_sapyc;
drop table tmp_esting_evals;
drop table tmp_esting_ingresos;
drop table tmp_esting_perfi1;
drop table tmp_esting_perfi2;
drop table tmp_esting_perfi3;
drop table tmp_esting_perfilingresos;
drop table tmp_esting_tipocambio;
drop table tmp_esting_tablon;
drop table tmp_esting_salida_modelo;
drop table tmp_esting_alertas;
drop table tmp_trx_epic030;
drop table tmp_esting_trx_alertas;
drop table epic030_doc;

commit;
quit;