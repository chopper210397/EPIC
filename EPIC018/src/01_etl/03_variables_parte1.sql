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

--********************************************************agente********************************************************
--acortamos el periodo de la tabla y extraemos los codclavecic beneficiarios
truncate table tmp_ingcashbcacei_agen_ben_var;
insert into tmp_ingcashbcacei_agen_ben_var
--create table tmp_ingcashbcacei_agen_ben_var tablespace d_aml_99 as
with tmp as (
	select
         a.codclaveopectacargo,a.codunicocli,a.codclaveopectaabono,a.fecdia, a.hortransaccion, a.codmoneda,
         a.mtotransaccion,a.tiptransaccionagenteviabcp,c.codclavecic as codclavecic_ben,b.codopecta as codopecta_ben,b.tipbanca as tipbanca_ben
	from
         t23377.tmp_movagente_i a
		 left join
               ods_v.md_agenteviabcp b on a.codclaveopectaabono=b.codclaveopecta
		inner  join
                  tmp_ingcashbcacei_univctasclie c on a.codclaveopectaabono=c.codclaveopecta
	where
		a.fecdia between trunc(add_months(sysdate,:intervalo_1),'mm') and trunc(last_day(add_months(sysdate,:intervalo_2))) and
		a.tiptransaccionagenteviabcp in('03','05') and
		a.tipesttransaccionagenteviabcp = 'P' and
		b.codclaveopecta is null
	union all
	select
         a.codclaveopectacargo,a.codunicocli,a.codclaveopectaabono,a.fecdia, a.hortransaccion, a.codmoneda,
         a.mtotransaccion,a.tiptransaccionagenteviabcp,c.codclavecic as codclavecic_ben,b.codopecta as codopecta_ben,b.tipbanca as tipbanca_ben
	from
         t23377.tmp_movagente_p a
		 left join
               ods_v.md_agenteviabcp b on a.codclaveopectaabono=b.codclaveopecta
		 inner  join
                  tmp_ingcashbcacei_univctasclie c on a.codclaveopectaabono=c.codclaveopecta
	where
		a.fecdia between trunc(add_months(sysdate,:intervalo_1),'mm') and trunc(last_day(add_months(sysdate,:intervalo_2))) and
		a.tiptransaccionagenteviabcp in('03','05') and
		a.tipesttransaccionagenteviabcp = 'P' and
		b.codclaveopecta is null
		)
	select distinct * from tmp ;

----codclavecic solicitante - transferencias
truncate table tmp_ingcashbcacei_agen_sol_var;
insert into tmp_ingcashbcacei_agen_sol_var
--create table tmp_ingcashbcacei_agen_sol_var tablespace d_aml_99 as
       with tmp_agen_sol1 as
       (
         select
                a.*,b.codclavecic as codclavecic_sol,b.codopecta as codopecta_sol
         from
              tmp_ingcashbcacei_agen_ben_var a
              left join
                        ods_v.md_cuenta b on a.codclaveopectacargo=b.codclaveopecta
         where
               a.tiptransaccionagenteviabcp in ('03')
       ),
       tmp_agen_sol2 as
       (
          select
                 a.*,b.codclavecic as codclavecic_sol,'NO APLICA' as codopecta_sol
          from
               tmp_ingcashbcacei_agen_ben_var a
               left join
                         ods_v.md_cliente b on a.codunicocli=b.codunicocli
          where
                a.tiptransaccionagenteviabcp in ('05')
       )
       select
              a.codclavecic_sol,a.codopecta_sol,a.codclavecic_ben,a.codopecta_ben,a.tipbanca_ben,a.fecdia,
              a.hortransaccion,a.codmoneda,a.mtotransaccion,a.tiptransaccionagenteviabcp
       from
              tmp_agen_sol1 a
       union
       select
              b.codclavecic_sol,b.codopecta_sol,b.codclavecic_ben,b.codopecta_ben,b.tipbanca_ben,b.fecdia,
              b.hortransaccion,b.codmoneda,b.mtotransaccion,b.tiptransaccionagenteviabcp
       from
              tmp_agen_sol2 b;

truncate table tmp_ingcashbcacei_trx_agente_var;
insert into tmp_ingcashbcacei_trx_agente_var
--create table tmp_ingcashbcacei_trx_agente_var tablespace d_aml_99 as
   select distinct
          a.codclavecic_sol,a.codopecta_sol,a.codclavecic_ben,a.codopecta_ben,a.tipbanca_ben,a.fecdia,
          a.hortransaccion,a.codmoneda,a.mtotransaccion,a.mtotransaccion * tc.mtocambioaldolar as mto_dolarizado,
          d.destiptransaccionagenteviabcp as tipo_transaccion, 'AGENTE' as canal,' ' codpaisorigen
   from
          tmp_ingcashbcacei_agen_sol_var a
          left join
                    ods_v.hd_tipocambiosaldodiario tc on a.fecdia = tc.fectipcambio and a.codmoneda = tc.codmoneda
          left join
                    ods_v.md_destipotranagenteviabcp d on a.tiptransaccionagenteviabcp = d.tiptransaccionagenteviabcp
   where
          a.codclavecic_ben<>0 and
          a.codclavecic_sol<>a.codclavecic_ben;

--***************************************************transferencias del exterior (remesas)***********************************************************
--acortamos el periodo de la tabla
truncate table tmp_ingcashbcacei_remittance_ben_var;
insert into tmp_ingcashbcacei_remittance_ben_var
--create table tmp_ingcashbcacei_remittance_ben_var tablespace d_aml_99 as
    select
           -1 as codclavecic_sol, codclaveopectaafectada, fecdia,hortransaccion,codmoneda,mtotransaccion,codproducto,mtotransacciondol,codpaisorigen,b.codclavecic as codclavecic_ben,b.codopecta as codopecta_ben,b.tipbanca as tipbanca_ben
    from
          ods_v.hd_movoperativoremittance a
		  		   inner join
                 tmp_ingcashbcacei_univctasclie b on a.codclaveopectaafectada=b.codclaveopecta
    where
          fecdia between trunc(add_months(sysdate,:intervalo_1),'mm') and trunc(last_day(add_months(sysdate,:intervalo_2))) and
          codproducto in ('TRAXAB','TRAXRE','TRAXVE');

--tabla final (filtrando codclavecic <> 0)
truncate table tmp_ingcashbcacei_trx_remittance_var;
insert into tmp_ingcashbcacei_trx_remittance_var
--create table tmp_ingcashbcacei_trx_remittance_var tablespace d_aml_99 as
	select distinct
                  a.codclavecic_sol,'NO APLICA' as codopecta_sol,a.codclavecic_ben,a.codopecta_ben,a.tipbanca_ben,a.fecdia, a.hortransaccion, a.codmoneda, a.mtotransaccion,
			            a.mtotransacciondol as mto_dolarizado, d.descodproducto as tipo_transaccion, 'REMITTANCE' as canal,upper(p.nombrepais) as codpaisorigen
	from
       tmp_ingcashbcacei_remittance_ben_var a
		   left join
                 ods_v.md_descodigoproducto d on a.codproducto = d.codproducto
		   left join
                 s55632.md_codigopais p on trim(a.codpaisorigen) = p.codpais3
	where a.codclavecic_ben<>0;

--***************************************************cajero***********************************************************
--acortamos el periodo de la tabla
truncate table tmp_ingcashbcacei_cajero_ben_var;
insert into tmp_ingcashbcacei_cajero_ben_var
--create table tmp_ingcashbcacei_cajero_ben_var tablespace d_aml_99 as
  	select
           codopectadesde,a.codclavecic,codopectahacia,fecdia,hortransaccion,
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
           codtrancajero,mtotransaccionsol,mtotransaccionme,codcajero,b.codclavecic as codclavecic_ben,b.codopecta as codopecta_ben,b.tipbanca as tipbanca_ben
  	from
           ods_v.hd_movimientocajero a
	inner join
               tmp_ingcashbcacei_univctasclie b on a.codopectahacia=b.codopecta
  	where
           fecdia between trunc(add_months(sysdate,:intervalo_1),'mm') and trunc(last_day(add_months(sysdate,:intervalo_2))) and
    		   codtrancajero in ('20','40') and
    		   flgvalida='S';

----codclavecic solicitante - transferencias
truncate table tmp_ingcashbcacei_cajero_sol_var;
insert into tmp_ingcashbcacei_cajero_sol_var
--create table tmp_ingcashbcacei_cajero_sol_var tablespace d_aml_99 as
       with tmp_cajero_sol1 as
       (
         select
                a.*,b.codclavecic as codclavecic_sol,a.codopectadesde as codopecta_sol
         from
              tmp_ingcashbcacei_cajero_ben_var a
              left join
                        ods_v.md_cuenta b on a.codopectadesde=b.codopecta
         where
               a.codtrancajero='40'
       ),
       tmp_cajero_sol2 as
       (
         select
                 a.*, a.codclavecic as codclavecic_sol,'NO APLICA' as codopecta_sol
         from
                 tmp_ingcashbcacei_cajero_ben_var a
         where
                 a.codtrancajero='20'
       )
       select
               a.codclavecic_sol,a.codopecta_sol,a.codclavecic_ben,codopecta_ben,a.tipbanca_ben,a.fecdia,
               a.hortransaccion,a.codmoneda,a.mtotransaccion,a.codtrancajero,mtotransaccionsol,mtotransaccionme,a.codcajero
       from
              tmp_cajero_sol1 a
       union
       select
               b.codclavecic_sol,b.codopecta_sol,b.codclavecic_ben,b.codopecta_ben,b.tipbanca_ben,b.fecdia,
               b.hortransaccion,b.codmoneda,b.mtotransaccion,b.codtrancajero,b.mtotransaccionsol,b.mtotransaccionme,b.codcajero
       from
              tmp_cajero_sol2 b;

truncate table tmp_ingcashbcacei_trx_cajero_var;
insert into tmp_ingcashbcacei_trx_cajero_var
--create table tmp_ingcashbcacei_trx_cajero_var tablespace d_aml_99 as
    select distinct
                   a.codclavecic_sol,a.codopecta_sol,a.codclavecic_ben,codopecta_ben,a.tipbanca_ben,a.fecdia, a.hortransaccion, a.codmoneda, a.mtotransaccion,
                  (case when a.codmoneda = '0001' then coalesce(a.mtotransaccionsol,a.mtotransaccion) else coalesce(a.mtotransaccionme,a.mtotransaccion) end) * tc.mtocambioaldolar as mto_dolarizado,
                  d.descodtrancajero as tipo_transaccion, 'CAJERO' as canal, ' ' codpaisorigen
    from
                   tmp_ingcashbcacei_cajero_sol_var a
                  left join
                            ods_v.hd_tipocambiosaldodiario tc on a.fecdia = tc.fectipcambio and a.codmoneda = tc.codmoneda
                  left join
                            ods_v.mm_descodigotransaccioncajero d on a.codtrancajero = d.codtrancajero
    where
          a.codclavecic_ben<>0 and
          a.codclavecic_sol<>a.codclavecic_ben;

--***************************************************home banking***********************************************************
truncate table tmp_ingcashbcacei_hm_ben_var;
insert into tmp_ingcashbcacei_hm_ben_var
--create table tmp_ingcashbcacei_hm_ben_var tablespace d_aml_99 as
  	select
           codopectaorigen,codopectadestino,fecdia,hortransaccion,codmoneda,mtotransaccion,codopehbctr,b.codclavecic as codclavecic_ben,b.codopecta as codopecta_ben,b.tipbanca as tipbanca_ben
  	from
           ods_v.hd_movhomebankingtransaccion a
	inner join
               tmp_ingcashbcacei_univctasclie b on a.codopectadestino=b.codopecta
  	where
           fecdia between trunc(add_months(sysdate,:intervalo_1),'mm') and trunc(last_day(add_months(sysdate,:intervalo_2))) and
  		   tipresultadotransaccion = 'OK' and
           codtipoperacionhb='701';

--extraemos la info de los solicitantes
truncate table tmp_ingcashbcacei_trx_hm_var;
insert into tmp_ingcashbcacei_trx_hm_var
--create table tmp_ingcashbcacei_trx_hm_var tablespace d_aml_99 as
       with tmp_hm_sol as
       (
        select
               a.*,coalesce(c.codclavecic,b.codclavecic) as codclavecic_sol,a.codopectaorigen as codopecta_sol
        from tmp_ingcashbcacei_hm_ben_var a
             left join
                       ods_v.md_cuenta b on a.codopectaorigen=b.codopecta
             left join
                       ods_v.md_cuentag94 c on a.codopectaorigen=c.codopecta
       )
      select distinct
                      a.codclavecic_sol,a.codopecta_sol,a.codclavecic_ben,a.codopecta_ben,a.tipbanca_ben,a.fecdia, a.hortransaccion, a.codmoneda, a.mtotransaccion,
    					        a.mtotransaccion * tc.mtocambioaldolar as mto_dolarizado, d.descodopehbctr as tipo_transaccion,'HOMEBANKING' as canal,' ' codpaisorigen
    	from
           tmp_hm_sol a
    			  left join
                      ods_v.hd_tipocambiosaldodiario tc on a.fecdia = tc.fectipcambio and a.codmoneda = tc.codmoneda
    			  left join
                      ods_v.md_descodigoopehbctr d on a.codopehbctr = d.codopehbctr
    	where
            a.codclavecic_ben<>0 and
    		    a.codclavecic_sol<>a.codclavecic_ben;

--***************************************************ventanilla***********************************************************
--acortamos el periodo de la tabla
truncate table tmp_ingcashbcacei_vent_ben_var;
insert into tmp_ingcashbcacei_vent_ben_var
--create table tmp_ingcashbcacei_vent_ben_var tablespace d_aml_99 as
  	select
           a.codclaveopecta,a.codclaveopectadestino,a.fecdia, a.horinitransaccion as hortransaccion,a.codmonedatransaccion as codmoneda,a.codsucage,a.codsesion,
    		   case
      				when a.mtotransaccioncta <> 0 then a.mtotransaccioncta
      				else a.mtotransaccion
    		   end as mtotransaccion,a.codtransaccionventanilla,b.codclavecic as codclavecic_ben,b.codopecta as codopecta_ben,b.tipbanca as tipbanca_ben
  	from
           ods_v.hd_transaccionventanilla a
	inner join
       tmp_ingcashbcacei_univctasclie b on a.codclaveopectadestino=b.codclaveopecta
  	where
            fecdia between trunc(add_months(sysdate,:intervalo_1),'mm') and trunc(last_day(add_months(sysdate,:intervalo_2))) and
      		a.codtransaccionventanilla in (60,62,63,159,186,187,188) and
      		a.flgtransaccionaprobada = 'S';

truncate table tmp_ingcashbcacei_ventanilla_sol_var;
insert into tmp_ingcashbcacei_ventanilla_sol_var
--create table tmp_ingcashbcacei_ventanilla_sol_var tablespace d_aml_99 as
       with tmp_vent_sol1 as
       (
         select
                a.*,coalesce(case
                                   when b.codunicoclisolicitante='.' then ''
                                   else b.codunicoclisolicitante
                              end,
                        		  case
                                  when b.codunicocliordenante='.' then ''
                                  else b.codunicocliordenante
                              end) as codunicocli_sol
          from
               tmp_ingcashbcacei_vent_ben_var a
               inner join
                     ods_v.hd_movlavadodineroventanilla b on a.fecdia = b.fecdia and a.codsucage = b.codsucage and a.codsesion = b.codsesion
          where
                a.codtransaccionventanilla in (60,62,63)
       ),
       tmp_vent_sol2 as
       (
         select
               a.*,b.codclavecic as codclavecic_sol,b.codopecta as codopecta_sol
         from
                tmp_ingcashbcacei_vent_ben_var a
                left join
                          ods_v.md_cuenta b on a.codclaveopecta=b.codclaveopecta
         where
               a.codtransaccionventanilla in (159,186,187,188)
       )
        select
               b.codclavecic as codclavecic_sol,'NO APLICA' as codopecta_sol,a.codclavecic_ben,a.codopecta_ben,a.tipbanca_ben,
               a.fecdia,a.hortransaccion,a.codmoneda,a.mtotransaccion,a.codtransaccionventanilla,a.codsucage
        from
              tmp_vent_sol1 a
              left join
                        ods_v.md_cliente b on a.codunicocli_sol=b.codunicocli
        union
        select
               b.codclavecic_sol,b.codopecta_sol,b.codclavecic_ben,b.codopecta_ben,b.tipbanca_ben,b.fecdia,b.hortransaccion,
               b.codmoneda,b.mtotransaccion,b.codtransaccionventanilla,b.codsucage
        from
             tmp_vent_sol2 b;

truncate table tmp_ingcashbcacei_trx_ventanilla_var;
insert into tmp_ingcashbcacei_trx_ventanilla_var
--create table tmp_ingcashbcacei_trx_ventanilla_var tablespace d_aml_99 as
  select distinct
         a.codclavecic_sol,a.codopecta_sol,a.codclavecic_ben,a.codopecta_ben,a.tipbanca_ben,a.fecdia,a.hortransaccion,a.codmoneda,a.mtotransaccion,
         a.mtotransaccion * tc.mtocambioaldolar as mto_dolarizado, d.destransaccionventanilla as tipo_transaccion, 'VENTANILLA' as canal,' ' codpaisorigen
  from
       tmp_ingcashbcacei_ventanilla_sol_var a
          left join
                    ods_v.hd_tipocambiosaldodiario tc on a.fecdia = tc.fectipcambio and a.codmoneda = tc.codmoneda
          left join
                    ods_v.md_destransaccionventanilla d on a.codtransaccionventanilla = d.codtransaccionventanilla
  where
        a.codclavecic_ben<>0 and
        a.codclavecic_sol<>a.codclavecic_ben;

--***************************************************telecredito***********************************************************
--acortamos el periodo de la tabla
truncate table tmp_ingcashbcacei_telcre_ben_var;
insert into tmp_ingcashbcacei_telcre_ben_var
--create table tmp_ingcashbcacei_telcre_ben_var tablespace d_aml_99 as
  	select
           a.codopecta,codopectaabono,fectransferencia as fecdia,hortransferencia as hortransaccion,codmoneda,
  		     mtotransferencia as mtotransaccion,tipoperaciontelcre,b.codclavecic as codclavecic_ben,b.codopecta as codopecta_ben,b.tipbanca as tipbanca_ben
  	from
           ods_v.hs_movimientotransferenctelcre a
	inner join
              tmp_ingcashbcacei_univctasclie b on a.codopectaabono=b.codopecta
  	where
       fectransferencia between trunc(add_months(sysdate,:intervalo_1),'mm') and trunc(last_day(add_months(sysdate,:intervalo_2))) and
	tipesttransferenciatelcre=40 and
    	tipoperaciontelcre in ('OMTRMT','OMTRTH','OMTRTN');

--extraemos la info de los solicitantes
truncate table tmp_ingcashbcacei_trx_telcre_var;
insert into tmp_ingcashbcacei_trx_telcre_var
--create table tmp_ingcashbcacei_trx_telcre_var tablespace d_aml_99 as
       with tmp_telcre_sol as
       (
        	select
                 a.*,coalesce(c.codclavecic,b.codclavecic) as codclavecic_sol,a.codopecta as codopecta_sol
        	from
               tmp_ingcashbcacei_telcre_ben_var a
        		 left join
                       ods_v.md_cuenta b on a.codopecta=b.codopecta
        		 left join
                       ods_v.md_cuentag94 c on a.codopecta=c.codopecta
       )
    	select distinct
                      a.codclavecic_sol,a.codopecta_sol ,a.codclavecic_ben,a.codopecta_ben,a.tipbanca_ben,a.fecdia, a.hortransaccion, a.codmoneda, a.mtotransaccion,
    					        a.mtotransaccion * tc.mtocambioaldolar as mto_dolarizado,d.destipoperaciontelcre as tipo_transaccion,'TELECREDITO' as canal,' ' codpaisorigen
    	from
           tmp_telcre_sol a
    			  left join
                      ods_v.hd_tipocambiosaldodiario tc on a.fecdia = tc.fectipcambio and a.codmoneda = tc.codmoneda
    			  left join
                      ods_v.ms_tipooperaciontelcre d on a.tipoperaciontelcre = d.tipoperaciontelcre
    	where
            a.codclavecic_ben<>0 and
    		    a.codclavecic_sol<>a.codclavecic_ben;

--***************************************************ggtt***********************************************************
truncate table tmp_ingcashbcacei_ggtt_ben_var;
insert into tmp_ingcashbcacei_ggtt_ben_var
--create table tmp_ingcashbcacei_ggtt_ben_var tablespace d_aml_99 as
    select
           codclavecicsolicitante,codclavecicbeneficiario as codclavecic_ben,fecdia,horemision,codmoneda,
           mtoimporteoperacion,codproducto,codswiftbcodestino,codswiftbcoemisor,'NO APLICA' as codopecta_ben,b.tipbanca as tipbanca_ben
    from
           ods_v.hd_documentoemitidoggtt a
	inner join
              tmp_ingcashbcacei_univclie b on a.codclavecicbeneficiario=b.codclavecic
    where
          fecdia between trunc(add_months(sysdate,:intervalo_1),'mm') and trunc(last_day(add_months(sysdate,:intervalo_2))) and
          codtipestadotransaccion = '00';

--extraemos la info de los solicitantes
truncate table tmp_ingcashbcacei_trx_ggtt_var;
insert into tmp_ingcashbcacei_trx_ggtt_var
--create table tmp_ingcashbcacei_trx_ggtt_var tablespace d_aml_99 as
       with tmp_ggtt_sol as
       (
        select
               a.*,a.codclavecicsolicitante as codclavecic_sol,'NO APLICA' as codopecta_sol
        from tmp_ingcashbcacei_ggtt_ben_var a
       )
      select distinct
                     a.codclavecic_sol,a.codopecta_sol,a.codclavecic_ben,a.codopecta_ben,a.tipbanca_ben,a.fecdia, a.horemision as hortransaccion, a.codmoneda, a.mtoimporteoperacion as mtotransaccion,
    			a.mtoimporteoperacion * tc.mtocambioaldolar as mto_dolarizado, d.descodproducto as tipo_transaccion,'DOCUMENTO_GGTT' as canal,upper(p.nombrepais) as codpaisorigen
    	from
      		tmp_ggtt_sol a
      		left join
                    ods_v.hd_tipocambiosaldodiario tc on a.fecdia = tc.fectipcambio and a.codmoneda = tc.codmoneda
      		left join
                    ods_v.md_descodigoproducto d on a.codproducto = d.codproducto
      		left join
                    s55632.md_codigopais p on substr(a.codswiftbcoemisor, 5, 2) = p.codpais2
    	where
            a.codclavecic_ben not in (0,3288453) and
    		    a.codclavecic_sol<>a.codclavecic_ben and
            codclavecic_sol<>3288453;

commit;
quit;