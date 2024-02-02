--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

drop table tmp_epic032_docggtt;
drop table tmp_epic032_grupos;
drop table tmp_epic032_pre_uncodu;
drop table tmp_epic032_docodu;
drop table tmp_epic032_uncodu;
drop table tmp_epic032_univ_1;
drop table tmp_epic032_univ_2;
drop table tmp_epic032_univ_3;
drop table tmp_epic032_univ;
drop table tmp_epic032_mto_semana;
drop table tmp_epic032_mto_ctd_semanal;
drop table tmp_epic032_monto_total;
drop table tmp_epic032_pre_perfil;
drop table tmp_epic032_perfil;
drop table tmp_epic032_group_perfil;
drop table tmp_epic032_perfil1;
drop table tmp_epic032_fec_perfil;
drop table tmp_epic032_fec_perfil2;
drop table tmp_epic032_ordenantes;
drop table tmp_epic032_extr;
drop table tmp_epic032_ros;
drop table tmp_epic032_pre_lsb;
drop table tmp_epic032_aux_lsb;
drop table tmp_epic032_lsb;
drop table tmp_epic032_pre_np;
drop table tmp_epic032_an;
drop table tmp_epic032_nombre;
drop table tmp_epic032_varfamiliares;
drop table tmp_epic032_cliente;
drop table tmp_epic032_univ_total;
drop table tmp_epic032_outputmodel;
drop table tmp_epic032_alertas;
drop table epic032_doc;

commit;
quit;