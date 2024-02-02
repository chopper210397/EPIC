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
truncate table tmp_ingcashbcacei_agen_ben;
insert into tmp_ingcashbcacei_agen_ben
--create table tmp_ingcashbcacei_agen_ben tablespace d_aml_99 as
	select distinct
         a.codclaveopectacargo,a.codunicocli,a.codclaveopectaabono,a.fecdia, a.hortransaccion, a.codmoneda,
         a.mtotransaccion,a.tiptransaccionagenteviabcp,c.codclavecic as codclavecic_ben,b.codopecta as codopecta_ben,b.tipbanca as tipbanca_ben
	from
         t23377.tmp_movagente_i a
		 left join
               ods_v.md_agenteviabcp b on a.codclaveopectaabono=b.codclaveopecta
		 		    inner join
                  tmp_ingcashbcacei_univctasclie c on a.codclaveopectaabono=c.codclaveopecta
	where
		a.fecdia between trunc(add_months(sysdate,:intervalo_1),'mm') and trunc(last_day(add_months(sysdate,:intervalo_2))) and
		a.tiptransaccionagenteviabcp='05' and
		b.codclaveopecta is null
	union all
	select distinct
         a.codclaveopectacargo,a.codunicocli,a.codclaveopectaabono,a.fecdia, a.hortransaccion, a.codmoneda,
         a.mtotransaccion,a.tiptransaccionagenteviabcp,c.codclavecic as codclavecic_ben,b.codopecta as codopecta_ben,b.tipbanca as tipbanca_ben
	from
         t23377.tmp_movagente_p a
		 left join
               ods_v.md_agenteviabcp b on a.codclaveopectaabono=b.codclaveopecta
		inner join
              tmp_ingcashbcacei_univctasclie c on a.codclaveopectaabono=c.codclaveopecta
	where
		a.fecdia between trunc(add_months(sysdate,:intervalo_1),'mm') and trunc(last_day(add_months(sysdate,:intervalo_2))) and
		a.tiptransaccionagenteviabcp='05' and
		b.codclaveopecta is null ;

----codclavecic solicitante - transferencias
truncate table tmp_ingcashbcacei_agen_sol;
insert into tmp_ingcashbcacei_agen_sol
--create table tmp_ingcashbcacei_agen_sol tablespace d_aml_99 as
       with tmp_agen_sol2 as
       (
          select
                 a.*,b.codclavecic as codclavecic_sol,'NO APLICA' as codopecta_sol
          from
               tmp_ingcashbcacei_agen_ben a
               left join
                         ods_v.md_cliente b on a.codunicocli=b.codunicocli
          where
                a.tiptransaccionagenteviabcp in ('05')
       )
       select distinct
              b.codclavecic_sol,b.codopecta_sol,b.codclavecic_ben,b.codopecta_ben,b.tipbanca_ben,b.fecdia,
              b.hortransaccion,b.codmoneda,b.mtotransaccion,b.tiptransaccionagenteviabcp
       from
              tmp_agen_sol2 b;

truncate table tmp_ingcashbcacei_trx_agente;
insert into tmp_ingcashbcacei_trx_agente
--create table tmp_ingcashbcacei_trx_agente tablespace d_aml_99 as
   select distinct
          a.codclavecic_sol,a.codopecta_sol,a.codclavecic_ben,a.codopecta_ben,a.tipbanca_ben,a.fecdia,
          a.hortransaccion,a.codmoneda,a.mtotransaccion,a.mtotransaccion * tc.mtocambioaldolar as mto_dolarizado,
          d.destiptransaccionagenteviabcp as tipo_transaccion, 'AGENTE' as canal
   from
          tmp_ingcashbcacei_agen_sol a
          left join
                    ods_v.hd_tipocambiosaldodiario tc on a.fecdia = tc.fectipcambio and a.codmoneda = tc.codmoneda
          left join
                    ods_v.md_destipotranagenteviabcp d on a.tiptransaccionagenteviabcp = d.tiptransaccionagenteviabcp
   where
          a.codclavecic_ben<>0 and
          a.codclavecic_sol<>a.codclavecic_ben;

--create table tmp_ingcashbcacei_cajero_ben_1 tablespace d_aml_99 as
truncate table tmp_ingcashbcacei_cajero_ben_1;
insert into tmp_ingcashbcacei_cajero_ben_1
select distinct
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
           codtrancajero,mtotransaccionsol,mtotransaccionme,codcajero
  	from
           ods_v.hd_movimientocajero a
  	where
			fecdia between trunc(add_months(sysdate,:intervalo_1),'mm') and trunc(last_day(add_months(sysdate,:intervalo_2))) and
    		codtrancajero='20' and
    		flgvalida='S';

truncate table tmp_ingcashbcacei_cajero_ben;
insert into tmp_ingcashbcacei_cajero_ben
--create table tmp_ingcashbcacei_cajero_ben tablespace d_aml_99 as
select codopectadesde,a.codclavecic,codopectahacia,fecdia,hortransaccion,codmoneda,
           mtotransaccion,
           codtrancajero,mtotransaccionsol,mtotransaccionme,codcajero,b.codclavecic as codclavecic_ben,b.codopecta as codopecta_ben,b.tipbanca as tipbanca_ben
from tmp_ingcashbcacei_cajero_ben_1 a
inner join
       tmp_ingcashbcacei_univctasclie b on a.codopectahacia=b.codopecta;

----codclavecic solicitante - depositos
truncate table tmp_ingcashbcacei_cajero_sol;
insert into tmp_ingcashbcacei_cajero_sol
--create table tmp_ingcashbcacei_cajero_sol tablespace d_aml_99 as
       with tmp_cajero_sol2 as
       (
         select
                 a.*, a.codclavecic as codclavecic_sol,'NO APLICA' as codopecta_sol
         from
                 tmp_ingcashbcacei_cajero_ben a
         where
                 a.codtrancajero='20'
       )
       select distinct
               b.codclavecic_sol,b.codopecta_sol,b.codclavecic_ben,b.codopecta_ben,b.tipbanca_ben,b.fecdia,
               b.hortransaccion,b.codmoneda,b.mtotransaccion,b.codtrancajero,b.mtotransaccionsol,b.mtotransaccionme,b.codcajero
       from
              tmp_cajero_sol2 b;

truncate table tmp_ingcashbcacei_trx_cajero;
insert into tmp_ingcashbcacei_trx_cajero
--create table tmp_ingcashbcacei_trx_cajero tablespace d_aml_99 as
    select distinct
                   a.codclavecic_sol,a.codopecta_sol,a.codclavecic_ben,codopecta_ben,a.tipbanca_ben,a.fecdia, a.hortransaccion, a.codmoneda, a.mtotransaccion,
                  (case when a.codmoneda = '0001' then coalesce(a.mtotransaccionsol,a.mtotransaccion) else coalesce(a.mtotransaccionme,a.mtotransaccion) end) * tc.mtocambioaldolar as mto_dolarizado,
                  d.descodtrancajero as tipo_transaccion, 'CAJERO' as canal
    from
                   tmp_ingcashbcacei_cajero_sol a
                  left join
                            ods_v.hd_tipocambiosaldodiario tc on a.fecdia = tc.fectipcambio and a.codmoneda = tc.codmoneda
                  left join
                            ods_v.mm_descodigotransaccioncajero d on a.codtrancajero = d.codtrancajero
    where
          a.codclavecic_ben<>0 and
          a.codclavecic_sol<>a.codclavecic_ben;

--***************************************************ventanilla-efectivo***********************************************************
-----------------------efectivo
--------------------soles
truncate table tmp_ingcashbcacei_cashsol;
insert into tmp_ingcashbcacei_cashsol
--create table tmp_ingcashbcacei_cashsol tablespace d_aml_99 as
	select distinct  a.codunicoclisolicitante,a.codclaveopectadestino,a.fecdia, a.horinitransaccion as hortransaccion,
			a.codmonedatransaccion as codmoneda,a.codsucage,
		   case
				when a.mtotransaccioncta <> 0 then a.mtotransaccion * tc.mtocambioaldolar
				else  a.mtotransaccion * tc.mtocambioaldolar
		   end as mto_dolarizado ,a.codtransaccionventanilla,b.codclavecic as codclavecic_ben,b.codopecta as codopecta_ben,b.tipbanca as tipbanca_ben
	from  t00985.efesol_trxparticipe a
	inner join tmp_ingcashbcacei_univctasclie b on a.codclaveopectadestino=b.codclaveopecta
	left join ods_v.hd_tipocambiosaldodiario tc on a.fecdia = tc.fectipcambio and a.codmonedatransaccion = tc.codmoneda
  where
	a.fecdia between trunc(add_months(sysdate,:intervalo_1),'mm') and trunc(last_day(add_months(sysdate,:intervalo_2))) and  a.codtransaccionventanilla in (60,62,63,159,186,187,188);

 --------------------dolares
truncate table tmp_ingcashbcacei_cashdol;
insert into tmp_ingcashbcacei_cashdol
--create table tmp_ingcashbcacei_cashdol tablespace d_aml_99 as
	select distinct  a.codunicoclisolicitante,a.codclaveopectadestino,a.fecdia, a.horinitransaccion as hortransaccion,
			a.codmonedatransaccion as codmoneda,a.codsucage,
		   case
			when a.mtotransaccioncta <> 0 then a.mtotransaccioncta
			else a.mtotransaccion
		   end as mto_dolarizado,a.codtransaccionventanilla,b.codclavecic as codclavecic_ben,b.codopecta as codopecta_ben,b.tipbanca as tipbanca_ben
	from t00985.qry_efectparticipe a
	inner join tmp_ingcashbcacei_univctasclie b on a.codclaveopectadestino=b.codclaveopecta
where
	a.fecdia between trunc(add_months(sysdate,:intervalo_1),'mm') and trunc(last_day(add_months(sysdate,:intervalo_2))) and  a.codtransaccionventanilla in (60,62,63,159,186,187,188);

--acortamos el periodo de la tabla
truncate table tmp_ingcashbcacei_cash;
insert into tmp_ingcashbcacei_cash
--create table tmp_ingcashbcacei_cash tablespace d_aml_99 as
select * from tmp_ingcashbcacei_cashdol
union all
select * from tmp_ingcashbcacei_cashsol;

--codclavecic solicitante
truncate table tmp_ingcashbcacei_vent_sol;
insert into tmp_ingcashbcacei_vent_sol
--create table tmp_ingcashbcacei_vent_sol tablespace d_aml_99 as
	select a.*,b.codclavecic as codclavecic_sol,'NO APLICA' as codopecta_sol
	from tmp_ingcashbcacei_cash a
		 left join ods_v.md_cliente b on a.codunicoclisolicitante=b.codunicocli;

--tabla final (filtrando codclavecic <> 0)
truncate table tmp_ingcashbcacei_trx_ventanilla;
insert into tmp_ingcashbcacei_trx_ventanilla
--create table tmp_ingcashbcacei_trx_ventanilla tablespace d_aml_99 as
  select distinct a.codclavecic_sol,a.codopecta_sol,a.codclavecic_ben,a.codopecta_ben,a.tipbanca_ben, a.fecdia, a.hortransaccion, a.codmoneda,a.codsucage,
          mto_dolarizado, d.destransaccionventanilla as tipo_transaccion, 'VENTANILLA' as canal
  from tmp_ingcashbcacei_vent_sol a
            left join ods_v.md_destransaccionventanilla d on a.codtransaccionventanilla = d.codtransaccionventanilla
  where a.codclavecic_ben<>0 and
        a.codclavecic_sol<>a.codclavecic_ben;

commit;
quit;