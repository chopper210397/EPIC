--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

--*********************************************u n i e n d o   t o d o***********************************************
truncate table tmp_egbcacei_trx;
insert into tmp_egbcacei_trx
--create table tmp_egbcacei_trx tablespace d_aml_99 as -- antes: 1,151,238 / ahora: 1,155,386
  with tmp as
  (
--agente
    select codclavecic_sol,codopecta_sol,codclavecic_ben,codopecta_ben,fecdia,hortransaccion,codmoneda, mtotransaccion,mto_dolarizado,tipo_transaccion,canal
    from tmp_egbcacei_trx_agente
    union
--ventanilla_
    select codclavecic_sol,codopecta_sol,codclavecic_ben,codopecta_ben,fecdia,hortransaccion,codmoneda, mtotransaccion,mto_dolarizado,tipo_transaccion,canal
    from tmp_egbcacei_trx_ventanilla
    union
--cajero
    select codclavecic_sol,codopecta_sol,codclavecic_ben,codopecta_ben,fecdia,hortransaccion,codmoneda, mtotransaccion,mto_dolarizado,tipo_transaccion,canal
    from tmp_egbcacei_trx_cajero
	union
--banca movil
    select codclavecic_sol,codopecta_sol,codclavecic_ben,codopecta_ben,fecdia,hortransaccion,codmoneda,mtotransaccion,mto_dolarizado,tipo_transaccion,canal
    from tmp_egbcacei_trx_bmovil
	union
--home banking
    select codclavecic_sol,codopecta_sol,codclavecic_ben,codopecta_ben,fecdia,hortransaccion,codmoneda,mtotransaccion,mto_dolarizado,tipo_transaccion,canal
    from tmp_egbcacei_trx_hm
	union
--telecredito
    select codclavecic_sol,codopecta_sol,codclavecic_ben,codopecta_ben,fecdia,hortransaccion,codmoneda,mtotransaccion,mto_dolarizado,tipo_transaccion,canal
    from tmp_egbcacei_trx_telcre
	union
--ggtt
    select codclavecic_sol,codopecta_sol,codclavecic_ben,codopecta_ben,fecdia,hortransaccion,codmoneda,mtotransaccion,mto_dolarizado,tipo_transaccion,canal
    from tmp_egbcacei_trx_ggtt
	union
--banni
    select codclavecic_sol,codopecta_sol,codclavecic_ben,codopecta_ben,fecdia,hortransaccion,codmoneda,mtotransaccion,mto_dolarizado,tipo_transaccion,canal
    from tmp_egbcacei_trx_banni
	union
--ttib
    select codclavecic_sol,codopecta_sol,codclavecic_ben,codopecta_ben,fecdia,hortransaccion,codmoneda,mtotransaccion,mto_dolarizado,tipo_transaccion,canal
    from tmp_egbcacei_trx_ttib
  )--filtro lista blanca
  select *
  from tmp
  where codclavecic_sol not in (select codclavecic
								from s55632.listablanca_cump);
grant select on tmp_egbcacei_trx to rol_vistasdwhgstcum;

commit;
quit;