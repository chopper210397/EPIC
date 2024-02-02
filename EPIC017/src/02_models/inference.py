import logging
import pandas as pd
from sklearn.preprocessing import StandardScaler
import pickle
import os
import warnings
warnings.filterwarnings('ignore')

def correr_modelo():
	#Importo la data
	dataframe = pd.read_csv('./data/production/01_raw.csv',encoding='ansi',infer_datetime_format=True,sep="|")
	with open('./logs/02_models/inference.log','w'):
		pass
	logging.basicConfig(filename='./logs/02_models/inference.log',level=logging.DEBUG)
	try:
		logging.info("Cargo modelo")
		loaded_model = pickle.load(open(r'./src/02_models/kmeans_model_39.model', "rb"))
		logging.info("Selecciono las variables que utiliza el modelo")
		dataset = dataframe[['CTDNP',
							'CTDLSB',
							'CTDEVALS',
							'FLGARCHIVONEGATIVO',
							'CTD_CTAS_NUEVAS',
							'MTO_TOTAL',
							'MTO_CASH',
							'MTO_TIB',
							'MTO_DEL_TTEE',
							'MTO_EMP_REL_NOPDH',
							'FLG_INGR_TER_NP_LSB',
							'FLG_INGR_TER_AN',
							'CTD_DEPO_10K',
							'CTD_INGR_REL_NPLSP',
							'MTO_EGRESO',
							'MTO_AL_TTEE',
							'FLG_PERFIL_INGTOTAL_3DS',
							'FLG_PERFIL_INGCASH_3DS',
							'FLG_PERFIL_EGR_3DS',
							'FLG_PERFIL_ING_EGR_3DS',
							'FLG_PERFIL_AL_DEL_TTEE_3DS',
							'FLG_PERFIL_INGR_VS_ESTIM']]
		logging.info("Separo para estandarización")
		cuantis = dataset[[
						'CTDNP',
						'CTDLSB',
						'CTDEVALS',
						'CTD_CTAS_NUEVAS',
						'MTO_TOTAL',
						'MTO_CASH',
						'MTO_TIB',
						'MTO_DEL_TTEE',
						'MTO_EMP_REL_NOPDH',
						'CTD_DEPO_10K',
						'CTD_INGR_REL_NPLSP',
						'MTO_EGRESO','MTO_AL_TTEE']]
		flags = dataset[[
						'FLGARCHIVONEGATIVO',
						'FLG_INGR_TER_NP_LSB',
						'FLG_INGR_TER_AN',
						'FLG_PERFIL_INGTOTAL_3DS',
						'FLG_PERFIL_INGCASH_3DS',
						'FLG_PERFIL_EGR_3DS',
						'FLG_PERFIL_ING_EGR_3DS',
						'FLG_PERFIL_AL_DEL_TTEE_3DS',
						'FLG_PERFIL_INGR_VS_ESTIM']]
		cuantis.head()
		logging.info("Estandarizo la data")
		cuantis_aux = StandardScaler().fit_transform(cuantis)
		cuantis_std = pd.DataFrame(cuantis_aux, index=cuantis.index, columns=cuantis.columns)
		#Join df
		data_cluster = cuantis_std.join(flags)
		logging.info("Cargo el modelo y lo aplico sobre la data")
		data_cluster.to_csv("./data/production/02_preprocessed.csv", sep="|", index = False)
		dataframe['N_Cluster']=loaded_model.predict(data_cluster)
		logging.info("Exporto la data con la columna adicional")
		dataframe_salida = dataframe[['PERIODO',
									'CODCLAVECIC',
									'CTDNP',
									'CTDLSB',
									'CTDEVALS',
									'FLGARCHIVONEGATIVO',
									'CTD_CTAS_NUEVAS',
									'MTO_TOTAL',
									'MTO_CASH',
									'MTO_TIB',
									'MTO_DEL_TTEE',
									'MTO_EMP_REL_NOPDH',
									'FLG_INGR_TER_NP_LSB',
									'FLG_INGR_TER_AN',
									'CTD_DEPO_10K',
									'CTD_INGR_REL_NPLSP',
									'MTO_EGRESO',
									'MTO_AL_TTEE',
									'FLG_PERFIL_INGTOTAL_3DS',
									'FLG_PERFIL_INGCASH_3DS',
									'FLG_PERFIL_EGR_3DS',
									'FLG_PERFIL_ING_EGR_3DS',
									'FLG_PERFIL_AL_DEL_TTEE_3DS',
									'FLG_PERFIL_INGR_VS_ESTIM',
									'N_Cluster']]
		dataframe_salida.to_csv(r'./data/production/04_predicted.csv',index=False,sep='|')
		logging.info("FIN: SIN ERRORES")
	except Exception as e:
		logging.error("Exception occurred", exc_info=True)
if os.path.exists('./data/production/04_predicted.csv'):
	os.remove('./data/production/04_predicted.csv')
	correr_modelo()
else:
	correr_modelo()