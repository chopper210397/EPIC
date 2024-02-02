'''
    Creado por: Ashly Aguilar
    Fecha: 06/12/23
    Descripcion: Archivo de ejecucion del modelo de la EPIC024 hecho
    con Isolation Forest
    Data Scientist: Maria Mallaupoma
'''

import logging
import os
import pickle
import sys
import warnings
from datetime import datetime
from sklearn.preprocessing import MinMaxScaler
import pandas as pd
import numpy as np

warnings.filterwarnings('ignore')

class Inference:
    ''' Clase con los pasos para la ejecucion de la inferencia '''
    # parameters
    logpath = ""
    logfile = ""
    datetime_excecution = ""
    # Functions

    def __init__(self, logpath, logfile, datetime_excecution):
        ''' Inicializa la clase Model'''
        self.logpath = logpath
        self.logfile = logfile
        self.datetime_excecution = datetime_excecution

    def load_data(self):
        ''' Lee del output obtenido por el ETL'''
        logging.info("Inicio del metodo")
        try:
            dataframe = pd.read_csv(
                r'./data/production/01_raw.csv', encoding='unicode_escape', sep="|")
            dat=dataframe[(dataframe.TIPPER=='P')] #Natural
        except FileNotFoundError:
            logging.warning("No existe el archivo 01_raw.csv")
            sys.exit()
        except pd.errors.EmptyDataError:
            logging.warning("El dataframe obtenido del ETL esta vacio")
            sys.exit()
        except Exception:
            exc_type, exc_value, exc_traceback = sys.exc_info()
            logging.warning("Sucedio un error inesperado: "+
                            exc_type+" - "+exc_value+" - "+exc_traceback)
            sys.exit()
        else:
            logging.info("Finaliza correctamente")
            return dat

    def data_type_validation(self, dataframe):
        ''' Valida los tipos de datos '''
        logging.info("Inicio del metodo")
        try:
            # Se realiza la transformacion de tipo de datos para las columnas
            dataframe['PERIODO'] = dataframe['PERIODO'].astype(int)
            dataframe['CODCLAVECIC'] = dataframe['CODCLAVECIC'].astype(int)
            dataframe['EDAD'] = dataframe['EDAD'].astype(int)
            dataframe['TIPPER'] = dataframe['TIPPER'].astype(str)
            dataframe['ANTIGUEDAD'] = dataframe['ANTIGUEDAD'].astype(int)
            dataframe['CODACTECONOMICA'] = dataframe['CODACTECONOMICA'].astype(str)
            dataframe['DESACTECONOMICA'] = dataframe['DESACTECONOMICA'].astype(str)
            dataframe['FLG_ACTECO_NODEF'] = dataframe['FLG_ACTECO_NODEF'].astype(int)
            dataframe['FLGNP'] = dataframe['FLGNP'].astype(int)
            dataframe['CTDNP'] = dataframe['CTDNP'].astype(int)
            dataframe['FLGLSB'] = dataframe['FLGLSB'].astype(int)
            dataframe['CTDLSB'] = dataframe['CTDLSB'].astype(int)
            dataframe['FLGARCHIVONEGATIVO'] = dataframe['FLGARCHIVONEGATIVO'].astype(int)
            dataframe['DESTIPMOTIVONEGATIVO'] = dataframe['DESTIPMOTIVONEGATIVO'].astype(str)
            dataframe['CTD_NP_LSB'] = dataframe['CTD_NP_LSB'].astype(int)
            dataframe['CTDEVAL'] = dataframe['CTDEVAL'].astype(int)
            dataframe['CODSUBSEGMENTO'] = dataframe['CODSUBSEGMENTO'].astype(str)
            dataframe['DESSUBSEGMENTO'] = dataframe['DESSUBSEGMENTO'].astype(str)
            dataframe['CODSEGMENTO'] = dataframe['CODSEGMENTO'].astype(str)
            dataframe['DESSEGMENTO'] = dataframe['DESSEGMENTO'].astype(str)
            dataframe['TIPDIR'] = dataframe['TIPDIR'].astype(str)
            dataframe['CODUBIGEO'] = dataframe['CODUBIGEO'].astype(str)
            dataframe['CODDISTRITO'] = dataframe['CODDISTRITO'].astype(str)
            dataframe['DESCODDISTRITO'] = dataframe['DESCODDISTRITO'].astype(str)
            dataframe['CODPROVINCIA'] = dataframe['CODPROVINCIA'].astype(str)
            dataframe['DESCODPROVINCIA'] = dataframe['DESCODPROVINCIA'].astype(str)
            dataframe['CODDEPARTAMENTO'] = dataframe['CODDEPARTAMENTO'].astype(str)
            dataframe['DESCODDEPARTAMENTO'] = dataframe['DESCODDEPARTAMENTO'].astype(str)
            dataframe['CODPAISNACIONALIDAD'] = dataframe['CODPAISNACIONALIDAD'].astype(str)
            dataframe['DESCODPAISNACIONALIDAD'] = dataframe['DESCODPAISNACIONALIDAD'].astype(str)
            dataframe['FLGNACIONALIDAD'] = dataframe['FLGNACIONALIDAD'].astype(int)
            dataframe['MTO_INGRESOS_MES'] = dataframe['MTO_INGRESOS_MES'].astype(float)
            dataframe['CTD_INGRESOS_MES'] = dataframe['CTD_INGRESOS_MES'].astype(int)
            dataframe['MEDIA_INGRESOS'] = dataframe['MEDIA_INGRESOS'].astype(float)
            dataframe['DESV_INGRESOS'] = dataframe['DESV_INGRESOS'].astype(float)
            dataframe['FLG_PERFIL_INGRESOS_3DS'] = dataframe['FLG_PERFIL_INGRESOS_3DS'].astype(int)
            dataframe['MAX_CTDMTOSREDONDOS'] = dataframe['MAX_CTDMTOSREDONDOS'].astype(int)
            dataframe['SUM_MTOSREDONDOS'] = dataframe['SUM_MTOSREDONDOS'].astype(float)
            dataframe['CTDMAXIMA'] = dataframe['CTDMAXIMA'].astype(int)
            dataframe['MTO_MAXIMOSREPETIDOS'] = dataframe['MTO_MAXIMOSREPETIDOS'].astype(float)
            dataframe['MTOMAXDEMAXREPETIDOS'] = dataframe['MTOMAXDEMAXREPETIDOS'].astype(float)
            dataframe['MTO_CONOTROSPROXIMOS'] = dataframe['MTO_CONOTROSPROXIMOS'].astype(float)
            dataframe['CTD_CONOTROSPROXIMOS'] = dataframe['CTD_CONOTROSPROXIMOS'].astype(int)
        except ValueError:
            logging.error(
                "Las datos obtenidos del ETL no tienen el tipo de dato correcto")
            sys.exit()
        except Exception:
            exc_type, exc_value, exc_traceback = sys.exc_info()
            logging.warning("Sucedio un error inesperado: "+
                            exc_type+" - "+exc_value+" - "+exc_traceback)
            sys.exit()
        else:
            logging.info("Finaliza correctamente")
            return dataframe

    def feature_engineering(self, dataframe):
        ''' Transforma las variables'''
        logging.info("Inicio del metodo")
        try:
            # Creacion de un archivo pre-procesado
            logging.info("Creando el archivo 02_preprocessed_ppnn.csv")
            with open(r'./data/production/02_preprocessed_ppnn.csv', 'w+',
                      encoding='latin-1',newline="") as csv_file:
                dataframe.to_csv(path_or_buf=csv_file, sep='|', index=False)
            logging.info("Guardamos el archivo 02_preprocessed_ppnn.csv")
        except ValueError:
            logging.error(
                "La ingeneria de caracteristicas fallo en una transformacion")
            sys.exit()
        except Exception:
            exc_type, exc_value, exc_traceback = sys.exc_info()
            logging.warning("Sucedio un error inesperado: "+
                            exc_type+" - "+exc_value+" - "+exc_traceback)
            sys.exit()
        else:
            logging.info("Finaliza correctamente")
            return dataframe

    def rule_1(self):
        ''' Realiza la regla 1 '''
        logging.info("Inicio del metodo")
        try:
            #Lectura del archivo preprocesado
            dataset = pd.read_csv(r'./data/production/02_preprocessed_ppnn.csv',encoding='unicode_escape',  sep="|")
            logging.info("Filtrando el archivo 02_preprocessed_ppnn.csv")
            # Identifica a los clientes para la segmentación escalon_3
            df_test_sc3 = dataset.loc[dataset['MTO_INGRESOS_MES']>1e+6]
            df_test_sc3['N_CLUSTER']=1
            dataset_escalon3=df_test_sc3
        except KeyError:
            exc_type, exc_obj, exc_traceback = sys.exc_info()
            lines = exc_traceback.tb_lineno
            logging.error("KeyError: Hubo un accediendo a una clave"
                    "Error en la linea %s. Detalle: %s - %s - %s",
                str(lines),str(exc_type),str(exc_obj),str(exc_traceback))
            sys.exit()
        except FileNotFoundError:
            exc_type, exc_obj, exc_traceback = sys.exc_info()
            lines = exc_traceback.tb_lineno
            logging.warning("FileNotFoundError: No existe el archivo 02_preprocessed_ppjj.csv"
                "Error en la linea %s. Detalle: %s - %s - %s",
                str(lines),str(exc_type),str(exc_obj),str(exc_traceback))
            sys.exit()
        except pd.errors.EmptyDataError:
            exc_type, exc_obj, exc_traceback = sys.exc_info()
            lines = exc_traceback.tb_lineno
            logging.warning("EmptyDataError: El dataframe del archivo 02_preprocessed_ppjj.csv \
                esta vacio"
                "Error en la linea %s. Detalle: %s - %s - %s",
                str(lines),str(exc_type),str(exc_obj),str(exc_traceback))
            sys.exit()
        else:
            logging.info("Finaliza correctamente")
            return dataset_escalon3

    def rule_2(self):
        ''' Predice en base al modelo entrenado (IForest) '''
        logging.info("Inicio del metodo")
        try:
            #Lectura del archivo preprocesado
            dataset = pd.read_csv(r'./data/production/02_preprocessed_ppnn.csv',encoding='unicode_escape', sep="|")
            dataset_f=dataset[(dataset['MTO_INGRESOS_MES']>=150) & (dataset['MTO_INGRESOS_MES']<=1e+6)]
            df_2 = dataset_f[['MTO_CONOTROSPROXIMOS', 'CTD_CONOTROSPROXIMOS','FLG_PERFIL_INGRESOS_3DS']]
            with open(r'./src/02_models/iforest_model_ppnn', "rb") as f:
                loaded_IF = pickle.load(f)
            # Aplico el modelo cargado sobre la data. Columna N_CLUSTER
            # es la que tiene el resultado del modelo
            dataset_f['N_CLUSTER']=loaded_IF.predict(df_2)
            dataset_escalon2=dataset_f[dataset_f['N_CLUSTER']==-1]
        except (IOError, OSError, pickle.PickleError, pickle.UnpicklingError):
            logging.error("El modelo no se pudo importar correctamente")
        except Exception:
            exc_type, exc_value, exc_traceback = sys.exc_info()
            logging.warning("Sucedio un error inesperado: "+
                            exc_type+" - "+exc_value+" - "+exc_traceback)
            sys.exit()
        else:
            logging.info("Finaliza correctamente")
            return dataset_escalon2

    def output(self, dataset_escalon2,dataset_escalon3):
        ''' Guarda el output de la prediccion '''
        try:
            vars_export=['PERIODO','CODCLAVECIC','TIPPER','MTO_INGRESOS_MES','FLG_PERFIL_INGRESOS_3DS','MTO_CONOTROSPROXIMOS', 'CTD_CONOTROSPROXIMOS','N_CLUSTER']
            df_final = pd.concat([dataset_escalon2,dataset_escalon3])
            df_final[vars_export].to_csv(r'./data/production/04_predicted_ppnn.csv', index=False, sep='|')
        except Exception:
            exc_type, exc_value, exc_traceback = sys.exc_info()
            logging.warning("Sucedio un error inesperado: "+
                            exc_type+" - "+exc_value+" - "+exc_traceback)
            sys.exit()
        else:
            logging.info("Finaliza correctamente")

    def run(self):
        ''' Ejecuta cada uno de los pasos para la inferencia '''
        try:
            dataframe = self.load_data()
            dataframe = self.data_type_validation(dataframe)
            self.feature_engineering(dataframe)
            dataset_escalon3 = self.rule_1()
            dataset_escalon2 = self.rule_2()
            self.output(dataset_escalon3,dataset_escalon2)
        except Exception:
            exc_type, exc_value, exc_traceback = sys.exc_info()
            logging.warning("Sucedio un error inesperado: "+
                            exc_type+" - "+exc_value+" - "+exc_traceback)
            sys.exit()

if __name__ == "__main__":
    now = datetime.now()
    _model = Inference(
        logpath="./logs/02_models",
        logfile="EPIC024",
        datetime_excecution=now.strftime("%Y%m%d_%H%M"))
    logging.basicConfig(
        filename= f"{_model.logpath}/{_model.logfile}_{_model.datetime_excecution}.log",
        level=logging.INFO,
        filemode='w',
        format='%(asctime)s - %(lineno)s - %(levelname)s - %(funcName)s - %(message)s')
    _model.run()