--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;


create table tmp_yape_universo 
   (	codmes_operacion number, 
	codclavecic number, 
	codclaveopecta_destino number
   ) tablespace d_aml_99;

create table tmp_yape_trx_ingreso_aux_01 
   (	codmes_operacion number, 
	codclavecic number, 
	monto_ingreso number
   ) tablespace d_aml_99;

create table tmp_yape_trx_ingreso_aux_02
   (	codmes_operacion number, 
	codclavecic number, 
	monto_ingreso number
   ) tablespace d_aml_99;

create table tmp_yape_trx_ingreso_aux_03 
   (	codmes_operacion number, 
	codclavecic number, 
	monto_ingreso number
   ) tablespace d_aml_99;

create table tmp_yape_trx_ingreso_aux_04 
   (	codmes_operacion number, 
	codclavecic number, 
	monto_ingreso number
   ) tablespace d_aml_99;

create table tmp_yape_trx_ingreso_aux_05
   (	codmes_operacion number, 
	codclavecic number, 
	monto_ingreso number
   ) tablespace d_aml_99;

create table tmp_yape_trx_ingreso_aux_06
   (	codmes_operacion number, 
	codclavecic number, 
	monto_ingreso number
   ) tablespace d_aml_99;

create table tmp_yape_trx_ingreso_ 
   (	codmes_operacion number, 
	codclavecic number, 
	monto_ingreso number
   ) tablespace d_aml_99;

create table tmp_yape_trx_egreso_aux_01 
   (	codmes_operacion number, 
	codclavecic number, 
	hora varchar2(6), 
	mto_operacion number, 
	dia_operacion date, 
	codclavecic_egr number
   ) tablespace d_aml_99;

create table tmp_yape_trx_egreso_aux_02
   (	codmes_operacion number, 
	codclavecic number, 
	hora varchar2(6), 
	mto_operacion number, 
	dia_operacion date, 
	codclavecic_egr number
   ) tablespace d_aml_99;

create table tmp_yape_trx_egreso_aux_03
   (	codmes_operacion number, 
	codclavecic number, 
	hora varchar2(6), 
	mto_operacion number, 
	dia_operacion date, 
	codclavecic_egr number
   ) tablespace d_aml_99;

create table tmp_yape_trx_egreso_aux_04
   (	codmes_operacion number, 
	codclavecic number, 
	hora varchar2(6), 
	mto_operacion number, 
	dia_operacion date, 
	codclavecic_egr number
   ) tablespace d_aml_99;

create table tmp_yape_trx_egreso_aux_05 
   (	codmes_operacion number, 
	codclavecic number, 
	hora varchar2(6), 
	mto_operacion number, 
	dia_operacion date, 
	codclavecic_egr number
   ) tablespace d_aml_99;

create table tmp_yape_trx_egreso_aux_06
   (	codmes_operacion number, 
	codclavecic number, 
	hora varchar2(6), 
	mto_operacion number, 
	dia_operacion date, 
	codclavecic_egr number
   ) tablespace d_aml_99;

create table tmp_yape_trx_egreso_
   (	codmes_operacion number, 
	codclavecic number, 
	hora varchar2(6), 
	mto_operacion number, 
	dia_operacion date, 
	codclavecic_egr number
   ) tablespace d_aml_99;

create table tmp_yape_prepep 
   (	codmes_operacion number, 
	codclavecic number, 
	hora varchar2(6), 
	monto_ingreso number, 
	dia_operacion date, 
	codclavecic_origen number, 
	tip_cuenta_destino varchar2(9)
   ) tablespace d_aml_99;

create table tmp_yape_pep 
   (	codmes_operacion number, 
	codclavecic number, 
	monto_ingreso number, 
	ctd_ingreso number, 
	mto_egr number, 
	ctd_egreso number, 
	flg_pep number, 
	flg_pep_rel number, 
	tipper char(1)
   ) tablespace d_aml_99;

create table tmp_yape_acteco_no_definidas 
   (	codacteconomica char(4), 
	desacteconomica varchar2(50), 
	busq varchar2(12)
   ) tablespace d_aml_99;

create table tmp_yape_actecocli 
   (	codmes_operacion number, 
	codclavecic number, 
	monto_ingreso number, 
	ctd_ingreso number, 
	mto_egr number, 
	ctd_egreso number, 
	flg_pep number, 
	flg_pep_rel number, 
	tipper char(1), 
	act_economica_gruposinteres number
   ) tablespace d_aml_99;

create table tmp_yape_profesion 
   (	codmes_operacion number, 
	codclavecic number, 
	monto_ingreso number, 
	ctd_ingreso number, 
	mto_egr number, 
	ctd_egreso number, 
	flg_pep number, 
	flg_pep_rel number, 
	tipper char(1), 
	act_economica_gruposinteres number, 
	codprofesion char(5), 
	descodprofesion varchar2(40), 
	catprofesion number
   ) tablespace d_aml_99;

create table tmp_md_historia
   (
	codclavecic number,
	fecapertura date
   ) tablespace d_aml_99;
   
create table tmp_yape_antiguedad 
   (	codmes_operacion number, 
	codclavecic number, 
	monto_ingreso number, 
	ctd_ingreso number, 
	mto_egr number, 
	ctd_egreso number, 
	flg_pep number, 
	flg_pep_rel number, 
	tipper char(1), 
	act_economica_gruposinteres number, 
	codprofesion char(5), 
	descodprofesion varchar2(40), 
	catprofesion number, 
	fecapertura date, 
	antiguedad number
   ) tablespace d_aml_99;

create table tmp_yape_np_aux2 
   (	codmes_operacion number, 
	codclavecic number, 
	ctdnp number
   ) tablespace d_aml_99;

create table tmp_yape_np 
   (	codclavecic number, 
	codmes_operacion number, 
	act_economica_gruposinteres number, 
	flgnp number, 
	ctdnp number
   ) tablespace d_aml_99;

create table tmp_yape_lsb_aux2 
   (	codmes_operacion number, 
	codclavecic number, 
	ctdlsb number
   ) tablespace d_aml_99;

create table tmp_yape_lsb 
   (	codclavecic number, 
	codmes_operacion number, 
	act_economica_gruposinteres number, 
	flgnp number, 
	ctdnp number, 
	flglsb number, 
	ctdlsb number
   ) tablespace d_aml_99;

create table tmp_yape_archnegativo 
   (	codclavecic number, 
	codmes_operacion number, 
	act_economica_gruposinteres number, 
	flgnp number, 
	ctdnp number, 
	flglsb number, 
	ctdlsb number, 
	flgarchivonegativo number, 
	destipmotivonegativo varchar2(35)
   ) tablespace d_aml_99;

create table tmp_yape_flg_ctd_nplsban 
   (	codclavecic number, 
	codmes_operacion number, 
	act_economica_gruposinteres number, 
	flgnp number, 
	ctdnp number, 
	flglsb number, 
	ctdlsb number, 
	flgarchivonegativo number, 
	destipmotivonegativo varchar2(35), 
	flgnplsban number, 
	ctd_an_np_lsb number
   ) tablespace d_aml_99;

create table tmp_yape_antcta 
   (	codclavecic number, 
	codmes_operacion number, 
	act_economica_gruposinteres number, 
	flgnp number, 
	ctdnp number, 
	flglsb number, 
	ctdlsb number, 
	flgarchivonegativo number, 
	destipmotivonegativo varchar2(35), 
	flgnplsban number, 
	ctd_an_np_lsb number, 
	tip_cta varchar2(13), 
	antiguedad_yape number
   ) tablespace d_aml_99;

create table tmp_yape_tipocuenta 
   (	codclavecic number, 
	flg_cuenta_bcp number, 
	flg_cuenta_otrosbancos number, 
	flg_cuenta_yapecard number
   ) tablespace d_aml_99;

create table tmp_yape_ord 
   (	codmes_operacion number, 
	codclavecic number, 
	ctd_ope_dist_ing number
   ) tablespace d_aml_99;

create table tmp_yape_sol 
   (	codmes_operacion number, 
	codclavecic number, 
	ctd_ope_dist_egr number
   ) tablespace d_aml_99;

create table tmp_yape_perfi1 
   (	codclavecic number, 
	numperiodo number, 
	codmes_operacion number, 
	meses number, 
	mtodolarizado number
   ) tablespace d_aml_99;

create table tmp_yape_perfi2 
   (	numperiodo number, 
	codclavecic number, 
	mtodolarizado number
   ) tablespace d_aml_99;

create table tmp_yape_perfi3 
   (	numperiodo number, 
	codclavecic number, 
	mtodolarizado number, 
	media_depo number, 
	desv_depo number
   ) tablespace d_aml_99;

create table tmp_yape_perfildepositos 
   (	codclavecic number, 
	codmes_operacion number, 
	act_economica_gruposinteres number, 
	flgnp number, 
	ctdnp number, 
	flglsb number, 
	ctdlsb number, 
	flgarchivonegativo number, 
	destipmotivonegativo varchar2(35), 
	flgnplsban number, 
	ctd_an_np_lsb number, 
	flg_perfil_3ds number
   ) tablespace d_aml_99;

create table tmp_yape_ctdalertas 
   (	codclavecic number, 
	periodo number, 
	ctd_alertas_prev number
   ) tablespace d_aml_99;

create table tmp_yape_policias 
   (	codclavecic number
   ) tablespace d_aml_99;

create table tmp_yape_flgpolicia 
   (	codclavecic number, 
	codmes_operacion number, 
	act_economica_gruposinteres number, 
	flgnp number, 
	ctdnp number, 
	flglsb number, 
	ctdlsb number, 
	flgarchivonegativo number, 
	destipmotivonegativo varchar2(35), 
	flgnplsban number, 
	ctd_an_np_lsb number, 
	flg_perfil_3ds number, 
	flg_policia number
   ) tablespace d_aml_99;

create table tmp_yape_antyape 
   (	codclavecic number, 
	codmes_operacion number, 
	act_economica_gruposinteres number, 
	flgnp number, 
	ctdnp number, 
	flglsb number, 
	ctdlsb number, 
	flgarchivonegativo number, 
	destipmotivonegativo varchar2(35), 
	flgnplsban number, 
	ctd_an_np_lsb number, 
	flg_perfil_3ds number, 
	flg_policia number, 
	ant_yape number
   ) tablespace d_aml_99;

create table tmp_yape_tablonfinal 
   (	codclavecic number, 
	codmes_operacion number, 
	act_economica_gruposinteres number, 
	flgnp number, 
	ctdnp number, 
	flglsb number, 
	ctdlsb number, 
	flgarchivonegativo number, 
	destipmotivonegativo varchar2(35), 
	flgnplsban number, 
	ctd_an_np_lsb number, 
	flg_perfil_3ds number, 
	flg_policia number, 
	ant_yape number, 
	monto_ingreso number, 
	ctd_ingreso number, 
	mto_egr number, 
	ctd_egreso number, 
	flg_pep number, 
	flg_pep_rel number, 
	tipper char(1), 
	codprofesion char(5), 
	descodprofesion varchar2(40), 
	catprofesion number, 
	flg_cuenta_yapecard number, 
	ctd_ope_dist_ing number, 
	antiguedad number, 
	ctd_ope_dist_egr number, 
	ctd_alertas_prev number
   ) tablespace d_aml_99;

create table tmp_yape_salida_modelo
	(	codmes_operacion number,
codclavecic number,
monto_ingreso number,
ctd_ingreso number,
mto_egr number,
ctd_egreso number,
flg_pep number,
flg_pep_rel number,
tipper	char(1),
act_economica_gruposinteres number,
codprofesion char(5),
catprofesion number,
antiguedad number,
flgnp number,
ctdnp number,
flglsb number,
ctdlsb number,
flgarchivonegativo number,
flgnplsban number,
ctd_an_np_lsb number,
flg_perfil_3ds number,
flg_policia number,
ant_yape number,
flg_cuenta_yapecard number,
ctd_ope_dist_ing number,
ctd_ope_dist_egr number,
ctd_alertas_prev number,
flg_pep_tot number,
outlier number
) tablespace d_aml_99 ;

create table tmp_yape_salida_modelopol
	(	codmes_operacion number,
codclavecic number,
monto_ingreso number,
ctd_ingreso number,
mto_egr number,
ctd_egreso number,
flg_pep number,
flg_pep_rel number,
tipper	char(1),
act_economica_gruposinteres number,
codprofesion char(5),
catprofesion number,
antiguedad number,
flgnp number,
ctdnp number,
flglsb number,
ctdlsb number,
flgarchivonegativo number,
flgnplsban number,
ctd_an_np_lsb number,
flg_perfil_3ds number,
flg_policia number,
ant_yape number,
flg_cuenta_yapecard number,
ctd_ope_dist_ing number,
ctd_ope_dist_egr number,
ctd_alertas_prev number,
flg_pep_tot number,
outlier number
) tablespace d_aml_99 ;

create table tmp_yape_alertas 
   (	codmes_operacion number, 
	codclavecic number, 
	monto_ingreso number, 
	ctd_ingreso number, 
	mto_egr number, 
	ctd_egreso number, 
	flg_pep number, 
	flg_pep_rel number, 
	tipper char(1), 
	act_economica_gruposinteres number, 
	codprofesion char(5), 
	catprofesion number, 
	antiguedad number, 
	flgnp number, 
	ctdnp number, 
	flglsb number, 
	ctdlsb number, 
	flgarchivonegativo number, 
	flgnplsban number, 
	ctd_an_np_lsb number, 
	flg_perfil_3ds number, 
	flg_policia number, 
	ant_yape number, 
	flg_cuenta_yapecard number, 
	ctd_ope_dist_ing number, 
	ctd_ope_dist_egr number, 
	ctd_alertas_prev number, 
	flg_pep_tot number, 
	outlier number, 
	codunicocli char(13), 
	nbr_beneficiario varchar2(77)
   ) tablespace d_aml_99;

create table tmp_yape_trx_alertas 
   (	codclavecic_ben number, 
	codunicocli_ben char(13), 
	nbr_beneficiario varchar2(77), 
	dia_operacion date, 
	hora varchar2(6), 
	monto_ingreso number, 
	codclavecic_sol number, 
	codunicocli_sol char(13), 
	nbr_solicitante varchar2(77), 
	canal char(4)
   ) tablespace d_aml_99;

drop table epic028;
create table epic028 
   (	fecgeneracion date, 
	idorigen number, 
	codunicocli char(13), 
	escenario char(7), 
	desescenario char(24), 
	periodo char(10), 
	triggering number, 
	comentario varchar2(781)
   ) tablespace d_aml_99;

create table epic028_doc 
   (	ruta char(66), 
	nbrdocumento char(45), 
	codunicocli char(13), 
	fecregistro date, 
	numcaso char(1), 
	idanalista number
   ) tablespace d_aml_99;

commit;
quit;