import logging
import numpy as np
import pandas as pd
import pickle
import os
import warnings
warnings.filterwarnings('ignore')

def correr_modelo():
	dataframe = pd.read_csv('./data/production/01_raw.csv',encoding='latin',sep='|')
    # Reconfigure logging again, this time with a file.
	with open('./logs/02_models/inference.log','w'):
		pass
	logging.basicConfig(filename='./logs/02_models/inference.log',level=logging.DEBUG)
	try:
		logging.info("Seleccionar las variables para el modelo")
		dataframe['TIPPER'].replace(['P','E'],[0,1],inplace=True)
		dataframe['FLGARCHIVONEGATIVO'].replace([0,1],[0,50],inplace=True)
		dataset=dataframe.loc[((dataframe['MTODOLARIZADO']>10000) & (dataframe['MTODOLARIZADO']<200000))]
		ds=dataset[['MTODOLARIZADO','PAISRIESGO_MONTO','TIPPER','FLGARCHIVONEGATIVO','CTDEVAL','CTD_BENEFICIARIO','INDICE_CONCENTRADOR','RATIO']]
		logging.info("Cargar Modelo")
		loaded_model = pickle.load(open(r'./src/02_models/if_model_39.model', "rb"))
		logging.info("Aplicar el modelo cargado sobre el dataset")
		dataset['Outlier']=loaded_model.predict(ds)
		logging.info("Exporto la data con la columna adicional")
		dataset.to_csv(r'./data/production/04_predicted.csv',index=False,sep='|')
		logging.info("FIN: SIN ERRORES")
	except Exception as e:
		logging.error("Exception occurred", exc_info=True)
if os.path.exists('./data/production/04_predicted.csv'):
	os.remove('./data/production/04_predicted.csv')
	correr_modelo()
else:
	correr_modelo()