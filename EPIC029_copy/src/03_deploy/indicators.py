import logging
import numpy as np   
import pandas as pd
from sklearn.preprocessing import scale
from datetime import date
import sys
import warnings
from SEGUIMIENTO_VARIABLES.Utiles.indicators_functions import score_silueta, psi, csi, data_quality_function
warnings.filterwarnings('ignore')

# # # # # # # # # # # # # # # # # # # # # # # # # # # #
#               Creando estructura                    #
# # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Definiendo variables

# # # # # # # # # # # # #
entorno = "development" #
# # # # # # # # # # # # #

if entorno == "production":
    ruta_modelo = r'.\src\02_models\kmeans_model_39.model'
    ruta_data_produccion = r".\data\production\01_raw.csv"
    ruta_data_entrenamiento = r'..\SEGUIMIENTO_VARIABLES\Data\EPIC029\02_preprocessed.csv'
    ruta_train_predicted = r'..\SEGUIMIENTO_VARIABLES\Data\EPIC029\04_predicted.csv'
    ruta_production_predicted = r'..\SEGUIMIENTO_VARIABLES\Temporal\produccion_scoreado.csv'
    ruta_model_indicators = r"..\SEGUIMIENTO_VARIABLES\Temporal\model_indicators.csv"
    ruta_model_stability = r'..\SEGUIMIENTO_VARIABLES\Temporal\model_stability.csv'
    ruta_data_quality = r'..\SEGUIMIENTO_VARIABLES\Temporal\data_quality.csv'
elif entorno == "development":
    ruta_modelo = r'EPIC029\src\02_models\kmeans_model_39.model' # Esto siempre esta dentro de la epic en bitbucket
    ruta_data_produccion = r"EPIC029\data\production\01_raw.csv" # Esto siempre esta dentro de la epic en bitbucket cuando está en producción
    ruta_data_entrenamiento = r'SEGUIMIENTO_VARIABLES\Data\EPIC029\02_preprocessed.csv' # Esto nosotros lo ponemos para cada EPIC
    ruta_train_predicted = r'SEGUIMIENTO_VARIABLES\Data\EPIC029\04_predicted.csv' # Esto nosotros lo ponemos para cada EPIC
    ruta_production_predicted = r'SEGUIMIENTO_VARIABLES\Temporal\produccion_scoreado.csv' # Esto se crea mientras se corre nuestro código
    ruta_model_indicators = r"SEGUIMIENTO_VARIABLES\Temporal\model_indicators.csv" # Este es un output de nuestro código
    ruta_model_stability = r'SEGUIMIENTO_VARIABLES\Temporal\model_stability.csv' # Este es un output de nuestro código
    ruta_data_quality = r'SEGUIMIENTO_VARIABLES\Temporal\data_quality.csv' # Este es un output de nuestro código

variables_modelo= ['FLG_MTO_P50','FLG_MTO_P75','FLG_MTO_P90','PERSONA_BEN','EMPRESA_BEN','FLG_NOREL','FLG_ROS_BEN','FLG_ROS_SOL']
columnas_numericas = ['MTOTRANSACCION']
columnas_categoricas = ['PERSONA_BEN','EMPRESA_BEN','FLG_NOREL','FLG_ROS_BEN','FLG_ROS_SOL']
variable_periodo="PERIODO"
variable_codigo_unico="CODCLAVECICBENEFICIARIO"
columna_clusters = 'cluster_kmeans'  # se deben convertir los labels/clusters a este nombre

# Variables generales de este escenario que se utilizarán dentro de las funciones para calcular las distintas metricas
modelo = 'EPIC029'
# como los modelos se corren con retraso en data management entonces el periodo no va a ser el del mes actual, sino en verdad
# debería ser del mes anterior, dicho esto, debemos tomar la máxima fecha de la data del etl
periodo=pd.read_csv(ruta_data_produccion, sep="|" ,encoding='ansi', usecols=[variable_periodo]).max()[0]
fecha_de_carga = date.today()

# Creamos dataframe que poblaremos con las distintas métricas calculadas
model_indicators = pd.DataFrame(columns=['MODELO','PERIODO','FECHA_DE_CARGA','METRICA','VALOR','ESTADO'])
model_stability = pd.DataFrame(columns=['MODELO','PERIODO','FECHA_DE_CARGA','VARIABLE','METRICA','VALOR','ESTADO'])
data_quality = pd.DataFrame(columns=['MODELO','PERIODO','FECHA_DE_CARGA','METRICA','VARIABLE','VALOR'])

# # # # # # # # # # # # # # # # # # # # # # # # # # # #
#                   Score silueta                    #
# # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Leemos la data
base=pd.read_csv(ruta_data_produccion, sep="|", encoding='latin')

# Limpieza/Transformacion data
# Aqui debe ir una función con toda la transformación/limpieza que se haga antes de correr el modelo
# El score de silueta, el csi y el data quality deben tener su función de transform()
def transform(data):
    logging.info("Inicio del metodo")
    try:
        data['FECONS_BENEFICIARIO'].replace('[NULL]', np.nan,inplace=True)
        data['FECONS_SOL'].replace('[NULL]', np.nan,inplace=True)

        p25=np.percentile(data['MTOTRANSACCION'], 25)
        p50=np.percentile(data["MTOTRANSACCION"], 50)
        p75=np.percentile(data["MTOTRANSACCION"], 75)
        p90=np.percentile(data["MTOTRANSACCION"], 90)
        p95=np.percentile(data["MTOTRANSACCION"], 95)

        data['FLG_MTO_P25']=0
        data.loc[(data['MTOTRANSACCION']>=p25)& (data['MTOTRANSACCION']<p50),'FLG_MTO_P25']=1
        data['FLG_MTO_P50']=0
        data.loc[(data['MTOTRANSACCION']>=p50)& (data['MTOTRANSACCION']<p75),'FLG_MTO_P50']=1
        data['FLG_MTO_P75']=0
        data.loc[(data['MTOTRANSACCION']>=p75)& (data['MTOTRANSACCION']<p90),'FLG_MTO_P75']=1
        data['FLG_MTO_P90']=0
        data.loc[(data['MTOTRANSACCION']>=p90),'FLG_MTO_P90']=1

        data['FECDIA2'] = pd.to_datetime(data['FECDIA'])
        data['FEC_BEN'] = pd.to_datetime(data['FECONS_BENEFICIARIO'])
        data['FEC_SOL'] = pd.to_datetime(data['FECONS_SOL'])

        data['FLG_AN']=0
        data.loc[(data['FLG_AN_BENEFICIARIO']==1)& (data['FLG_AN_SOLICITANTE']==1),'FLG_AN']=1
        data['TIPPER']=0
        data.loc[(data['TIPPER_SOLICITANTE']=='P')& (data['TIPPER_BENEFICIARIO']=='P'),'TIPPER']=1
        data["FLG_NUEVA_BEN"]=np.where(data["FECONS_BENEFICIARIO"].astype(str).str[6:10]==2020,1,0)
        data['dif']   = data['FECDIA2'] - data['FEC_BEN']
        data['dif2'] = data['dif'].dt.days

        data["FLG_NUEVA_SOL"]=np.where(data["FECONS_SOL"].astype(str).str[6:10]==2020,1,0)
        data['FLG_NUEVA']=0
        data.loc[(data['FLG_NUEVA_SOL']==1)& (data['FLG_NUEVA_BEN']== 1),'FLG_NUEVA']=1
        data['FLG_BANCA']=0
        data['PERSONA_SOL']=0
        data.loc[(data['DESBANCA_SOLICITANTE']== 'BANCA PERSONAL                     '),'PERSONA_SOL']=1
        data['EMPRESA_SOL']=0
        data.loc[(data['DESBANCA_SOLICITANTE']== 'EMPRESA                            '),'EMPRESA_SOL']=1
        data['PERSONA_BEN']=0
        data.loc[(data['DESBANCA_BENEFICIARIO']== 'BANCA PERSONAL                     '),'PERSONA_BEN']=1
        data['EMPRESA_BEN']=0
        data.loc[(data['DESBANCA_BENEFICIARIO']== 'EMPRESA                            '),'EMPRESA_BEN']=1
        data.loc[(data['DESBANCA_SOLICITANTE']== 'BANCA PERSONAL                     ')& (data['DESBANCA_BENEFICIARIO']== 'BANCA PERSONAL                     '),'FLG_BANCA']=1

        data['FLG_ROS']=0
        data.loc[(data['FLG_ROS_SOL']==1)& (data['FLG_ROS_BEN']==1),'FLG_ROS']=1
        data['FLG_BANCA']=0
        data.loc[(data['DESBANCA_SOLICITANTE']=='BANCA PERSONAL                     ','FLG_BANCA')]= 1
        data["FLG_MTO"]=np.where(data["MTOTRANSACCION"]>500000,1,0)
        data["FLG_NOREL"]=np.where(data["FLG_REL"]==1,0,1)

        data['MTOTRANSACCION_ES']=data['MTOTRANSACCION'].astype(float)
        scale(data['MTOTRANSACCION_ES'], axis=0, with_mean=True, with_std=True, copy=True)

        data["TIPPER_BEN"]=np.where(data["TIPPER_BENEFICIARIO"]=='P',0,1)
        data["TIPPER_SOL"]=np.where(data["TIPPER_SOLICITANTE"]=='P',0,1) 

        p95=np.percentile(data["MTOTRANSACCION"], 95)
        data["MTO_P95"]=np.where(data["MTOTRANSACCION"]>p95,p95,data["MTOTRANSACCION"])

        data['MTOTRANSACCION_ES95']=data['MTO_P95'].astype(float)
        scale(data['MTOTRANSACCION_ES95'], axis=0, with_mean=True, with_std=True, copy=True)       
    except ValueError:
        logging.error(
            "La ingeneria de caracteristicas fallo en una transformacion")
        sys.exit()
    except Exception:
        exc_type, exc_value, exc_traceback = sys.exc_info()
        logging.warning("Sucedio un error inesperado: "+
                        exc_type+" - "+exc_value+" - "+exc_traceback)
        sys.exit()
    else:
        logging.info("Finaliza correctamente")
        return data

data = transform(base)

# Llamamos la función de score_silueta
score_silueta_modelo = score_silueta(ruta_modelo, ruta_production_predicted, data, 
                                     variables_modelo, variable_periodo, variable_codigo_unico, 
                                     modelo, periodo, fecha_de_carga)

# Insertamos fila respecto a score de silueta
model_indicators.loc[len(model_indicators.index)] = score_silueta_modelo

# # # # # # # # # # # # # # # # # # # # # # # # # # # #
#                       Psi                           #
# # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Interpretation
# PSI < 0.1: no significant population change
# PSI < 0.2: moderate population change
# PSI >= 0.2: significant population change

# Creando variables
# Se utiliza el 04_predicted.csv porque contiene la data de entrenamiento con el label (columna cluster_kmeans) 
df_entrenamiento_scoreado = pd.read_csv(ruta_train_predicted, sep="|")

# Se utiliza el .csv temporal que se creó en la seccion de score de silueta ya que contiene los clusters de produccion
df_produccion_scoreado = pd.read_csv(ruta_production_predicted, sep=",")

# Indicar el nombre de la columna que contiene los clusters, tanto entrenamiento como produccion deben tener el mismo nombre
df_entrenamiento_scoreado = df_entrenamiento_scoreado.rename(columns={'N_Cluster': columna_clusters})

# Llamamos la función de psi
a,b = psi(df_entrenamiento_scoreado, df_produccion_scoreado, 
          columna_clusters, 
          modelo, periodo, fecha_de_carga)
# Insertamos fila respecto a psi de los clusters del modelo
model_indicators.loc[len(model_indicators.index)] = b

# # # # # # # # # # # # # # # # # # # # # # # # # # # #
#                       Csi                           #
# # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Interpretation
# CSI < 0.1: no significant population change
# CSI < 0.2: moderate population change
# CSI >= 0.2: significant population change
# Vamos a calcular el psi por cada variable de nuestro modelo a fin de ver su estabilidad a través del tiempo 
df_entrenamiento = pd.read_csv(ruta_data_entrenamiento , sep="|")
df_entrenamiento = transform(df_entrenamiento)

df_produccion = pd.read_csv(ruta_data_produccion, sep="|", encoding='latin')
df_produccion = transform(df_produccion)

# Llamando a la función para calcular el csi de cada variable
a,b,c =csi(df_entrenamiento, df_produccion, 
           columnas_numericas, columnas_categoricas, variable_periodo, 
           modelo, periodo, fecha_de_carga)
# Insertamos fila respecto a score de silueta
model_stability = model_stability._append(c)

# # # # # # # # # # # # # # # # # # # # # # # # # # # #
#                       Data quality                  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Definición variables
df_produccion = pd.read_csv(ruta_data_produccion, sep="|", encoding='latin')

# Llamando a la función para calcular ciertas métricas de calidad de los datos
data_quality_return = data_quality_function(df_produccion,
                                            variables_modelo, variable_periodo, variable_codigo_unico, 
                                            modelo, periodo, fecha_de_carga,
                                            variables_a_evaluar="etl")
# Insertamos fila respecto a calidad de los datos
data_quality = data_quality._append(data_quality_return)

# # # # # # # # # # # # # # # # # # # # # # # # # # # #
#                Output agrupado final                #
# # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Output: Convirtiendo dataframe a csv que se cargará a oracle
# Se agregó una carpeta 
model_indicators.to_csv(ruta_model_indicators,index=False)
model_stability.to_csv(ruta_model_stability,index=False)
data_quality.to_csv(ruta_data_quality,index=False)