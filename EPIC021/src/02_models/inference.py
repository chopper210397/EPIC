import logging
import pandas as pd
import numpy as np
import pickle
from sklearn.preprocessing import MinMaxScaler
from sklearn.ensemble import RandomForestClassifier
import os
import warnings
warnings.filterwarnings('ignore')

def correr_modelo():
	#Seleccionar ruta de la data
	base=pd.read_csv('./data/production/01_raw.csv', sep="|")
	# Reconfigure logging again, this time with a file.
	with open('./logs/02_models/inference.log','w'):
		pass
	logging.basicConfig(filename='./logs/02_models/inference.log',level=logging.DEBUG)
	try:
		logging.info("Crear flg zaed")
		base["FLG_ZAED"]=base["TIPO_ZONA"].apply(lambda x:1 if x == 2 else 0)
		logging.info("Seleccionar variables")
		variables_numericas=['MTO_CASH_DEPO',
							'CTD_CASH_DEPO',
							'MTO_CASH_RET',
							'CTD_CASH_RET',
							'CTD_TRXS_SINCTAAGENTE',
							'ANTIGUEDAD',
							'FLG_ACTECO_NODEF',
							'FLG_PERFIL_CASH_DEPO_3DS',
							'CTD_TRXSFUERAHORARIO',
							'PROM_DEPODIARIOS',
							'CTD_DIASDEPO',
							'CTD_AN_NP_LSB',
							'MTO_AN_NP_LSB',
							'CTD_EVALS_PROP'
							] #---------filter3 sin imputer
		columnas_flags=['FLG_ZAED']
		variables_modelo=variables_numericas+columnas_flags
		logging.info("Estandarizar las variables")
		minmax = MinMaxScaler()
		test_scalado = minmax.fit_transform(base[variables_modelo])
		test_scalado = pd.DataFrame(test_scalado, columns=[variables_modelo])
		test_scalado.head()
		logging.info("Cargar el modelo")
		modelo_rf = pickle.load(open(r'./src/02_models/random_forest_model_39.model', 'rb'))
		logging.info("Predecir sobre la data")
		base['rf_pred'] = modelo_rf.predict(test_scalado)
		base.rf_pred.value_counts()
		logging.info("Guardar data con predicciones")
		base.to_csv(r'./data/production/04_predicted.csv',index=False,sep='|')
		logging.info("FIN: SIN ERRORES")
	except Exception as e:
		logging.error("Exception occurred", exc_info=True)
if os.path.exists('./data/production/04_predicted.csv'):
	os.remove('./data/production/04_predicted.csv')
	correr_modelo()
else:
	correr_modelo()