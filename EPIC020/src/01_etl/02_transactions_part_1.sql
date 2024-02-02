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

--***************************************************banca movil***********************************************************
--acortamos el periodo de la tabla y extraemos los codclavecic solicitante
--create table tmp_egbcacei_bmovil_sol as
truncate table tmp_egbcacei_bmovil_sol;
insert into tmp_egbcacei_bmovil_sol
    select
           a.codclaveopectaorigen,a.codclaveopectadestino,a.fectransaccion as fecdia,a.hortransaccion,
		   a.codmonedatransaccion as codmoneda,a.mtotransaccion,a.tiptransaccionbcamovil,b.codclavecic as codclavecic_sol,
		   b.codopecta as codopecta_sol
    from
           t23377.tmp_movbcamovil_i a
           inner join tmp_egbcacei_univctasclie b on a.codclaveopectaorigen=b.codclaveopecta
    where
          a.fectransaccion between trunc(add_months(sysdate, :intervalo_1),'mm') and trunc(last_day(add_months(sysdate, :intervalo_2))) and
		  a.tiptransaccionbcamovil='2' and
          a.codclaveopectaorigen is not null
	union all
	select
           a.codclaveopectaorigen,a.codclaveopectadestino,a.fectransaccion as fecdia,a.hortransaccion,
		   a.codmonedatransaccion as codmoneda,a.mtotransaccion,a.tiptransaccionbcamovil,b.codclavecic as codclavecic_sol,
		   b.codopecta as codopecta_sol
    from
           t23377.tmp_movbcamovil_p a
           inner join tmp_egbcacei_univctasclie b on a.codclaveopectaorigen=b.codclaveopecta
    where
          a.fectransaccion between trunc(add_months(sysdate, :intervalo_1),'mm') and trunc(last_day(add_months(sysdate, :intervalo_2))) and
		  a.tiptransaccionbcamovil='2' and
          a.codclaveopectaorigen is not null;

--extraemos la info de los beneficiarios
--create table tmp_egbcacei_trx_bmovil as
truncate table tmp_egbcacei_trx_bmovil;
insert into tmp_egbcacei_trx_bmovi
       with tmp_bancamovil_ben as
       (
      	select
               a.*,b.codclavecic as codclavecic_ben, b.codopecta as codopecta_ben
      	from
             tmp_egbcacei_bmovil_sol a
      		   left join
                       ods_v.md_cuentag94 b on a.codclaveopectadestino=b.codclaveopecta
       )
       select distinct
                      a.codclavecic_sol,a.codopecta_sol,a.codclavecic_ben,a.codopecta_ben,a.fecdia, a.hortransaccion,
					  a.codmoneda,a.mtotransaccion,a.mtotransaccion * tc.mtocambioaldolar as mto_dolarizado,
                      d.destiptransaccionbcamovil as tipo_transaccion, 'BANCA MOVIL' as canal
    	 from
            tmp_bancamovil_ben a
    			  left join
                      ods_v.hd_tipocambiosaldodiario tc on a.fecdia = tc.fectipcambio and a.codmoneda = tc.codmoneda
    			  left join
                      ods_v.mm_destiptransaccionbcamovil d on a.tiptransaccionbcamovil = d.tiptransaccionbcamovil
    	 where
             a.codclavecic_sol<>0 and
		     a.codclavecic_sol<>a.codclavecic_ben;
commit;
quit;