'''
    Creado por: Ashly Aguilar
    Fecha: 07/12/23
    Descripcion: Archivo para seguimiento estabilidad de variables
'''
# ============================ LIBRERIAS ==================================================================

import logging
import os
import sys
import warnings
from datetime import datetime
import pandas as pd

warnings.filterwarnings('ignore')

#Agregamos path para importar funcion de PSI
print(os.getcwd())
sys.path.append(r".\..\SEGUIMIENTO_VARIABLES\Utiles")
from Seguimiento import stability_function, stablity_function_from_R

class Seguimiento:

    def __init__(self, logpath, logfile, datetime_excecution):
        ''' Inicializa la clase Seguimiento'''
        self.logpath = logpath
        self.logfile = logfile
        self.datetime_excecution = datetime_excecution

    def load_data(self):
        ''' Lee el dataframe de desarrollo del modelo y el dataframe de produccion'''
        logging.info("Inicio del metodo")
        try:
            df_actual = pd.read_csv(r"./data/production/02_preprocessed_ppjj.csv",
                                    encoding= "latin-1",sep="|")
            df_desarrollo = pd.read_csv(r"./data/modeling/02_preprocessed_ppjj.csv",
                                        encoding= "latin",sep="|")
        except FileNotFoundError:
            logging.warning("No existe el archivo 02_preprocessed_ppjj.csv")
            sys.exit()
        except pd.errors.EmptyDataError:
            logging.warning("Uno de los dataframes se encuentra vacio")
            sys.exit()
        else:
            logging.info("Finaliza correctamente")
            return df_actual,df_desarrollo

    def stability(self, df_actual,df_desarrollo):
        ''' Realiza el calculo de la estabilidad de las variables'''
        logging.info("Inicio del metodo")
        try:
            columnas_numericas = ['MTO_INGRESOS_MES', 'FLG_PERFIL_INGRESOS_3DS','MTO_CONOTROSPROXIMOS','CTD_CONOTROSPROXIMOS']
            columnas_categoricas = ['TIPPER']
            columna_periodo = 'PERIODO'
            modelo = 'EPIC024'
            version = '202312_PJ'

            if df_actual.shape[0] != 0:
                salida, periodo = stability_function(df_desarrollo,df_actual,columnas_numericas,
                                                     columnas_categoricas,columna_periodo,
                                                     modelo,version)
                return modelo,salida, periodo
        except Exception:
            exc_type, exc_obj, exc_traceback = sys.exc_info()
            lines = exc_traceback.tb_lineno
            logging.error("%s .Sucedio un error inesperado: "
                          "Detalle: %s - Linea: %s",str(exc_type),str(exc_obj),str(lines))
            sys.exit()
        else:
            logging.info("Finaliza correctamente")

    def output(self,modelo,salida, periodo):
        ''' Guardamos la estabilidad en la carpeta de SEGUIMIENTO_VARIABLES/Temporal '''
        logging.info("Inicio del metodo")
        try:
            ruta_seg = r".\..\SEGUIMIENTO_VARIABLES\Temporal"
            nombre_file = "RESULTADOS_PPJJ_"+modelo+"_"+str(periodo)+".xlsx"
            salida.to_excel(os.path.join(ruta_seg, nombre_file),index=False)
        except Exception:
            exc_type, exc_obj, exc_traceback = sys.exc_info()
            lines = exc_traceback.tb_lineno
            logging.error("%s .Sucedio un error inesperado: "
                          "Detalle: %s - Linea: %s",str(exc_type),str(exc_obj),str(lines))
            sys.exit()
        else:
            logging.info("Finaliza correctamente")

    def run(self):
        ''' Ejecuta cada uno de los pasos para el calculo de estabilidad '''
        try:
            df_actual, df_desarrollo = self.load_data()
            modelo, salida, periodo = self.stability(df_actual, df_desarrollo)
            self.output(modelo, salida, periodo)
        except Exception:
            exc_type, exc_obj, exc_traceback = sys.exc_info()
            lines = exc_traceback.tb_lineno
            logging.error("%s .Sucedio un error inesperado: "
                          "Detalle: %s - Linea: %s",str(exc_type),str(exc_obj),str(lines))
            sys.exit()

if __name__ == "__main__":
    now = datetime.now()
    _monitoring = Seguimiento(
        logpath="./logs/03_deploy",
        logfile="variable_monitoring",
        datetime_excecution=now.strftime("%Y%m%d_%H%M"))
    logging.basicConfig(
        filename= f"{_monitoring.logpath}/{_monitoring.logfile}_{_monitoring.datetime_excecution}.log",
        level=logging.INFO,
        filemode='w',
        format='%(asctime)s - %(lineno)s - %(levelname)s - %(funcName)s - %(message)s')
    _monitoring.run()
