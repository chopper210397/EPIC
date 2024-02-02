import logging
import numpy as np
import pandas as pd
from scipy.spatial.distance import cdist
from sklearn.cluster import KMeans
import pickle
import os
from sklearn.preprocessing import MinMaxScaler
import warnings
warnings.filterwarnings('ignore')

def correr_modelo():
	dataframe=pd.read_csv('./data/production/01_raw.csv', sep = "|")
	# Reconfigure logging again, this time with a file.
	with open('./logs/02_models/inference1.log','w'):
		pass
	logging.basicConfig(filename='./logs/02_models/inference1.log',level=logging.DEBUG)

	try:
		logging.info("Seleccionar las variables para el modelo")
		dataframe['FLG_PEP_TOT']=dataframe['FLG_PEP']+dataframe['FLG_PEP_REL']
		dataframe["ACT_ECONOMICA_GRUPOSINTERES"].replace([1,2,3,4],[0,1,1,1],inplace=True)
		dataframe["CATPROFESION"].replace([0,1,2,4],[1,0,1,1],inplace=True)
		ds=dataframe[['MONTO_INGRESO','CTD_INGRESO','FLG_PERFIL_3DS']]
		logging.info("Cargar modelo")
        #Cargo modelo:
		import pickle
		loaded_model = pickle.load(open(r'./src/02_models/if1_model_39.model', "rb"))
		logging.info("Aplicar el modelo cargado sobre el dataframe")
        #Aplico el modelo cargado sobre la data 
		dataframe['Outlier']=loaded_model.predict(ds)
		logging.info("Exportar la data con la columna adicional")
        #Exporto la data con la columna adicional
		dataframe.to_csv(r'./data/production/03_input1.csv',index=False,sep='|')
		dataframe=dataframe.loc[(dataframe['Outlier']==-1)]
		logging.info("Exportar la data con la columna adicional")
        #Exporto la data con la columna adicional = -1
		dataframe.to_csv(r'./data/production/04_predicted1.csv',index=False,sep='|')
		logging.info("FIN: SIN ERRORES")
	except Exception as e:
		logging.error("Exception occurred", exc_info=True)	
		
if os.path.exists('./data/production/04_predicted1.csv'):
	os.remove('./data/production/04_predicted1.csv')
	correr_modelo()
else:
	correr_modelo()

