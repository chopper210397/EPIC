@&1

SET ECHO ON
WHENEVER SQLERROR EXIT SQL.SQLCODE
ALTER SESSION DISABLE PARALLEL QUERY;

--Tabla EPIC014
TRUNCATE table EPIC014;
INSERT INTO EPIC014
Select
      sysdate as FecGeneracion, 38 as idOrigen, a.Codunicocli, 'EPIC014' as Escenario,
      'EPIC014 - Perfil de ingresos para clientes de banca Corporativa, Empresa e Institucional' as DesEscenario,
	  'Ultimo mes' as Periodo, round(a.MTO_RECIBIDO, 2) as Triggering,
      'En el periodo ' || to_char(TRUNC(ADD_MONTHS(SYSDATE, -1),'MM'),'MONYYYY') || ' la alerta es generada
      porque el monto mensual acumulado del cliente '||a.MTO_RECIBIDO||' sale de su perfil, dado que excede
      a su promedio de ingresos de los 6 meses anteriores '||A.MEDIA_DEP||
	  ' mas 3 veces la desviacion estandar '||A.DESV_DEP||' .Adicionalmente,
	  la empresa tiene Representantes Legales, Gerentes o Accionistas que han sido reportados
	  como '||CASE when a.FLG_ROS_REL=1 and a.FLG_LSB_NP_REL=1 then 'ROS y LSB o Noticia Periodística.'
					when a.FLG_ROS_REL=1 and a.FLG_LSB_NP_REL=0 then 'ROS.'
					else 'LSB o Noticia Periodística.'END  as Comentario
from TMP_INGCLIEBCACEI_ALERTAS a;

--Grant select on EPIC014 to ROL_VISTASDWHGSTCUM;

--Tabla EPIC014 - documentos
TRUNCATE table EPIC014_DOC;
INSERT INTO EPIC014_DOC
Select distinct
      '\\Pfilep11\lavadoactivos\99_Procesos_BI\0_SapycWeb\PAQUETES_ADHOC\' as Ruta,
      '99999999_MODEM_EPIC014_TRXS_' || Codunicocli || '.csv' as NbrDocumento,
      Codunicocli,
      sysdate as FecRegistro,
      ' ' as NUMCASO,
      0 as idAnalista
from EPIC014
UNION ALL
Select distinct
      '\\Pfilep11\lavadoactivos\99_Procesos_BI\0_SapycWeb\PAQUETES_ADHOC\' as Ruta,
      '99999999_MODEM_EPIC014_EECC_' || Codunicocli || '.csv' as NbrDocumento,
      Codunicocli,
      sysdate as FecRegistro,
      ' ' as NUMCASO,
      0 as idAnalista
from EPIC014;
quit;