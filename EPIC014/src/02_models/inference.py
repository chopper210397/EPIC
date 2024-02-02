#!/usr/bin/env python
# coding: utf-8

# In[16]:

import logging
import numpy as np
import pandas as pd
from sklearn.preprocessing import StandardScaler
from sklearn.cluster import KMeans
import pickle

import warnings
warnings.filterwarnings('ignore')
#
import os
#os.remove('./logs/02_models/inference.log')
logging.basicConfig(filename='./logs/02_models/inference.log',level=logging.DEBUG)

try:
	pd.set_option('display.max_columns', None)

	#Seleccionar ruta de la data
	dataset = pd.read_csv('./data/production/01_raw.csv', encoding='ansi',infer_datetime_format=True,sep=",")
	dataset

	#Cargo modelo:
	import pickle
	loaded_model = pickle.load(open(r'./src/02_models/kmeans_model_39.model', "rb"))

	#Selecciono las variables que utiliza el modelo
	ds4=dataset[['MTO_RECIBIDO',
			 'FLG_ROS_REL',
		   'FLG_LSB_NP_REL', 'FLG_PERFIL_3DESVT_TRX']]

	#Escalo la data
	data_cluster2 = StandardScaler().fit_transform(ds4)


	#Cargo el modelo y lo aplico sobre la data
	loaded_model.predict(data_cluster2)
	dataset['N_Cluster']=loaded_model.predict(data_cluster2)
	dataset.head()

	#Exporto la data con la columna adicional
	dataset.to_csv(r'./data/production/04_predicted.csv',index=False, sep ="|")

except Exception as e:
  logging.error("Exception occurred", exc_info=True)