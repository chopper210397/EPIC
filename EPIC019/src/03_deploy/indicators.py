import logging
import numpy as np
import pandas as pd
from scipy.spatial.distance import cdist
from sklearn.cluster import KMeans
from sklearn.preprocessing import MinMaxScaler
from sklearn.preprocessing import scale
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
#               Creando estructura                   #
# # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Definiendo variables

# # # # # # # # # # # # #
entorno = "development" #
# # # # # # # # # # # # #

if entorno == "production":
    ruta_modelo = r'.\src\02_models\kmeans_model_39.model'
    ruta_data_produccion = r".\data\production\01_raw.csv"
    ruta_data_entrenamiento = r'..\SEGUIMIENTO_VARIABLES\Data\EPIC019\02_preprocessed.csv'
    ruta_train_predicted = r'..\SEGUIMIENTO_VARIABLES\Data\EPIC019\04_predicted.csv'
    ruta_production_predicted = r'..\SEGUIMIENTO_VARIABLES\Temporal\produccion_scoreado.csv'
    ruta_model_indicators = r"..\SEGUIMIENTO_VARIABLES\Temporal\model_indicators.csv"
    ruta_model_stability = r'..\SEGUIMIENTO_VARIABLES\Temporal\model_stability.csv'
    ruta_data_quality = r'..\SEGUIMIENTO_VARIABLES\Temporal\data_quality.csv'
elif entorno == "development":
    ruta_modelo = r'EPIC019\src\02_models\kmeans_model_39.model' # Esto siempre esta dentro de la epic en bitbucket
    ruta_data_produccion = r"EPIC019\data\production\01_raw.csv" # Esto siempre esta dentro de la epic en bitbucket cuando está en producción
    ruta_data_entrenamiento = r'SEGUIMIENTO_VARIABLES\Data\EPIC019\02_preprocessed.csv' # Esto nosotros lo ponemos para cada EPIC
    ruta_train_predicted = r'SEGUIMIENTO_VARIABLES\Data\EPIC019\04_predicted.csv' # Esto nosotros lo ponemos para cada EPIC
    ruta_production_predicted = r'SEGUIMIENTO_VARIABLES\Temporal\produccion_scoreado.csv' # Esto se crea mientras se corre nuestro código
    ruta_model_indicators = r"SEGUIMIENTO_VARIABLES\Temporal\model_indicators.csv" # Este es un output de nuestro código
    ruta_model_stability = r'SEGUIMIENTO_VARIABLES\Temporal\model_stability.csv' # Este es un output de nuestro código
    ruta_data_quality = r'SEGUIMIENTO_VARIABLES\Temporal\data_quality.csv' # Este es un output de nuestro código

variables_modelo=['BENEF_99','SOLIC_99','ZONA_ZAED','ZONA_NOZAED','PROF_RIESGO','SEGM_PEQCON','NAC_RIESGO','PERU','OTROSNAC']
columnas_numericas = ['BENEF_99','SOLIC_99']
columnas_categoricas = ['ZONA_ZAED','ZONA_NOZAED','PROF_RIESGO','SEGM_PEQCON','NAC_RIESGO','PERU','OTROSNAC']
variable_periodo="PERIODO"
variable_codigo_unico="CODIGO_CLIENTE"
columna_clusters = 'cluster_kmeans'

# Variables generales de este escenario que se utilizarán dentro de las funciones para calcular las distintas metricas
modelo = 'EPIC019'
# como los modelos se corren con retraso en data management entonces el periodo no va a ser el del mes actual, sino en verdad
# debería ser del mes anterior, dicho esto, debemos tomar la máxima fecha de la data del etl
periodo=pd.read_csv(ruta_data_produccion, sep="|" ,encoding='ansi', usecols=[variable_periodo]).max()[0]
fecha_de_carga = date.today()

# Creamos dataframe que poblaremos con las distintas métricas calculadas
model_indicators = pd.DataFrame(columns=['MODELO','PERIODO','FECHA_DE_CARGA','METRICA','VALOR','ESTADO'])
model_stability = pd.DataFrame(columns=['MODELO','PERIODO','FECHA_DE_CARGA','VARIABLE','METRICA','VALOR','ESTADO'])
data_quality = pd.DataFrame(columns=['MODELO','PERIODO','FECHA_DE_CARGA','METRICA','VARIABLE','VALOR'])

# # # # # # # # # # # # # # # # # # # # # # # # # # # #
#                   Score silueta                     #
# # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Leemos la data
base=pd.read_csv(ruta_data_produccion, sep="|", encoding='ansi')

# Limpieza/Transformacion data
def transform(base):
    data= base[(base.SOLICITANTE>50000)]
    p50=np.percentile(data["BENEFICIARIO"], 50)
    p75=np.percentile(data["BENEFICIARIO"], 75)
    p90=np.percentile(data["BENEFICIARIO"], 90)
    p99=np.percentile(data["BENEFICIARIO"], 99)
    data['BENEF_99']=np.where(data['BENEFICIARIO']>=p99,p99,data['BENEFICIARIO'])
    p50=np.percentile(data["SOLICITANTE"], 50,)
    p75=np.percentile(data["SOLICITANTE"], 75)
    p90=np.percentile(data["SOLICITANTE"], 90)
    p99=np.percentile(data["SOLICITANTE"], 99)
    data['SOLIC_99']=np.where(data['SOLICITANTE']>=p99,p99,data['SOLICITANTE'])
    data['ZONA_LIMA']=data["CATFLGZAED"].replace([1],1).replace([0],0).replace([2],0)
    data['ZONA_ZAED']=data["CATFLGZAED"].replace([1],0).replace([0],0).replace([2],1)
    data['ZONA_NOZAED']=data["CATFLGZAED"].replace([1],2).replace([2],2).replace([0],1).replace([2],0)
    data['PROF_RIESGO']=data["CATPROFESION"].replace([1],1).replace([3],0).replace([2],0)
    data['PROF_SININFO']=data["CATPROFESION"].replace([1],0).replace([3],0).replace([2],1)
    data['PROF_OTRAS']=data["CATPROFESION"].replace([1],0).replace([2],0).replace([3],1)
    data['SEGM_PEQCON']=data["CATSEGMENTO"].replace([2],0).replace([1],0).replace([3],1)
    data['SEGM_EXCNEG']=data["CATSEGMENTO"].replace([1],0).replace([3],0).replace([2],1)
    data['SEGM_ENAPRIV']=data["CATSEGMENTO"].replace([1],1).replace([2],0).replace([3],0)
    data['OTROSNAC']=data["CATNACIONAL"].replace([1],2).replace([2],2).replace([3],2).replace([0],1).replace([2],0)
    data['PERU']=data["CATNACIONAL"].replace([1],1).replace([0],0).replace([2],0).replace([3],0)
    data['SIN_NAC']=data["CATNACIONAL"].replace([0],0).replace([1],0).replace([3],0).replace([2],1)
    data['NAC_RIESGO']=data["CATNACIONAL"].replace([0],0).replace([1],0).replace([2],0).replace([3],1)
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
df_entrenamiento_scoreado = pd.read_csv(ruta_train_predicted, sep=",")

# Se utiliza el .csv temporal que se creó en la seccion de score de silueta ya que contiene los clusters de produccion
df_produccion_scoreado = pd.read_csv(ruta_production_predicted, sep=",")

# Indicar el nombre de la columna que contiene los clusters, tanto entrenamiento como produccion deben tener el mismo nombre
df_entrenamiento_scoreado = df_entrenamiento_scoreado.rename(columns={'ClienteSegment': columna_clusters})

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
a,b,c =csi(df_entrenamiento, df_produccion, columnas_numericas, columnas_categoricas, variable_periodo, modelo, periodo, fecha_de_carga)
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