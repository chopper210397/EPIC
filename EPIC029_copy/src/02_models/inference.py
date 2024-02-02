import mlflow
import mlflow.sklearn
from mlflow.models import infer_signature

import numpy as np
import pandas as pd
import pickle
from sklearn.cluster import KMeans
pd.set_option("display.max_columns",500)
pd.set_option("display.max_rows",500)
from sklearn import metrics
from sklearn.preprocessing import scale
from sklearn.preprocessing import StandardScaler

# set the experiment id
mlflow.set_experiment(experiment_name= "gato")
mlflow.set_tracking_uri("http://127.0.0.1:5000")

mlflow.sklearn.autolog()

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
    ruta_modelo = r'EPIC029_copy\src\02_models\kmeans_model_39.model' # Esto siempre esta dentro de la epic en bitbucket
    ruta_data_produccion = r"EPIC029_copy\data\production\01_raw.csv" # Esto siempre esta dentro de la epic en bitbucket cuando está en producción
    ruta_data_entrenamiento = r'SEGUIMIENTO_VARIABLES\Data\EPIC029\02_preprocessed.csv' # Esto nosotros lo ponemos para cada EPIC
    ruta_train_predicted = r'SEGUIMIENTO_VARIABLES\Data\EPIC029\04_predicted.csv' # Esto nosotros lo ponemos para cada EPIC
    ruta_production_predicted = r'SEGUIMIENTO_VARIABLES\Temporal\produccion_scoreado.csv' # Esto se crea mientras se corre nuestro código
    ruta_model_indicators = r"SEGUIMIENTO_VARIABLES\Temporal\model_indicators.csv" # Este es un output de nuestro código
    ruta_model_stability = r'SEGUIMIENTO_VARIABLES\Temporal\model_stability.csv' # Este es un output de nuestro código
    ruta_data_quality = r'SEGUIMIENTO_VARIABLES\Temporal\data_quality.csv' # Este es un output de nuestro código



# configuration mlflow
# model_name = 'external_model1'
# with mlflow.start_run() as run:     
#     # Set the Run Name    
#     mlflow.set_tag("mlflow.runName","my_run_name1")          
#     # log_model needs atleast 2 parameters, first one model,     
#     # second a foldername.     
#     mlflow.sklearn.log_model(ruta_modelo, "internal_model_path")     
#     run_id = run.info.run_id     
#     mlflow.register_model(f"runs:/{run_id}/internal_model_path", model_name)              
#     print(run.info.artifact_uri)     
#     print(run_id)

#

data = pd.read_csv(ruta_data_produccion,sep="|", encoding='latin')

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

# data['FECDIA2'] = pd.to_datetime(data['FECDIA'])
# data['FEC_BEN'] = pd.to_datetime(data['FECONS_BENEFICIARIO'])
# data['FEC_SOL'] = pd.to_datetime(data['FECONS_SOL'])

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

variables=['FLG_MTO_P50','FLG_MTO_P75','FLG_MTO_P90',
'PERSONA_BEN','EMPRESA_BEN',
'FLG_NOREL',
'FLG_ROS_BEN','FLG_ROS_SOL'
          ]

logged_model = 'runs:/b91e605e4c4c4c4287656a8b2ca22a0a/internal_model_path'

# Load model
loaded_model = mlflow.sklearn.load_model(logged_model)

data['N_Cluster']=loaded_model.predict(data[variables]) 
data_new = data.filter(['CODCLAVECICBENEFICIARIO','CODCLAVECICSOLICITANTE','PERIODO','FECDIA','CODSUCAGE','CODSESION',
                        'CODINTERNOTRANSACCION','CODTRANSACCIONVENTANILLA','MTOTRANSACCION','FLG_MTO_P25','FLG_MTO_P50',
                        'FLG_MTO_P75','FLG_MTO_P90','FLG_AN','TIPPER','FLG_NUEVA_BEN','dif2','FLG_NUEVA_SOL','FLG_NUEVA',
                        'FLG_BANCA','PERSONA_SOL','EMPRESA_SOL','PERSONA_BEN','EMPRESA_BEN','FLG_ROS','FLG_MTO','FLG_NOREL',
                        'MTOTRANSACCION_ES','TIPPER_BEN','TIPPER_SOL','MTO_P95','MTOTRANSACCION_ES95','FLG_ROS_BEN','FLG_ROS_SOL','N_Cluster'])


# mlflow.sklearn.log_model(loaded_model, "modelo")



# # Puedes recuperar el ID del run actual si lo necesitas
# run_id = mlflow.active_run().info.run_id
# print(f"Run ID: {run_id}")