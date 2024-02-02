--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

drop table tmp_ingrestrc_trxs_ggtt;
drop table tmp_ingrestrc_trxs_remit;
drop table tmp_ingrestrc_trxs_total;
drop table tmp_ingrestrc_trxs_total_vf;
drop table tmp_ingrestrc_universo_cli;

--variables
drop table tmp_ingrestrc_edad;
drop table tmp_ingrestrc_tipper;
drop table tmp_ingrestrc_antiguedad;
drop table tmp_ingrestrc_acteconomica_nodef_aux;
drop table tmp_ingrestrc_acteconomica_nodef;
drop table tmp_ingrestrc_np_aux2;
drop table tmp_ingrestrc_np;
drop table tmp_ingrestrc_lsb_aux2;
drop table tmp_ingrestrc_lsb;
drop table tmp_ingrestrc_archnegativo;
drop table tmp_ingrestrc_ctd_nplsb;
drop table tmp_ingrestrc_sapyc;
drop table tmp_ingrestrc_evals;
drop table tmp_ingrestrc_segmento;
drop table tmp_ingrestrc_lugarresidencia_aux2;
drop table tmp_ingrestrc_lugarresidencia;
drop table tmp_ingrestrc_nacionalidad;
drop table tmp_ingrestrc_varcomportamiento;
drop table tmp_ingrestrc_perfi1;
drop table tmp_ingrestrc_perfi2;
drop table tmp_ingrestrc_perfi3;
drop table tmp_ingrestrc_perfilingresos;
drop table tmp_ingrestrc_mtosredondos;
drop table tmpctds;
drop table tmpctdsmax;
drop table tmpctdsycdtsmax;
drop table tmpmaxsnorepetidos;
drop table tmpmaxsrepetidos;
drop table tmpmaxsrepetidosunicos;
drop table tmpclientesmtosmaximosunicos;
drop table tmp_ingrestrc_mtosmaximosrepetidos_aux;
drop table tmp_ingrestrc_mtosmaximosrepetidos;
drop table tmp_ingrestrc_mtosyctdsproximos_aux;
drop table tmp_ingrestrc_mtosyctdsproximos;
drop table tmp_ingrestrc_mtosyctdsproximos_tablon;

--02_models: Salidas del modelo
drop table tmp_ingresotrc_salida_modelopj;
drop table tmp_ingresotrc_salida_modelopn;

--03_deploy/packages_adhoc
drop table tmp_ingresotrc_alertaspj;
drop table tmp_trx_epic024_pj;
drop table tmp_ingresotrc_alertaspn;
drop table tmp_trx_epic024_pn;

--03 deploy/deploy
drop table epic024_pj;
drop table epic024_pn;

commit;
quit;