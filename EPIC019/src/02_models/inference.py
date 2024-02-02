import numpy as np
import pandas as pd
import logging
from sklearn.preprocessing import scale
import pickle
import os
import warnings
warnings.filterwarnings('ignore')

def correr_modelo():
    dataframe = pd.read_csv('./data/production/01_raw.csv', encoding='ansi', sep="|")
    with open('./logs/02_models/inference.log','w'):
        pass
    logging.basicConfig(filename='./logs/02_models/inference.log',level=logging.DEBUG)

    try:
        logging.info("Seleccionar las variables para el modelo")
        data= dataframe[(dataframe.SOLICITANTE>50000)]
        p50=np.percentile(data["BENEFICIARIO"], 50)
        p75=np.percentile(data["BENEFICIARIO"], 75)
        p90=np.percentile(data["BENEFICIARIO"], 90)
        p99=np.percentile(data["BENEFICIARIO"], 99)
        data['BENEF_99']=np.where(data['BENEFICIARIO']>=p99,p99,data['BENEFICIARIO'])
        p50=np.percentile(data["SOLICITANTE"], 50,)
        p75=np.percentile(data["SOLICITANTE"], 75)
        p90=np.percentile(data["SOLICITANTE"], 90)
        p99=np.percentile(data["SOLICITANTE"], 99)
        data['SOLIC_99']=np.where(data['SOLICITANTE']>=p99,p99,data['SOLICITANTE'])
        data['ZONA_LIMA']=data["CATFLGZAED"].replace([1],1).replace([0],0).replace([2],0)
        data['ZONA_ZAED']=data["CATFLGZAED"].replace([1],0).replace([0],0).replace([2],1)
        data['ZONA_NOZAED']=data["CATFLGZAED"].replace([1],2).replace([2],2).replace([0],1).replace([2],0)
        data['PROF_RIESGO']=data["CATPROFESION"].replace([1],1).replace([3],0).replace([2],0)
        data['PROF_SININFO']=data["CATPROFESION"].replace([1],0).replace([3],0).replace([2],1)
        data['PROF_OTRAS']=data["CATPROFESION"].replace([1],0).replace([2],0).replace([3],1)
        data['SEGM_PEQCON']=data["CATSEGMENTO"].replace([2],0).replace([1],0).replace([3],1)
        data['SEGM_EXCNEG']=data["CATSEGMENTO"].replace([1],0).replace([3],0).replace([2],1)
        data['SEGM_ENAPRIV']=data["CATSEGMENTO"].replace([1],1).replace([2],0).replace([3],0)
        data['OTROSNAC']=data["CATNACIONAL"].replace([1],2).replace([2],2).replace([3],2).replace([0],1).replace([2],0)
        data['PERU']=data["CATNACIONAL"].replace([1],1).replace([0],0).replace([2],0).replace([3],0)
        data['SIN_NAC']=data["CATNACIONAL"].replace([0],0).replace([1],0).replace([3],0).replace([2],1)
        data['NAC_RIESGO']=data["CATNACIONAL"].replace([0],0).replace([1],0).replace([2],0).replace([3],1)
        #Seleccion de variables para el modelo
        df = data[['BENEF_99','SOLIC_99','ZONA_ZAED','ZONA_NOZAED','PROF_RIESGO','SEGM_PEQCON','NAC_RIESGO','PERU','OTROSNAC']]
        pc_toarray = df.values
        pc_toarray = scale(pc_toarray)
        km = pickle.load(open(r'.\src\02_models\kmeans_model_39.model', 'rb'))
        logging.info("Aplicar el modelo cargado sobre el dataframe")
        data['ClienteSegment'] = km.predict(pc_toarray)
        data= data[(data.ClienteSegment == 11) | (data.ClienteSegment == 10)| (data.ClienteSegment == 17) | (data.ClienteSegment == 21) | (data.ClienteSegment == 7)  ]
        logging.info("Exportar la data con la columna adicional")
        data.to_csv(r'./data/production/04_predicted.csv',index=False,sep='|')
        logging.info("FIN: SIN ERRORES")
    except Exception as e:
        logging.error("Exception occurred", exc_info=True)
if os.path.exists('./data/production/04_predicted.csv'):
	os.remove('./data/production/04_predicted.csv')
	correr_modelo()
else:
	correr_modelo()