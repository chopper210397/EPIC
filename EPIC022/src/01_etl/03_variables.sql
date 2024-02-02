--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

--extraer monto total cash
truncate table tmp_clinuevo_mtocash;
insert into tmp_clinuevo_mtocash
--create TABLE TMP_CLINUEVO_MTOCASH TABLESPACE D_AML_99 AS
select a.periodo,a.codclaveciccli as codclavecic, b.antiguedadcli,
sum(case when flgcash=1 then a.mtodolarizado else 0 end) as mto_total_cash,
sum(case when flgcash=1 then 1 else 0 end) as ctd_total_cash,
sum(a.mtodolarizado) as mto_total,
sum(case when canal = 'DOCUMENTOGGTT' and codtransaccion = 'CHQGER' then 1 else 0 end) as ctdchqgen,
sum(case when canal = 'DOCUMENTOGGTT' and codtransaccion = 'CHQGER' then a.mtodolarizado else 0 end) as mto_chqgen,
sum(case when tipo_zona = 'ZAED' and flgcash=1 then a.mtodolarizado else 0 end) as mto_total_cash_zaed,
sum(case when tipo_zona = 'ZAED' and flgcash=1 then 1 else 0 end) as ctd_cash_zaed
from tmp_clinuevo_trx a
	left join tmp_clinuevo_universo_cli b on a.periodo = b.periodo and a.codclaveciccli = b.codclavecic
group by a.periodo,a.codclaveciccli, b.antiguedadcli;

--extraer edad
truncate table tmp_clinuevo_edad;
insert into tmp_clinuevo_edad
--create table tmp_clinuevo_edad tablespace d_aml_99 as
with tmp_proc_edad_ppnn_aux as
(
  select a.codclavecic,a.periodo,c.fecnacimiento, floor(months_between(to_date(to_char(periodo||'01'),'yyyymmdd'), c.fecnacimiento) /12) as edad
  from tmp_clinuevo_mtocash a
  inner join ods_v.md_cliente b on a.codclavecic = b.codclavecic
  left join ods_v.md_personanatural c on a.codclavecic = c.codclavecic
)
select a.*, b.edad
  from tmp_clinuevo_mtocash a
  left join ods_v.md_cliente x on a.codclavecic = x.codclavecic
  left join tmp_proc_edad_ppnn_aux b on a.periodo = b.periodo and a.codclavecic = b.codclavecic;

--extraer banca
truncate table tmp_clinuevo_banca;
insert into tmp_clinuevo_banca
--create table tmp_clinuevo_banca tablespace d_aml_99 as
select a.*, b.tipbanca, c.destipbanca
from tmp_clinuevo_edad a
left join ods_v.md_cliente b on a.codclavecic = b.codclavecic
left join ods_v.mm_destipobanca c on b.tipbanca = c.tipbanca;

--extraer nacionalidad
truncate table tmp_clinuevo_nacionalidad;
insert into tmp_clinuevo_nacionalidad
--create table tmp_clinuevo_nacionalidad tablespace d_aml_99 as
select a.*, c.codpaisnacionalidad, d.nombrepais,
case when c.codpaisnacionalidad is null then null
     when c.codpaisnacionalidad = 'PER' then 0
else 1 end flgnacionalidad
from tmp_clinuevo_banca a
inner join ods_v.md_cliente b on a.codclavecic = b.codclavecic
  left join ods_v.md_personanatural c on a.codclavecic = c.codclavecic
  left join s55632.md_codigopais d on c.codpaisnacionalidad = d.codpais3;

--flg si cliente es agente
truncate table tmp_clinuevo_difftiempo_agente;
insert into tmp_clinuevo_difftiempo_agente
--create table tmp_clinuevo_difftiempo_agente tablespace d_aml_99 as
with tmp_clinuevo_agente as
(
select a.codagenteviabcp, a.fecingresosistema, a.codclaveopecta, b.codclavecic
from ods_v.md_agenteviabcp a
left join ods_v.md_cuenta b on a.codclaveopecta = b.codclaveopecta
) select a.periodo, a.codclavecic,  b.fecingresosistema, months_between(last_day(to_date(to_char(a.periodo||'01'),'yyyymmdd')), b.fecingresosistema) as diff
  from tmp_clinuevo_nacionalidad a
  left join tmp_clinuevo_agente b on a.codclavecic =  b.codclavecic
  where months_between(last_day(to_date(to_char(a.periodo||'01'),'yyyymmdd')), b.fecingresosistema) > 0;

truncate table tmp_clinuevo_ctd_flg_agente;
insert into tmp_clinuevo_ctd_flg_agente
--create table tmp_clinuevo_ctd_flg_agente tablespace d_aml_99 as
with tmp_clinuevo_ctd_agente as
(
select periodo, codclavecic, count(*) as ctd
from tmp_clinuevo_difftiempo_agente
group by periodo, codclavecic
) select a.*,
  case when b.ctd is null then 0 else b.ctd end as ctdagentes,
  case when b.ctd is null then 0 else 1 end as flgagente
  from tmp_clinuevo_nacionalidad a
  left join tmp_clinuevo_ctd_agente b on a.periodo = b.periodo and a.codclavecic = b.codclavecic;

--flg cheque y porc_cheque , y mto y ctd zaed
truncate table tmp_clinuevo_ctd_flg_porc_chqgen;
insert into tmp_clinuevo_ctd_flg_porc_chqgen
--create table tmp_clinuevo_ctd_flg_porc_chqgen tablespace d_aml_99 as
select a.*,
case when a.ctdchqgen > 0  then 1 else 0 end as flgchqgen,
round(a.mto_chqgen / a.mto_total,1) as porc_chqgen
from tmp_clinuevo_ctd_flg_agente a;

--flg cheque y porc_cheque
--dias debajo de lava
truncate table tmp_clinuevo_ctddias_debajolava;
insert into tmp_clinuevo_ctddias_debajolava
--create table tmp_clinuevo_ctddias_debajolava tablespace d_aml_99 as
  with tmp1 as
  (
  --detectar por cada dia cuantas operaciones fueron menores a 10k
    select codclaveciccli,fecdia,mtodolarizado
    from tmp_clinuevo_trx
    where mtodolarizado>=10000
  ),tmp2 as
  (
  --si al menos hace 3 operaciones debajo de lava se activa un flg
    select codclaveciccli as codclavecic,fecdia,count(*) nrope_diarias_mayor10k
    from tmp1
    group by codclaveciccli,fecdia
  ),tmp3 as
  (
  --creacion del flg
    select a.*, case
                    when nrope_diarias_mayor10k>2 then 1
                    else 0
                end flg_lava
    from tmp2 a
  ),tmp4 as
  (
    --finalmente, para ese mes cuento o sumo los dias en los que tuvo el flg
    select codclavecic,to_number(to_char(fecdia,'yyyymm')) as periodo,sum(flg_lava) as ctd_dias_debajolava
    from tmp3
    group by codclavecic,to_char(fecdia,'yyyymm')
  )
   select a.*,nvl(b.ctd_dias_debajolava,0) as ctd_dias_debajolava
   from tmp_clinuevo_ctd_flg_porc_chqgen a
    left join tmp4 b on a.codclavecic=b.codclavecic and a.periodo=b.periodo;

truncate table  tmp_trs_epic022 ;
insert into tmp_trs_epic022
--create table tmp_trs_epic022 tablespace d_aml_99 as
select
a.numregistro,
a.codsucage,
a.codclavecicint,
b.codunicocli as codunicocliint,
trim(b.apepatcli)||' '||trim(b.apematcli)||' '||trim(b.nbrcli) as nomnbreint,
d.codopecta as codopectaint,
a.codpaisorigen,
a.fecdia,
a.hortransaccion,
a.codmoneda,
a.mtotransaccion,
a.mtodolarizado,
a.codtransaccion,
a.tipotransaccion,
a.canal,
a.codclaveciccli,
c.codunicocli as codunicoclicli,
trim(c.apepatcli)||' '||trim(c.apematcli)||' '||trim(c.nbrcli) as nomnbrecli,
e.codopecta as codopectacli
 from tmp_clinuevo_trx a
 left join ods_v.md_clienteg94 b on a.codclavecicint=b.codclavecic
 left join ods_v.md_clienteg94 c on a.codclaveciccli=c.codclavecic
 left join ods_v.md_cuentag94 d on a.codclaveopectaint=d.codclaveopecta
 left join ods_v.md_cuentag94 e on a.codclaveopectacli=e.codclaveopecta;

commit;
quit;