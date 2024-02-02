import numpy as np
import pandas as pd
import pickle
import logging
import os

#Mostrar todas las columnas de un dataframe
pd.set_option('display.max_columns', None)

import warnings
warnings.filterwarnings('ignore')

#======================= FUNCIONES ===========================================

def correr_modelo():

    #Seleccionar ruta de la data
    dataframe = pd.read_csv('./data/production/01_raw.csv', encoding='latin',sep="|")
    with open('./logs/02_models/inference.log','w'): 
        pass
    logging.basicConfig(filename='./logs/02_models/inference.log',level=logging.DEBUG)
    try:
        #Transformaciones
        logging.info("Seleccionar las variables para el modelo y trasnformarlas")
        dataframe.rename(columns={'CODMES':'PERIODO'},inplace=True)
        dataframe['RATIO']=dataframe['MTO_INGRESO']/dataframe['MTO_ESTIMADOR']
        dataframe=dataframe.loc[dataframe['MTO_ESTIMADOR'].notnull()]
        dataset=dataframe.loc[(dataframe['PERIODO']==dataframe['PERIODO'].max())]
        #Seleccionamos las variables de nuestro interes
        dataset=dataset[['PERIODO','CODCLAVECIC','RATIO','MTO_ESTIMADOR','CTDEVAL','CTD_INGRESO','MTO_INGRESO','FLG_PERFIL_DEPOSITOS_3DS']]
        ds=dataset[['RATIO','FLG_PERFIL_DEPOSITOS_3DS','CTDEVAL','CTD_INGRESO']]
        #Cargo modelo:
        logging.info("Cargar modelo")
        loaded_model = pickle.load(open(r'./src/02_models/if_model_39.model', "rb"))
        logging.info("Aplicar el modelo cargado sobre el dataframe")
        #Aplico el modelo cargado sobre la data 
        logging.info("Aplicar el modelo cargado sobre el dataframe")
        dataset['Outlier']=loaded_model.predict(ds)
        logging.info("Exportar la data con la columna adicional")
        dataset.to_csv(r'./data/production/04_predicted.csv',index=False,sep='|')
        logging.info("FIN: SIN ERRORES")
    except Exception as e:
        logging.error("Exception occurred", exc_info=True)

#======================= MAIN ===========================================

if os.path.exists('./data/production/04_predicted.csv'):
	os.remove('./data/production/04_predicted.csv')
	correr_modelo()
else:
	correr_modelo()

