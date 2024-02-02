import logging
import numpy as np
import pandas as pd
from sklearn.ensemble import IsolationForest
import os
import pickle

import warnings
warnings.filterwarnings('ignore')


def correr_modelo():
	dataframe = pd.read_csv('./data/production/01_raw.csv',encoding='latin',sep="|")
	with open('./logs/02_models/inference.log','w'):
		pass
	logging.basicConfig(filename='./logs/02_models/inference.log',level=logging.DEBUG)

	try:
		logging.info("Seleccionar las variables para el modelo")
		dataframe['MTO_TOTAL_OPE']=dataframe['MTO_OPEPOS']+dataframe['MTO_OPEATM']
		dataframe['CTD_TOTAL_OPE']=dataframe['CTD_OPEPOS']+dataframe['CTD_OPEATM']
		dataset=dataframe.loc[(dataframe['MTO_TOTAL_OPE']>1000)]
		ds=dataset[['MTO_TOTAL_OPE','CTD_TOTAL_OPE']]
		logging.info("Cargar Modelo")

		loaded_model = pickle.load(open(r'./src/02_models/if_model_39.model', "rb"))
		logging.info("Aplicar el modelo cargado sobre el dataset")
		dataset['Outlier']=loaded_model.predict(ds)
		logging.info("Exportar la data con la columna adicional")
		dataset.to_csv(r'./data/production/04_predicted.csv',index=False,sep='|')
		logging.info("FIN: SIN ERRORES")
	except Exception as e:
		logging.error("Exception occurred",exc_info=True)

if os.path.exists('./data/production/04_predicted.csv'):
	os.remove('./data/production/04_predicted.csv')
	correr_modelo()
else:
	correr_modelo()