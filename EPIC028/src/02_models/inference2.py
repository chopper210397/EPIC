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
	with open('./logs/02_models/inference2.log','w'):
		pass
	logging.basicConfig(filename='./logs/02_models/inference2.log',level=logging.DEBUG)

	try:
		dataframe['FLG_PEP_TOT']=dataframe['FLG_PEP']+dataframe['FLG_PEP_REL']
		dataframe["ACT_ECONOMICA_GRUPOSINTERES"].fillna(4, inplace = True)
		dataframe["ACT_ECONOMICA_GRUPOSINTERES"].replace([1,2,3,4],[0,1,1,1],inplace=True)
		dataframe["CATPROFESION"].fillna(4, inplace = True)
		dataframe["CATPROFESION"].replace([0,1,2,4],[1,0,1,1],inplace=True)
		dataframe["ANTIGUEDAD"][dataframe["ANTIGUEDAD"]<0] = 0
		dataframe["ANT_YAPE"].fillna(0, inplace = True)
		dataframe["ANT_YAPE"][dataframe["ANTIGUEDAD"]<0] = 0
		dataframe['MTO_EGR'].fillna(0, inplace = True)
		dataframe['CTD_EGRESO'].fillna(0, inplace = True)
		dataframe['CTD_OPE_DIST_EGR'].fillna(0, inplace = True)
		dataframe['CTD_ALERTAS_PREV'].fillna(0, inplace = True)
		dataset=dataframe.loc[(dataframe['FLG_POLICIA']==1)]
		ds=dataset[['MONTO_INGRESO','CTD_OPE_DIST_ING']]
		logging.info("Cargar modelo")
		#Cargo modelo:
		import pickle
		loaded_model = pickle.load(open(r'./src/02_models/if2_model_39.model', "rb"))
		logging.info("Aplicar el modelo cargado sobre el dataset")		
		#Aplico el modelo cargado sobre la data 
		dataset['Outlier']=loaded_model.predict(ds)
		logging.info("Exportar la data con la columna adicional")
		#Exporto la data con la columna adicional
		dataset.to_csv(r'./data/production/03_input2.csv',index=False,sep='|')
		dataset=dataset.loc[(dataset['Outlier']==-1)]
		logging.info("Exportar la data con la columna adicional")
		#Exporto la data con la columna adicional = -1
		dataset.to_csv(r'./data/production/04_predicted2.csv',index=False,sep='|')
		logging.info("FIN: SIN ERRORES")
	except Exception as e:
		logging.error("Exception occurred", exc_info=True)	

	os.path.exists	
if os.path.exists('./data/production/04_predicted2.csv'):
	os.remove('./data/production/04_predicted2.csv')
	correr_modelo()
else:
	correr_modelo()

