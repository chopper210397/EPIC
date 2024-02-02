--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

--*********************************************u n i e n d o   t o d o***********************************************
--eliminar:tmp_ingcashbcacei_trx_backup

truncate table tmp_ingcashbcacei_trx;
insert into tmp_ingcashbcacei_trx
--create table tmp_ingcashbcacei_trx tablespace d_aml_99 as
  with tmp as
  (
--agente
    select codclavecic_sol,codopecta_sol,codclavecic_ben,codopecta_ben,tipbanca_ben,fecdia,hortransaccion,codmoneda, mto_dolarizado,tipo_transaccion,canal
    from tmp_ingcashbcacei_trx_agente
    union
--ventanilla_
    select codclavecic_sol,codopecta_sol,codclavecic_ben,codopecta_ben,tipbanca_ben,fecdia,hortransaccion,codmoneda, mto_dolarizado,tipo_transaccion,canal
    from tmp_ingcashbcacei_trx_ventanilla
    union
--cajero
    select codclavecic_sol,codopecta_sol,codclavecic_ben,codopecta_ben,tipbanca_ben,fecdia,hortransaccion,codmoneda,mto_dolarizado,tipo_transaccion,canal
    from tmp_ingcashbcacei_trx_cajero
  )--filtro lista blanca
  select *
  from tmp
  where codclavecic_ben not in (select codclavecic
								from s55632.rm_cumplimientolistablanca_tmp);

commit;
quit;