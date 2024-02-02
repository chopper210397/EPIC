--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

drop table tmp_yape_universo;
drop table tmp_yape_trx_ingreso_aux_01;
drop table tmp_yape_trx_ingreso_aux_02;
drop table tmp_yape_trx_ingreso_aux_03;
drop table tmp_yape_trx_ingreso_aux_04;
drop table tmp_yape_trx_ingreso_aux_05;
drop table tmp_yape_trx_ingreso_aux_06;
drop table tmp_yape_trx_ingreso_;
drop table tmp_yape_trx_egreso_aux_01;
drop table tmp_yape_trx_egreso_aux_02;
drop table tmp_yape_trx_egreso_aux_03;
drop table tmp_yape_trx_egreso_aux_04;
drop table tmp_yape_trx_egreso_aux_05;
drop table tmp_yape_trx_egreso_aux_06;
drop table tmp_yape_trx_egreso_;
drop table tmp_yape_prepep;
drop table tmp_yape_pep;
drop table tmp_yape_acteco_no_definidas;
drop table tmp_yape_actecocli;
drop table tmp_yape_profesion;
drop table tmp_md_historia;
drop table tmp_yape_antiguedad;
drop table tmp_yape_np_aux2;
drop table tmp_yape_np;
drop table tmp_yape_lsb_aux2;
drop table tmp_yape_lsb;
drop table tmp_yape_archnegativo;
drop table tmp_yape_flg_ctd_nplsban;
drop table tmp_yape_antcta;
drop table tmp_yape_tipocuenta;
drop table tmp_yape_ord;
drop table tmp_yape_sol;
drop table tmp_yape_perfi1;
drop table tmp_yape_perfi2;
drop table tmp_yape_perfi3;
drop table tmp_yape_perfildepositos;
drop table tmp_yape_ctdalertas;
drop table tmp_yape_policias;
drop table tmp_yape_flgpolicia;
drop table tmp_yape_antyape;
drop table tmp_yape_tablonfinal;
drop table tmp_yape_salida_modelo;
drop table tmp_yape_salida_modelopol;
drop table tmp_yape_alertas;
drop table tmp_yape_trx_alertas;
drop table epic028_doc;

commit;
quit;
