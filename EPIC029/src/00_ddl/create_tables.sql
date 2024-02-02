--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

create table tmp_topsolicitante_trx 
   (	periodo number, 
	fecdia date not null enable, 
	horinitransaccion char(8) not null enable, 
	codsucage char(6) not null enable, 
	codsesion number not null enable, 
	codinternotransaccion number, 
	codtransaccionventanilla number not null enable, 
	destransaccionventanilla varchar2(65), 
	codctacomercial varchar2(20), 
	mtotransaccion number(16,2), 
	codunicoclisolicitante char(13), 
	idcsolicitante varchar2(8), 
	tipdocsolicitante varchar2(1), 
	nbrclientesolicitante varchar2(77), 
	bancasolicitante varchar2(35), 
	codunicoclibeneficiario varchar2(17), 
	idcbeneficiario varchar2(8), 
	tipdocbeneficiario varchar2(1), 
	nbrclientebeneficiario varchar2(77), 
	bancabeneficiario varchar2(35), 
	codterminal char(10) not null enable, 
	codmatricula char(6) not null enable
   ) tablespace d_aml_99;

create table tmp_topsolicitante_previa 
   (	codclavecicbeneficiario number, 
	codclavecicsolicitante number, 
	periodo number, 
	fecdia date not null enable, 
	horinitransaccion char(8) not null enable, 
	codsucage char(6) not null enable, 
	codsesion number not null enable, 
	codinternotransaccion number, 
	codtransaccionventanilla number not null enable, 
	destransaccionventanilla varchar2(65), 
	actv_beneficiario char(4), 
	tipper_beneficiario char(1), 
	flg_ffnn_beneficiario number, 
	flg_ffnn_solicitante number, 
	tipbanca_beneficiario char(1), 
	tipbanca_solicitante char(1), 
	mtotransaccion number(16,2), 
	tipper_solicitante char(1), 
	codunicoclisolicitante char(13), 
	codunicoclibeneficiario varchar2(17)
   ) tablespace d_aml_99;

create table tmp_topsolicitante_spool 
   (	codclavecicbeneficiario number, 
	codclavecicsolicitante number, 
	periodo number, 
	fecdia date not null enable, 
	horinitransaccion char(8) not null enable, 
	codsucage char(6) not null enable, 
	codsesion number not null enable, 
	codinternotransaccion number, 
	codtransaccionventanilla number not null enable, 
	destransaccionventanilla varchar2(65), 
	actv_beneficiario char(4), 
	tipper_beneficiario char(1), 
	flg_ffnn_beneficiario number, 
	flg_ffnn_solicitante number, 
	tipbanca_beneficiario char(1), 
	tipbanca_solicitante char(1), 
	mtotransaccion number(16,2), 
	tipper_solicitante char(1), 
	desbanca_beneficiario varchar2(35), 
	desbanca_solicitante varchar2(35), 
	fecons_beneficiario date, 
	fecons_sol date, 
	flg_an_beneficiario number, 
	flg_an_solicitante number, 
	flg_rel number, 
	flg_ros_ben number, 
	flg_ros_sol number
   ) tablespace d_aml_99;

create table tmp_topsolicitante_output
( codclavecicbeneficiario number,
  codclavecicsolicitante number,
  periodo number,
  fecdia date,
  codsucage number,
  codsesion number,
  codinternotransaccion number,
  codtransaccionventanilla number,
  mtotransaccion number,
  flg_mto_p25 number,
  flg_mto_p50 number,
  flg_mto_p75 number,
  flg_mto_p90 number,
  flg_an number,
  tipper number,
  flg_nueva_ben number,
  dif2 number,
  flg_nueva_sol number,
  flg_nueva number,
  flg_banca number,
  persona_sol number,
  empresa_sol number,
  persona_ben number,
  empresa_ben number,
  flg_ros number,
  flg_mto number,
  flg_norel number,
  mtotransaccion_es number,
  tipper_ben number,
  tipper_sol number,
  mto_p95 number,
  mtotransaccion_es95 number,
  flg_ros_ben number,
  flg_ros_sol number,
  n_cluster number
) tablespace d_aml_99 ;

create table tmp_topsolicitante_filtrado 
   (	codunicoclibeneficiario varchar2(17), 
	codclavecicbeneficiario number, 
	periodo number, 
	n_cluster number, 
	mto_recibido number
   ) tablespace d_aml_99;

create table tmp_topsolicitante_alerta 
   (	periodo number, 
	codunicocli varchar2(17), 
	codclavecic number
   ) tablespace d_aml_99;

create table tmp_trx_epic029 
   (	periodo number, 
	fecdia date not null enable, 
	horinitransaccion char(8) not null enable, 
	codsucage char(6) not null enable, 
	codsesion number not null enable, 
	codinternotransaccion number, 
	codtransaccionventanilla number not null enable, 
	destransaccionventanilla varchar2(65), 
	codctacomercial varchar2(20), 
	mtotransaccion number(16,2), 
	codunicoclisolicitante char(13), 
	nbrclientesolicitante varchar2(77), 
	bancasolicitante varchar2(35), 
	codunicoclibeneficiario varchar2(17), 
	nbrclientebeneficiario varchar2(77), 
	bancabeneficiario varchar2(35), 
	codterminal char(10) not null enable, 
	n_cluster number
   ) tablespace d_aml_99;

drop table epic029;
create table epic029 
   (	fecgeneracion date, 
	idorigen number, 
	codunicoclibeneficiario varchar2(17), 
	escenario char(7), 
	desescenario char(39), 
	periodo char(10), 
	triggering number, 
	comentario varchar2(190)
   ) tablespace d_aml_99;


create table tmp_topsolicitante_clientes_bed_sindac
(
	codclavecic number,
	CODINTERNOCOMPUTACIONAL VARCHAR2(20),
	CODSECTOR VARCHAR(10),
	CODSECTORISTA VARCHAR(6),
	DESSECTORISTA VARCHAR(150),
	CODSUBSEGMENTO VARCHAR(4),
	TIPCLI VARCHAR(3),
	AGENCIA VARCHAR(100),
	REGION VARCHAR(50)
);
commit;
quit;