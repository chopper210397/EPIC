--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode

var intervalo_1 number 
exec :intervalo_1 := to_number(&2);

select :intervalo_1 from dual;

alter session disable parallel query;

/*************************************************************************************************
****************************** Escenario estimador de ingresos ***********************************
*************************************************************************************************/

-- creado por: Celeste Cabanillas
-- key user escenario: plaft
/*************************************************************************************************/

truncate table tmp_esting_univctasclie;
insert into tmp_esting_univctasclie
       select a.*,b.codclaveopecta as codclaveopecta ,b.codopecta as codopecta
       from tmp_esting_universo a
             left join ods_v.md_cuenta b on a.codclavecic=b.codclavecic
       where b.codclaveopecta is not null and
       b.flgregeliminado='N' and
       b.codsistemaorigen in ('SAV','IMP') and
       b.codopecta is not null and
       b.codopecta<>'.';

--********************************************************agente********************************************************
--acortamos el periodo de la tabla y extraemos los codclavecic beneficiarios
truncate table tmp_esting_agen_ben;
insert into tmp_esting_agen_ben
	select 
         a.codclaveopectacargo,a.codunicocli,a.codclaveopectaabono,a.fecdia, a.hortransaccion, a.codmoneda, 
         a.mtotransaccion,a.tiptransaccionagenteviabcp,a.codagenteviabcp,b.codclavecic as codclavecic_ben,b.codopecta as codopecta_ben
	from 
         s61751.tmp_movagente_i a
		 left join 
               ods_v.md_agenteviabcp b on a.codclaveopectaabono=b.codclaveopecta
		inner join 
                  tmp_esting_univctasclie b on a.codclaveopectaabono=b.codclaveopecta
	where  
		a.fecdia between trunc(add_months(sysdate,:intervalo_1-5),'mm') and trunc(last_day(add_months(sysdate,:intervalo_1))) and
		a.tiptransaccionagenteviabcp in('03','05') and
		a.tipesttransaccionagenteviabcp = 'P' and
		b.codclaveopecta is null 
          union all
  	select 
         a.codclaveopectacargo,a.codunicocli,a.codclaveopectaabono,a.fecdia, a.hortransaccion, a.codmoneda, 
         a.mtotransaccion,a.tiptransaccionagenteviabcp,a.codagenteviabcp,b.codclavecic as codclavecic_ben,b.codopecta as codopecta_ben
	from 
         s61751.tmp_movagente_p a
		 left join 
               ods_v.md_agenteviabcp b on a.codclaveopectaabono=b.codclaveopecta
	inner join 
		       tmp_esting_univctasclie b on a.codclaveopectaabono=b.codclaveopecta
	where  
		a.fecdia between trunc(add_months(sysdate,:intervalo_1-5),'mm') and trunc(last_day(add_months(sysdate,:intervalo_1))) and
		a.tiptransaccionagenteviabcp in('03','05') and
		a.tipesttransaccionagenteviabcp = 'P' and
		b.codclaveopecta is null ;
          
----codclavecic solicitante - transferencias
truncate table tmp_esting_agen_sol;
insert into tmp_esting_agen_sol
       with tmp_agen_sol1 as 
       (
         select
                a.*,b.codclavecic as codclavecic_sol,b.codopecta as codopecta_sol
         from
              tmp_esting_agen_ben a
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
               tmp_esting_agen_ben a
               left join
                         ods_v.md_cliente b on a.codunicocli=b.codunicocli
          where
                a.tiptransaccionagenteviabcp in ('05')
       )
       select
              a.codclavecic_sol,a.codopecta_sol,a.codclavecic_ben,a.codopecta_ben,a.fecdia,
              a.hortransaccion,a.codmoneda,a.mtotransaccion,a.tiptransaccionagenteviabcp,a.codagenteviabcp
       from
              tmp_agen_sol1 a
       union
       select
              b.codclavecic_sol,b.codopecta_sol,b.codclavecic_ben,b.codopecta_ben,b.fecdia,
              b.hortransaccion,b.codmoneda,b.mtotransaccion,b.tiptransaccionagenteviabcp,b.codagenteviabcp
       from
              tmp_agen_sol2 b;
			  
 truncate table tmp_esting_trx_agente;
 insert into tmp_esting_trx_agente
   select 
          a.codclavecic_sol,a.codopecta_sol,a.codclavecic_ben,a.codopecta_ben,a.fecdia,
          a.hortransaccion,a.codmoneda,a.mtotransaccion,a.mtotransaccion * tc.mtocambioaldolar as mto_dolarizado, 
          d.destiptransaccionagenteviabcp as tipo_transaccion, 'AGENTE' as canal,' ' codpaisorigen
   from 
          tmp_esting_agen_sol a
          left join 
                    ods_v.hd_tipocambiosaldodiario tc on a.fecdia = tc.fectipcambio and a.codmoneda = tc.codmoneda
          left join 
                    ods_v.md_destipotranagenteviabcp d on a.tiptransaccionagenteviabcp = d.tiptransaccionagenteviabcp
   where 
          a.codclavecic_ben<>0 and
          a.codclavecic_sol<>a.codclavecic_ben; 
		  
--***************************************************transferencias del exterior (remesas)***********************************************************
--acortamos el periodo de la tabla
truncate table tmp_esting_remittance_ben;
insert into tmp_esting_remittance_ben
  with tmp_movoperativoremittance as
  (
    select 
           -1 as codclavecic_sol, codclaveopectaafectada, fecdia,hortransaccion,codmoneda,mtotransaccion,codproducto,mtotransacciondol,codpaisorigen
    from  
          ods_v.hd_movoperativoremittance
    where 
          fecdia between trunc(add_months(sysdate,:intervalo_1-5),'mm') and trunc(last_day(add_months(sysdate,:intervalo_1))) and
          codproducto in ('TRAXAB','TRAXRE','TRAXVE') and
          codclaveopectaafectada in (select codclaveopecta from tmp_esting_univctasclie)
  )      
	select
        a.*,b.codclavecic as codclavecic_ben,b.codopecta as codopecta_ben
	from 
       tmp_movoperativoremittance a
		   left join 
                 tmp_esting_univctasclie b on a.codclaveopectaafectada=b.codclaveopecta;
                 
--tabla final (filtrando codclavecic <> 0)
truncate table tmp_esting_trx_remittance;
insert into tmp_esting_trx_remittance
	select distinct 
                  a.codclavecic_sol,'NO APLICA' as codopecta_sol,a.codclavecic_ben,a.codopecta_ben,a.fecdia, a.hortransaccion, a.codmoneda, a.mtotransaccion,
			            a.mtotransacciondol as mto_dolarizado, d.descodproducto as tipo_transaccion, 'REMITTANCE' as canal,upper(p.nombrepais) as codpaisorigen
	from 
       tmp_esting_remittance_ben a
		   left join 
                 ods_v.md_descodigoproducto d on a.codproducto = d.codproducto
		   left join 
                 s55632.md_codigopais p on trim(a.codpaisorigen) = p.codpais3
	where a.codclavecic_ben<>0; 
  
--***************************************************cajero***********************************************************
--acortamos el periodo de la tabla
truncate table tmp_esting_cajero_ben;
insert into tmp_esting_cajero_ben
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
           codtrancajero,mtotransaccionsol,mtotransaccionme,codcajero,b.codclavecic as codclavecic_ben,b.codopecta as codopecta_ben
  	from  ods_v.hd_movimientocajero a
    inner join tmp_esting_univctasclie b on a.codopectahacia=b.codopecta
  	where   
           fecdia between trunc(add_months(sysdate,:intervalo_1-5),'mm') and trunc(last_day(add_months(sysdate,:intervalo_1)))  and
    		   codtrancajero in ('20','40') and 
    		   flgvalida='S' ;

----codclavecic solicitante - transferencias
truncate table tmp_esting_cajero_sol;
insert into tmp_esting_cajero_sol
       with tmp_cajero_sol1 as 
       (             
         select 
                a.*,b.codclavecic as codclavecic_sol,a.codopectadesde as codopecta_sol
         from 
              tmp_esting_cajero_ben a
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
                 tmp_esting_cajero_ben a
         where 
                 a.codtrancajero='20'
       )
       select              
               a.codclavecic_sol,a.codopecta_sol,a.codclavecic_ben,codopecta_ben,a.fecdia,
               a.hortransaccion,a.codmoneda,a.mtotransaccion,a.codtrancajero,mtotransaccionsol,mtotransaccionme,a.codcajero     
       from 
              tmp_cajero_sol1 a
       union
       select 
               b.codclavecic_sol,b.codopecta_sol,b.codclavecic_ben,b.codopecta_ben,b.fecdia,
               b.hortransaccion,b.codmoneda,b.mtotransaccion,b.codtrancajero,b.mtotransaccionsol,b.mtotransaccionme,b.codcajero 
       from 
              tmp_cajero_sol2 b;
		  
truncate table tmp_esting_trx_cajero;
insert into tmp_esting_trx_cajero
    select distinct 
                   a.codclavecic_sol,a.codopecta_sol,a.codclavecic_ben,codopecta_ben,a.fecdia, a.hortransaccion, a.codmoneda, a.mtotransaccion,
                  (case when a.codmoneda = '0001' then coalesce(a.mtotransaccionsol,a.mtotransaccion) 
                  else coalesce(a.mtotransaccionme,a.mtotransaccion) end) * tc.mtocambioaldolar as mto_dolarizado,
                  d.descodtrancajero as tipo_transaccion, 'CAJERO' as canal, ' ' codpaisorigen
    from 
                   tmp_esting_cajero_sol a
                  left join 
                            ods_v.hd_tipocambiosaldodiario tc on a.fecdia = tc.fectipcambio and a.codmoneda = tc.codmoneda
                  left join 
                            ods_v.mm_descodigotransaccioncajero d on a.codtrancajero = d.codtrancajero
    where 
          a.codclavecic_ben<>0 and
          a.codclavecic_sol<>a.codclavecic_ben;

--***************************************************home banking***********************************************************      
--acortamos el periodo de la tabla
truncate table tmp_esting_hm_ben;
insert into tmp_esting_hm_ben
  	select 
           codopectaorigen,codopectadestino,fecdia,hortransaccion,codmoneda,mtotransaccion,codopehbctr,b.codclavecic as codclavecic_ben,b.codopecta as codopecta_ben       
  	from   
           ods_v.hd_movhomebankingtransaccion a
    inner join 
               tmp_esting_univctasclie b on a.codopectadestino=b.codopecta
  	where  
           fecdia between trunc(add_months(sysdate,:intervalo_1-5),'mm') and trunc(last_day(add_months(sysdate,:intervalo_1))) and
  		   tipresultadotransaccion = 'OK' and  		     
           codtipoperacionhb='701';
  
--extraemos la info de los solicitantes 
truncate table tmp_esting_trx_hm;
insert into tmp_esting_trx_hm
       with tmp_hm_sol as
       (
        select 
               a.*,coalesce(c.codclavecic,b.codclavecic) as codclavecic_sol,a.codopectaorigen as codopecta_sol
        from tmp_esting_hm_ben a
             left join 
                       ods_v.md_cuenta b on a.codopectaorigen=b.codopecta
             left join 
                       ods_v.md_cuentag94 c on a.codopectaorigen=c.codopecta
       )           
      select distinct 
                    a.codclavecic_sol,a.codopecta_sol,a.codclavecic_ben,a.codopecta_ben,a.fecdia, a.hortransaccion, a.codmoneda, a.mtotransaccion,
    				a.mtotransaccion * tc.mtocambioaldolar as mto_dolarizado, d.descodopehbctr as tipo_transaccion,
                    'HOMEBANKING' as canal,' ' codpaisorigen
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
truncate table tmp_esting_vent_ben_6;
insert into tmp_esting_vent_ben_6
  	select 
           a.codclaveopecta,a.codclaveopectadestino,a.fecdia, a.horinitransaccion as hortransaccion,
           a.codmonedatransaccion as codmoneda,a.codsucage,a.codsesion,
    		   case 
      				when a.mtotransaccioncta <> 0 then a.mtotransaccioncta 
      				else a.mtotransaccion 
    		   end as mtotransaccion,a.codtransaccionventanilla,
			   b.codclavecic as codclavecic_ben,b.codopecta as codopecta_ben
  	from 
           ods_v.hd_transaccionventanilla a
	inner join 
			tmp_esting_univctasclie b on a.codclaveopectadestino=b.codclaveopecta
  	where    
            fecdia between trunc(add_months(sysdate,:intervalo_1-5),'mm') and trunc(last_day(add_months(sysdate,:intervalo_1-5))) and
      		a.codtransaccionventanilla in (60,62,63,159,186,187,188) and 
      		a.flgtransaccionaprobada = 'S' ;

truncate table tmp_esting_vent_ben_5;
insert into tmp_esting_vent_ben_5
  	select 
           a.codclaveopecta,a.codclaveopectadestino,a.fecdia, a.horinitransaccion as hortransaccion,
           a.codmonedatransaccion as codmoneda,a.codsucage,a.codsesion,
    		   case 
      				when a.mtotransaccioncta <> 0 then a.mtotransaccioncta 
      				else a.mtotransaccion 
    		   end as mtotransaccion,a.codtransaccionventanilla,
			   b.codclavecic as codclavecic_ben,b.codopecta as codopecta_ben
  	from 
           ods_v.hd_transaccionventanilla a
	inner join 
			tmp_esting_univctasclie b on a.codclaveopectadestino=b.codclaveopecta
  	where    
            fecdia between trunc(add_months(sysdate,:intervalo_1-4),'mm') and trunc(last_day(add_months(sysdate,:intervalo_1-4))) and
      		a.codtransaccionventanilla in (60,62,63,159,186,187,188) and 
      		a.flgtransaccionaprobada = 'S' ;

truncate table tmp_esting_vent_ben_4;
insert into tmp_esting_vent_ben_4
  	select 
           a.codclaveopecta,a.codclaveopectadestino,a.fecdia, a.horinitransaccion as hortransaccion,
           a.codmonedatransaccion as codmoneda,a.codsucage,a.codsesion,
    		   case 
      				when a.mtotransaccioncta <> 0 then a.mtotransaccioncta 
      				else a.mtotransaccion 
    		   end as mtotransaccion,a.codtransaccionventanilla,
			   b.codclavecic as codclavecic_ben,b.codopecta as codopecta_ben
  	from 
           ods_v.hd_transaccionventanilla a
	inner join 
			tmp_esting_univctasclie b on a.codclaveopectadestino=b.codclaveopecta
  	where    
            fecdia between trunc(add_months(sysdate,:intervalo_1-3),'mm') and trunc(last_day(add_months(sysdate,:intervalo_1-3))) and
      		a.codtransaccionventanilla in (60,62,63,159,186,187,188) and 
      		a.flgtransaccionaprobada = 'S' ;

truncate table tmp_esting_vent_ben_3;
insert into tmp_esting_vent_ben_3
  	select 
           a.codclaveopecta,a.codclaveopectadestino,a.fecdia, a.horinitransaccion as hortransaccion,
           a.codmonedatransaccion as codmoneda,a.codsucage,a.codsesion,
    		   case 
      				when a.mtotransaccioncta <> 0 then a.mtotransaccioncta 
      				else a.mtotransaccion 
    		   end as mtotransaccion,a.codtransaccionventanilla,
			   b.codclavecic as codclavecic_ben,b.codopecta as codopecta_ben
  	from 
           ods_v.hd_transaccionventanilla a
	inner join 
			tmp_esting_univctasclie b on a.codclaveopectadestino=b.codclaveopecta
  	where    
            fecdia between trunc(add_months(sysdate,:intervalo_1-2),'mm') and trunc(last_day(add_months(sysdate,:intervalo_1-2))) and
      		a.codtransaccionventanilla in (60,62,63,159,186,187,188) and 
      		a.flgtransaccionaprobada = 'S' ;

truncate table tmp_esting_vent_ben_2;
insert into tmp_esting_vent_ben_2
  	select 
           a.codclaveopecta,a.codclaveopectadestino,a.fecdia, a.horinitransaccion as hortransaccion,
           a.codmonedatransaccion as codmoneda,a.codsucage,a.codsesion,
    		   case 
      				when a.mtotransaccioncta <> 0 then a.mtotransaccioncta 
      				else a.mtotransaccion 
    		   end as mtotransaccion,a.codtransaccionventanilla,
			   b.codclavecic as codclavecic_ben,b.codopecta as codopecta_ben
  	from 
           ods_v.hd_transaccionventanilla a
	inner join 
			tmp_esting_univctasclie b on a.codclaveopectadestino=b.codclaveopecta
  	where    
            fecdia between trunc(add_months(sysdate,:intervalo_1-1),'mm') and trunc(last_day(add_months(sysdate,:intervalo_1-1))) and
      		a.codtransaccionventanilla in (60,62,63,159,186,187,188) and 
      		a.flgtransaccionaprobada = 'S' ;

truncate table tmp_esting_vent_ben_1;
insert into tmp_esting_vent_ben_1
  	select 
           a.codclaveopecta,a.codclaveopectadestino,a.fecdia, a.horinitransaccion as hortransaccion,
           a.codmonedatransaccion as codmoneda,a.codsucage,a.codsesion,
    		   case 
      				when a.mtotransaccioncta <> 0 then a.mtotransaccioncta 
      				else a.mtotransaccion 
    		   end as mtotransaccion,a.codtransaccionventanilla,
			   b.codclavecic as codclavecic_ben,b.codopecta as codopecta_ben
  	from 
           ods_v.hd_transaccionventanilla a
	inner join 
			tmp_esting_univctasclie b on a.codclaveopectadestino=b.codclaveopecta
  	where    
            fecdia between trunc(add_months(sysdate,:intervalo_1),'mm') and trunc(last_day(add_months(sysdate,:intervalo_1))) and
      		a.codtransaccionventanilla in (60,62,63,159,186,187,188) and 
      		a.flgtransaccionaprobada = 'S' ;

truncate table tmp_esting_vent_ben;
insert into tmp_esting_vent_ben
       select * from tmp_esting_vent_ben_1
       union 
       select * from tmp_esting_vent_ben_2
       union 
       select * from tmp_esting_vent_ben_3
       union 
       select * from tmp_esting_vent_ben_4
       union 
       select * from tmp_esting_vent_ben_5
       union 
       select * from tmp_esting_vent_ben_6;

truncate table tmp_esting_ventanilla_sol;
insert into tmp_esting_ventanilla_sol
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
               tmp_esting_vent_ben a
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
                tmp_esting_vent_ben a
                left join 
                          ods_v.md_cuenta b on a.codclaveopecta=b.codclaveopecta
         where 
               a.codtransaccionventanilla in (159,186,187,188)
       )
        select 
               b.codclavecic as codclavecic_sol,'NO APLICA' as codopecta_sol,a.codclavecic_ben,a.codopecta_ben,
               a.fecdia,a.hortransaccion,a.codmoneda,a.mtotransaccion,a.codtransaccionventanilla,a.codsucage
        from  
              tmp_vent_sol1 a
              left join 
                        ods_v.md_cliente b on a.codunicocli_sol=b.codunicocli
        union
        select 
               b.codclavecic_sol,b.codopecta_sol,b.codclavecic_ben,b.codopecta_ben,b.fecdia,b.hortransaccion,
               b.codmoneda,b.mtotransaccion,b.codtransaccionventanilla,b.codsucage
        from 
             tmp_vent_sol2 b;
            
truncate table tmp_esting_trx_ventanilla;
insert into tmp_esting_trx_ventanilla
  select 
         a.codclavecic_sol,a.codopecta_sol,a.codclavecic_ben,a.codopecta_ben,a.fecdia,a.hortransaccion,a.codmoneda,a.mtotransaccion,
         a.mtotransaccion * tc.mtocambioaldolar as mto_dolarizado, 
         d.destransaccionventanilla as tipo_transaccion, 'VENTANILLA' as canal,' ' codpaisorigen
  from 
       tmp_esting_ventanilla_sol a
          left join 
                    ods_v.hd_tipocambiosaldodiario tc on a.fecdia = tc.fectipcambio and a.codmoneda = tc.codmoneda
          left join 
                    ods_v.md_destransaccionventanilla d on a.codtransaccionventanilla = d.codtransaccionventanilla
  where 
        a.codclavecic_ben<>0 and
        a.codclavecic_sol<>a.codclavecic_ben and a.mtotransaccion>0;
        
--***************************************************telecredito***********************************************************
--acortamos el periodo de la tabla
truncate table tmp_esting_telcre_ben;
insert into tmp_esting_telcre_ben
  	select 
           a.codopecta,codopectaabono,fectransferencia as fecdia,hortransferencia as hortransaccion,codmoneda,
  		     mtotransferencia as mtotransaccion,tipoperaciontelcre,b.codclavecic as codclavecic_ben,b.codopecta as codopecta_ben     
  	from   
           ods_v.hs_movimientotransferenctelcre a
	inner join 
              tmp_esting_univctasclie b on a.codopectaabono=b.codopecta	   
  	where  
           fectransferencia  between trunc(add_months(sysdate,:intervalo_1-5),'mm') and trunc(last_day(add_months(sysdate,:intervalo_1))) and
			tipesttransferenciatelcre=40                           and
    		   tipoperaciontelcre in ('OMTRMT','OMTRTH','OMTRTN') ;

--extraemos la info de los solicitantes 
truncate table  tmp_esting_trx_telcre;
insert into tmp_esting_trx_telcre
       with tmp_telcre_sol as
       (
        	select 
                 a.*,coalesce(c.codclavecic,b.codclavecic) as codclavecic_sol,a.codopecta as codopecta_sol
        	from 
               tmp_esting_telcre_ben a
        		 left join 
                       ods_v.md_cuenta b on a.codopecta=b.codopecta
        		 left join 
                       ods_v.md_cuentag94 c on a.codopecta=c.codopecta
       )              
    	select distinct 
                    a.codclavecic_sol,a.codopecta_sol ,a.codclavecic_ben,a.codopecta_ben,a.fecdia, a.hortransaccion, a.codmoneda, a.mtotransaccion,
    				a.mtotransaccion * tc.mtocambioaldolar as mto_dolarizado,
                    d.destipoperaciontelcre as tipo_transaccion,'TELECREDITO' as canal,' ' codpaisorigen
    	from 
           tmp_telcre_sol a
    			  left join 
                      ods_v.hd_tipocambiosaldodiario tc on a.fecdia = tc.fectipcambio and a.codmoneda = tc.codmoneda
    			  left join 
                      ods_v.ms_tipooperaciontelcre d on a.tipoperaciontelcre = d.tipoperaciontelcre
    	where 
            a.codclavecic_ben<>0 and
    		    a.codclavecic_sol<>a.codclavecic_ben and a.mtotransaccion>0;
            
--***************************************************ggtt*********************************************************** 
truncate table tmp_esting_ggtt_ben;
insert into tmp_esting_ggtt_ben
    select 
           codclavecicsolicitante,codclavecicbeneficiario,fecdia,horemision,codmoneda,
           mtoimporteoperacion,codproducto,codswiftbcodestino,codswiftbcoemisor,
		   a.codclavecicbeneficiario as codclavecic_ben,'NO APLICA' as codopecta_ben
    from 
           ods_v.hd_documentoemitidoggtt a
	inner join 
              tmp_esting_univctasclie b on a.codclavecicbeneficiario=b.codclavecic
    where 
          fecdia between trunc(add_months(sysdate,:intervalo_1-5),'mm') and trunc(last_day(add_months(sysdate,:intervalo_1))) and
          codtipestadotransaccion = '00' ;

--extraemos la info de los solicitantes  
truncate  table tmp_esting_trx_ggtt;
insert into tmp_esting_trx_ggtt
	with tmp_ggtt_sol as
	(
	   select 
               a.*,a.codclavecicsolicitante as codclavecic_sol,'NO APLICA' as codopecta_sol
        from tmp_esting_ggtt_ben a
       )           
      select distinct 
                    a.codclavecic_sol,a.codopecta_sol,a.codclavecic_ben,a.codopecta_ben,a.fecdia, a.horemision as hortransaccion, a.codmoneda, 
                    a.mtoimporteoperacion as mtotransaccion,a.mtoimporteoperacion * tc.mtocambioaldolar as mto_dolarizado, 
                    d.descodproducto as tipo_transaccion,'DOCUMENTO_GGTT' as canal,upper(p.nombrepais) as codpaisorigen
    	from 
      		tmp_ggtt_sol a
      		left join 
                    ods_v.hd_tipocambiosaldodiario tc on a.fecdia = tc.fectipcambio and a.codmoneda = tc.codmoneda
      		left join 
                    ods_v.md_descodigoproducto d on a.codproducto = d.codproducto
      		left join 
                    s55632.md_codigopais p on substr(a.codswiftbcoemisor, 5, 2) = p.codpais2              
    	where 
    		    a.codclavecic_sol<>a.codclavecic_ben and a.mtoimporteoperacion>0;

--***************************************************banca movil***********************************************************
--acortamos el periodo de la tabla y extraemos los codclavecic beneficiarios
truncate table tmp_esting_bancamovil_ben;
insert into tmp_esting_bancamovil_ben
select
	a.codclaveopectaorigen,a.codclaveopectadestino,a.fectransaccion as fecdia,a.hortransaccion,
	a.codmonedatransaccion as codmoneda,a.mtotransaccion,a.tiptransaccionbcamovil,
	b.codclavecic as codclavecic_ben,b.codopecta as codopecta_ben
from
	s61751.tmp_movbcamovil_i a
	inner join tmp_esting_univctasclie b on a.codclaveopectadestino=b.codclaveopecta
where
	a.fectransaccion between trunc(add_months(sysdate,:intervalo_1-5),'mm') and trunc(last_day(add_months(sysdate,:intervalo_1))) and
	a.tiptransaccionbcamovil='2' and
	a.flgtransaccionvalida='S'
union all
select
	a.codclaveopectaorigen,a.codclaveopectadestino,a.fectransaccion as fecdia,a.hortransaccion,
	a.codmonedatransaccion as codmoneda,a.mtotransaccion,a.tiptransaccionbcamovil,
	b.codclavecic as codclavecic_ben,b.codopecta as codopecta_ben
from
	s61751.tmp_movbcamovil_p a
	inner join tmp_esting_univctasclie b on a.codclaveopectadestino=b.codclaveopecta
where
	a.fectransaccion between trunc(add_months(sysdate,:intervalo_1-5),'mm') and trunc(last_day(add_months(sysdate,:intervalo_1))) and
	a.tiptransaccionbcamovil='2' and
	a.flgtransaccionvalida='S'  and mtotransaccion>0;

--extraemos la info de los solicitantes
truncate table tmp_esting_trx_bancamovil;
insert into tmp_esting_trx_bancamovil
       with tmp_bancamovil_sol as
       (
      	select 
               a.*,b.codclavecic as codclavecic_sol, b.codopecta as codopecta_sol
      	from 
             tmp_esting_bancamovil_ben a
      		   left join
                       ods_v.md_cuenta b on a.codclaveopectaorigen=b.codclaveopecta
       )
       select distinct
                      a.codclavecic_sol,a.codopecta_sol,a.codclavecic_ben,a.codopecta_ben,a.fecdia,
                      a.hortransaccion, a.codmoneda, a.mtotransaccion,a.mtotransaccion * tc.mtocambioaldolar as mto_dolarizado,
                      d.destiptransaccionbcamovil as tipo_transaccion, 'BANCA MOVIL' as canal,' ' codpaisorigen
    	 from 
            tmp_bancamovil_sol a
    			  left join 
                      ods_v.hd_tipocambiosaldodiario tc on a.fecdia = tc.fectipcambio and a.codmoneda = tc.codmoneda
    			  left join 
                      ods_v.mm_destiptransaccionbcamovil d on a.tiptransaccionbcamovil = d.tiptransaccionbcamovil
    	 where 
             a.codclavecic_ben<>0 and
		         a.codclavecic_sol<>a.codclavecic_ben;

commit;
quit;