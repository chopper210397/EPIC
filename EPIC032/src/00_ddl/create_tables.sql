--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

create table tmp_epic032_docggtt 
   (	coddocggtt char(25) not null enable, 
	fecdia date not null enable, 
	nbrclibeneficiario varchar2(75), 
	nbrclibeneficiario_limpio varchar2(4000), 
	codunicoclibeneficiario char(13), 
	codinternocomputacionalbenef char(12), 
	codclavecicbeneficiario number, 
	codmodalidadpago char(2), 
	tipformapago char(4), 
	codtipindicadoritf char(1), 
	nbrordenante varchar2(4000), 
	codunicocliordenante char(13), 
	codintercomputacionalordenante char(12), 
	codclavecicordenante number, 
	nbrsolicitante varchar2(4000), 
	codunicoclisolicitante char(13), 
	codinternocomputacionalsolicit char(12), 
	codclavecicsolicitante number, 
	fecemision date, 
	horemision char(8), 
	fecvaluta date, 
	codsucage char(6), 
	codterminal char(4), 
	codoperadorterminal char(1), 
	numoperacionggtt char(8), 
	codusroperador char(8), 
	codmoneda char(4), 
	mtotransaccion number(16,2), 
	mtotransacciondolar number, 
	codswiftbcodestino char(11), 
	codswiftbcocorresponsal char(11), 
	codswiftbcoemisor char(11), 
	codswiftbcointermediario char(11), 
	nbrbcointermediario varchar2(75), 
	nbrbcodestino varchar2(75), 
	desdetallepago varchar2(250), 
	flgextorno char(1), 
	codopefinesse char(4), 
	codtipestadotransaccion char(2) not null enable, 
	codcausalfinesse char(3)
   ) tablespace d_aml_99;

create table tmp_epic032_grupos 
   (	nbrclibeneficiario_limpio varchar2(4000), 
	cantidad_codu number
   ) tablespace d_aml_99;

create table tmp_epic032_pre_uncodu 
   (	nbrclibeneficiario_limpio varchar2(4000), 
	codunicoclibeneficiario char(13), 
	codclavecicbeneficiario number, 
	codunicocli char(13), 
	nombre varchar2(77)
   ) tablespace d_aml_99;

create table tmp_epic032_docodu 
   (	nbrclibeneficiario_limpio varchar2(4000), 
	cantidad_codu number
   ) tablespace d_aml_99;

create table tmp_epic032_uncodu 
   (	nbrclibeneficiario_limpio varchar2(4000), 
	codunicoclibeneficiario char(13), 
	codclavecicbeneficiario number, 
	codunicocli char(13), 
	nombre varchar2(77)
   ) tablespace d_aml_99;

create table tmp_epic032_univ_1 
   (	coddocggtt char(25) not null enable, 
	fecdia date not null enable, 
	nbrclibeneficiario varchar2(75), 
	nbrclibeneficiario_limpio varchar2(4000), 
	codunicoclibeneficiario char(13), 
	codinternocomputacionalbenef char(12), 
	codclavecicbeneficiario number, 
	codmodalidadpago char(2), 
	tipformapago char(4), 
	codtipindicadoritf char(1), 
	nbrordenante varchar2(4000), 
	codunicocliordenante char(13), 
	codintercomputacionalordenante char(12), 
	codclavecicordenante number, 
	nbrsolicitante varchar2(4000), 
	codunicoclisolicitante char(13), 
	codinternocomputacionalsolicit char(12), 
	codclavecicsolicitante number, 
	fecemision date, 
	horemision char(8), 
	fecvaluta date, 
	codsucage char(6), 
	codterminal char(4), 
	codoperadorterminal char(1), 
	numoperacionggtt char(8), 
	codusroperador char(8), 
	codmoneda char(4), 
	mtotransaccion number(16,2), 
	mtotransacciondolar number, 
	codswiftbcodestino char(11), 
	codswiftbcocorresponsal char(11), 
	codswiftbcoemisor char(11), 
	codswiftbcointermediario char(11), 
	nbrbcointermediario varchar2(75), 
	nbrbcodestino varchar2(75), 
	desdetallepago varchar2(250), 
	flgextorno char(1), 
	codopefinesse char(4), 
	codtipestadotransaccion char(2) not null enable, 
	codcausalfinesse char(3), 
	codunicocli_limpio char(13)
   ) tablespace d_aml_99;

create table tmp_epic032_univ_2 
   (	coddocggtt char(25) not null enable, 
	fecdia date not null enable, 
	nbrclibeneficiario varchar2(75), 
	nbrclibeneficiario_limpio varchar2(4000), 
	codunicoclibeneficiario char(13), 
	codinternocomputacionalbenef char(12), 
	codclavecicbeneficiario number, 
	codmodalidadpago char(2), 
	tipformapago char(4), 
	codtipindicadoritf char(1), 
	nbrordenante varchar2(4000), 
	codunicocliordenante char(13), 
	codintercomputacionalordenante char(12), 
	codclavecicordenante number, 
	nbrsolicitante varchar2(4000), 
	codunicoclisolicitante char(13), 
	codinternocomputacionalsolicit char(12), 
	codclavecicsolicitante number, 
	fecemision date, 
	horemision char(8), 
	fecvaluta date, 
	codsucage char(6), 
	codterminal char(4), 
	codoperadorterminal char(1), 
	numoperacionggtt char(8), 
	codusroperador char(8), 
	codmoneda char(4), 
	mtotransaccion number(16,2), 
	mtotransacciondolar number, 
	codswiftbcodestino char(11), 
	codswiftbcocorresponsal char(11), 
	codswiftbcoemisor char(11), 
	codswiftbcointermediario char(11), 
	nbrbcointermediario varchar2(75), 
	nbrbcodestino varchar2(75), 
	desdetallepago varchar2(250), 
	flgextorno char(1), 
	codopefinesse char(4), 
	codtipestadotransaccion char(2) not null enable, 
	codcausalfinesse char(3), 
	codunicocli_limpio char(13)
   ) tablespace d_aml_99;

create table tmp_epic032_univ_3 
   (	coddocggtt char(25) not null enable, 
	fecdia date not null enable, 
	nbrclibeneficiario varchar2(75), 
	nbrclibeneficiario_limpio varchar2(4000), 
	codunicoclibeneficiario char(13), 
	codinternocomputacionalbenef char(12), 
	codclavecicbeneficiario number, 
	codmodalidadpago char(2), 
	tipformapago char(4), 
	codtipindicadoritf char(1), 
	nbrordenante varchar2(4000), 
	codunicocliordenante char(13), 
	codintercomputacionalordenante char(12), 
	codclavecicordenante number, 
	nbrsolicitante varchar2(4000), 
	codunicoclisolicitante char(13), 
	codinternocomputacionalsolicit char(12), 
	codclavecicsolicitante number, 
	fecemision date, 
	horemision char(8), 
	fecvaluta date, 
	codsucage char(6), 
	codterminal char(4), 
	codoperadorterminal char(1), 
	numoperacionggtt char(8), 
	codusroperador char(8), 
	codmoneda char(4), 
	mtotransaccion number(16,2), 
	mtotransacciondolar number, 
	codswiftbcodestino char(11), 
	codswiftbcocorresponsal char(11), 
	codswiftbcoemisor char(11), 
	codswiftbcointermediario char(11), 
	nbrbcointermediario varchar2(75), 
	nbrbcodestino varchar2(75), 
	desdetallepago varchar2(250), 
	flgextorno char(1), 
	codopefinesse char(4), 
	codtipestadotransaccion char(2) not null enable, 
	codcausalfinesse char(3), 
	codunicocli_limpio varchar2(13)
   ) tablespace d_aml_99;

create table tmp_epic032_univ 
   (	coddocggtt char(25), 
	fecdia date, 
	nbrclibeneficiario varchar2(75), 
	nbrclibeneficiario_limpio varchar2(4000), 
	codunicoclibeneficiario char(13), 
	codinternocomputacionalbenef char(12), 
	codclavecicbeneficiario number, 
	codmodalidadpago char(2), 
	tipformapago char(4), 
	codtipindicadoritf char(1), 
	nbrordenante varchar2(4000), 
	codunicocliordenante char(13), 
	codintercomputacionalordenante char(12), 
	codclavecicordenante number, 
	nbrsolicitante varchar2(4000), 
	codunicoclisolicitante char(13), 
	codinternocomputacionalsolicit char(12), 
	codclavecicsolicitante number, 
	fecemision date, 
	horemision char(8), 
	fecvaluta date, 
	codsucage char(6), 
	codterminal char(4), 
	codoperadorterminal char(1), 
	numoperacionggtt char(8), 
	codusroperador char(8), 
	codmoneda char(4), 
	mtotransaccion number(16,2), 
	mtotransacciondolar number, 
	codswiftbcodestino char(11), 
	codswiftbcocorresponsal char(11), 
	codswiftbcoemisor char(11), 
	codswiftbcointermediario char(11), 
	nbrbcointermediario varchar2(75), 
	nbrbcodestino varchar2(75), 
	desdetallepago varchar2(250), 
	flgextorno char(1), 
	codopefinesse char(4), 
	codtipestadotransaccion char(2), 
	codcausalfinesse char(3), 
	codunicocli_limpio varchar2(13)
   ) tablespace d_aml_99;

create table tmp_epic032_mto_semana 
   (	periodo number, 
	semana number, 
	codunicocli_limpio varchar2(13), 
	monto_total number, 
	ctd_trx number
   ) tablespace d_aml_99;

create table tmp_epic032_mto_ctd_semanal 
   (	periodo number, 
	codunicocli_limpio varchar2(13), 
	monto_total_semanal number, 
	porcentaje_monto number, 
	ctd_trx_semanal number, 
	porcentaje_ctd number
   ) tablespace d_aml_99;

create table tmp_epic032_monto_total 
   (	periodo number, 
	codunicocli_limpio varchar2(13), 
	monto_total number, 
	ctd_trx number
   ) tablespace d_aml_99;

create table tmp_epic032_pre_perfil 
   (	coddocggtt char(25) not null enable, 
	fecdia date not null enable, 
	nbrclibeneficiario varchar2(75), 
	nbrbeneficiario varchar2(4000), 
	codunicoclibeneficiario char(13), 
	codclavecicbeneficiario number, 
	fecemision date, 
	horemision char(8), 
	codmoneda char(4), 
	mtotransaccion number(16,2), 
	mtotransacciondolar number
   ) tablespace d_aml_99;

create table tmp_epic032_perfil 
   (	coddocggtt char(25) not null enable, 
	fecdia date not null enable, 
	nbrclibeneficiario varchar2(75), 
	nbrbeneficiario varchar2(4000), 
	codunicoclibeneficiario char(13), 
	codclavecicbeneficiario number, 
	fecemision date, 
	horemision char(8), 
	codmoneda char(4), 
	mtotransaccion number(16,2), 
	mtotransacciondolar number, 
	codunicocli_limpio varchar2(13)
   ) tablespace d_aml_99;

create table tmp_epic032_group_perfil 
   (	periodo number, 
	codunicocli_limpio varchar2(13), 
	mto_total number
   ) tablespace d_aml_99;

create table tmp_epic032_perfil1 
   (	periodo number, 
	codunicocli_limpio varchar2(13), 
	mto_total number
   ) tablespace d_aml_99;

create table tmp_epic032_fec_perfil 
   (	periodo number, 
	codunicocli_limpio varchar2(13), 
	monto_total number, 
	ctd_trx number, 
	fecha_min number, 
	fecha_max number
   ) tablespace d_aml_99;

create table tmp_epic032_fec_perfil2 
   (	periodo number, 
	codunicocli_limpio varchar2(13), 
	media_depo number, 
	desv_depo number
   ) tablespace d_aml_99;

create table tmp_epic032_ordenantes 
   (	periodo number, 
	codunicocli_limpio varchar2(13), 
	ctd_ordenantes number
   ) tablespace d_aml_99;

create table tmp_epic032_extr 
   (	codunicocli_limpio varchar2(13), 
	flg_extranjero number
   ) tablespace d_aml_99;

create table tmp_epic032_ros 
   (	periodo number, 
	codunicocli_limpio varchar2(13)
   ) tablespace d_aml_99;

create table tmp_epic032_pre_lsb 
   (	fecdia date, 
	codunicocli_limpio varchar2(13), 
	codunicocli_gremio char(13)
   ) tablespace d_aml_99;

create table tmp_epic032_aux_lsb 
   (	fecdia date, 
	codunicocli_limpio varchar2(13), 
	codunicocli varchar2(13)
   ) tablespace d_aml_99;

create table tmp_epic032_lsb 
   (	periodo number, 
	codunicocli_limpio varchar2(13)
   ) tablespace d_aml_99;

create table tmp_epic032_pre_np 
   (	periodo number, 
	codunicocli_limpio varchar2(13), 
	codclavecic number, 
	fecdia date
   )tablespace d_aml_99; 

create table tmp_epic032_an 
   (	periodo number, 
	codunicocli_limpio varchar2(13)
   ) tablespace d_aml_99;

create table tmp_epic032_nombre 
   (	coddocggtt char(25), 
	fecdia date, 
	codunicocli_limpio varchar2(13), 
	nbrclibeneficiario_limpio varchar2(4000), 
	apepatbeneficiario varchar2(4000), 
	apematbeneficiario varchar2(4000), 
	nombrebeneficiario varchar2(4000), 
	nbrordenante varchar2(4000), 
	apepatordenante varchar2(4000), 
	apematordenante varchar2(4000), 
	nombreordenante varchar2(4000)
   ) tablespace d_aml_99;

create table tmp_epic032_varfamiliares 
   (	periodo number, 
	codunicocli_limpio varchar2(13), 
	flg_familiar_apellido number
   ) tablespace d_aml_99;

create table tmp_epic032_cliente 
   (	codunicocli_limpio varchar2(13)
   ) tablespace d_aml_99;

create table tmp_epic032_univ_total 
   (	periodo number, 
	codunicocli_limpio varchar2(13), 
	monto_total number, 
	ctd_trx number, 
	ctd_ordenantes number, 
	flg_extranjero number, 
	flg_ros number, 
	flg_lsb_np number, 
	flg_an number,
	flg_perfil number, 
	flg_familiar_apellido number, 
	flg_cliente number, 
	monto_total_semanal number, 
	porcentaje_monto number, 
	ctd_trx_semanal number, 
	porcentaje_ctd number
   ) tablespace d_aml_99;

create table tmp_epic032_outputmodel
   (	periodo number, 
	codunicocli_limpio varchar2(13), 
	monto_total number, 
	ctd_trx number, 
	ctd_ordenantes number, 
	flg_extranjero number, 
	flg_ros number, 
	flg_lsb_np number, 
	flg_an number,
	flg_perfil number, 
	flg_familiar_apellido number, 
	flg_cliente number, 
	monto_total_semanal number, 
	porcentaje_monto number, 
	ctd_trx_semanal number, 
	porcentaje_ctd number,
	if_label number
   ) tablespace d_aml_99;

create table tmp_epic032_alertas 
   (	periodo number, 
	codunicocli_limpio varchar2(13), 
	monto_total number, 
	ctd_trx number, 
	ctd_ordenantes number, 
	flg_extranjero number, 
	flg_ros number, 
	flg_lsb_np number, 
	flg_an number, 
	flg_perfil number, 
	flg_familiar_apellido number, 
	flg_cliente number, 
	monto_total_semanal number, 
	porcentaje_monto number, 
	ctd_trx_semanal number, 
	porcentaje_ctd number, 
	if_label number
   ) tablespace d_aml_99;

drop table epic032;
create table epic032 
   (	fecgeneracion date, 
	idorigen number, 
	codunicocli varchar2(13), 
	escenario char(7), 
	desescenario char(30), 
	periodo char(10), 
	triggering number, 
	comentario varchar2(650)
   ) tablespace d_aml_99;

create table epic032_doc 
   (	ruta char(62), 
	nbrdocumento varchar2(45), 
	codunicocli varchar2(13), 
	fecregistro date, 
	numcaso char(1), 
	idanalista number
   ) tablespace d_aml_99;
   
commit;
quit;