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
--acortamos el periodo de la tabla y extraemos los codclavecic beneficiarios
truncate table tmp_ingcashbcacei_bancamovil_ben1_var;
insert into tmp_ingcashbcacei_bancamovil_ben1_var
--create table tmp_ingcashbcacei_bancamovil_ben1_var tablespace d_aml_99 as
    select
           a.codclaveopectaorigen,a.codclaveopectadestino,a.fectransaccion as fecdia,a.hortransaccion,a.codmonedatransaccion as codmoneda,
           a.mtotransaccion,a.tiptransaccionbcamovil,b.codclavecic as codclavecic_ben,b.codopecta as codopecta_ben,b.tipbanca as tipbanca_ben
    from
           t23377.tmp_movbcamovil_i a
		   inner join tmp_ingcashbcacei_univctasclie b on a.codclaveopectadestino=b.codclaveopecta
    where
		a.fectransaccion between trunc(add_months(sysdate,:intervalo_1),'mm') and trunc(last_day(add_months(sysdate,:intervalo_2))) and
          a.tiptransaccionbcamovil='2' and
          a.codclaveopectadestino is not null
	union all
	select
           a.codclaveopectaorigen,a.codclaveopectadestino,a.fectransaccion as fecdia,a.hortransaccion,a.codmonedatransaccion as codmoneda,
           a.mtotransaccion,a.tiptransaccionbcamovil,b.codclavecic as codclavecic_ben,b.codopecta as codopecta_ben,b.tipbanca as tipbanca_ben
    from
           t23377.tmp_movbcamovil_p a
		   inner join tmp_ingcashbcacei_univctasclie b on a.codclaveopectadestino=b.codclaveopecta
    where
		a.fectransaccion between trunc(add_months(sysdate,:intervalo_1),'mm') and trunc(last_day(add_months(sysdate,:intervalo_2))) and
          a.tiptransaccionbcamovil='2' and
          a.codclaveopectadestino is not null;

--extraemos la info de los solicitantes
truncate table tmp_ingcashbcacei_trx_bancamovil_var;
insert into tmp_ingcashbcacei_trx_bancamovil_var
--create table tmp_ingcashbcacei_trx_bancamovil_var tablespace d_aml_99 as
       with tmp_bancamovil_sol as
       (
      	select
               a.*,b.codclavecic as codclavecic_sol, b.codopecta as codopecta_sol
      	from
             tmp_ingcashbcacei_bancamovil_ben1_var a
      		   left join
                       ods_v.md_cuenta b on a.codclaveopectaorigen=b.codclaveopecta
       )
       select distinct
                      a.codclavecic_sol,a.codopecta_sol,a.codclavecic_ben,a.codopecta_ben,a.tipbanca_ben,a.fecdia,
                      a.hortransaccion, a.codmoneda, a.mtotransaccion,a.mtotransaccion * tc.mtocambioaldolar as mto_dolarizado,
                      d.destiptransaccionbcamovil as tipo_transaccion, 'BANCA MOVIL' as canal,' ' codpaisorigen, '0'flg_zar
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