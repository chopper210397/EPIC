--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

var intervalo_1 number
exec :intervalo_1 := to_number(&2);
var intervalo_2 number
exec :intervalo_2 := to_number(&3);

select :intervalo_1, :intervalo_2 from dual;

--*******************************************************************agente*******************************************************************
--create table tmp_egbcacei_agente_sol as
truncate table tmp_egbcacei_agente_sol;
insert into tmp_egbcacei_agente_sol
 with tmp_movagente_sol1 as
 (
	select
         a.codclaveopectacargo,a.codunicocli,a.codclaveopectaabono,a.fecdia, a.hortransaccion,
		 a.codmoneda,a.mtotransaccion,a.tiptransaccionagenteviabcp
	from
         t23377.tmp_movagente_i a
		 left join
               ods_v.md_agenteviabcp b on a.codclaveopectaabono=b.codclaveopecta
	where
      		a.fecdia between trunc(add_months(sysdate, :intervalo_1),'mm') and trunc(last_day(add_months(sysdate, :intervalo_2))) and
      		a.tiptransaccionagenteviabcp in('03','04') and
			b.codclaveopecta is null and
			a.codclaveopectacargo in (select codclaveopecta from tmp_egbcacei_univctasclie)
union all
	select
         a.codclaveopectacargo,a.codunicocli,a.codclaveopectaabono,a.fecdia, a.hortransaccion,
		 a.codmoneda,a.mtotransaccion,a.tiptransaccionagenteviabcp
	from
         t23377.tmp_movagente_p a
		 left join
               ods_v.md_agenteviabcp b on a.codclaveopectaabono=b.codclaveopecta
	where
      		a.fecdia between trunc(add_months(sysdate, :intervalo_1),'mm') and trunc(last_day(add_months(sysdate, :intervalo_2))) and
      		a.tiptransaccionagenteviabcp in('03','04') and
			b.codclaveopecta is null and
			a.codclaveopectacargo in (select codclaveopecta from tmp_egbcacei_univctasclie)
  ), tmp_movagente_sol2 as
  (
  	select
         a.codclaveopectacargo,a.codunicocli,a.codclaveopectaabono,a.fecdia, a.hortransaccion,
		 a.codmoneda, a.mtotransaccion,a.tiptransaccionagenteviabcp
  	from
           t23377.tmp_movagente_i a
		   left join
               ods_v.md_agenteviabcp b on a.codclaveopectaabono=b.codclaveopecta
  	where
  		a.fecdia between trunc(add_months(sysdate, :intervalo_1),'mm') and trunc(last_day(add_months(sysdate, :intervalo_2))) and
  		a.tiptransaccionagenteviabcp in('05') and
  		a.tipesttransaccionagenteviabcp = 'P' and
		b.codclaveopecta is null and
		a.codunicocli in (select codunicocli from tmp_egbcacei_univclie)
union all
	select
         a.codclaveopectacargo,a.codunicocli,a.codclaveopectaabono,a.fecdia, a.hortransaccion,
		 a.codmoneda, a.mtotransaccion,a.tiptransaccionagenteviabcp
  	from
           t23377.tmp_movagente_p a
		   left join
               ods_v.md_agenteviabcp b on a.codclaveopectaabono=b.codclaveopecta
  	where
  		a.fecdia between trunc(add_months(sysdate, :intervalo_1),'mm') and trunc(last_day(add_months(sysdate, :intervalo_2))) and
  		a.tiptransaccionagenteviabcp in('05') and
  		a.tipesttransaccionagenteviabcp = 'P' and
		b.codclaveopecta is null and
		a.codunicocli in (select codunicocli from tmp_egbcacei_univclie)
  )
  select a.*,b.codclavecic codclavecic_sol,b.codopecta as codopecta_sol
  from tmp_movagente_sol1 a
       left join tmp_egbcacei_univctasclie b on a.codclaveopectacargo=b.codclaveopecta
  union
  select a.*,b.codclavecic codclavecic_sol,'NO APLICA' as codopecta_sol
  from tmp_movagente_sol2 a
       left join tmp_egbcacei_univctasclie b on a.codunicocli=b.codunicocli;

--create table tmp_egbcacei_trx_agente as
truncate table tmp_egbcacei_trx_agente;
insert into tmp_egbcacei_trx_agente
    with tmp_movagente_ben as
    (
     select a.*,b.codclavecic as codclavecic_ben,b.codopecta as codopecta_ben
     from tmp_egbcacei_agente_sol a
          left join  ods_v.md_cuentag94 b on a.codclaveopectaabono=b.codclaveopecta
    )
   select distinct
          a.codclavecic_sol,a.codopecta_sol,a.codclavecic_ben,a.codopecta_ben,a.fecdia,a.hortransaccion,a.codmoneda,
		  a.mtotransaccion,a.mtotransaccion * tc.mtocambioaldolar as mto_dolarizado, 
          d.destiptransaccionagenteviabcp as tipo_transaccion, 'AGENTE' as canal
   from
          tmp_movagente_ben a
          left join
                    ods_v.hd_tipocambiosaldodiario tc on a.fecdia = tc.fectipcambio and a.codmoneda = tc.codmoneda
          left join
                    ods_v.md_destipotranagenteviabcp d on a.tiptransaccionagenteviabcp = d.tiptransaccionagenteviabcp
   where
          a.codclavecic_sol<>0 and
          a.codclavecic_sol<>a.codclavecic_ben;

--*******************************************************************home banking*******************************************************************
--create table tmp_egbcacei_hm_sol as
truncate table tmp_egbcacei_hm_sol;
insert into tmp_egbcacei_hm_sol
  with tmp_movhm as
  (
  	select
           codopectaorigen,codopectadestino,fecdia,hortransaccion,codmoneda,mtotransaccion,codopehbctr
  	from
           ods_v.hd_movhomebankingtransaccion
  	where
           fecdia between trunc(add_months(sysdate, :intervalo_1),'mm') and trunc(last_day(add_months(sysdate, :intervalo_2))) and
  		   tipresultadotransaccion = 'OK' and
           codtipoperacionhb='701' and
           codopectaorigen in(select codopecta from tmp_egbcacei_univctasclie)
  )
  select
         a.*,b.codclavecic as codclavecic_sol,b.codopecta as codopecta_sol
	from
         tmp_movhm a
		 left join
               tmp_egbcacei_univctasclie b on a.codopectaorigen=b.codopecta;

--create table tmp_egbcacei_trx_hm as
truncate table  tmp_egbcacei_trx_hm;
insert into tmp_egbcacei_trx_hm
   with tmp_movhm_ben as
   (
     select
          a.*,b.codclavecic as codclavecic_ben,b.codopecta as codopecta_ben
	 from
         tmp_egbcacei_hm_sol a
             left join
                       ods_v.md_cuentag94 b on a.codopectadestino=b.codopecta
   )
      select distinct
						a.codclavecic_sol,a.codopecta_sol,a.codclavecic_ben,a.codopecta_ben,a.fecdia, a.hortransaccion,
						a.codmoneda,a.mtotransaccion,a.mtotransaccion * tc.mtocambioaldolar as mto_dolarizado,
						d.descodopehbctr as tipo_transaccion,'HOMEBANKING' as canal
    	from
           tmp_movhm_ben a
    			  left join
                      ods_v.hd_tipocambiosaldodiario tc on a.fecdia = tc.fectipcambio and a.codmoneda = tc.codmoneda
    			  left join
                      ods_v.md_descodigoopehbctr d on a.codopehbctr = d.codopehbctr
    	where
            a.codclavecic_sol<>0 and
    		a.codclavecic_sol<>a.codclavecic_ben;

--*******************************************************************cajero*******************************************************************
--create table tmp_egbcacei_cajero_sol as
truncate table tmp_egbcacei_cajero_sol;
insert into tmp_egbcacei_cajero_sol
  with tmp_movcajero_sol1 as
  (
  	select
           codopectadesde,codclavecic,codopectahacia,fecdia,hortransaccion,
           case
                when mtotransaccionsol is null or mtotransaccionme is null then coalesce(codmonedactadesde,codmonedactahacia)
                else codmonedatran
           end codmoneda,
           coalesce(
            		   case
                				when codmonedatran = '0001' then mtotransaccionsol
                				else mtotransaccionme
            		   end,
					   mtotransaccionorigen
                   ) mtotransaccion,
           codtrancajero,mtotransaccionsol,mtotransaccionme,codcajero
  	from
           ods_v.hd_movimientocajero
  	where
			fecdia between trunc(add_months(sysdate, :intervalo_1),'mm') and trunc(last_day(add_months(sysdate, :intervalo_2))) and
    		codtrancajero in ('40','10') and
			flgvalida='S' and
           codopectadesde in (select codopecta from tmp_egbcacei_univctasclie)
  ),tmp_movcajero_sol2 as
 (
  	select
           codopectadesde,codclavecic,codopectahacia,fecdia,hortransaccion,
           case
                when mtotransaccionsol is null or mtotransaccionme is null then coalesce(codmonedactadesde,codmonedactahacia)
                else codmonedatran
           end codmoneda,
           coalesce(
            		   case
                				when codmonedatran = '0001' then mtotransaccionsol
                				else mtotransaccionme
            		   end, mtotransaccionorigen
                   ) mtotransaccion,
           codtrancajero,mtotransaccionsol,mtotransaccionme,codcajero
  	from
           ods_v.hd_movimientocajero
  	where
			fecdia between trunc(add_months(sysdate, :intervalo_1),'mm') and trunc(last_day(add_months(sysdate, :intervalo_2))) and
			codtrancajero in ('20') and 
    		flgvalida='S' and
			codclavecic in (select codclavecic from tmp_egbcacei_univclie)
 )
 select a.*,b.codclavecic as codclavecic_sol,b.codopecta as codopecta_sol
 from tmp_movcajero_sol1 a
      left join  tmp_egbcacei_univctasclie b on a.codopectadesde=b.codopecta
 union
 select a.*, a.codclavecic as codclavecic_sol,'NO APLICA' as codopecta_sol
 from tmp_movcajero_sol2 a;

create table tmp_movcajero_sol1 as
select
           codopectadesde,codclavecic,codopectahacia,fecdia,hortransaccion,
           case
                when mtotransaccionsol is null or mtotransaccionme is null then coalesce(codmonedactadesde,codmonedactahacia)
                else codmonedatran
           end codmoneda,
           coalesce(
            		   case
                				when codmonedatran = '0001' then mtotransaccionsol
                				else mtotransaccionme
            		   end,
					   mtotransaccionorigen
                   ) mtotransaccion,
           codtrancajero,mtotransaccionsol,mtotransaccionme,codcajero
  	from
           ods_v.hd_movimientocajero
  	where
			fecdia between trunc(add_months(sysdate, :intervalo_1),'mm') and trunc(last_day(add_months(sysdate, :intervalo_2))) and
    		codtrancajero in ('40','10') and
			flgvalida='S';

--drop table tmp_movcajero_sol2;
--create table tmp_movcajero_sol2 as
truncate table tmp_movcajero_sol2;
insert into tmp_movcajero_sol2
select
           codopectadesde,codclavecic,codopectahacia,fecdia,hortransaccion,
           case
                when mtotransaccionsol is null or mtotransaccionme is null then coalesce(codmonedactadesde,codmonedactahacia)
                else codmonedatran
           end codmoneda,
           coalesce(
            		   case
                				when codmonedatran = '0001' then mtotransaccionsol
                				else mtotransaccionme
            		   end, mtotransaccionorigen
                   ) mtotransaccion,
           codtrancajero,mtotransaccionsol,mtotransaccionme,codcajero
  	from
           ods_v.hd_movimientocajero
  	where
			fecdia between trunc(add_months(sysdate, :intervalo_1),'mm') and trunc(last_day(add_months(sysdate, :intervalo_2))) and
			codtrancajero in ('20') and
    		flgvalida='S';

--create table tmp_egbcacei_cajero_sol as
truncate table tmp_egbcacei_cajero_sol;
insert into tmp_egbcacei_cajero_sol
select a.*,b.codclavecic as codclavecic_sol,b.codopecta as codopecta_sol
 from tmp_movcajero_sol1 a
      left join  tmp_egbcacei_univctasclie b on a.codopectadesde=b.codopecta
 union
 select a.*, a.codclavecic as codclavecic_sol,'NO APLICA' as codopecta_sol
 from tmp_movcajero_sol2 a
      left join tmp_egbcacei_univclie b on a.codclavecic = b.codclavecic;

--create table tmp_egbcacei_trx_cajero as
truncate table tmp_egbcacei_trx_cajero;
insert into  tmp_egbcacei_trx_cajero
    with tmp_cajero_ben as
   (
	select   a.*,nvl(b.codclavecic,:intervalo_2) as codclavecic_ben,nvl(b.codopecta,'NO APLICA') as codopecta_ben
	from tmp_egbcacei_cajero_sol a
        left join ods_v.md_cuentag94 b on a.codopectahacia=b.codopecta
   )
   select distinct
                   a.codclavecic_sol,a.codopecta_sol,a.codclavecic_ben,a.codopecta_ben,a.fecdia, a.hortransaccion, a.codmoneda, a.mtotransaccion,
                  (case when a.codmoneda = '0001' then coalesce(a.mtotransaccionsol,a.mtotransaccion) else coalesce(a.mtotransaccionme,a.mtotransaccion) end) * tc.mtocambioaldolar as mto_dolarizado,
                  d.descodtrancajero as tipo_transaccion, 'CAJERO' as canal
    from
                  tmp_cajero_ben a
                  left join
                            ods_v.hd_tipocambiosaldodiario tc on a.fecdia = tc.fectipcambio and a.codmoneda = tc.codmoneda
                  left join
                            ods_v.mm_descodigotransaccioncajero d on a.codtrancajero = d.codtrancajero
    where
          a.codclavecic_sol<>0 and
          a.codclavecic_sol<>a.codclavecic_ben and
          a.codmoneda is not null;

--***************************************************telecredito***************************************************
--create table tmp_egbcacei_telcre_sol as
truncate table tmp_egbcacei_telcre_sol;
insert into tmp_egbcacei_telcre_sol
  with tmp_movtelcre_sol as
  (
  	select
           codopecta,codopectaabono,fectransferencia as fecdia,hortransferencia as hortransaccion,
		   codmoneda,mtotransferencia as mtotransaccion,tipoperaciontelcre
  	from
           ods_v.hs_movimientotransferenctelcre
  	where
			fectransferencia between trunc(add_months(sysdate, :intervalo_1),'mm') and trunc(last_day(add_months(sysdate, :intervalo_2))) and
			tipesttransferenciatelcre=40                           and
    		tipoperaciontelcre in ('OMTRMT','OMTRTH','OMTRTN') and
			codopecta in (select codopecta from tmp_egbcacei_univctasclie)
  )
	select
          a.*,b.codclavecic as codclavecic_sol,b.codopecta as codopecta_sol
	from
          tmp_movtelcre_sol a
		 left join
              tmp_egbcacei_univctasclie b on a.codopecta=b.codopecta;

--create table tmp_egbcacei_trx_telcre as
truncate table 	tmp_egbcacei_trx_telcre;
insert into tmp_egbcacei_trx_telcre
  with tmp_ben as
  (
	  select a.*,b.codclavecic as codclavecic_ben,b.codopecta as codopecta_ben
	  from tmp_egbcacei_telcre_sol a
			 left join
					ods_v.md_cuentag94 b on a.codopectaabono=b.codopecta
  )
  select distinct
                a.codclavecic_sol,a.codopecta_sol,a.codclavecic_ben,a.codopecta_ben,a.fecdia, a.hortransaccion, a.codmoneda, a.mtotransaccion,
				a.mtotransaccion * tc.mtocambioaldolar as mto_dolarizado,d.destipoperaciontelcre as tipo_transaccion,'TELECREDITO' as canal
    	from
           tmp_ben a
    			  left join
                      ods_v.hd_tipocambiosaldodiario tc on a.fecdia = tc.fectipcambio and a.codmoneda = tc.codmoneda
    			  left join
                      ods_v.ms_tipooperaciontelcre d on a.tipoperaciontelcre = d.tipoperaciontelcre
    	where
            a.codclavecic_sol<>0 and
    		a.codclavecic_sol<>a.codclavecic_ben;

--***************************************************ggtt***************************************************
--create table tmp_egbcacei_ggtt_sol as
truncate table tmp_egbcacei_ggtt_sol;
insert into tmp_egbcacei_ggtt_sol
  with tmp_movggtt_sol as
  (
    select
           codclavecicordenante,codclavecicbeneficiario,fecdia,horemision,codmoneda,
           mtoimporteoperacion,codproducto,codswiftbcodestino,codswiftbcoemisor
    from
           ods_v.hd_documentoemitidoggtt
    where
          fecdia between trunc(add_months(sysdate, :intervalo_1),'mm') and trunc(last_day(add_months(sysdate, :intervalo_2))) and
          codtipestadotransaccion = '00' and
          codclavecicordenante in (select codclavecic from tmp_egbcacei_univclie)
  )
	select
          a.*,a.codclavecicordenante as codclavecic_sol,'NO APLICA' as codopecta_sol
	from
          tmp_movggtt_sol a;

--create table tmp_egbcacei_trx_ggtt as
truncate table tmp_egbcacei_trx_ggtt;
insert into tmp_egbcacei_trx_ggtt
       with tmp_ggtt_ben as
       (
        select
               a.*,a.codclavecicbeneficiario as codclavecic_ben,'NO APLICA' as codopecta_ben
        from tmp_egbcacei_ggtt_sol a
       )
      select distinct
                    a.codclavecic_sol,a.codopecta_sol,a.codclavecic_ben,a.codopecta_ben,a.fecdia, a.horemision as hortransaccion, a.codmoneda, a.mtoimporteoperacion as mtotransaccion,
    				a.mtoimporteoperacion * tc.mtocambioaldolar as mto_dolarizado, d.descodproducto as tipo_transaccion,'DOCUMENTO_GGTT' as canal
    	from
      		tmp_ggtt_ben a
      		left join
                    ods_v.hd_tipocambiosaldodiario tc on a.fecdia = tc.fectipcambio and a.codmoneda = tc.codmoneda
      		left join
                    ods_v.md_descodigoproducto d on a.codproducto = d.codproducto
    	where
    		a.codclavecic_sol not in (0,3288453) and
    		a.codclavecic_sol<>a.codclavecic_ben and
            codclavecic_ben<>3288453;

--create table tmp_egbcacei_vent_sol1_1 as
truncate table tmp_egbcacei_vent_sol1_1;
insert into tmp_egbcacei_vent_sol1_1
    select a.codclaveopecta,a.codclaveopectadestino,a.fecdia, a.horinitransaccion as hortransaccion,
           a.codmonedatransaccion as codmoneda,a.codsucage,a.codsesion,
    		   case
      				when a.mtotransaccioncta <> 0 then a.mtotransaccioncta
      				else a.mtotransaccion
    		   end as mtotransaccion,
           a.codtransaccionventanilla
  	from ods_v.hd_transaccionventanilla a
  	where   a.fecdia between trunc(add_months(sysdate, :intervalo_1),'mm') and trunc(last_day(add_months(sysdate, :intervalo_2))) and
      		a.codtransaccionventanilla in (60,62,63)  and
      		a.flgtransaccionaprobada = 'S';

--create table tmp_egbcacei_vent_sol1 as
drop table   tmp_egbcacei_vent_sol1_1;
truncate table tmp_egbcacei_vent_sol1;
insert into tmp_egbcacei_vent_sol1
    select a.*,
			coalesce(case
                        when b.codunicoclisolicitante='.' then ''
                        else b.codunicoclisolicitante
					end,
            		case
                       when b.codunicocliordenante='.' then ''
                       else b.codunicocliordenante
					end) as codunicocli_sol
  	from tmp_egbcacei_vent_sol1_1 a
           inner join ods_v.hd_movlavadodineroventanilla b on a.fecdia = b.fecdia and a.codsucage = b.codsucage and a.codsesion = b.codsesion;

--create table tmp_egbcacei_vent_sol2 as
truncate table tmp_egbcacei_vent_sol2;
insert into tmp_egbcacei_vent_sol2
     select a.codclaveopecta,a.codclaveopectadestino,a.fecdia, a.horinitransaccion as hortransaccion,
            a.codmonedatransaccion as codmoneda,a.codsucage,a.codsesion,
			case
				when a.mtotransaccioncta <> 0 then a.mtotransaccioncta
      			else a.mtotransaccion
    		end as mtotransaccion,a.codtransaccionventanilla
  	from  	ods_v.hd_transaccionventanilla a
  	where 	fecdia between trunc(add_months(sysdate, :intervalo_1),'mm') and trunc(last_day(add_months(sysdate, :intervalo_2))) and
      		a.codtransaccionventanilla in (159,186,187,188,142,143,145) and
      		a.flgtransaccionaprobada = 'S' and
			a.codclaveopecta in (select codclaveopecta from tmp_egbcacei_univctasclie);

--create table tmp_egbcacei_vent_sol as
truncate table tmp_egbcacei_vent_sol;
insert into tmp_egbcacei_vent_sol
   select distinct
		a.codclaveopecta,a.codclaveopectadestino,a.fecdia,a.hortransaccion,
        a.codmoneda,a.codsucage,a.codsesion,a.mtotransaccion,a.codtransaccionventanilla,
        b.codclavecic as codclavecic_sol,'NO APLICA' as codopecta_sol
   from tmp_egbcacei_vent_sol1 a
        left join tmp_egbcacei_univctasclie b on a.codunicocli_sol=b.codunicocli
   where a.codunicocli_sol in (select codunicocli from tmp_egbcacei_univclie)
   union
   select distinct
		a.*,b.codclavecic as codclavecic_sol,b.codopecta as codopecta_sol
   from tmp_egbcacei_vent_sol2 a
        left join tmp_egbcacei_univctasclie b on a.codclaveopecta=b.codclaveopecta;

--create table tmp_egbcacei_vent_ben as
truncate table tmp_egbcacei_vent_ben;
insert into tmp_egbcacei_vent_ben
    select  a.*,nvl(c.codclavecic,:intervalo_2) as codclavecic_ben,nvl(c.codopecta,'NO APLICA') as codopecta_ben
   from tmp_egbcacei_vent_sol a
            left join ods_v.md_cuentag94 c on a.codclaveopectadestino=c.codclaveopecta;

--create table tmp_egbcacei_trx_ventanilla as
truncate table tmp_egbcacei_trx_ventanilla;
insert into tmp_egbcacei_trx_ventanilla
	select distinct a.codclavecic_sol,a.codopecta_sol,a.codclavecic_ben,a.codopecta_ben,a.fecdia,a.hortransaccion,a.codmoneda,a.mtotransaccion,
        a.mtotransaccion * tc.mtocambioaldolar as mto_dolarizado, d.destransaccionventanilla as tipo_transaccion, 'VENTANILLA' as canal
	from tmp_egbcacei_vent_ben a
            left join ods_v.hd_tipocambiosaldodiario tc on a.fecdia = tc.fectipcambio and a.codmoneda = tc.codmoneda
            left join ods_v.md_destransaccionventanilla d on a.codtransaccionventanilla = d.codtransaccionventanilla
	where a.codclavecic_sol<>0 and
         a.codclavecic_sol<>a.codclavecic_ben;

--***************************************************banni***********************************************************
--create table tmp_egbcacei_banni_sol_ben as
truncate table tmp_egbcacei_banni_sol_ben;
insert into tmp_egbcacei_banni_sol_ben
  select
         a.hortransaccion,b.fecdia,b.codmoneda,b.mtooperacion,b.mtooperaciondol as mto_dolarizado,nvl(cgre.codopecta,'NO APLICA') as codopecta_sol,
         cl.codclavecic as codclavecic_sol,b.codpaisbeneficiario,b.codproducto,:intervalo_2 as codclavecic_ben,'NO APLICA' as codopecta_ben,
         upper(p.nombrepais) as codpaisdestino
  from
       ods_v.hd_movimientobanni  a
       left join
                 ods_v.md_operacionban b on a.codclaveopecta = b.codclaveopecta
       inner join
                  tmp_egbcacei_univclie cl on b.codclavecic=cl.codclavecic
       left join
                 tmp_egbcacei_univctasclie cgre on a.codclaveopectaafectada = cgre.codclaveopecta
       left join
                 s55632.md_codigopais p on trim(b.codpaisbeneficiario) = trim(p.codpais3)
  where
        a.fecdia between trunc(add_months(sysdate, :intervalo_1),'mm') and trunc(last_day(add_months(sysdate, :intervalo_2))) and
        a.codproducto = 'TRAEXT' and
        b.flgregeliminado='N' and
        b.codpaisbeneficiario not in ('PER');

--create table tmp_egbcacei_trx_banni as
truncate table tmp_egbcacei_trx_banni;
insert into tmp_egbcacei_trx_banni
	select distinct
            a.codclavecic_sol,a.codopecta_sol,a.codclavecic_ben,a.codopecta_ben,a.fecdia, a.hortransaccion, a.codmoneda, a.mtooperacion as mtotransaccion,
			a.mto_dolarizado,d.descodproducto as tipo_transaccion,'BANNI' as canal
	from  tmp_egbcacei_banni_sol_ben a
      		left join ods_v.md_descodigoproducto d on a.codproducto = d.codproducto
	where 	a.codclavecic_sol<>0 and
			a.codclavecic_sol<>a.codclavecic_ben;

--***************************************************transferencias interbancarias***********************************************************
--create table tmp_egbcacei_ttib_sol as
truncate table tmp_egbcacei_ttib_sol;
insert into tmp_egbcacei_ttib_sol
	select 	distinct
          a.fectransaccion fecdia,a.hortransaccion,a.codopetransaccionttib,a.codclaveopectabeneficiario,
			    a.codmoneda,a.mtotransaccion,b.codclavecic as codclavecic_sol,b.codopecta as codopecta_sol
	from    ods_v.hd_movimientottib a
		inner join tmp_egbcacei_univctasclie b on a.codclaveopectaordenante=b.codclaveopecta
	where 	a.fectransaccion between trunc(add_months(sysdate, :intervalo_1),'mm') and trunc(last_day(add_months(sysdate, :intervalo_2))) and
			    a.tipestttib='00' and
			    a.codopetransaccionttib not  in (223,221);

--create table tmp_egbcacei_trx_ttib as
truncate table tmp_egbcacei_trx_ttib;
insert into tmp_egbcacei_trx_ttib
       with tmp_ben as
       (
       select a.*,
              case
                  when a.codclaveopectabeneficiario is null or b.codclaveopecta is null then :intervalo_2
                  else b.codclavecic
              end codclavecic_ben,'NO APLICA' as codopecta_ben
       from tmp_egbcacei_ttib_sol a
            left join ods_v.md_cuentag94 b on a.codclaveopectabeneficiario=b.codclaveopecta
       )
       select distinct
             a.codclavecic_sol,a.codopecta_sol,a.codclavecic_ben,a.codopecta_ben,a.fecdia,a.hortransaccion,a.codmoneda,a.mtotransaccion,
    				a.mtotransaccion * tc.mtocambioaldolar as mto_dolarizado,d.destipoperacionttib as tipo_transaccion,'TTIB' as canal
    	from
      		tmp_ben a
      		left join
                    ods_v.hd_tipocambiosaldodiario tc on a.fecdia = tc.fectipcambio and a.codmoneda = tc.codmoneda
      		left join
                    ods_v.md_destipoperacionttib d on a.codopetransaccionttib = d.tipoperacionttib
    	where
    		    a.codclavecic_sol<>a.codclavecic_ben and
				a.codclavecic_sol<>0;
commit;
quit;