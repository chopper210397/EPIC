--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

--tabla sobre escenario de cv me
create table tmp_cvme_salida_modelo
(	periodo number,
	codclavecic number,
	edad number,
	tipper varchar2(10),
	codprofesion varchar2(10),
	descodprofesion varchar2(100),
	catprofesion number,
	fecapertura date,
	antiguedad number,
	tipcli varchar2(10),
	codsubsegmento varchar2(10),
	dessubsegmento varchar2(100),
	codsegmento varchar2(10),
	dessegmento varchar2(100),
	flgnocliente number,
	codacteconomica varchar2(10),
	desacteconomica varchar2(100),
	flg_acteco_nodef number,
	flgnp number,
	ctdnp number,
	flglsb number,
	ctdlsb number,
	flgarchivonegativo number,
	destipmotivonegativo varchar2(100),
	flgnplsban number,
	ctd_an_np_lsb number,
	ctdeval number,
	ctd_ordenates_distintos number,
	mto_total number,
	mto_compra number,
	mto_venta number,
	ctd_total number,
	ctd_compra number,
	ctd_venta number,
	mto_zaed number,
	ctd_zaed number,
	ctd_dias number,
	mto_depositos number,
	flg_perfil_depositos_3ds number,
	ctd_trx_lim number,
	outlier number
) tablespace d_aml_99 ;

commit;
quit;