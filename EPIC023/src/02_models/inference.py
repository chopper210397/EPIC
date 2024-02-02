# ## Producción Modelo CV ME
import logging
import numpy as np
import pandas as pd
from sklearn.ensemble import IsolationForest
import pickle
import os
import warnings
warnings.filterwarnings('ignore')

def correr_modelo():
	#Seleccionar ruta de la data
	dataframe = pd.read_csv('./data/production/01_raw.csv',encoding='unicode_escape',sep="|")
	# Reconfigure logging again, this time with a file.
	with open('./logs/02_models/inference.log','w'):
		pass
	logging.basicConfig(filename='./logs/02_models/inference.log',level=logging.DEBUG)
	try:
		logging.info("Imputar valores vacios")
		dataframe['EDAD'] = dataframe['EDAD'].fillna(dataframe['EDAD'].median())
		dataframe['ANTIGUEDAD'] = dataframe['ANTIGUEDAD'].fillna(dataframe['ANTIGUEDAD'].median())
		logging.info("Cargar modelo")
		loaded_model = pickle.load(open(r'./src/02_models/isolation_forest_model_39.model', 'rb'))
		logging.info("Seleccionar las variables que utiliza el modelo")
		dataset = dataframe[['EDAD','ANTIGUEDAD','FLGNOCLIENTE','CTD_AN_NP_LSB','CTDEVAL','CTD_ORDENATES_DISTINTOS',
		                    'MTO_COMPRA','MTO_VENTA','CTD_COMPRA','CTD_VENTA','MTO_ZAED','CTD_ZAED','CTD_DIAS',
			                'FLG_PERFIL_DEPOSITOS_3DS','CTD_TRX_LIM']]
		logging.info("Predecir sobre la data")
		dataframe['Outlier']=loaded_model.predict(dataset)
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