--parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode

alter session disable parallel query;

/*************************************************************************************************
****************************** Escenario estimador de ingresos ***********************************
*************************************************************************************************/

-- creado por: Celeste Cabanillas
-- key user escenario: plaft
/*************************************************************************************************/

--*********************************************u n i e n d o   t o d o***********************************************
--create table tmp_esting_trx tablespace d_aml_99 as
truncate table tmp_esting_trx;
insert into tmp_esting_trx
--agente
    select codclavecic_sol,codopecta_sol,codclavecic_ben,codopecta_ben,fecdia,hortransaccion,codmoneda, 
    mtotransaccion,mto_dolarizado,tipo_transaccion,canal,codpaisorigen
    from tmp_esting_trx_agente
    union
--ventanilla
    select codclavecic_sol,codopecta_sol,codclavecic_ben,codopecta_ben,fecdia,hortransaccion,codmoneda, 
    mtotransaccion,mto_dolarizado,tipo_transaccion,canal,codpaisorigen
    from tmp_esting_trx_ventanilla
    union
--transferencias del exterior (remesas)
    select codclavecic_sol,codopecta_sol,codclavecic_ben,codopecta_ben,fecdia,hortransaccion,codmoneda, 
    mtotransaccion,mto_dolarizado,tipo_transaccion,canal,codpaisorigen
    from tmp_esting_trx_remittance
    union
--cajero
    select codclavecic_sol,codopecta_sol,codclavecic_ben,codopecta_ben,fecdia,hortransaccion,codmoneda, 
    mtotransaccion,mto_dolarizado,tipo_transaccion,canal,codpaisorigen
    from tmp_esting_trx_cajero
    union
--banca movil
    select codclavecic_sol,codopecta_sol,codclavecic_ben,codopecta_ben,fecdia,hortransaccion,codmoneda, 
    mtotransaccion,mto_dolarizado,tipo_transaccion,canal,codpaisorigen
    from tmp_esting_trx_bancamovil
    union
--telecredito
    select codclavecic_sol,codopecta_sol,codclavecic_ben,codopecta_ben,fecdia,hortransaccion,codmoneda, 
    mtotransaccion,mto_dolarizado,tipo_transaccion,canal,codpaisorigen
    from tmp_esting_trx_telcre
    union
--homebanking
    select codclavecic_sol,codopecta_sol,codclavecic_ben,codopecta_ben,fecdia,hortransaccion,codmoneda, 
    mtotransaccion,mto_dolarizado,tipo_transaccion,canal,codpaisorigen
    from tmp_esting_trx_hm
    union
--ggtt
    select codclavecic_sol,codopecta_sol,codclavecic_ben,codopecta_ben,fecdia,hortransaccion,codmoneda, 
    mtotransaccion,mto_dolarizado,tipo_transaccion,canal,codpaisorigen
    from tmp_esting_trx_ggtt;

commit;
quit;