--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

var intervalo_1 number
exec :intervalo_1 := to_number(&2);

select :intervalo_1 from dual;
--variable cliente-mes antes
--create table tmp_egbcacei_cliemes_egretot as
truncate table tmp_egbcacei_cliemes_egretot;
insert into tmp_egbcacei_cliemes_egretot
	select  codclavecic_sol as codclavecic,to_number(to_char(fecdia,'yyyymm')) numperiodo,
			sum(mto_dolarizado) as mto_egresos
	from    tmp_egbcacei_trx
	group by  codclavecic_sol,to_char(fecdia,'yyyymm');

truncate table tmp_egbcacei_trx_2;
insert into tmp_egbcacei_trx_2
select codclavecic_sol,
b.codunicocli as codunicocli_sol,
trim(b.apepatcli)||' '||trim(b.apematcli)||' '||trim(b.nbrcli) as nombre_sol,
codopecta_sol,
codclavecic_ben,
c.codunicocli as codunicocli_ben,
trim(c.apepatcli)||' '||trim(c.apematcli)||' '||trim(c.nbrcli) as nombre_ben,
codopecta_ben,
a.fecdia,
a.hortransaccion,
a.codmoneda,
a.mtotransaccion,
a.mto_dolarizado,
a.tipo_transaccion,
a.canal from tmp_egbcacei_trx a
left join ods_v.md_clienteg94 b on a.codclavecic_sol = b.codclavecic
left join ods_v.md_clienteg94 c on a.codclavecic_ben = c.codclavecic
where a.fecdia between trunc(add_months(sysdate, :intervalo_1),'mm') and trunc(last_day(add_months(sysdate,:intervalo_1)));

--perfil total
truncate table tmp_egbcacei_perfi1;
insert into tmp_egbcacei_perfi1
--create table tmp_egbcacei_perfi1 tablespace d_aml_99 as
	with temp_tab as
	(
	select codclavecic_sol,to_char(fecdia,'yyyymm') periodo, sum(mto_dolarizado) acum_mto_dolarizado
	from 	tmp_egbcacei_trx
	group by codclavecic_sol,to_char(fecdia,'yyyymm')
	)
	select  a.codclavecic,a.numperiodo,b.periodo,
			months_between(to_date(a.numperiodo,'yyyymm'),to_date(b.periodo,'yyyymm')) meses,
			b.acum_mto_dolarizado
	from tmp_egbcacei_cliemes_egretot a
		 inner join temp_tab b on (a.codclavecic=b.codclavecic_sol);

--create table tmp_egbcacei_perfi2 tablespace d_aml_99 as
truncate table tmp_egbcacei_perfi2;
insert into tmp_egbcacei_perfi2
  select numperiodo,codclavecic,acum_mto_dolarizado
  from tmp_egbcacei_perfi1 a
  where numperiodo=periodo;

--create table tmp_egbcacei_perfi3 tablespace d_aml_99 as
truncate table tmp_egbcacei_perfi3;
insert into tmp_egbcacei_perfi3
	with temp_tab as
	(select numperiodo,codclavecic,avg(nullif(acum_mto_dolarizado,0)) media_dep,stddev(nullif(acum_mto_dolarizado,0)) desv_dep
	 from tmp_egbcacei_perfi1
	 where meses<=6 and meses>=1
	 group by numperiodo,codclavecic
	)
	select a.*,round(nvl(b.media_dep,0),2) media_dep,round(nvl(b.desv_dep,0),2) desv_dep
	from tmp_egbcacei_perfi2 a
		left join temp_tab b on (a.numperiodo=b.numperiodo and a.codclavecic=b.codclavecic);

--creamos el flg perfil total
--create table tmp_egbcacei_cliemes_egretot1 tablespace d_aml_99 as
truncate table tmp_egbcacei_cliemes_egretot1;
insert into tmp_egbcacei_cliemes_egretot1

	select  a.*,
				case
					when b.media_dep+3*b.desv_dep<b.acum_mto_dolarizado then 1
					else 0
				end flg_perfil_3desvt,b.media_dep,b.desv_dep
	from    tmp_egbcacei_cliemes_egretot a
			left join tmp_egbcacei_perfi3 b on (a.numperiodo=b.numperiodo and a.codclavecic=b.codclavecic);

--***********************************************representantes legales , accionistas y gerentes de las empresas*************************************************
--******************************codrel***************************
--gerentes:gad,gap,gco,gfi,ggr,gsp,gte
--representante legal: rlg
--******************************codtiprel***************************
--accionistas: ac
--create table tmp_egbcacei_cic_empresas tablespace d_aml_99 as
truncate table tmp_egbcacei_cic_empresas;
insert into tmp_egbcacei_cic_empresas
    select distinct codclavecic_sol as codclavecic_emp
    from   tmp_egbcacei_trx;

--drop table  tmp_egbcacei_rel_empresas_1;
--create table tmp_egbcacei_rel_empresas_1 as
truncate table tmp_egbcacei_rel_empresas_1;
insert into tmp_egbcacei_rel_empresas_1
 select codclavecic as codclavecic_rel,codclavecicclirel as codclavecic_emp
    from   ods_v.mm_relacioncliente
    where
           codrel in ('GAD','GAP','GCO','GFI','GGR','GSP','GTE','RLG') or
           codtiprel in ('AC');

--drop table  tmp_egbcacei_rel_empresas;
--create table tmp_egbcacei_rel_empresas as
truncate table tmp_egbcacei_rel_empresas;
insert into tmp_egbcacei_rel_empresas
select a.codclavecic_rel,a.codclavecic_emp
    from   tmp_egbcacei_rel_empresas_1 a
    inner join tmp_egbcacei_cic_empresas b on a.codclavecic_emp=b.codclavecic_emp;

--create table tmp_egbcacei_rel_empresas_final tablespace d_aml_99 as
truncate table tmp_egbcacei_rel_empresas_final;
insert into tmp_egbcacei_rel_empresas_final
  select a.codclavecic_emp, a.codclavecic_rel,b.codunicocli as codunicocli_rel
  from   tmp_egbcacei_rel_empresas a
       left join ods_v.md_cliente b on a.codclavecic_rel=b.codclavecic;

--variable flag ros historico de los relacionados de las empresa
--create table tmp_egbcacei_cliemes_egretot2 tablespace d_aml_99 as
truncate table tmp_egbcacei_cliemes_egretot2;
insert into tmp_egbcacei_cliemes_egretot2
 with tmp_ros as
  (
    select distinct codunicocli
    from s61751.sapy_dminvestigacion
    where idresultado=2
  ),
   tmp_flgros as
  (
    select distinct a.*,
      		 case
               when b.codunicocli is not null then 1
               else 0
           end flg_ros_rel
    from tmp_egbcacei_rel_empresas_final a
         left join tmp_ros b on a.codunicocli_rel=b.codunicocli
  ),
  tmp2 as
  (
  select codclavecic_emp,sum(flg_ros_rel) as flg_ros_rel
  from tmp_flgros
  group by codclavecic_emp
  )
  select distinct
         a.*,
  		   case
             when b.codclavecic_emp is not null then
                                                case
                                                    when b.flg_ros_rel >0 then 1
                                                    else 0
                                                 end
             else 0
         end flg_ros_rel
  from tmp_egbcacei_cliemes_egretot1 a
       left join tmp2 b on a.codclavecic=b.codclavecic_emp;

--flag si el rl, acc o gte es extranjero
--create table tmp_egbcacei_cliemes_egretot3 tablespace d_aml_99 as
truncate table tmp_egbcacei_cliemes_egretot3;
insert into tmp_egbcacei_cliemes_egretot3
  with tmp as
  (
  	select a.*,
  			case
  				when b.codpaisnacionalidad is null then -1
  				when trim(b.codpaisnacionalidad)='PER' then 0
  				else 1
  			end flg_rel_extranj
  	from tmp_egbcacei_rel_empresas_final a
  		left join ods_v.mm_personanatural b on a.codclavecic_rel=b.codclavecic
  ),tmp2 as
  (
    select a.*, row_number() over (partition by a.codclavecic_emp order by flg_rel_extranj desc) as row_num
    from tmp  a
  ),tmp3 as
  (
   select *
   from tmp2
   where row_num=1
  )
  select a.*,
         case
             when b.flg_rel_extranj=-1 then 0
             when b.flg_rel_extranj=0 then 0
             else 1
         end flg_rel_extranj
  from tmp_egbcacei_cliemes_egretot2 a
  	left join tmp3 b on a.codclavecic=b.codclavecic_emp;

--flag si el beneficiario esta en np
--create table tmp_egbcacei_cliemes_egretot4 tablespace d_aml_99 as
truncate table tmp_egbcacei_cliemes_egretot4;
insert into tmp_egbcacei_cliemes_egretot4
 with tmp_np as
  (
    select b.codunicocli,cast(min(b.fecregistro) as date) fecgeneracion
	from s61751.sapy_dmevaluacion a
		 right join  s61751.sapy_dmalerta b on a.idcaso=b.idcaso
	where b.idorigen=2
	group by b.codunicocli
  ),tmp_ben as
  (
	  select distinct a.codclavecic_ben codclavecic_ben,b.codunicocli as codunicocli_ben
	  from tmp_egbcacei_trx a
		left join ods_v.md_clienteg94 b on a.codclavecic_ben=b.codclavecic
  ),tmp_flg_np as
  (
    select a.codclavecic_sol codclavecic_sol,a.fecdia fecdia,
           case
               when c.fecgeneracion is null or a.fecdia-c.fecgeneracion<0 then 0
               else 1
            end flg_np_ben
    from tmp_egbcacei_trx a
         left join tmp_ben b on a.codclavecic_ben=b.codclavecic_ben
         left join tmp_np c on b.codunicocli_ben=c.codunicocli
  ),
  tmp2 as
  (
    select codclavecic_sol,to_number(to_char(fecdia,'yyyymm')) numperiodo,sum(flg_np_ben) as flg_np_ben
    from tmp_flg_np
    group by codclavecic_sol,to_char(fecdia,'yyyymm')
  )
  select distinct
         a.*,
		case
			when b.flg_np_ben >0 then 1
			else 0
		end flg_np_ben
  from tmp_egbcacei_cliemes_egretot3 a
       left join tmp2 b on a.codclavecic=b.codclavecic_sol and a.numperiodo=b.numperiodo;

 --flag si el beneficiario esta en lsb
--create table tmp_egbcacei_cliemes_egretot5 tablespace d_aml_99 as
truncate table tmp_egbcacei_cliemes_egretot5;
insert into tmp_egbcacei_cliemes_egretot5
 with tmp_np as
  (
    select b.codunicocli,cast(min(b.fecregistro) as date) fecgeneracion
    from s61751.sapy_dmevaluacion a
         right join  s61751.sapy_dmalerta b on a.idcaso=b.idcaso
    where b.idorigen=29
    group by b.codunicocli
  ),tmp_ben as
  (
	  select distinct a.codclavecic_ben codclavecic_ben,b.codunicocli as codunicocli_ben
	  from tmp_egbcacei_trx a
		left join ods_v.md_clienteg94 b on a.codclavecic_ben=b.codclavecic
  ),tmp_flg_lsb as
  (
    select a.codclavecic_sol,a.fecdia,
           case
               when c.fecgeneracion is null or a.fecdia-c.fecgeneracion<0 then 0
               else 1
            end flg_lsb_ben
    from tmp_egbcacei_trx a
         left join tmp_ben b on a.codclavecic_ben=b.codclavecic_ben
         left join tmp_np c on b.codunicocli_ben=c.codunicocli
  ),
  tmp2 as
  (
    select codclavecic_sol,to_number(to_char(fecdia,'yyyymm')) numperiodo,sum(flg_lsb_ben) as flg_lsb_ben
    from tmp_flg_lsb
    group by codclavecic_sol,to_char(fecdia,'yyyymm')
  )
  select distinct
         a.*,
		case
			when b.flg_lsb_ben >0 then 1
			else 0
		end flg_lsb_ben
  from tmp_egbcacei_cliemes_egretot4 a
       left join tmp2 b on a.codclavecic=b.codclavecic_sol and a.numperiodo=b.numperiodo;

 --flag si el beneficiario esta en an
--create table tmp_egbcacei_cliemes_egretot6 tablespace d_aml_99 as
 truncate table tmp_egbcacei_cliemes_egretot6;
 insert into tmp_egbcacei_cliemes_egretot6
  with tmp as
  (
    select codclavecic,min(fecregistrodetallenegativo) fecregistro_an
    from ods_v.md_motivodetalleclinegativo
    where tipmotivonegativo='013' and  --m1 - cumplimiento
          tipdetallemotivonegativo='001'
    group by codclavecic
  ),tmp2 as
  (
    select distinct a.codclavecic_sol,a.fecdia,
           case
               when c.fecregistro_an is null or a.fecdia-c.fecregistro_an<0 then 0
               else 1
            end flg_an_ben
    from tmp_egbcacei_trx a
         left join tmp c on a.codclavecic_ben=c.codclavecic
  ),tmp3 as
  (
    select codclavecic_sol as codclavecic,to_number(to_char(fecdia,'yyyymm')) numperiodo,sum(flg_an_ben) flg_an_ben
    from tmp2
    group by codclavecic_sol,to_char(fecdia,'yyyymm')
  )
  select a.*,
         case
             when b.flg_an_ben is null then 0
             when b.flg_an_ben>0 then 1
             else 0
         end flg_an_ben
  from tmp_egbcacei_cliemes_egretot5 a
       left join tmp3 b on a.codclavecic=b.codclavecic and a.numperiodo=b.numperiodo;

--flag si el rl-acc o gte es pep
--create table tmp_egbcacei_cliemes_egretot7 tablespace d_aml_99 as
truncate table tmp_egbcacei_cliemes_egretot7;
insert into tmp_egbcacei_cliemes_egretot7
	with tmp as
	(
	 select a.codclavecic_emp,
			case
				when b.tipmarcacli='P' then 1
				else 0
			end flg_rel_pep
	 from tmp_egbcacei_rel_empresas_final a
		left join s55632.clibcp_actual_total b on a.codclavecic_rel=b.codclavecic
	),tmp2 as
  (
    select a.*, row_number() over (partition by a.codclavecic_emp order by flg_rel_pep desc) as row_num
    from tmp  a
  ),tmp3 as
  (
   select *
   from tmp2
   where row_num=1
  )
	select a.*,nvl(b.flg_rel_pep,0)
	from tmp_egbcacei_cliemes_egretot6 a
		left join tmp3 b on a.codclavecic=b.codclavecic_emp;

 --dinero al ext
 --create table tmp_egbcacei_var_mto_ext as
truncate table tmp_egbcacei_var_mto_ext;
insert into tmp_egbcacei_var_mto_ext
  with tmp as
  (
  --ggtt
      select a.codclavecic_sol as codclavecic,to_number(to_char(a.fecdia,'yyyymm')) numperiodo,
  			     sum(a.mtoimporteoperacion * tc.mtocambioaldolar) as mto_ext
      from  tmp_egbcacei_ggtt_sol   a
            left join  ods_v.hd_tipocambiosaldodiario tc on a.fecdia = tc.fectipcambio and a.codmoneda = tc.codmoneda
            left join  s55632.md_codigopais p on substr(a.codswiftbcodestino, 5, 2) = p.codpais2
      where
            a.codclavecic_sol not in (select codclavecic from s55632.listablanca_cump) and
            trim(upper(p.nombrepais)) is not null and
            trim(upper(p.nombrepais)) not in ('PERÚ') and
            a.codclavecic_sol not in (0,3288453) and
            a.codclavecicbeneficiario<>3288453 and
            a.codclavecic_sol<>a.codclavecicbeneficiario
      group by a.codclavecic_sol,to_char(a.fecdia,'yyyymm')
      union all
      --banni
      select codclavecic_sol as codclavecic,to_number(to_char(fecdia,'yyyymm')) numperiodo,
             sum(mto_dolarizado) as mto_ext
      from tmp_egbcacei_banni_sol_ben
      where codclavecic_sol not in (select codclavecic from s55632.listablanca_cump) and
            codclavecic_sol<>0 and
      		codclavecic_sol<>codclavecic_ben
      group by codclavecic_sol,to_char(fecdia,'yyyymm')
  )
  select numperiodo,codclavecic,sum(mto_ext) mto_ext
  from tmp
  group by numperiodo,codclavecic;

--create table tmp_egbcacei_cliemes_egretot8 as
truncate table tmp_egbcacei_cliemes_egretot8;
insert into tmp_egbcacei_cliemes_egretot8

       select a.*,nvl(b.mto_ext,0) mto_ext, round(nvl(b.mto_ext,0)/a.mto_egresos,2) pctje_ext
       from tmp_egbcacei_cliemes_egretot7 a
            left join tmp_egbcacei_var_mto_ext b on a.codclavecic=b.codclavecic and a.numperiodo=b.numperiodo;

--dias debajo de lava
--create table tmp_egbcacei_cliemes_egretot9 as
truncate table tmp_egbcacei_cliemes_egretot9;
insert into tmp_egbcacei_cliemes_egretot9
  with tmp1 as
  (
  --detectar por cada dia cuantas operaciones fueron menores a 10k
    select codclavecic_ben,fecdia,mto_dolarizado
    from tmp_egbcacei_trx
    where mto_dolarizado>=10000
  ),tmp2 as
  (
  --si al menos hace 3 operaciones debajo de lava se activa un flg
    select codclavecic_ben,fecdia,count(*) nrope_diarias_mayor10k
    from tmp1
    group by codclavecic_ben,fecdia
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
    select codclavecic_ben codclavecic,to_number(to_char(fecdia,'yyyymm')) numperiodo,sum(flg_lava) as ctd_dias_debajolava02
    from tmp3
    group by codclavecic_ben,to_char(fecdia,'yyyymm')
  )
   select a.*,nvl(b.ctd_dias_debajolava02,0) ctd_dias_debajolava02
   from tmp_egbcacei_cliemes_egretot8 a
    left join tmp4 b on a.codclavecic=b.codclavecic and a.numperiodo=b.numperiodo;

--create table tmp_egbcacei_cliemes_egretot10 as
truncate table tmp_egbcacei_cliemes_egretot10;
insert into tmp_egbcacei_cliemes_egretot10
	select a.codclavecic,a.numperiodo,a.mto_egresos,a.flg_perfil_3desvt,a.media_dep,a.desv_dep,a.flg_ros_rel,
			a.flg_rel_extranj,
			case
				when a.flg_lsb_ben=1 or a.flg_np_ben=1 then 1
				else 0
			end flg_lsb_np_ben,
			a.flg_an_ben,a.flg_rel_pep,a.mto_ext,a.pctje_ext,a.ctd_dias_debajolava02
	from tmp_egbcacei_cliemes_egretot9 a
	where numperiodo=to_char(trunc(last_day(add_months(sysdate,:intervalo_1))),'yyyymm') and
			a.mto_egresos>50000;

commit;
quit;