import logging
import numpy as np
import pandas as pd
from sklearn.ensemble import IsolationForest
import pickle
import os
import warnings
warnings.filterwarnings('ignore')

def correr_modelo():
	dataframe = pd.read_csv('./data/production/01_raw.csv',encoding= 'latin',sep="|")
	# Reconfigure logging again, this time with a file.
	with open('./logs/02_models/inference.log','w'):
		pass
	logging.basicConfig(filename='./logs/02_models/inference.log',level=logging.DEBUG)
	try:
		logging.info("Seleccionar las variables para el modelo")
		#Transformo variables
		df = dataframe[dataframe['VARIACIO_1M_TOTAL_DEUDA'].notna()]
		df = dataframe[dataframe['RATIO_NO_TOTAL_SF_HAB']>0]
		df.loc[dataframe.VARIACIO_1M_TOTAL_DEUDA < 0, 'VARIACIO_1M_TOTAL_DEUDA'] = 0
		ds=dataframe[['RATIO_NO_TOTAL_SF_HAB','VARIACIO_1M_TOTAL_DEUDA']]
		logging.info("Cargar modelo")
		#Cargo modelo:
		loaded_model = pickle.load(open(r'./src/02_models/if_model_39.model', "rb"))
		logging.info("Aplicar el modelo cargado sobre el dataset")
		#Aplico el modelo cargado sobre la data
		dataframe['Outlier']=loaded_model.predict(ds)
		logging.info("Exportar la data con la columna adicional")

		#Exporto la data con la columna adicional
		dataframe.to_csv(r'./data/production/04_predicted.csv',index=False,sep='|')
		logging.info("FIN: SIN ERRORES")
	except Exception as e:
		logging.error("Exception occurred", exc_info=True)
if os.path.exists('./data/production/04_predicted.csv'):
	os.remove('./data/production/04_predicted.csv')
	correr_modelo()
else:
	correr_modelo()