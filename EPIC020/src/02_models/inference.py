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
	base=pd.read_csv('./data/production/01_raw.csv', sep = ",")
	# Reconfigure logging again, this time with a file.
	with open('./logs/02_models/inference.log','w'):
		pass
	logging.basicConfig(filename='./logs/02_models/inference.log',level=logging.DEBUG)
	try:
		variables_modelo=['MTO_EGRESOS', 'MTO_EXT', 'PCTJE_EXT', 'CTD_DIAS_DEBAJOLAVA02', 'FLG_PERFIL_3DESVT', 'FLG_ROS_REL', 'FLG_REL_EXTRANJ', 'FLG_AN_BEN', 'FLG_REL_PEP', 'FLG_LSB_NP_BEN']
		base2=base[["NUMPERIODO","CODCLAVECIC"]+variables_modelo]
		minmax = MinMaxScaler()
		base_scalada_step1 = minmax.fit_transform(base2[variables_modelo])
		base_scalada = pd.DataFrame(base_scalada_step1, columns=[variables_modelo])
		km = pickle.load(open(r'./src/02_models/kmeans_model_39.model', "rb"))
		base2['cluster_kmeans'] = km.predict(base_scalada)
		# centroides
		centroids=km.cluster_centers_
		# Calculate the Euclidean distance from
		# each point to each cluster center
		k_euclid = cdist(base_scalada, centroids, 'euclidean')
		dist = np.min(k_euclid,axis=1)
		base2['distance_to_center'] = dist
		base_cluster_riesgo=base2.loc[base2['cluster_kmeans'].isin([6,8,12])]
		#se seleccionan aquellos cluster con distancias mas altas, para el cluster 6 se toma primero los cluster
		#fuera de perfil(rasgo principal del cluster)
		#cluster 6
		base_cluster_6=base_cluster_riesgo[(base_cluster_riesgo['cluster_kmeans']==6) & (base_cluster_riesgo["FLG_PERFIL_3DESVT"]==1)]
		base_cluster_6=base_cluster_6[base_cluster_6['distance_to_center']>(base_cluster_6['distance_to_center'].quantile(.75))]
		#cluster 8
		base_cluster_8=base_cluster_riesgo[(base_cluster_riesgo['cluster_kmeans']==8)]
		base_cluster_8=base_cluster_8[base_cluster_8['distance_to_center']>(base_cluster_8['distance_to_center'].quantile(.9))]
		#cluster 12
		base_cluster_12=base_cluster_riesgo[(base_cluster_riesgo['cluster_kmeans']==12)]
		base_cluster_12=base_cluster_12[base_cluster_12['distance_to_center']>(base_cluster_12['distance_to_center'].quantile(.9))]
		base_cluster_riesgo=pd.concat([base_cluster_6, base_cluster_8,base_cluster_12])
		base_cluster_riesgo=base_cluster_riesgo.drop(['distance_to_center'],axis=1)
		base_cluster_riesgo.to_csv('./data/production/04_predicted.csv',index=False)
		logging.info("FIN: SIN ERRORES")

	except Exception as e:
		logging.error("Exception occurred", exc_info=True)

if os.path.exists('./data/production/04_predicted.csv'):
	os.remove('./data/production/04_predicted.csv')
	correr_modelo()
else:
	correr_modelo()