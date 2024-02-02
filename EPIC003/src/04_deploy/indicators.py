import logging
import numpy as np
import pandas as pd
from scipy.spatial.distance import cdist
from sklearn.cluster import KMeans
from sklearn.preprocessing import MinMaxScaler
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import silhouette_score
from datetime import date
import pickle
import sys
import os
import warnings
import math
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
    ruta_modelo = r'.\src\03_models\IF_EPIC003_alerta.model'
    ruta_data_produccion = r".\data\production\01_raw.csv"
    ruta_data_entrenamiento = r'..\SEGUIMIENTO_VARIABLES\Data\EPIC003\02_preprocessed.csv'
    ruta_train_predicted = r'..\SEGUIMIENTO_VARIABLES\Data\EPIC003\04_predicted.csv'
    ruta_production_predicted = r'..\SEGUIMIENTO_VARIABLES\Temporal\produccion_scoreado.csv'
    ruta_model_indicators = r"..\SEGUIMIENTO_VARIABLES\Temporal\model_indicators.csv"
    ruta_model_stability = r'..\SEGUIMIENTO_VARIABLES\Temporal\model_stability.csv'
    ruta_data_quality = r'..\SEGUIMIENTO_VARIABLES\Temporal\data_quality.csv'
elif entorno == "development":
    ruta_modelo = r'EPIC003\src\03_models\IF_EPIC003_alerta.model' # Esto siempre esta dentro de la epic en bitbucket
    ruta_data_produccion = r"EPIC003\data\production\01_raw.csv" # Esto siempre esta dentro de la epic en bitbucket cuando está en producción
    ruta_data_entrenamiento = r'SEGUIMIENTO_VARIABLES\Data\EPIC003\02_preprocessed.csv' # Esto nosotros lo ponemos para cada EPIC
    ruta_train_predicted = r'SEGUIMIENTO_VARIABLES\Data\EPIC003\04_predicted.csv' # Esto nosotros lo ponemos para cada EPIC
    ruta_production_predicted = r'SEGUIMIENTO_VARIABLES\Temporal\produccion_scoreado.csv' # Esto se crea mientras se corre nuestro código
    ruta_model_indicators = r"SEGUIMIENTO_VARIABLES\Temporal\model_indicators.csv" # Este es un output de nuestro código
    ruta_model_stability = r'SEGUIMIENTO_VARIABLES\Temporal\model_stability.csv' # Este es un output de nuestro código
    ruta_data_quality = r'SEGUIMIENTO_VARIABLES\Temporal\data_quality.csv' # Este es un output de nuestro código

variables_modelo= ['MTO_TRANSF', 'CTD_OPE', 'FLG_PEP', 'FLG_PROF', 'FLG_PERFIL','CTDEVAL', 'FLG_PAIS']
columnas_numericas = ['MTO_TRANSF', 'CTD_OPE','CTDEVAL']
columnas_categoricas = ['FLG_PEP','FLG_PROF','FLG_PERFIL','FLG_PAR']
variable_periodo="PERIODO"
variable_codigo_unico="CODCLAVECIC"
columna_clusters = 'cluster_kmeans'  # se deben convertir los labels/clusters a este nombre

# Variables generales de este escenario que se utilizarán dentro de las funciones para calcular las distintas metricas
modelo = 'EPIC003'
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
base=pd.read_csv(ruta_data_produccion, sep="|", encoding='unicode_escape')

# Limpieza/Transformacion data
# Aqui debe ir una función con toda la transformación/limpieza que se haga antes de correr el modelo
# El score de silueta, el csi y el data quality deben tener su función de transform()
def transform(dataframe):
    logging.info("Inicio del metodo")
    try:
        # Cambio nombre de columna
        #dataframe.rename(columns={'NUMPERIODO': 'PERIODO'}, inplace=True)
        # Creo variable FLG_ANSLBNP que es la unión de las variables FLG_AN y FLG_LSBNP
        # Inicializo la variable en cero
        dataframe['FLG_PAIS']=0
        #Creo las condicionales donde dependiendo de la  categoría de la variable inical pinto como 1
        dataframe.loc[(dataframe.FLG_PAR==0),'FLG_PAIS' ] = 0
        dataframe.loc[(dataframe.FLG_PAR==1), 'FLG_PAIS' ] = 1
        dataframe.loc[(dataframe.FLG_PAR==2) ,'FLG_PAIS' ] = 1          
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
        return dataframe

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
df_entrenamiento_scoreado = pd.read_csv(ruta_train_predicted, sep=",")

# Se utiliza el .csv temporal que se creó en la seccion de score de silueta ya que contiene los clusters de produccion
df_produccion_scoreado = pd.read_csv(ruta_production_predicted, sep=",")

# Indicar el nombre de la columna que contiene los clusters, tanto entrenamiento como produccion deben tener el mismo nombre
df_entrenamiento_scoreado = df_entrenamiento_scoreado.rename(columns={'OUTLIER': columna_clusters})

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
df_entrenamiento = pd.read_csv(ruta_data_entrenamiento , sep=",")
df_entrenamiento = transform(df_entrenamiento)

df_produccion = pd.read_csv(ruta_data_produccion, sep="|", encoding='ansi')
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
df_produccion = pd.read_csv(ruta_data_produccion, sep="|", encoding='ansi')

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