--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

--tabla sobre escenario de agentes
create table tmp_escagente_salida_modelo
(	periodo number,
	codagenteviabcp varchar2(10),
	codclavecic number,
	codclaveopectaagente number,
	mto_cash_depo number,
	ctd_cash_depo number,
	mto_cash_ret number,
	ctd_cash_ret number,
	ctd_trxs_sinctaagente number,
	fecapertura date,
	antiguedad number,
	codacteconomica varchar2(10),
	desacteconomica varchar2(100),
	flg_acteco_nodef number,
	flg_perfil_cash_depo_3ds number,
	ctd_trxsfuerahorario number,
	prom_depodiarios number,
	ctd_diasdepo number,
	prom_retdiarios number,
	ctd_diasret number,
	codsucage varchar2(10),
	coddepartamento varchar2(10),
	descoddepartamento varchar2(100),
	tipo_zona number,
	ctd_an_np_lsb number,
	mto_an_np_lsb number,
	ctdeval number,
	ctd_evals_prop number,
	flg_zaed number,
	rf_pred number
) tablespace d_aml_99 ;

commit;
quit;