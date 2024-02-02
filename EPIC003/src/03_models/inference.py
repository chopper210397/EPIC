'''
    Creado por: Francesca Melgar
    Fecha: 04/01/23
    Descripcion: Archivo de ejecucion del modelo de la EPIC003 hecho
    con Isolation Forest
    Data Scientist: Jorge del Rio
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
            # Se realizal la transformacion de tipo de datos para las columnas
            dataframe['PERIODO'] = dataframe['PERIODO'].astype(int)
            dataframe['CODCLAVECIC'] = dataframe['CODCLAVECIC'].astype(int)
            dataframe['NBRCLIORDENANTE'] = dataframe['NBRCLIORDENANTE'].astype(str)
            dataframe['SEGMENTO'] = dataframe['SEGMENTO'].astype(str)
            dataframe['MTO_TRANSF'] = dataframe['MTO_TRANSF'].astype(float)
            dataframe['CTD_OPE'] = dataframe['CTD_OPE'].astype(int)
            dataframe['FLG_PEP'] = dataframe['FLG_PEP'].astype(int)
            dataframe['FLG_PROF'] = dataframe['FLG_PROF'].astype(int)
            dataframe['FLG_PAR'] = dataframe['FLG_PAR'].astype(int)
            dataframe['FLG_PERFIL'] = dataframe['FLG_PERFIL'].astype(int)
            dataframe['CTDEVAL'] = dataframe['CTDEVAL'].astype(int)
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
            #dataframe.rename(columns={'NUMPERIODO': 'PERIODO'}, inplace=True)
            # Creo variable FLG_ANSLBNP que es la unión de las variables FLG_AN y FLG_LSBNP
            # Inicializo la variable en cero
            dataframe['FLG_PAIS']=0
            #Creo las condicionales donde dependiendo de la  categoría de la variable inical pinto como 1
            dataframe.loc[(dataframe.FLG_PAR==0),'FLG_PAIS' ] = 0
            dataframe.loc[(dataframe.FLG_PAR==1), 'FLG_PAIS' ] = 1
            dataframe.loc[(dataframe.FLG_PAR==2) ,'FLG_PAIS' ] = 1          
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
            # Monto de ingresos entre 10000 y 500000
            dataset = dataframe.loc[(dataframe['MTO_TRANSF']>10000) & (dataframe['MTO_TRANSF']<500000)]
            dataset.to_csv(r'./data/production/02_preprocessed.csv',index=False, sep='|')
            # Selecciono solo las variables que necesita el modelo
            cols = ['MTO_TRANSF', 'CTD_OPE', 'FLG_PEP', 'FLG_PROF', 'FLG_PERFIL','CTDEVAL', 'FLG_PAIS']
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
            dataset_f = MinMaxScaler().fit_transform(dataset_f)
            with open(r'./src/03_models/KMeans1_9seg_stairs.model', "rb") as f:
                loaded_KM = pickle.load(f)
            # Aplico el modelo cargado sobre la data. Columna Outlier
            # es la que tiene el resultado del modelo
            
            dataset['N_CLUSTER']=loaded_KM.predict(dataset_f)
            dataset.to_csv(r'./data/production/04_predicted.csv',index=False, sep='|')
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

    def universe_2(self, dataframe):
        ''' Selecciona las variables de interes para el modelo '''
        logging.info("Inicio del metodo")
        try:
            # Seleccionar los cluster desde el 4 hasta el 8
            dataframe = pd.read_csv(
                r'./data/production/04_predicted.csv', encoding='unicode_escape', sep="|")
            dataseg=dataframe[dataframe['N_CLUSTER'].isin([4,5,6,7,8])]
            dataseg.shape
            dataseg.to_csv(r'./data/production/05_preprocessed.csv',index=False, sep='|')
            # Selecciono solo las variables que necesita el modelo
            cols = ['MTO_TRANSF', 'CTD_OPE', 'FLG_PEP', 'FLG_PROF', 'FLG_PERFIL','CTDEVAL', 'FLG_PAIS']
            dataset_f = dataseg.copy()
            dataset_f = dataset_f[cols]
            dataset_f.to_csv(r'./data/production/06_inputmodel.csv',index=False, sep='|')
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

    def model_2(self):
        ''' Predice en base al modelo entrenado (IForest) '''
        logging.info("Inicio del metodo")
        try:
            #Lectura del archivo preprocesado
            dataset = pd.read_csv(r'./data/production/05_preprocessed.csv',encoding='unicode_escape', sep="|")
            dataset_f = pd.read_csv(r'./data/production/06_inputmodel.csv',encoding='unicode_escape', sep="|")
            with open(r'./src/03_models/IF_EPIC003_alerta.model', "rb") as f:
                loaded_IF = pickle.load(f)
            # Aplico el modelo cargado sobre la data. Columna Outlier
            # es la que tiene el resultado del modelo
            dataset['OUTLIER']=loaded_IF.predict(dataset_f)
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
        try:
            cols = ['PERIODO','CODCLAVECIC','NBRCLIORDENANTE','SEGMENTO','MTO_TRANSF',
                    'CTD_OPE','FLG_PEP','FLG_PROF','FLG_PAR','FLG_PERFIL','CTDEVAL','FLG_PAIS',
                    'N_CLUSTER','OUTLIER']
            dataset = dataset[cols]
            dataset.to_csv(r'./data/production/07_predicted.csv', index=False, sep='|')
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
            self.universe_2(dataframe)
            dataset_output = self.model_2()
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
        logfile="EPIC003",
        datetime_excecution=now.strftime("%Y%m%d_%H%M"))
    logging.basicConfig(
        filename= f"{_model.logpath}/{_model.logfile}_{_model.datetime_excecution}.log",
        level=logging.INFO,
        filemode='w',
        format='%(asctime)s - %(lineno)s - %(levelname)s - %(funcName)s - %(message)s')
    _model.run()