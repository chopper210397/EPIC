--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

create table tmp_esting_gremio
(	codclavecic number
)  tablespace d_aml_99;

create table tmp_esting_segmentobanca
(	codsubsegmento char(3) not null enable,
dessubsegmento varchar2(40),
codsegmento char(3),
dessegmento varchar2(35)
)  tablespace d_aml_99;

create table tmp_esting_universo_00
(	codclavecic number,
tipper char(1)
)  tablespace d_aml_99;

create table tmp_esting_universo
(	codclavecic number,
tipper char(1)
)  tablespace d_aml_99;

create table tmp_esting_univctasclie
(	codclavecic number,
tipper char(1),
codclaveopecta number not null enable,
codopecta char(20)
)  tablespace d_aml_99;

create table tmp_esting_agen_ben
(	codclaveopectacargo number,
codunicocli char(13),
codclaveopectaabono number,
fecdia date,
hortransaccion char(6),
codmoneda char(4),
mtotransaccion number(16,4),
tiptransaccionagenteviabcp char(2),
codagenteviabcp char(7),
codclavecic_ben number,
codopecta_ben char(20)
)  tablespace d_aml_99;

    create table tmp_esting_agen_sol
(	codclavecic_sol number,
codopecta_sol varchar2(20),
codclavecic_ben number,
codopecta_ben char(20),
fecdia date,
hortransaccion char(6),
codmoneda char(4),
mtotransaccion number(16,4),
tiptransaccionagenteviabcp char(2),
codagenteviabcp char(7)
)  tablespace d_aml_99;

create table tmp_esting_trx_agente
(	codclavecic_sol number,
codopecta_sol varchar2(20),
codclavecic_ben number,
codopecta_ben char(20),
fecdia date,
hortransaccion char(6),
codmoneda char(4),
mtotransaccion number(16,4),
mto_dolarizado number,
tipo_transaccion varchar2(70),
canal char(6),
codpaisorigen char(1)
)  tablespace d_aml_99;

create table tmp_esting_remittance_ben
(	codclavecic_sol number,
codclaveopectaafectada number not null enable,
fecdia date not null enable,
hortransaccion char(6) not null enable,
codmoneda char(4),
mtotransaccion number(16,2),
codproducto char(6),
mtotransacciondol number(16,2),
codpaisorigen char(3),
codclavecic_ben number,
codopecta_ben char(20)
)  tablespace d_aml_99;

create table tmp_esting_trx_remittance
(	codclavecic_sol number,
codopecta_sol char(9),
codclavecic_ben number,
codopecta_ben char(20),
fecdia date not null enable,
hortransaccion char(6) not null enable,
codmoneda char(4),
mtotransaccion number(16,2),
mto_dolarizado number(16,2),
tipo_transaccion char(40),
canal char(10),
codpaisorigen varchar2(100)
)  tablespace d_aml_99;

create table tmp_esting_cajero_ben
(	codopectadesde char(20),
codclavecic number,
codopectahacia char(20),
fecdia date not null enable,
hortransaccion char(6) not null enable,
codmoneda char(4),
mtotransaccion number,
codtrancajero char(2),
mtotransaccionsol number(16,2),
mtotransaccionme number(16,2),
codcajero char(7) not null enable,
codclavecic_ben number,
codopecta_ben char(20)
)  tablespace d_aml_99;

create table tmp_esting_cajero_sol
(	codclavecic_sol number,
codopecta_sol varchar2(20),
codclavecic_ben number,
codopecta_ben char(20),
fecdia date,
hortransaccion char(6),
codmoneda char(4),
mtotransaccion number,
codtrancajero char(2),
mtotransaccionsol number(16,2),
mtotransaccionme number(16,2),
codcajero char(7)
)  tablespace d_aml_99;

create table tmp_esting_trx_cajero
(	codclavecic_sol number,
codopecta_sol varchar2(20),
codclavecic_ben number,
codopecta_ben char(20),
fecdia date,
hortransaccion char(6),
codmoneda char(4),
mtotransaccion number,
mto_dolarizado number,
tipo_transaccion varchar2(30),
canal char(6),
codpaisorigen char(1)
)  tablespace d_aml_99;

create table tmp_esting_hm_ben
(	codopectaorigen char(20),
codopectadestino char(20),
fecdia date not null enable,
hortransaccion char(6) not null enable,
codmoneda char(4),
mtotransaccion number(16,2),
codopehbctr char(15),
codclavecic_ben number,
codopecta_ben char(20)
)  tablespace d_aml_99;

create table tmp_esting_trx_hm
(	codclavecic_sol number,
codopecta_sol char(20),
codclavecic_ben number,
codopecta_ben char(20),
fecdia date not null enable,
hortransaccion char(6) not null enable,
codmoneda char(4),
mtotransaccion number(16,2),
mto_dolarizado number,
tipo_transaccion varchar2(50),
canal char(11),
codpaisorigen char(1)
)  tablespace d_aml_99;

create table tmp_esting_vent_ben_1
(	codclaveopecta number,
codclaveopectadestino number,
fecdia date not null enable,
hortransaccion char(8) not null enable,
codmoneda char(4),
codsucage char(6) not null enable,
codsesion number not null enable,
mtotransaccion number(16,2),
codtransaccionventanilla number not null enable,
codclavecic_ben number,
codopecta_ben char(20)
)  tablespace d_aml_99;

create table tmp_esting_vent_ben_2
(	codclaveopecta number,
codclaveopectadestino number,
fecdia date not null enable,
hortransaccion char(8) not null enable,
codmoneda char(4),
codsucage char(6) not null enable,
codsesion number not null enable,
mtotransaccion number(16,2),
codtransaccionventanilla number not null enable,
codclavecic_ben number,
codopecta_ben char(20)
)  tablespace d_aml_99;

create table tmp_esting_vent_ben_3
(	codclaveopecta number,
codclaveopectadestino number,
fecdia date not null enable,
hortransaccion char(8) not null enable,
codmoneda char(4),
codsucage char(6) not null enable,
codsesion number not null enable,
mtotransaccion number(16,2),
codtransaccionventanilla number not null enable,
codclavecic_ben number,
codopecta_ben char(20)
)  tablespace d_aml_99;

create table tmp_esting_vent_ben_4
(	codclaveopecta number,
codclaveopectadestino number,
fecdia date not null enable,
hortransaccion char(8) not null enable,
codmoneda char(4),
codsucage char(6) not null enable,
codsesion number not null enable,
mtotransaccion number(16,2),
codtransaccionventanilla number not null enable,
codclavecic_ben number,
codopecta_ben char(20)
)  tablespace d_aml_99;

create table tmp_esting_vent_ben_5
(	codclaveopecta number,
codclaveopectadestino number,
fecdia date not null enable,
hortransaccion char(8) not null enable,
codmoneda char(4),
codsucage char(6) not null enable,
codsesion number not null enable,
mtotransaccion number(16,2),
codtransaccionventanilla number not null enable,
codclavecic_ben number,
codopecta_ben char(20)
)  tablespace d_aml_99;

create table tmp_esting_vent_ben_6
(	codclaveopecta number,
codclaveopectadestino number,
fecdia date not null enable,
hortransaccion char(8) not null enable,
codmoneda char(4),
codsucage char(6) not null enable,
codsesion number not null enable,
mtotransaccion number(16,2),
codtransaccionventanilla number not null enable,
codclavecic_ben number,
codopecta_ben char(20)
)  tablespace d_aml_99;

create table tmp_esting_vent_ben
(	codclaveopecta number,
codclaveopectadestino number,
fecdia date not null enable,
hortransaccion char(8) not null enable,
codmoneda char(4),
codsucage char(6) not null enable,
codsesion number not null enable,
mtotransaccion number(16,2),
codtransaccionventanilla number not null enable,
codclavecic_ben number,
codopecta_ben char(20)
)  tablespace d_aml_99;

create table tmp_esting_ventanilla_sol
(	codclavecic_sol number,
codopecta_sol varchar2(20),
codclavecic_ben number,
codopecta_ben char(20),
fecdia date,
hortransaccion char(8),
codmoneda char(4),
mtotransaccion number(16,2),
codtransaccionventanilla number,
codsucage char(6)
)  tablespace d_aml_99;

create table tmp_esting_trx_ventanilla
(	codclavecic_sol number,
codopecta_sol varchar2(20),
codclavecic_ben number,
codopecta_ben char(20),
fecdia date,
hortransaccion char(8),
codmoneda char(4),
mtotransaccion number(16,2),
mto_dolarizado number,
tipo_transaccion varchar2(65),
canal char(10),
codpaisorigen char(1)
)  tablespace d_aml_99;

create table tmp_esting_telcre_ben
(	codopecta char(20),
codopectaabono char(20),
fecdia date,
hortransaccion char(4),
codmoneda char(4),
mtotransaccion number(20,4),
tipoperaciontelcre char(6),
codclavecic_ben number,
codopecta_ben char(20)
)  tablespace d_aml_99;

create table tmp_esting_trx_telcre
(	codclavecic_sol number,
codopecta_sol char(20),
codclavecic_ben number,
codopecta_ben char(20),
fecdia date,
hortransaccion char(4),
codmoneda char(4),
mtotransaccion number(20,4),
mto_dolarizado number,
tipo_transaccion varchar2(60),
canal char(11),
codpaisorigen char(1)
)  tablespace d_aml_99;

create table tmp_esting_ggtt_ben
(	codclavecicsolicitante number,
codclavecicbeneficiario number,
fecdia date not null enable,
horemision char(8),
codmoneda char(4),
mtoimporteoperacion number(16,2),
codproducto char(6),
codswiftbcodestino char(11),
codswiftbcoemisor char(11),
codclavecic_ben number,
codopecta_ben char(9)
)  tablespace d_aml_99;

create table tmp_esting_trx_ggtt
(	codclavecic_sol number,
codopecta_sol char(9),
codclavecic_ben number,
codopecta_ben char(9),
fecdia date not null enable,
hortransaccion char(8),
codmoneda char(4),
mtotransaccion number(16,2),
mto_dolarizado number,
tipo_transaccion char(40),
canal char(14),
codpaisorigen varchar2(100)
)  tablespace d_aml_99;

create table tmp_esting_bancamovil_ben
(	codclaveopectaorigen number,
codclaveopectadestino number,
fecdia date,
hortransaccion varchar2(6),
codmoneda varchar2(4),
mtotransaccion number,
tiptransaccionbcamovil number,
codclavecic_ben number,
codopecta_ben char(20)
)  tablespace d_aml_99;

create table tmp_esting_trx_bancamovil
(	codclavecic_sol number,
codopecta_sol char(20),
codclavecic_ben number,
codopecta_ben char(20),
fecdia date,
hortransaccion varchar2(6),
codmoneda varchar2(4),
mtotransaccion number,
mto_dolarizado number,
tipo_transaccion varchar2(100),
canal char(11),
codpaisorigen char(1)
)  tablespace d_aml_99;

create table tmp_esting_trx
(	codclavecic_sol number,
codopecta_sol varchar2(20),
codclavecic_ben number,
codopecta_ben varchar2(20),
fecdia date,
hortransaccion varchar2(8),
codmoneda varchar2(4),
mtotransaccion number,
mto_dolarizado number,
tipo_transaccion varchar2(100),
canal varchar2(14),
codpaisorigen varchar2(100)
)  tablespace d_aml_99;

create table tmp_esting_banca_estimador
(	codmes number not null enable,
codclavecic number,
mto_estimador number(16,2),
cod_estimador char(4)
)  tablespace d_aml_99;

create table tmp_esting_banca_no_definidas
(	codacteconomica char(4),
desacteconomica varchar2(50),
busq varchar2(12)
)  tablespace d_aml_99;

create table tmp_esting_banca_acteco
(	codclavecic number,
tipper char(1),
flg_act_eco number
)  tablespace d_aml_99;

create table tmp_esting_banca_profesion
(	codclavecic number,
flg_act_eco number,
codprofesion char(5),
descodprofesion varchar2(40),
flg_prof number
)  tablespace d_aml_99;

create table tmp_esting_sapyc
(	idcaso number,
codclavecic number,
idresultadoeval number,
fecfineval timestamp (6),
idresultadosupervisor number
)  tablespace d_aml_99;

create table tmp_esting_evals
(	codmes number not null enable,
codclavecic number,
mto_estimador number(16,2),
cod_estimador char(4),
ctdeval number
)  tablespace d_aml_99;

create table tmp_esting_ingresos
(	periodo number,
codclavecic_ben number,
mto_ingreso number,
ctd_ingreso number
)  tablespace d_aml_99;

create table tmp_esting_perfi1
(	codclavecic_ben number,
numperiodo number,
periodo number,
meses number,
mto_ingreso number
)  tablespace d_aml_99;

create table tmp_esting_perfi2
(	numperiodo number,
codclavecic_ben number,
mto_ingreso number
)  tablespace d_aml_99;

create table tmp_esting_perfi3
(	numperiodo number,
codclavecic_ben number,
mto_ingreso number,
media_depo number,
desv_depo number
)  tablespace d_aml_99;

create table tmp_esting_perfilingresos
(	periodo number,
codclavecic_ben number,
ctd_ingreso number,
mto_ingreso number,
flg_perfil_depositos_3ds number
)  tablespace d_aml_99;

create table tmp_esting_tipocambio
(	codmoneda char(4),
mtocambioalnuevosol number(16,6),
mtocambioaldolar number(16,6),
fectipcambio date,
numperiodo number,
col number
)  tablespace d_aml_99;

create table tmp_esting_tablon
(	codmes number not null enable,
codclavecic number,
mto_estimador number,
ctdeval number,
ctd_ingreso number,
mto_ingreso number,
flg_perfil_depositos_3ds number
)  tablespace d_aml_99;

create table tmp_esting_salida_modelo
(	periodo	number,
codclavecic	number,
ratio number,
mto_estimador number,
ctdeval number,
ctd_ingreso number,
mto_ingreso number,
flg_perfil_depositos_3ds number,
outlier number
) tablespace d_aml_99 ;

create table tmp_esting_alertas
(	codmes number not null enable,
codclavecic number,
mto_estimador number,
ctdeval number,
ctd_ingreso number,
mto_ingreso number,
flg_perfil_depositos_3ds number,
codunicocli char(13),
nbr_cli varchar2(75)
)  tablespace d_aml_99;

create table tmp_trx_epic030 
   (	codclavecic_sol number, 
	codunicocli_sol char(13), 
	nombre_sol varchar2(77), 
	codopecta_sol varchar2(20), 
	codclavecic_ben number, 
	codunicocli_ben char(13), 
	nombre_ben varchar2(77), 
	codopecta_ben varchar2(20), 
	fecdia date, 
	hortransaccion varchar2(8), 
	codmoneda varchar2(4), 
	mtotransaccion number, 
	mto_dolarizado number, 
	tipo_transaccion varchar2(100), 
	canal varchar2(14), 
	codpaisorigen varchar2(100)
   ) tablespace d_aml_99;

create table tmp_esting_trx_alertas
(	codclavecic_sol number,
codunicocli_sol char(13),
nbr_cli_sol varchar2(75),
codclavecic_ben number,
codunicocli_ben char(13),
nbr_cli_ben varchar2(75),
fecdia date,
hortransaccion varchar2(8),
codmoneda varchar2(4),
mtotransaccion number,
mto_dolarizado number,
tipo_transaccion varchar2(100),
canal varchar2(14),
codpaisorigen varchar2(100)
)  tablespace d_aml_99;

drop table epic030;

create table epic030
(	fecgeneracion date,
idorigen number,
codunicocli char(13),
escenario char(7),
desescenario char(41),
periodo char(10),
triggering number,
comentario varchar2(649)
)  tablespace d_aml_99;

create table epic030_doc
(	ruta char(200),
nbrdocumento char(45),
codunicocli char(13),
fecregistro date,
numcaso char(1),
idanalista number
)  tablespace d_aml_99;

commit;
quit;
