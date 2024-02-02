'''
    Creado por: Joshua Suasnabar
    Fecha: 27/10/22
    Descripcion: Archivo de ejecucion del modelo del EPIC016 hecho
    con Isolation Forest
    Data Scientist: Jorge del Rio
'''

import logging
import os
import pickle
import sys
import warnings
from datetime import datetime

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
            # Se realizal la transformacion de tipo de datos para las columnas
            dataframe['NUMPERIODO'] = dataframe['NUMPERIODO'].astype(int)
            dataframe['FLG_AN'] = dataframe['FLG_AN'].astype(int)
            dataframe['FLG_LSB_NP'] = dataframe['FLG_LSB_NP'].astype(int)
            dataframe['MTO_INGRESOS'] = dataframe['MTO_INGRESOS'].astype(float)
            dataframe['POR_CASH'] = dataframe['POR_CASH'].astype(float)
            dataframe['FLG_PERFIL_3DESVT_TRX'] = dataframe['FLG_PERFIL_3DESVT_TRX'].astype(int)
            dataframe['TIPPER_AGRUP'] = dataframe['TIPPER_AGRUP'].astype(str)
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
        ''' Transforma las variables, escala o crea sus dummies'''
        logging.info("Inicio del metodo")
        try:
            # Cambio nombre de columna
            dataframe.rename(columns={'NUMPERIODO': 'PERIODO'}, inplace=True)
            # Creo variable FLG_ANSLBNP que es la unión de las variables FLG_AN y FLG_LSBNP
            # Inicializo la variable en cero
            dataframe['FLG_ANLSBNP'] = 0
            # Creo las condicionales donde dependiendo de la
            # categoría de la variable inical pinto como 1
            dataframe.loc[(dataframe.FLG_AN == 1) & (
                dataframe.FLG_LSB_NP == 1), 'FLG_ANLSBNP'] = 1
            dataframe.loc[(dataframe.FLG_AN == 1) & (
                dataframe.FLG_LSB_NP == 0), 'FLG_ANLSBNP'] = 1
            dataframe.loc[(dataframe.FLG_AN == 0) & (
                dataframe.FLG_LSB_NP == 1), 'FLG_ANLSBNP'] = 1
            # Creo variables dummy de los tipos de persona para luego analizarlo
            # en el perfilamiento (No es parte del modelamiento esta variable)
            data_dummies = pd.get_dummies(
                dataframe['TIPPER_AGRUP']).astype(int)
            logging.info(
                "Se realiza correctamente la transformacion de dummies")
            # Agrego las variables dummies creadas al dataframe original
            dataframe = pd.concat([dataframe, data_dummies], axis=1)
            logging.info(
                "Se realiza correctamente la concatenacion de dataframes")
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

    def universe(self, dataframe):
        ''' Selecciona las variables de interes para el modelo '''
        logging.info("Inicio del metodo")
        try:
            # Monto de ingresos mayor a 1000
            dataset = dataframe.loc[(dataframe['MTO_INGRESOS'] > 1000)]
            dataset.to_csv(r'./data/production/02_preprocessed.csv',index=False, sep='|')
            # Selecciono solo las variables que necesita el modelo
            cols = ['MTO_INGRESOS', 'POR_CASH', 'FLG_PERFIL_3DESVT_TRX', 'FLG_ANLSBNP']
            dataset_f = dataset.copy()
            dataset_f = dataset_f[cols]
            dataset_f.to_csv(r'./data/production/03_inputmodel.csv',index=False, sep='|')
        except FileNotFoundError:
            logging.warning("No existe el archivo 02_preprocessed.csv")
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

    def model(self):
        ''' Predice en base al modelo entrenado (IForest) '''
        logging.info("Inicio del metodo")
        try:
            #Lectura del archivo preprocesado
            dataset = pd.read_csv(r'./data/production/02_preprocessed.csv',encoding='unicode_escape', sep="|")
            dataset_f = pd.read_csv(r'./data/production/03_inputmodel.csv',encoding='unicode_escape', sep="|")
            with open(r'./src/03_models/IF_MEpic16.model', "rb") as f:
                loaded_model = pickle.load(f)
            # Aplico el modelo cargado sobre la data. Columna Outlier
            # es la que tiene el resultado del modelo
            dataset['OUTLIER'] = loaded_model.predict(dataset_f)
        except (IOError, OSError, pickle.PickleError, pickle.UnpicklingError):
            logging.error("El modelo no se pudo importar correctamente")
        except Exception:
            exc_type, exc_value, exc_traceback = sys.exc_info()
            logging.warning("Sucedio un error inesperado: "+
                            exc_type+" - "+exc_value+" - "+exc_traceback)
            sys.exit()
        else:
            logging.info("Finaliza correctamente")
            return dataset

    def output(self, dataset):
        ''' Guarda el output de la prediccion '''
        logging.info("Inicio del metodo")
        try:
            cols = ['CODCLAVECIC','PERIODO','TIPPER_AGRUP','MTO_INGRESOS','MTO_EGRESOS',
                    'RATIO_ING_TOT','POR_CASH','FLG_PERFIL_3DESVT_TRX','FLG_AN','FLG_LSB_NP','FLG_ANLSBNP',
                    'OUTLIER']
            dataset = dataset[cols]
            dataset.to_csv(r'./data/production/04_predicted.csv', index=False, sep='|')
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
            dataframe = self.feature_engineering(dataframe)
            self.universe(dataframe)
            dataset_output = self.model()
            self.output(dataset_output)
        except Exception:
            exc_type, exc_value, exc_traceback = sys.exc_info()
            logging.warning("Sucedio un error inesperado: "+
                            exc_type+" - "+exc_value+" - "+exc_traceback)
            sys.exit()


if __name__ == "__main__":
    now = datetime.now()
    _model = Inference(
        logpath="./logs/03_models",
        logfile="EPIC016",
        datetime_excecution=now.strftime("%Y%m%d_%H%M"))
    logging.basicConfig(
        filename= f"{_model.logpath}/{_model.logfile}_{_model.datetime_excecution}.log",
        level=logging.INFO,
        filemode='w',
        format='%(asctime)s - %(lineno)s - %(levelname)s - %(funcName)s - %(message)s')
    _model.run()
