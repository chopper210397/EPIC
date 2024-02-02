import logging
import pandas as pd
import pickle
import os
import warnings
warnings.filterwarnings('ignore')
def correr_modelo():
	#Seleccionar ruta de la data
	dataframe = pd.read_csv('./data/production/01_raw.csv',encoding= 'latin',sep="|")
	with open('./logs/02_models/inference.log','w'):
		pass
	logging.basicConfig(filename='./logs/02_models/inference.log',level=logging.DEBUG)
	try:
		logging.info("Seleccionar las variables para el modelo")
		#Transformaciones
		dataframe.rename(columns = {'NUMPERIODO':'PERIODO'}, inplace = True)
		dataframe['PORC_CASH_MESANTERIOR']=round(dataframe['PORC_CASH_MESANTERIOR'])
		dataframe['PORC_CASH_MESANTERIOR'] = dataframe['PORC_CASH_MESANTERIOR'].astype(int)
		dataset=dataframe.loc[(dataframe['MTO_INGRESO']>50000)]
		ds=dataset[['MTO_INGRESO',
	      			'NUM_INGRESO',
					'FLG_PERFIL',
					'FLG_AN_LSB_NP',
					'FLG_ACT_ECO',
					'MTO_CTAS_RECIENTES',
					'POR_CASH',
					'CTD_DIAS_DEBAJOLAVA02',
					'PORC_CASH_MESANTERIOR',
					'FLG_REL_AN_LSB_NP',
					'FLG_ACTECO_PLAFT',
					'FLG_MARCASENSIBLE_PLAFT']]
		#Cargo modelo:
		loaded_model = pickle.load(open(r'./src/02_models/if_model_39.model', "rb"))
		logging.info("Aplicar el modelo cargado sobre el dataframe")
		dataset['Outlier']=loaded_model.predict(ds)
		logging.info("Exportar la data con la columna adicional")
		dataset.to_csv(r'./data/production/04_predicted.csv',index=False,sep='|')
		logging.info("FIN: SIN ERRORES")
	except Exception as e:
		logging.error("Exception occurred", exc_info=True)
if os.path.exists('./data/production/04_predicted.csv'):
	os.remove('./data/production/04_predicted.csv')
	correr_modelo()
else:
	correr_modelo()