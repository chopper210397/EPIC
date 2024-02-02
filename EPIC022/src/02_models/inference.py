import logging
import numpy as np
import pandas as pd
from sklearn.ensemble import IsolationForest
import os
import pickle
import warnings
warnings.filterwarnings('ignore')

def correr_modelo():
	dataframe = pd.read_csv('./data/production/01_raw.csv',encoding='ansi',infer_datetime_format=True,sep="|")
    #print('Nro filas: ' + str(dataframe.shape[0]))
	with open('./logs/02_models/inference.log','w'):
		pass
	logging.basicConfig(filename='./logs/02_models/inference.log',level=logging.DEBUG)
	try:
		logging.info("Imputar valores vacios")
		dataset= dataframe[dataframe.MTO_TOTAL_CASH>10000]
		dataset['EDAD'] = dataset['EDAD'].fillna(dataset['EDAD'].mean())
		dataset['FLGNACIONALIDAD'] = dataset['FLGNACIONALIDAD'].fillna(0)
		print(dataset['FLGNACIONALIDAD'].value_counts())
		loaded_model = pickle.load(open(r'./src/02_models/isolation_forest_model_39.model', 'rb'))
		logging.info("Seleccionar las variables que utiliza el modelo")
		ds_new=dataset[['ANTIGUEDADCLI','EDAD','MTO_TOTAL_CASH','MTO_TOTAL','CTD_TOTAL_CASH','MTO_CHQGEN','PORC_CHQGEN','MTO_TOTAL_CASH_ZAED', 'CTD_CASH_ZAED', 'CTD_DIAS_DEBAJOLAVA']]
		logging.info("Predecir sobre la data")
		dataset['Outlier']=loaded_model.predict(ds_new)
		print(dataset['Outlier'].value_counts())
		dataset.to_csv(r'./data/production/04_predicted.csv',index=False,sep='|')
		logging.info("FIN: SIN ERRORES")
	except Exception as e:
		logging.error("Exception occurred", exc_info=True)
if os.path.exists('./data/production/04_predicted.csv'):
	os.remove('./data/production/04_predicted.csv')
	correr_modelo()
else:
	correr_modelo()