--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

--tabla sobre escenario de no clientes
drop table tmp_escagente_salida_modelo;

drop table tmp_escagente_acteconomica_nodef;
drop table tmp_escagente_acteconomica_nodef_aux;
drop table tmp_escagente_alertas;
drop table tmp_escagente_antiguedad;
drop table tmp_escagente_archnegativo_solicitantes;
drop table tmp_escagente_cic_empresas;
drop table tmp_escagente_codclavecics_alertas;
drop table tmp_escagente_ctas;
drop table tmp_escagente_ctd_sol_nplsban;
drop table tmp_escagente_eecc_alertas;
drop table tmp_escagente_evals;
drop table tmp_escagente_evals_prop;
drop table tmp_escagente_flg_nplsban;
drop table tmp_escagente_fuera_horario;
drop table tmp_escagente_impac;
drop table tmp_escagente_inicial;
drop table tmp_escagente_lsb_aux2;
drop table tmp_escagente_lsb_solicitantes;
drop table tmp_escagente_np_aux2;
drop table tmp_escagente_np_solicitantes;
drop table tmp_escagente_perfi1;
drop table tmp_escagente_perfi2;
drop table tmp_escagente_perfi3;
drop table tmp_escagente_perfil_mtocashdepo;
drop table tmp_escagente_prom_dias_depo;
drop table tmp_escagente_prom_dias_ret;
drop table tmp_escagente_rel_empresas;
drop table tmp_escagente_rel_empresas_final;
drop table tmp_escagente_sapyc;
drop table tmp_escagente_saving;
drop table tmp_escagente_solicitantes;
drop table tmp_escagente_tablon;
drop table tmp_escagente_trx;
drop table tmp_escagente_trx_1;
drop table tmp_escagente_trx_alertas;
drop table tmp_escagente_trx_alertas_dataagente;
drop table tmp_escagente_trx_aux;
drop table tmp_escagente_varagrupadas;
drop table tmp_escagente_zonazaed;

commit;
quit;