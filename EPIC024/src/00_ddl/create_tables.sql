--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

--01_etl
--universo
create table tmp_ingrestrc_trxs_ggtt
(	coddocggtt char(25) not null enable,
numoperacionggtt char(8),
codsucage char(6),
fecdia date not null enable,
fecemision date,
horemision char(8),
codtipestadotransaccion char(2) not null enable,
codproducto char(6),
descodproducto char(40),
codmoneda char(4),
mtoimporteoperacion number(16,2),
mtodolarizado number,
codclavecicsolicitante number,
codclavecicordenante number,
codclavecicbeneficiario number,
codswiftbcoemisor char(11),
nbrpaisorigen varchar2(100),
codswiftbcodestino char(11),
codpaisbcodestino char(3)
) tablespace d_aml_99;

create table tmp_ingrestrc_trxs_remit
(	numoperacionremittance char(6) not null enable,
codsucursal char(3),
fecdia date not null enable,
hortransaccion char(6) not null enable,
codproducto char(6),
descodproducto char(40),
codestadooperemittance char(1),
codmoneda char(4),
mtotransaccion number(16,2),
mtotransacciondol number(16,2),
codpaisorigen char(3),
codswiftinstordenante char(11),
codswiftbcoordenante char(11),
nbrpaisorigen varchar2(100),
codclavecicbeneficiario number not null enable,
codclaveopectabeneficiario number not null enable
) tablespace d_aml_99;

create table tmp_ingrestrc_trxs_total
(	periodo number,
numtrx varchar2(25),
codsucage varchar2(6),
codclavecicordenante number,
codclaveopectaordenante number,
nbrpaisorigen varchar2(100),
fecdia date,
hortransaccion varchar2(8),
codmoneda char(4),
mtotransaccion number(16,2),
mtodolarizado number,
codproducto char(6),
descodproducto char(40),
fuente varchar2(10),
codclavecicbeneficiario number,
codclaveopectabeneficiario number,
bancoemisor char(11)
) tablespace d_aml_99;

create table tmp_ingrestrc_trxs_total_vf
(	periodo number,
numtrx varchar2(25),
codsucage varchar2(6),
codclavecicordenante number,
codclaveopectaordenante number,
nbrpaisorigen varchar2(100),
fecdia date,
hortransaccion varchar2(8),
codmoneda char(4),
mtotransaccion number(16,2),
mtodolarizado number,
codproducto char(6),
descodproducto char(40),
fuente varchar2(10),
codclavecicbeneficiario number,
codclaveopectabeneficiario number,
bancoemisor char(11)
) tablespace d_aml_99 ;

create table tmp_ingrestrc_universo_cli
(	periodo number,
codclavecic number
) tablespace d_aml_99;

--variables
create table tmp_ingrestrc_edad
(	periodo number,
codclavecic number,
edad number
) tablespace d_aml_99;

create table tmp_ingrestrc_tipper
(	periodo number,
codclavecic number,
edad number,
tipper char(1)
) tablespace d_aml_99;

create table tmp_ingrestrc_antiguedad
(	periodo number,
codclavecic number,
edad number,
tipper char(1),
antiguedad number
) tablespace d_aml_99;

create table tmp_ingrestrc_acteconomica_nodef_aux
(	codacteconomica char(4),
desacteconomica varchar2(50),
busq varchar2(12)
) tablespace d_aml_99;

create table tmp_ingrestrc_acteconomica_nodef
(	periodo number,
codclavecic number,
edad number,
tipper char(1),
antiguedad number,
codacteconomica varchar2(4),
desacteconomica varchar2(50),
flg_acteco_nodef number
) tablespace d_aml_99;

create table tmp_ingrestrc_np_aux2
(	periodo number,
codclavecic number,
ctdnp number
) tablespace d_aml_99 ;

create table tmp_ingrestrc_np
(	periodo number,
codclavecic number,
edad number,
tipper char(1),
antiguedad number,
codacteconomica varchar2(4),
desacteconomica varchar2(50),
flg_acteco_nodef number,
flgnp number,
ctdnp number
) tablespace d_aml_99;

create table tmp_ingrestrc_lsb_aux2
(	periodo number,
codclavecic number,
ctdlsb number
) tablespace d_aml_99;

create table tmp_ingrestrc_lsb
(	periodo number,
codclavecic number,
edad number,
tipper char(1),
antiguedad number,
codacteconomica varchar2(4),
desacteconomica varchar2(50),
flg_acteco_nodef number,
flgnp number,
ctdnp number,
flglsb number,
ctdlsb number
) tablespace d_aml_99;

create table tmp_ingrestrc_archnegativo
(	periodo number,
codclavecic number,
edad number,
tipper char(1),
antiguedad number,
codacteconomica varchar2(4),
desacteconomica varchar2(50),
flg_acteco_nodef number,
flgnp number,
ctdnp number,
flglsb number,
ctdlsb number,
flgarchivonegativo number,
destipmotivonegativo varchar2(35)
) tablespace d_aml_99;

create table tmp_ingrestrc_ctd_nplsb
(	periodo number,
codclavecic number,
edad number,
tipper char(1),
antiguedad number,
codacteconomica varchar2(4),
desacteconomica varchar2(50),
flg_acteco_nodef number,
flgnp number,
ctdnp number,
flglsb number,
ctdlsb number,
flgarchivonegativo number,
destipmotivonegativo varchar2(35),
ctd_np_lsb number
) tablespace d_aml_99;

create table tmp_ingrestrc_sapyc
(	idcaso number,
codclavecic number,
idresultadoeval number,
fecfineval timestamp (6),
idresultadosupervisor number
) tablespace d_aml_99;

create table tmp_ingrestrc_evals
(	periodo number,
codclavecic number,
edad number,
tipper char(1),
antiguedad number,
codacteconomica varchar2(4),
desacteconomica varchar2(50),
flg_acteco_nodef number,
flgnp number,
ctdnp number,
flglsb number,
ctdlsb number,
flgarchivonegativo number,
destipmotivonegativo varchar2(35),
ctd_np_lsb number,
ctdeval number
) tablespace d_aml_99;

create table tmp_ingrestrc_segmento
(	periodo number,
codclavecic number,
edad number,
tipper char(1),
antiguedad number,
codacteconomica varchar2(4),
desacteconomica varchar2(50),
flg_acteco_nodef number,
flgnp number,
ctdnp number,
flglsb number,
ctdlsb number,
flgarchivonegativo number,
destipmotivonegativo varchar2(35),
ctd_np_lsb number,
ctdeval number,
codsubsegmento varchar2(3),
dessubsegmento varchar2(40),
codsegmento varchar2(3),
dessegmento varchar2(35)
) tablespace d_aml_99;

create table tmp_ingrestrc_lugarresidencia_aux2
(	codclavecic number not null enable,
tipdir char(1),
codubigeo char(6),
coddistrito char(4),
descoddistrito varchar2(25),
codprovincia char(5),
descodprovincia varchar2(25),
coddepartamento char(5),
descoddepartamento varchar2(25)
) tablespace d_aml_99;

create table tmp_ingrestrc_lugarresidencia
(	periodo number,
codclavecic number,
edad number,
tipper char(1),
antiguedad number,
codacteconomica varchar2(4),
desacteconomica varchar2(50),
flg_acteco_nodef number,
flgnp number,
ctdnp number,
flglsb number,
ctdlsb number,
flgarchivonegativo number,
destipmotivonegativo varchar2(35),
ctd_np_lsb number,
ctdeval number,
codsubsegmento varchar2(3),
dessubsegmento varchar2(40),
codsegmento varchar2(3),
dessegmento varchar2(35),
tipdir char(1),
codubigeo char(6),
coddistrito char(4),
descoddistrito varchar2(25),
codprovincia char(5),
descodprovincia varchar2(25),
coddepartamento char(5),
descoddepartamento varchar2(25)
) tablespace d_aml_99;

create table tmp_ingrestrc_nacionalidad
(	periodo number,
codclavecic number,
edad number,
tipper char(1),
antiguedad number,
codacteconomica varchar2(4),
desacteconomica varchar2(50),
flg_acteco_nodef number,
flgnp number,
ctdnp number,
flglsb number,
ctdlsb number,
flgarchivonegativo number,
destipmotivonegativo varchar2(35),
ctd_np_lsb number,
ctdeval number,
codsubsegmento varchar2(3),
dessubsegmento varchar2(40),
codsegmento varchar2(3),
dessegmento varchar2(35),
tipdir char(1),
codubigeo char(6),
coddistrito char(4),
descoddistrito varchar2(25),
codprovincia char(5),
descodprovincia varchar2(25),
coddepartamento char(5),
descoddepartamento varchar2(25),
codpaisnacionalidad varchar2(3),
descodpaisnacionalidad varchar2(40),
flgnacionalidad number
) tablespace d_aml_99;

create table tmp_ingrestrc_varcomportamiento
(	periodo number,
codclavecic number,
edad number,
tipper char(1),
antiguedad number,
codacteconomica varchar2(4),
desacteconomica varchar2(50),
flg_acteco_nodef number,
flgnp number,
ctdnp number,
flglsb number,
ctdlsb number,
flgarchivonegativo number,
destipmotivonegativo varchar2(35),
ctd_np_lsb number,
ctdeval number,
codsubsegmento varchar2(3),
dessubsegmento varchar2(40),
codsegmento varchar2(3),
dessegmento varchar2(35),
tipdir char(1),
codubigeo char(6),
coddistrito char(4),
descoddistrito varchar2(25),
codprovincia char(5),
descodprovincia varchar2(25),
coddepartamento char(5),
descoddepartamento varchar2(25),
codpaisnacionalidad varchar2(3),
descodpaisnacionalidad varchar2(40),
flgnacionalidad number,
mto_ingresos_mes number,
ctd_ingresos_mes number
) tablespace d_aml_99;

create table tmp_ingrestrc_perfi1
(	codclavecic number,
numperiodo number,
periodo number,
meses number,
mto_ingresos number
) tablespace d_aml_99;

create table tmp_ingrestrc_perfi2
(	numperiodo number,
codclavecic number,
mto_ingresos number
) tablespace d_aml_99;

create table tmp_ingrestrc_perfi3
(	numperiodo number,
codclavecic number,
mto_ingresos number,
media_ingresos number,
desv_ingresos number
) tablespace d_aml_99;

create table tmp_ingrestrc_perfilingresos
(	periodo number,
codclavecic number,
edad number,
tipper char(1),
antiguedad number,
codacteconomica varchar2(4),
desacteconomica varchar2(50),
flg_acteco_nodef number,
flgnp number,
ctdnp number,
flglsb number,
ctdlsb number,
flgarchivonegativo number,
destipmotivonegativo varchar2(35),
ctd_np_lsb number,
ctdeval number,
codsubsegmento varchar2(3),
dessubsegmento varchar2(40),
codsegmento varchar2(3),
dessegmento varchar2(35),
tipdir char(1),
codubigeo char(6),
coddistrito char(4),
descoddistrito varchar2(25),
codprovincia char(5),
descodprovincia varchar2(25),
coddepartamento char(5),
descoddepartamento varchar2(25),
codpaisnacionalidad varchar2(3),
descodpaisnacionalidad varchar2(40),
flgnacionalidad number,
mto_ingresos_mes number,
ctd_ingresos_mes number,
media_ingresos number,
desv_ingresos number,
flg_perfil_ingresos_3ds number
) tablespace d_aml_99;

create table tmp_ingrestrc_mtosredondos
 (	periodo number,
codclavecic number,
edad number,
tipper char(1),
antiguedad number,
codacteconomica varchar2(4),
desacteconomica varchar2(50),
flg_acteco_nodef number,
flgnp number,
ctdnp number,
flglsb number,
ctdlsb number,
flgarchivonegativo number,
destipmotivonegativo varchar2(35),
ctd_np_lsb number,
ctdeval number,
codsubsegmento varchar2(3),
dessubsegmento varchar2(40),
codsegmento varchar2(3),
dessegmento varchar2(35),
tipdir char(1),
codubigeo char(6),
coddistrito char(4),
descoddistrito varchar2(25),
codprovincia char(5),
descodprovincia varchar2(25),
coddepartamento char(5),
descoddepartamento varchar2(25),
codpaisnacionalidad varchar2(3),
descodpaisnacionalidad varchar2(40),
flgnacionalidad number,
mto_ingresos_mes number,
ctd_ingresos_mes number,
media_ingresos number,
desv_ingresos number,
flg_perfil_ingresos_3ds number,
max_ctdmtosredondos number,
sum_mtosredondos number
) tablespace d_aml_99 ;

create table tmpctds
(	periodo number,
codclavecic number,
mtotransaccion number(16,2),
ctd number
) tablespace d_aml_99;

create table tmpctdsmax
(	periodo number,
codclavecic number,
max_ctd number
) tablespace d_aml_99;

create table tmpctdsycdtsmax
(	periodo number,
codclavecic number,
mtotransaccion number(16,2),
ctd number,
max_ctd number
) tablespace d_aml_99;

create table tmpmaxsnorepetidos
(	periodo number,
codclavecic number,
ctdmaxima number,
ctdmaximos number,
mtotransaccion number(16,2)
) tablespace d_aml_99;

create table tmpmaxsrepetidos
(	periodo number,
codclavecic number,
ctdmaxima number,
ctdmaximos number
) tablespace d_aml_99;

create table tmpmaxsrepetidosunicos
(	periodo number,
codclavecic number,
ctdmaxima number,
ctdmaximos number,
mtomaxdemaxrepetidos number
) tablespace d_aml_99;

create table tmpclientesmtosmaximosunicos
 (	periodo number,
codclavecic number,
ctdmaxima number,
ctdmaximos number,
mtomaxdemaxrepetidos number
) tablespace d_aml_99;

create table tmp_ingrestrc_mtosmaximosrepetidos_aux
 (	periodo number,
codclavecic number,
ctdmaxima number,
mto_maximosrepetidos number
) tablespace d_aml_99;

create table tmp_ingrestrc_mtosmaximosrepetidos
(	periodo number,
codclavecic number,
edad number,
tipper char(1),
antiguedad number,
codacteconomica varchar2(4),
desacteconomica varchar2(50),
flg_acteco_nodef number,
flgnp number,
ctdnp number,
flglsb number,
ctdlsb number,
flgarchivonegativo number,
destipmotivonegativo varchar2(35),
ctd_np_lsb number,
ctdeval number,
codsubsegmento varchar2(3),
dessubsegmento varchar2(40),
codsegmento varchar2(3),
dessegmento varchar2(35),
tipdir char(1),
codubigeo char(6),
coddistrito char(4),
descoddistrito varchar2(25),
codprovincia char(5),
descodprovincia varchar2(25),
coddepartamento char(5),
descoddepartamento varchar2(25),
codpaisnacionalidad varchar2(3),
descodpaisnacionalidad varchar2(40),
flgnacionalidad number,
mto_ingresos_mes number,
ctd_ingresos_mes number,
media_ingresos number,
desv_ingresos number,
flg_perfil_ingresos_3ds number,
max_ctdmtosredondos number,
sum_mtosredondos number,
ctdmaxima number,
mto_maximosrepetidos number
) tablespace d_aml_99;

create table tmp_ingrestrc_mtosyctdsproximos_aux
(	periodo number,
codclavecic number,
mtomaxdemaxrepetidos number,
mto_conotrosproximos number,
ctd_conotrosproximos number
) tablespace d_aml_99;

create table tmp_ingrestrc_mtosyctdsproximos
(	periodo number,
codclavecic number,
edad number,
tipper char(1),
antiguedad number,
codacteconomica varchar2(4),
desacteconomica varchar2(50),
flg_acteco_nodef number,
flgnp number,
ctdnp number,
flglsb number,
ctdlsb number,
flgarchivonegativo number,
destipmotivonegativo varchar2(35),
ctd_np_lsb number,
ctdeval number,
codsubsegmento varchar2(3),
dessubsegmento varchar2(40),
codsegmento varchar2(3),
dessegmento varchar2(35),
tipdir char(1),
codubigeo char(6),
coddistrito char(4),
descoddistrito varchar2(25),
codprovincia char(5),
descodprovincia varchar2(25),
coddepartamento char(5),
descoddepartamento varchar2(25),
codpaisnacionalidad varchar2(3),
descodpaisnacionalidad varchar2(40),
flgnacionalidad number,
mto_ingresos_mes number,
ctd_ingresos_mes number,
media_ingresos number,
desv_ingresos number,
flg_perfil_ingresos_3ds number,
max_ctdmtosredondos number,
sum_mtosredondos number,
ctdmaxima number,
mto_maximosrepetidos number,
mtomaxdemaxrepetidos number,
mto_conotrosproximos number,
ctd_conotrosproximos number
) tablespace d_aml_99;

create table tmp_ingrestrc_mtosyctdsproximos_tablon
(	periodo number,
codclavecic number,
edad number,
tipper char(1),
antiguedad number,
codacteconomica varchar2(4),
desacteconomica varchar2(50),
flg_acteco_nodef number,
flgnp number,
ctdnp number,
flglsb number,
ctdlsb number,
flgarchivonegativo number,
destipmotivonegativo varchar2(35),
ctd_np_lsb number,
ctdeval number,
codsubsegmento varchar2(3),
dessubsegmento varchar2(40),
codsegmento varchar2(3),
dessegmento varchar2(35),
tipdir char(1),
codubigeo char(6),
coddistrito char(4),
descoddistrito varchar2(25),
codprovincia char(5),
descodprovincia varchar2(25),
coddepartamento char(5),
descoddepartamento varchar2(25),
codpaisnacionalidad varchar2(3),
descodpaisnacionalidad varchar2(40),
flgnacionalidad number,
mto_ingresos_mes number,
ctd_ingresos_mes number,
media_ingresos number,
desv_ingresos number,
flg_perfil_ingresos_3ds number,
max_ctdmtosredondos number,
sum_mtosredondos number,
ctdmaxima number,
mto_maximosrepetidos number,
mtomaxdemaxrepetidos number,
mto_conotrosproximos number,
ctd_conotrosproximos number
) tablespace d_aml_99;

--02_models: Salidas del modelo
--tabla sobre escenario pj
create table tmp_ingresotrc_salida_modelopj
(	periodo number,
codclavecic number,
tipper char(1),
mto_ingresos_mes number,
flg_perfil_ingresos_3ds number,
mto_conotrosproximos number,
ctd_conotrosproximos number,
n_cluster number
) tablespace d_aml_99;

--tabla sobre escenario pn
create table tmp_ingresotrc_salida_modelopn
(	periodo number,
codclavecic number,
tipper char(1),
mto_ingresos_mes number,
flg_perfil_ingresos_3ds number,
mto_conotrosproximos number,
ctd_conotrosproximos number,
n_cluster number
) tablespace d_aml_99;

--03_deploy
--packages_adhoc
create table tmp_ingresotrc_alertaspj
(	periodo number,
codclavecic number,
tipper char(1),
mto_ingresos_mes number,
flg_perfil_ingresos_3ds number,
mto_conotrosproximos number,
ctd_conotrosproximos number,
n_cluster number,
codunicocli char(13),
nbrclibeneficiario varchar2(77)
) tablespace d_aml_99;

create table tmp_trx_epic024_pj
(	periodo number,
codclavecic number,
codsucage varchar2(6),
codclavecicordenante number,
codunicocliordenante char(13),
nombreordenante varchar2(77),
codopectaordenante char(20),
bancoemisor char(11),
nbrpaisorigen varchar2(100),
fecdia date,
hortransaccion varchar2(8),
codmoneda char(4),
mtotransaccion number(16,2),
mtodolarizado number,
mto_conotrosproximos number,
codproducto char(6),
descodproducto char(40),
codclavecicbeneficiario number,
codunicoclibeneficiario char(13),
nombrebeneficiario varchar2(77),
codopectabeneficiario char(20)
) tablespace d_aml_99;

create table tmp_ingresotrc_alertaspn
(	periodo number,
codclavecic number,
tipper char(1),
mto_ingresos_mes number,
flg_perfil_ingresos_3ds number,
mto_conotrosproximos number,
ctd_conotrosproximos number,
n_cluster number,
codunicocli char(13),
nbrclibeneficiario varchar2(77)
) tablespace d_aml_99;

create table tmp_trx_epic024_pn
(	periodo number,
codclavecic number,
codsucage varchar2(6),
codclavecicordenante number,
codunicocliordenante char(13),
nombreordenante varchar2(77),
codopectaordenante char(20),
bancoemisor char(11),
nbrpaisorigen varchar2(100),
fecdia date,
hortransaccion varchar2(8),
codmoneda char(4),
mtotransaccion number(16,2),
mtodolarizado number,
mto_conotrosproximos number,
codproducto char(6),
descodproducto char(40),
codclavecicbeneficiario number,
codunicoclibeneficiario char(13),
nombrebeneficiario varchar2(77),
codopectabeneficiario char(20)
 ) tablespace d_aml_99;

--deploy
create table epic024_pj
(	fecgeneracion date,
idorigen number,
codunicocli char(13),
escenario char(7),
desescenario char(53),
periodo char(10),
triggering number,
comentario varchar2(448)
 ) tablespace d_aml_99;

create table epic024_pn
(	fecgeneracion date,
idorigen number,
codunicocli char(13),
escenario char(7),
desescenario char(53),
periodo char(10),
triggering number,
comentario varchar2(448)
) tablespace d_aml_99;

drop table epic024;
create table epic024
(	fecgeneracion date,
idorigen number,
codunicocli char(13),
escenario char(7),
desescenario char(53),
periodo char(10),
triggering number,
comentario varchar2(448)
) tablespace d_aml_99;

drop table epic024_doc;
create table epic024_doc
(	ruta char(66),
nbrdocumento char(48),
codunicocli char(13),
fecregistro date,
numcaso char(1),
idanalista number
) tablespace d_aml_99;

commit;
quit;