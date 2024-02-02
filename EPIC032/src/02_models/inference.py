'''
    Creado por: Francesca Melgar
    Fecha: 26/06/23
    Descripcion: Archivo de ejecucion del modelo de la EPIC032 hecho
    con Isolation Forest
    Data Scientist: Freddy Bustamante
'''

import logging
import os
import pickle
import sys
import warnings
from datetime import datetime
from sklearn.preprocessing import MinMaxScaler

import pandas as pd

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
            return dataframe

    def data_type_validation(self, dataframe):
        ''' Valida los tipos de datos '''
        logging.info("Inicio del metodo")
        try:
            # Se realiza la transformacion de tipo de datos para las columnas
            dataframe['PERIODO'] = dataframe['PERIODO'].astype(int)
            dataframe['CODUNICOCLI_LIMPIO'] = dataframe['CODUNICOCLI_LIMPIO'].astype(str)
            dataframe['MONTO_TOTAL'] = dataframe['MONTO_TOTAL'].astype(float)
            dataframe['CTD_TRX'] = dataframe['CTD_TRX'].astype(int)
            dataframe['CTD_ORDENANTES'] = dataframe['CTD_ORDENANTES'].astype(int)
            dataframe['FLG_EXTRANJERO'] = dataframe['FLG_EXTRANJERO'].astype(int)
            dataframe['FLG_ROS'] = dataframe['FLG_ROS'].astype(int)
            dataframe['FLG_LSB_NP'] = dataframe['FLG_LSB_NP'].astype(int)
            dataframe['FLG_AN'] = dataframe['FLG_AN'].astype(int)
            dataframe['FLG_PERFIL'] = dataframe['FLG_PERFIL'].astype(int)
            dataframe['FLG_FAMILIAR_APELLIDO'] = dataframe['FLG_FAMILIAR_APELLIDO'].astype(int)
            dataframe['FLG_CLIENTE'] = dataframe['FLG_CLIENTE'].astype(int)
            dataframe['MONTO_TOTAL_SEMANAL'] = dataframe['MONTO_TOTAL_SEMANAL'].astype(float)
            dataframe['PORCENTAJE_MONTO'] = dataframe['PORCENTAJE_MONTO'].astype(float)
            dataframe['CTD_TRX_SEMANAL'] = dataframe['CTD_TRX_SEMANAL'].astype(int)
            dataframe['PORCENTAJE_CTD'] = dataframe['PORCENTAJE_CTD'].astype(float)
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
            logging.info("Creando el archivo 02_preprocessed.csv")
            with open(r'./data/production/02_preprocessed.csv', 'w+',
                      encoding='latin-1',newline="") as csv_file:
                dataframe.to_csv(path_or_buf=csv_file, sep='|', index=False)
            logging.info("Guardamos el archivo 02_preprocessed.csv")
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
            dataset = pd.read_csv(r'./data/production/02_preprocessed.csv', sep="|")
            logging.info("Filtrando el archivo 02_preprocessed.csv")
            # Identifica a los clientes para la segmentación escalon_3
            dataset = dataset.loc[(dataset['CTD_TRX']>=25) | (dataset['MONTO_TOTAL']>=20000)]
            dataset['IF_LABEL']=3
            dataset_escalon3=dataset
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
            logging.warning("FileNotFoundError: No existe el archivo 02_preprocessed.csv"
                "Error en la linea %s. Detalle: %s - %s - %s",  
                str(lines),str(exc_type),str(exc_obj),str(exc_traceback))
            sys.exit()
        except pd.errors.EmptyDataError:
            exc_type, exc_obj, exc_traceback = sys.exc_info()
            lines = exc_traceback.tb_lineno
            logging.warning("EmptyDataError: El dataframe del archivo 02_preprocessed.csv \
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
            dataset = pd.read_csv(r'./data/production/02_preprocessed.csv', sep="|")
            dataset_f=dataset[dataset['MONTO_TOTAL']>=200]
            dataset_f=dataset_f[(dataset_f['CTD_TRX']<25) & (dataset_f['MONTO_TOTAL']<20000)]
            df_2 = dataset_f[['MONTO_TOTAL', 'CTD_TRX', 'CTD_ORDENANTES', 'FLG_PERFIL']]
            dataset_f1 = MinMaxScaler().fit_transform(df_2)
            with open(r'./src/02_models/IF.model', "rb") as f:
                loaded_IF = pickle.load(f)
            # Aplico el modelo cargado sobre la data. Columna IF_LABEL
            # es la que tiene el resultado del modelo
            dataset_f['IF_LABEL']=loaded_IF.predict(dataset_f1)
            dataset_escalon2=dataset_f[dataset_f["IF_LABEL"]==-1]
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
            df_final = pd.concat([dataset_escalon2,dataset_escalon3])
            df_final.to_csv(r'./data/production/04_predicted.csv', index=False, sep='|')
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
        logfile="EPIC032",
        datetime_excecution=now.strftime("%Y%m%d_%H%M"))
    logging.basicConfig(
        filename= f"{_model.logpath}/{_model.logfile}_{_model.datetime_excecution}.log",
        level=logging.INFO,
        filemode='w',
        format='%(asctime)s - %(lineno)s - %(levelname)s - %(funcName)s - %(message)s')
    _model.run()