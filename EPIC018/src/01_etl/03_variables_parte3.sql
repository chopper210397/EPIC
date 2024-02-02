--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

var intervalo_1 number
exec :intervalo_1 := to_number(&2);

select :intervalo_1 from dual;

--variable cliente-mes
truncate table tmp_ingcashbcacei_cliemes_ingretot;
insert into tmp_ingcashbcacei_cliemes_ingretot
--create table tmp_ingcashbcacei_cliemes_ingretot tablespace d_aml_99 as
	select  codclavecic_ben as codclavecic,to_number(to_char(fecdia,'yyyymm')) numperiodo,
			sum(mto_dolarizado) as mto_recibido,count(*) as nro_ingresos
	from    tmp_ingcashbcacei_trx
	group by  codclavecic_ben,to_char(fecdia,'yyyymm');

--tipo banca y actividad economica antes : 29,503 / ahora:  29,514
truncate table tmp_ingcashbcacei_cliemes_ingretot1;
insert into tmp_ingcashbcacei_cliemes_ingretot1
--create table tmp_ingcashbcacei_cliemes_ingretot1 tablespace d_aml_99 as
   select a.*,b.desacteconomica
   from   tmp_ingcashbcacei_cliemes_ingretot a
          left join tmp_ingcashbcacei_univclie b on a.codclavecic=b.codclavecic;

truncate table tmp_trx_epic018;
insert into tmp_trx_epic018
--create table tmp_trx_epic018 tablespace d_aml_99 as
select codclavecic_sol,
b.codunicocli as codunicocli_sol,
trim(b.apepatcli)||' '||trim(b.apematcli)||' '||trim(b.nbrcli) as nombre_sol,
codopecta_sol,
codclavecic_ben,
c.codunicocli as codunicocli_ben,
trim(c.apepatcli)||' '||trim(c.apematcli)||' '||trim(c.nbrcli) as nombre_ben,
codopecta_ben,
tipbanca_ben,
a.fecdia,
a.hortransaccion,
a.codmoneda,
mto_dolarizado,
tipo_transaccion,
canal
from tmp_ingcashbcacei_trx a
left join ods_v.md_clienteg94 b on a.codclavecic_sol = b.codclavecic
left join ods_v.md_clienteg94 c on a.codclavecic_ben = c.codclavecic;

--perfil total
truncate table tmp_ingcashbcacei_perfi1;
insert into tmp_ingcashbcacei_perfi1
--create table tmp_ingcashbcacei_perfi1 tablespace d_aml_99 as
	with temp_tab as
	(
	select codclavecic_ben,to_char(fecdia,'yyyymm') periodo, sum(mto_dolarizado) acum_mto_dolarizado
	from 	tmp_ingcashbcacei_trx
	group by codclavecic_ben,to_char(fecdia,'yyyymm')
	)
	select  a.codclavecic,a.numperiodo,b.periodo,
			months_between(to_date(a.numperiodo,'yyyymm'),to_date(b.periodo,'yyyymm')) meses,
			b.acum_mto_dolarizado
	from tmp_ingcashbcacei_cliemes_ingretot1 a
		 inner join temp_tab b on (a.codclavecic=b.codclavecic_ben);

truncate table tmp_ingcashbcacei_perfi2;
insert into tmp_ingcashbcacei_perfi2
--create table tmp_ingcashbcacei_perfi2 tablespace d_aml_99 as
  select numperiodo,codclavecic,acum_mto_dolarizado
  from tmp_ingcashbcacei_perfi1 a
  where numperiodo=periodo;

truncate table tmp_ingcashbcacei_perfi3;
insert into tmp_ingcashbcacei_perfi3
--create table tmp_ingcashbcacei_perfi3 tablespace d_aml_99 as
	with temp_tab as
	(select numperiodo,codclavecic,avg(nullif(acum_mto_dolarizado,0)) media_dep,stddev(nullif(acum_mto_dolarizado,0)) desv_dep
	 from tmp_ingcashbcacei_perfi1
	 where meses<=6 and meses>=1
	 group by numperiodo,codclavecic
	)
	select a.*,round(nvl(b.media_dep,0),2) media_dep,round(nvl(b.desv_dep,0),2) desv_dep
  from tmp_ingcashbcacei_perfi2 a
		left join temp_tab b on (a.numperiodo=b.numperiodo and a.codclavecic=b.codclavecic);

--creamos el flg perfil total
truncate table tmp_ingcashbcacei_cliemes_ingretot2;
insert into tmp_ingcashbcacei_cliemes_ingretot2
--create table tmp_ingcashbcacei_cliemes_ingretot2 tablespace d_aml_99 as
	select  a.*,
				case
					when b.media_dep+3*b.desv_dep<b.acum_mto_dolarizado then 1
					else 0
				end flg_perfilcash_3desvt_trx,b.media_dep,b.desv_dep
	from    tmp_ingcashbcacei_cliemes_ingretot1 a
			left join tmp_ingcashbcacei_perfi3 b on (a.numperiodo=b.numperiodo and a.codclavecic=b.codclavecic);

--variable antiguedad de cliente
truncate table tmp_ingcashbcacei_cliemes_ingretot3;
insert into tmp_ingcashbcacei_cliemes_ingretot3
--create table tmp_ingcashbcacei_cliemes_ingretot3 tablespace d_aml_99 as
	select codclavecic,min(t.fecapertura) as fecapertura
	from (select codclavecic,fecapertura from ods_v.md_prestamo where flgregeliminado = 'N'
  		  union all
  		  select codclavecic,fecapertura from ods_v.md_impac where flgregeliminado = 'N'
  		  union all
  		  select codclavecic,fecapertura from ods_v.md_saving where flgregeliminado = 'N'
       )  t
	group by codclavecic;

--variable antiguedad cliente
truncate table tmp_ingcashbcacei_cliemes_ingretot4;
insert into tmp_ingcashbcacei_cliemes_ingretot4
--create table tmp_ingcashbcacei_cliemes_ingretot4 tablespace d_aml_99 as
  select a.*,
         case
              when b.fecapertura is null or (b.fecapertura>to_date(a.numperiodo,'yyyymm')) then 0
              else round(months_between(to_date(a.numperiodo,'yyyymm'),b.fecapertura),2)
         end as antiguedadcliente
  from tmp_ingcashbcacei_cliemes_ingretot2 a
       left join tmp_ingcashbcacei_cliemes_ingretot3 b on a.codclavecic=b.codclavecic;

--flag si el beneficiario recibe dinero de alguien que esta en an
truncate table tmp_ingcashbcacei_cliemes_ingretot5;
insert into tmp_ingcashbcacei_cliemes_ingretot5
--create table tmp_ingcashbcacei_cliemes_ingretot5 tablespace d_aml_99 as
  with tmp as
  (
    select codclavecic,min(fecregistrodetallenegativo) fecregistro_an
    from ods_v.md_motivodetalleclinegativo
    where tipmotivonegativo='013' and  --m1 - cumplimiento
          tipdetallemotivonegativo='001'
    group by codclavecic
  ),tmp2 as
  (
    select distinct a.codclavecic_sol,a.codclavecic_ben,a.fecdia,
           case
               when b.fecregistro_an is null or a.fecdia-b.fecregistro_an<0 then 0
               else 1
            end flg_an
    from tmp_ingcashbcacei_trx a
         left join tmp b on a.codclavecic_sol=b.codclavecic
  ),tmp3 as
  (
    select codclavecic_ben as codclavecic,to_number(to_char(fecdia,'yyyymm')) numperiodo,sum(flg_an) flg_an
    from tmp2
    group by codclavecic_ben,to_char(fecdia,'yyyymm')
  )
  select a.*,
         case
             when b.flg_an is null then 0
             when b.flg_an>0 then 1
             else 0
         end flg_an
  from tmp_ingcashbcacei_cliemes_ingretot4 a
       left join tmp3 b on a.codclavecic=b.codclavecic and a.numperiodo=b.numperiodo;

--flag si el beneficiario recibe dinero de alguien que esta en np
truncate table tmp_ingcashbcacei_cliemes_ingretot6;
insert into tmp_ingcashbcacei_cliemes_ingretot6
--create table tmp_ingcashbcacei_cliemes_ingretot6 tablespace d_aml_99 as
  with tmp as
  (
      select b.codunicocli,min(to_date(to_char(b.fecregistro,'dd/mm/yyyy'),'dd/mm/yyyy')) fecgeneracion_np
      from s61751.sapy_dmevaluacion a
           right join  s61751.sapy_dmalerta b on a.idcaso=b.idcaso
      where b.idorigen=2
      group by b.codunicocli
  ),tmp2 as
  (
      select distinct a.codclavecic_sol,b.codunicocli
      from tmp_ingcashbcacei_trx a
           left join ods_v.md_cliente b on a.codclavecic_sol=b.codclavecic
  ),tmp3 as (
      select distinct a.codclavecic_sol,a.codclavecic_ben,a.fecdia,
             case
                 when c.fecgeneracion_np is null or a.fecdia-c.fecgeneracion_np<0 then 0
                 else 1
              end flg_np
      from tmp_ingcashbcacei_trx a
           left join tmp2 b on a.codclavecic_sol=b.codclavecic_sol
           left join tmp c on b.codunicocli=c.codunicocli
   ),tmp4 as
    (
      select codclavecic_ben as codclavecic,to_number(to_char(fecdia,'yyyymm')) numperiodo,sum(flg_np) flg_np
      from tmp3
      group by codclavecic_ben,to_char(fecdia,'yyyymm')
    )
    select a.*,
           case
               when b.flg_np is null then 0
               when b.flg_np>0 then 1
               else 0
           end flg_np
    from tmp_ingcashbcacei_cliemes_ingretot5 a
         left join tmp4 b on a.codclavecic=b.codclavecic and a.numperiodo=b.numperiodo;

--flag si el beneficiario recibe dinero de alguien que esta en lsb
truncate table tmp_ingcashbcacei_cliemes_ingretot7;
insert into tmp_ingcashbcacei_cliemes_ingretot7
--create table tmp_ingcashbcacei_cliemes_ingretot7 tablespace d_aml_99 as
  with tmp as
  (
      select b.codunicocli,min(to_date(to_char(b.fecregistro,'dd/mm/yyyy'),'dd/mm/yyyy')) fecgeneracion_lsb
      from s61751.sapy_dmevaluacion a
           right join  s61751.sapy_dmalerta b on a.idcaso=b.idcaso
      where b.idorigen=29
      group by b.codunicocli
  ),tmp2 as
  (
      select distinct a.codclavecic_sol,b.codunicocli
      from tmp_ingcashbcacei_trx a
           left join ods_v.md_cliente b on a.codclavecic_sol=b.codclavecic
  ),tmp3 as
  (
      select distinct a.codclavecic_sol,a.codclavecic_ben,a.fecdia,
             case
                 when c.fecgeneracion_lsb is null or a.fecdia-c.fecgeneracion_lsb<0 then 0
                 else 1
              end flg_lsb
      from tmp_ingcashbcacei_trx a
           left join tmp2 b on a.codclavecic_sol=b.codclavecic_sol
           left join tmp c on b.codunicocli=c.codunicocli
   ),tmp4 as
    (
      select codclavecic_ben as codclavecic,to_number(to_char(fecdia,'yyyymm')) numperiodo,sum(flg_lsb) flg_lsb
      from tmp3
      group by codclavecic_ben,to_char(fecdia,'yyyymm')
    )
    select a.*,
           case
               when b.flg_lsb is null then 0
               when b.flg_lsb>0 then 1
               else 0
           end flg_lsb
    from tmp_ingcashbcacei_cliemes_ingretot6 a
         left join tmp4 b on a.codclavecic=b.codclavecic and a.numperiodo=b.numperiodo;

 --categorizacion de la actividad economica
-- actividades economicas grupos de interes
truncate table tmp_ingcashbcacei_acteco_no_definidas;
insert into tmp_ingcashbcacei_acteco_no_definidas
--create table tmp_ingcashbcacei_acteco_no_definidas tablespace d_aml_99 as
  select codacteconomica,desacteconomica,'OTRSERV'as busq
  from ods_v.mm_descodactividadeconomica
  where upper(desacteconomica) like '%OTR%SERV%'
        union
  select codacteconomica,desacteconomica,'NO ESPECIF'
  from ods_v.mm_descodactividadeconomica
  where upper(desacteconomica) like '%NO ESPECIF%'
        union
  select codacteconomica,desacteconomica,'NO DISPO'
  from ods_v.mm_descodactividadeconomica
  where upper(desacteconomica) like '%NO DISPO%'
         union
  select codacteconomica,desacteconomica,'MAYOROTRPROD'
  from ods_v.mm_descodactividadeconomica
  where upper(desacteconomica) like '%MAYOR%OTR%PROD%'
         union
  select codacteconomica,desacteconomica,'MENOROTRPROD'
  from ods_v.mm_descodactividadeconomica
  where upper(desacteconomica) like '%MENOR%OTR%PROD%';

truncate table tmp_ingcashbcacei_cliemes_ingretot8;
insert into tmp_ingcashbcacei_cliemes_ingretot8
--create table tmp_ingcashbcacei_cliemes_ingretot8 tablespace d_aml_99 as
   select a.*,
         case
             when flg_lsb=1 or flg_np=1 then 1
             else 0
         end flg_lsb_np,
         case
             when b.codacteconomica is null then 1
             when c.codacteconomica is not null then 1
             else 0
         end act_economica_gruposinteres
  from tmp_ingcashbcacei_cliemes_ingretot7 a
    left join ods_v.md_clienteg94 b on a.codclavecic = b.codclavecic
    left join tmp_ingcashbcacei_acteco_no_definidas c on b.codacteconomica = c.codacteconomica;

---monto recibido en cuentas recientes
truncate table tmp_ingcashbcacei_ctas_trxcash;
insert into tmp_ingcashbcacei_ctas_trxcash
--create table tmp_ingcashbcacei_ctas_trxcash tablespace d_aml_99 as
    select a.fecdia,a.codclavecic_ben,a.codopecta_ben,b.codclaveopecta,a.mto_dolarizado
    from tmp_ingcashbcacei_trx a
         left join tmp_ingcashbcacei_univctasclie b on a.codopecta_ben=b.codopecta;

truncate table tmp_ingcashbcacei_fecap_ctas_trxcash;
insert into tmp_ingcashbcacei_fecap_ctas_trxcash
--create table tmp_ingcashbcacei_fecap_ctas_trxcash tablespace d_aml_99 as
   select codclaveopecta, fecapertura
   from ods_v.md_saving
   where codclaveopecta in (select codclaveopecta from tmp_ingcashbcacei_ctas_trxcash)
   union
   select codclaveopecta, fecapertura
   from ods_v.md_impac
   where codclaveopecta in (select codclaveopecta from tmp_ingcashbcacei_ctas_trxcash);

truncate table tmp_ingcashbcacei_cliemes_ingretot9;
insert into tmp_ingcashbcacei_cliemes_ingretot9
--create table tmp_ingcashbcacei_cliemes_ingretot9 tablespace d_aml_99 as
  with tmp as
  (
    select a.*, b.fecapertura,months_between(a.fecdia,b.fecapertura)
    from tmp_ingcashbcacei_ctas_trxcash a
         left join tmp_ingcashbcacei_fecap_ctas_trxcash b on a.codclaveopecta=b.codclaveopecta
    where  months_between(a.fecdia,b.fecapertura) >=0 and
           months_between(a.fecdia,b.fecapertura)<=12
  ),tmp2 as
  (
    select codclavecic_ben codclavecic,to_number(to_char(fecdia,'yyyymm')) numperiodo, sum(mto_dolarizado) mto_dolarizado
    from tmp
    group by codclavecic_ben,to_char(fecdia,'yyyymm')
  )
  select a.*,nvl(round(b.mto_dolarizado,2),0) mto_ctas_recientes
  from tmp_ingcashbcacei_cliemes_ingretot8 a
       left join tmp2 b on a.codclavecic=b.codclavecic and a.numperiodo=b.numperiodo;

truncate table tmp_ingcashbcacei_ing_totales;
insert into tmp_ingcashbcacei_ing_totales
--create table tmp_ingcashbcacei_ing_totales tablespace d_aml_99 as
  with tmp as
  (
--agente
    select codclavecic_ben,fecdia,mto_dolarizado
    from tmp_ingcashbcacei_trx_agente_var
    union all
--ventanilla
    select codclavecic_ben,fecdia,mto_dolarizado
    from tmp_ingcashbcacei_trx_remittance_var
    union all
--transferencias del exterior (remesas)
    select codclavecic_ben,fecdia,mto_dolarizado
    from tmp_ingcashbcacei_trx_cajero_var
    union all
--cajero
    select codclavecic_ben,fecdia,mto_dolarizado
    from tmp_ingcashbcacei_trx_hm_var
    union all
--banca movil
    select codclavecic_ben,fecdia,mto_dolarizado
    from tmp_ingcashbcacei_trx_ventanilla_var
    union all
--telecredito
    select codclavecic_ben,fecdia,mto_dolarizado
    from tmp_ingcashbcacei_trx_telcre_var
    union all
--homebanking
    select codclavecic_ben,fecdia,mto_dolarizado
    from tmp_ingcashbcacei_trx_ggtt_var
    union all
--ggtt
    select codclavecic_ben,fecdia,mto_dolarizado
    from tmp_ingcashbcacei_trx_bancamovil_var
  ),tmp2 as--filtro lista blanca
  (
  select *
  from tmp
  where codclavecic_ben not in (select codclavecic
								from s55632.rm_cumplimientolistablanca_tmp)
  )
  select  a.codclavecic_ben as codclavecic,to_number(to_char(a.fecdia,'yyyymm')) numperiodo,
			    sum(mto_dolarizado) as mto_ingresos
	from    tmp2 a
	group by  a.codclavecic_ben,to_char(a.fecdia,'yyyymm');

truncate table tmp_ingcashbcacei_cliemes_ingretot10;
insert into tmp_ingcashbcacei_cliemes_ingretot10
--create table tmp_ingcashbcacei_cliemes_ingretot10 tablespace d_aml_99 as
	 select a.*,
			case
				when b.mto_ingresos=0 then 0
				else round(coalesce(a.mto_recibido,0)/b.mto_ingresos,2)
			end as por_cash
	 from tmp_ingcashbcacei_cliemes_ingretot9 a
		  left join tmp_ingcashbcacei_ing_totales b on a.codclavecic=b.codclavecic and a.numperiodo=b.numperiodo;

truncate table tmp_ingcashbcacei_cliemes_ingretot11;
insert into tmp_ingcashbcacei_cliemes_ingretot11
--create table tmp_ingcashbcacei_cliemes_ingretot11 tablespace d_aml_99 as
  with tmp1 as
  (
  --detectar por cada dia cuantas operaciones fueron menores a 10k
    select codclavecic_ben,fecdia,mto_dolarizado
    from tmp_ingcashbcacei_trx
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
   from tmp_ingcashbcacei_cliemes_ingretot10 a
    left join tmp4 b on a.codclavecic=b.codclavecic and a.numperiodo=b.numperiodo;

 --agregado
--ratio ventas netas
truncate table tmp_ingcashbcacei_epg_empresas2;
insert into tmp_ingcashbcacei_epg_empresas2
--create table tmp_ingcashbcacei_epg_empresas2 tablespace d_aml_99 as
  with tmp_tipocambiosaldodiario as
  (
     select to_number(to_char(fectipcambio,'yyyymm')) numperiodo,avg(mtocambioaldolar) as mtocambioaldolar
     from  ods_v.hd_tipocambiosaldodiario
     where codmoneda='0001'
     group by to_char(fectipcambio,'yyyymm')
  ),
  tmp as
  (
     select a.codclavecic,a.codmesest,a.mtoventaneta*1000*b.mtocambioaldolar as mtoventaneta_dolar
     from ods_v.mm_estadogananciaperdidasafic a
          left join tmp_tipocambiosaldodiario b on a.codmesest=b.numperiodo
     where a.tipcondicion='A'
  ),
  tmp2 as
  (
    select a.codclavecic,a.numperiodo,b.codmesest,b.mtoventaneta_dolar
    from tmp_ingcashbcacei_cliemes_ingretot11 a
         inner join tmp b on a.codclavecic=b.codclavecic
  ),
  tmp3 as
  (
    select a.*,substr(a.numperiodo,1,4) as anio1,substr(a.codmesest,1,4) as anio2
    from tmp2 a
  ),
  tmp4 as
  (
    select a.*,a.anio1-a.anio2 as dif_year,months_between(to_date(a.numperiodo,'yyyymm'),to_date(a.codmesest,'yyyymm')) meses
    from tmp3 a
    where a.anio1-a.anio2>0
  ),
  tmp5 as
  (
    select a.*, row_number() over (partition by a.codclavecic,a.numperiodo order by meses,dif_year asc) as row_num
    from tmp4 a
  )
   select * from tmp5 where row_num=1;

truncate table tmp_ingcashbcacei_cliemes_ingretot12;
insert into tmp_ingcashbcacei_cliemes_ingretot12
--create table tmp_ingcashbcacei_cliemes_ingretot12 tablespace d_aml_99 as
  select a.*,
         case
             when a.codclavecic is null then null
             else case
                      when b.mtoventaneta_dolar is null then null
                      else round(b.mtoventaneta_dolar,2)
                  end
          end as mtoventaneta_dolar_lastejerc
  from tmp_ingcashbcacei_cliemes_ingretot11 a
       left join tmp_ingcashbcacei_epg_empresas2 b on a.codclavecic=b.codclavecic and a.numperiodo=b.numperiodo;

-------------------------------------------------******************nuevas variables*********************----------------------------------------
----------------flg_rel_an_lsb_np
--***********************************************representantes legales , accionistas y gerentes de las empresas*************************************************
--******************************codrel***************************
--gerentes:gad,gap,gco,gfi,ggr,gsp,gte
--representante legal: rlg
--******************************codtiprel***************************
--accionistas: ac
truncate table tmp_ingcashbcacei_cic_empresas;
insert into tmp_ingcashbcacei_cic_empresas
--create table tmp_ingcashbcacei_cic_empresas tablespace d_aml_99 as
    select distinct codclavecic as codclavecic_emp
    from   tmp_ingcashbcacei_univclie;

truncate table tmp_ingcashbcacei_rel_empresas;
insert into tmp_ingcashbcacei_rel_empresas
--create table tmp_ingcashbcacei_rel_empresas tablespace d_aml_99 as
    select codclavecic as codclavecic_rel,codclavecicclirel as codclavecic_emp
    from   ods_v.mm_relacioncliente a
	inner join tmp_ingcashbcacei_cic_empresas b on codclavecicclirel=b.codclavecic_emp
    where  codrel in ('GAD','GAP','GCO','GFI','GGR','GSP','GTE','RLG') OR
           codtiprel in ('AC');

truncate table tmp_ingcashbcacei_rel_empresas_final;
insert into tmp_ingcashbcacei_rel_empresas_final
--create table tmp_ingcashbcacei_rel_empresas_final tablespace d_aml_99 as
  select a.codclavecic_emp, a.codclavecic_rel,b.codunicocli as codunicocli_rel
  from   tmp_ingcashbcacei_rel_empresas a
       left join ods_v.md_cliente b on a.codclavecic_rel=b.codclavecic;

--noticias periodisticas

truncate table tmp_ingcashbcacei_cliemes_np;
insert into tmp_ingcashbcacei_cliemes_np
--create table tmp_ingcashbcacei_cliemes_np tablespace d_aml_99 as
   with tmp_np as
  (
    select distinct codunicocli
    from s61751.sapy_dmalerta
    where idorigen=2
  ),
   tmp_flg_np as
  (
    select distinct a.*,
      		 case
               when b.codunicocli is not null then 1
               else 0
           end flg_np_rel
    from tmp_ingcashbcacei_rel_empresas_final a
         left join tmp_np b on a.codunicocli_rel=b.codunicocli
  ),
  tmp2 as
  (
  select codclavecic_emp,sum(flg_np_rel) as flg_np_rel
  from tmp_flg_np
  group by codclavecic_emp
  )
  select distinct
         a.*,
  		   case
             when b.codclavecic_emp is not null then
													case
														when b.flg_np_rel >0 then 1
														else 0
													end
             else 0
         end flg_np_rel
  from tmp_ingcashbcacei_cliemes_ingretot12 a
       left join tmp2 b on a.codclavecic=b.codclavecic_emp ;

--lsb

truncate table tmp_ingcashbcacei_cliemes_lsb;
insert into tmp_ingcashbcacei_cliemes_lsb
--create table tmp_ingcashbcacei_cliemes_lsb tablespace d_aml_99 as
 with tmp_lsb as
  (
    select distinct codunicocli
    from s61751.sapy_dmalerta
    where idorigen=29
  ),
   tmp_flg_lsb as
  (
    select distinct a.*,
      		 case
               when b.codunicocli is not null then 1
               else 0
           end flg_lsb_rel
    from tmp_ingcashbcacei_rel_empresas_final a
         left join tmp_lsb b on a.codunicocli_rel=b.codunicocli
  ),
  tmp2 as
  (
  select codclavecic_emp,sum(flg_lsb_rel) as flg_lsb_rel
  from tmp_flg_lsb
  group by codclavecic_emp
  )
  select distinct
         a.*,
  		   case
             when b.codclavecic_emp is not null then
													case
														when b.flg_lsb_rel >0 then 1
														else 0
													end
             else 0
         end flg_lsb_rel
  from tmp_ingcashbcacei_cliemes_np a
       left join tmp2 b on a.codclavecic=b.codclavecic_emp ;

truncate table tmp_ingcashbcacei_cliemes_an;
insert into tmp_ingcashbcacei_cliemes_an
--create table tmp_ingcashbcacei_cliemes_an tablespace d_aml_99 as
 with tmp_an as
  (
    select codclavecic,min(fecregistrodetallenegativo) fecregistro_an
    from ods_v.md_motivodetalleclinegativo
    where tipmotivonegativo='013' and  --m1 - cumplimiento
          tipdetallemotivonegativo='001'
    group by codclavecic
  ),
   tmp_flg_an as
  (
    select distinct a.*,
      		 case
               when b.codclavecic is not null then 1
               else 0
           end flg_lsb_rel
    from tmp_ingcashbcacei_rel_empresas_final a
         left join tmp_an b on a.codclavecic_rel=b.codclavecic
  ),
  tmp2 as
  (
  select codclavecic_emp,sum(flg_lsb_rel) as flg_lsb_rel
  from tmp_flg_an
  group by codclavecic_emp
  )
  select distinct
         a.*,
  		   case
             when b.codclavecic_emp is not null then
													case
														when b.flg_lsb_rel >0 then 1
														else 0
													end
             else 0
         end flg_an_rel
  from tmp_ingcashbcacei_cliemes_lsb a
       left join tmp2 b on a.codclavecic=b.codclavecic_emp ;

truncate table tmp_ingcashbcacei_rel_npanlsb;
insert into tmp_ingcashbcacei_rel_npanlsb
--create table tmp_ingcashbcacei_rel_npanlsb tablespace d_aml_99 as
  select a.*,
            case
              when flg_np_rel=1 or flg_lsb_rel=1 or flg_an_rel=1 then 1
              else 0
          end flg_rel_an_lsb_np  from tmp_ingcashbcacei_cliemes_an a ;

--tipbanca
truncate table tmp_ingcashbcacei_tipbanca;
insert into tmp_ingcashbcacei_tipbanca
--create table tmp_ingcashbcacei_tipbanca tablespace d_aml_99 as
   select a.*,b.tipbanca
   from   tmp_ingcashbcacei_rel_npanlsb a
          left join tmp_ingcashbcacei_univclie b on a.codclavecic=b.codclavecic;

----------------------------extraer edad relacionado

truncate table tmp_ingcashbcacei_cic_edadrel;
insert into tmp_ingcashbcacei_cic_edadrel
--create table tmp_ingcashbcacei_cic_edadrel tablespace d_aml_99 as
    select distinct codclavecic as codclavecic_emp,numperiodo
    from   tmp_ingcashbcacei_cliemes_ingretot12;

truncate table tmp_ingcashbcacei_rel_edad;
insert into tmp_ingcashbcacei_rel_edad
--create table tmp_ingcashbcacei_rel_edad tablespace d_aml_99 as
    select codclavecic as codclavecic_rel,codclavecicclirel as codclavecic_emp,numperiodo
    from   ods_v.mm_relacioncliente a
	inner join  tmp_ingcashbcacei_cic_edadrel b on a.codclavecicclirel=b.codclavecic_emp
	where codrel ='RLG';

truncate table tmp_ingcashbcacei_preedad;
insert into tmp_ingcashbcacei_preedad
--create table tmp_ingcashbcacei_preedad tablespace d_aml_99 as
with tmp_proc_edad_ppnn_aux as
                    (
  select a.codclavecic_rel,a.numperiodo,c.fecnacimiento, floor(months_between(to_date(to_char(numperiodo||'01'),'yyyymmdd'), c.fecnacimiento) /12) as edad
  from tmp_ingcashbcacei_rel_edad a
  inner join ods_v.md_cliente b on a.codclavecic_rel = b.codclavecic
  left join ods_v.md_personanatural c on a.codclavecic_rel = c.codclavecic
  where trim(b.tipper) = 'P'
) ,
tmp_proc_edad_ppjj_aux as
(
  select a.codclavecic_rel,a.numperiodo,c.fecconstitucion, floor(months_between(to_date(to_char(numperiodo||'01'),'yyyymmdd'), c.fecconstitucion) /12) as edad
  from tmp_ingcashbcacei_rel_edad a
  inner join ods_v.md_cliente b on a.codclavecic_rel = b.codclavecic
  left join ods_v.mm_empresa c on a.codclavecic_rel = c.codclavecic
  where trim(b.tipper) = 'E'
)
select a.numperiodo, a.codclavecic_emp, case when trim(x.tipper) = 'P' then b.edad else case when trim(x.tipper) = 'E' then c.edad else null end end as edad_rl_min
  from tmp_ingcashbcacei_rel_edad a
  left join ods_v.md_cliente x on a.codclavecic_rel = x.codclavecic
  left join tmp_proc_edad_ppnn_aux b on a.numperiodo = b.numperiodo and a.codclavecic_rel = b.codclavecic_rel
  left join tmp_proc_edad_ppjj_aux c on a.numperiodo = c.numperiodo and a.codclavecic_rel = c.codclavecic_rel;

truncate table tmp_ingcashbcacei_edad;
insert into tmp_ingcashbcacei_edad
--create table tmp_ingcashbcacei_edad tablespace d_aml_99 as
    select numperiodo,codclavecic_emp,max(edad_rl_min) edad_rl_min
    from tmp_ingcashbcacei_preedad
    group by numperiodo,codclavecic_emp;

----------------------------porc_cash_mesanterior
--perfil total
truncate table tmp_ingcashbcacei_mto_ant3;
insert into tmp_ingcashbcacei_mto_ant3
--create table tmp_ingcashbcacei_mto_ant3 tablespace d_aml_99 as
	with temp_tab as
	(
	select codclavecic_ben,to_char(fecdia,'yyyymm') periodo, sum(mto_dolarizado) acum_mto_dolarizado
	from 	tmp_ingcashbcacei_trx
	group by codclavecic_ben,to_char(fecdia,'yyyymm')
	)
	select  a.codclavecic,a.numperiodo,b.periodo,
			months_between(to_date(a.numperiodo,'yyyymm'),to_date(b.periodo,'yyyymm')) meses,
			b.acum_mto_dolarizado
	from tmp_ingcashbcacei_cliemes_ingretot1 a
		 inner join temp_tab b on (a.codclavecic=b.codclavecic_ben);

truncate table tmp_ingcashbcacei_mto_ant2;
insert into tmp_ingcashbcacei_mto_ant2
--create table tmp_ingcashbcacei_mto_ant2 tablespace d_aml_99 as
  select numperiodo,codclavecic,acum_mto_dolarizado
  from tmp_ingcashbcacei_mto_ant3 a
  where numperiodo=periodo;

truncate table tmp_ingcashbcacei_mto_ant;
insert into tmp_ingcashbcacei_mto_ant
--create table tmp_ingcashbcacei_mto_ant tablespace d_aml_99 as
  	with temp_tab as (
	 select numperiodo,codclavecic,acum_mto_dolarizado as mto_act
	 from tmp_ingcashbcacei_mto_ant3
	 where meses=1
	 group by numperiodo,codclavecic,acum_mto_dolarizado
	)
	select a.*,b.mto_act as mto_ant
  from tmp_ingcashbcacei_mto_ant2 a
		left join temp_tab b on (a.numperiodo=b.numperiodo and a.codclavecic=b.codclavecic)
		where a.numperiodo= to_number(to_char(add_months(sysdate,  :intervalo_1),'yyyymm'));

truncate table tmp_ingcashbcacei_pctmtoant;
insert into tmp_ingcashbcacei_pctmtoant
--create table tmp_ingcashbcacei_pctmtoant tablespace d_aml_99 as
  with tmp_ultimomes as (
  select codclavecic, numperiodo, case when acum_mto_dolarizado is null then 0 else acum_mto_dolarizado end as mto_act, case when mto_ant is not null then mto_ant else 0 end as mto_ant
  from tmp_ingcashbcacei_mto_ant
) select a.*,
  case when b.codclavecic is null or mto_ant<=0 then 0 else nvl(((mto_act/mto_ant)/mto_ant)*100,0) end as porc_cash_mesanterior,edad_rl_min
  from tmp_ingcashbcacei_tipbanca a
  left join tmp_ultimomes b  on a.codclavecic=b.codclavecic  and a.numperiodo=b.numperiodo
  left join tmp_ingcashbcacei_edad c on a.codclavecic=c.codclavecic_emp  and a.numperiodo=c.numperiodo;

truncate table tmp_ingcashbcacei_plaft;
insert into tmp_ingcashbcacei_plaft
--create table tmp_ingcashbcacei_plaft tablespace d_aml_99 as
    select distinct a.codclavecic,
    case when b.codacteconomica in (1200,1310,1320,1421,1429,2429,2927,4520,5142,6519,
    6592,6599,6719,7010,7020,7411,7421,7512,9191,9192,9199,9219,9249,9900) then 1 else 0 end flg_acteco_plaft,
        case when b.tipmarcacli in ('E','Z','B','K','I','W') then 1 else 0 end flg_marcasensible_plaft
    from tmp_ingcashbcacei_univclie a
    inner join ods_v.md_clienteg94 b on a.codclavecic=b.codclavecic
    left join ods_v.mm_descodactividadeconomica c on b.codacteconomica=b.codacteconomica;

truncate table tmp_ingcashbcacei_tablon;
insert into tmp_ingcashbcacei_tablon
--create table tmp_ingcashbcacei_tablon tablespace d_aml_99 as
		select codclavecic,numperiodo,round(mto_recibido,2) mto_ingreso,nro_ingresos num_ingreso,desacteconomica act_economica,
				flg_perfilcash_3desvt_trx flg_perfil,antiguedadcliente,
				case when flg_an=1 or flg_lsb_np=1 then 1 else 0 end flg_an_lsb_np,
				act_economica_gruposinteres flg_act_eco,mto_ctas_recientes,
				case when por_cash is null then 0 else por_cash end por_cash,ctd_dias_debajolava02,
				round(porc_cash_mesanterior,2) porc_cash_mesanterior,edad_rl_min,flg_rel_an_lsb_np,tipbanca
		from tmp_ingcashbcacei_pctmtoant;

truncate table tmp_ingcashbcacei_final;
insert into tmp_ingcashbcacei_final
--create table tmp_ingcashbcacei_final  tablespace d_aml_99 as
select distinct a.*,
flg_acteco_plaft,flg_marcasensible_plaft
from tmp_ingcashbcacei_tablon a
left join tmp_ingcashbcacei_plaft b on a.codclavecic=b.codclavecic
where numperiodo = to_number(to_char(add_months(sysdate,  :intervalo_1),'yyyymm'));

commit;
quit;