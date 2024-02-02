import numpy as np
import pandas as pd
import pickle
from sklearn.cluster import KMeans
pd.set_option("display.max_columns",500)
pd.set_option("display.max_rows",500)
from sklearn import metrics
from sklearn.preprocessing import scale
from sklearn.preprocessing import StandardScaler

data = pd.read_csv('./data/production/01_raw.csv',sep="|", encoding='latin')

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

variables=['FLG_MTO_P50','FLG_MTO_P75','FLG_MTO_P90',
'PERSONA_BEN','EMPRESA_BEN',
'FLG_NOREL',
'FLG_ROS_BEN','FLG_ROS_SOL'
          ]

#Cargo modelo:
loaded_model = pickle.load(open('./src/02_models/kmeans_model_39.model', "rb"))

data['N_Cluster']=loaded_model.predict(data[variables]) 
data_new = data.filter(['CODCLAVECICBENEFICIARIO','CODCLAVECICSOLICITANTE','PERIODO','FECDIA','CODSUCAGE','CODSESION',
                        'CODINTERNOTRANSACCION','CODTRANSACCIONVENTANILLA','MTOTRANSACCION','FLG_MTO_P25','FLG_MTO_P50',
                        'FLG_MTO_P75','FLG_MTO_P90','FLG_AN','TIPPER','FLG_NUEVA_BEN','dif2','FLG_NUEVA_SOL','FLG_NUEVA',
                        'FLG_BANCA','PERSONA_SOL','EMPRESA_SOL','PERSONA_BEN','EMPRESA_BEN','FLG_ROS','FLG_MTO','FLG_NOREL',
                        'MTOTRANSACCION_ES','TIPPER_BEN','TIPPER_SOL','MTO_P95','MTOTRANSACCION_ES95','FLG_ROS_BEN','FLG_ROS_SOL','N_Cluster'])

data_new.to_csv('./data/production/04_predicted.csv',index=False,sep='|')
