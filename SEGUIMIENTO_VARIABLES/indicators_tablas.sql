--Parametro de credenciales
@&1

set echo on
whenever sqlerror exit sql.sqlcode
alter session disable parallel query;

--Tabla de indicadores/metricas modelos
-- ejemplo
-- modelo : epic020
-- periodo : 2023-10-01
-- fecha_de_carga : 2023-10-07
-- metrica : score silueta
-- valor : 0.86
-- estado : verde
create table model_indicators
(	
        modelo varchar(20),
        periodo number,
        fecha_de_carga date,
        metrica varchar(100),
        valor number,
        estado varchar(50)
) tablespace d_aml_99 ;

--Tabla de estabilidad de las variables de los modelos
-- ejemplo
-- modelo : epic020
-- periodo : 2023-10-01
-- fecha_de_carga : 2023-10-07
-- variable : mto_egresos
-- metrica : csi
-- valor : 0.86
-- estado : rojo
create table model_stability
(	
        modelo varchar(20),
        periodo number,
        fecha_de_carga date,
        variable varchar(100),
        metrica varchar(100),
        valor number,
        estado varchar(50)
) tablespace d_aml_99 ;

-- Tabla de la calidad de los datos respecto a los modelos evaluados
create table data_quality
(	
        modelo varchar(20),
        periodo number,
        fecha_de_carga date,
        metrica varchar(100),
        variable varchar(100),
        valor number
) tablespace d_aml_99 ;

commit;
quit;