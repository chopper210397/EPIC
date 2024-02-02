--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

--tabla sobre escenario de agentes
create table tmp_clinuevo_salida_modelo
(	periodo number,
	codclavecic number,
	antiguedadcli number,
	mto_total_cash number,
	ctd_total_cash number,
	mto_total number,
	ctdchqgen number,
	mto_chqgen number,
	mto_total_cash_zaed number,
	ctd_cash_zaed number,
	edad number,
	tipbanca varchar2(1),
	destipbanca varchar2(32),
	codpaisnacionalidad varchar2(5),
	nombrepais varchar2(128),
	flgnacionalidad number,
	ctdagentes number,
	flgagente number,
	flgchqgen number,
	porc_chqgen number,
	ctd_dias_debajolava number,
	outlier number
) tablespace d_aml_99 ;

commit;
quit;