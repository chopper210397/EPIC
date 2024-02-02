'''
    Creado por: Francesca Melgar
    Fecha: 30/06/23
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

# ============================ LECTURA DE DATAFRAMES + VARIABLES ===========================================

df_actual = pd.read_csv(r"./data/production/04_predicted.csv",encoding= "latin",sep="|")
df_desarrollo = pd.read_csv(r"./data/modeling/02_preprocessed.csv",encoding= "latin",sep="|")

# ============================ CALCULO DE ESTABILIDAD ======================================================

# Variables
columnas_numericas = ['MTOTRANSACCION']
columnas_categoricas = ['PERSONA_BEN','EMPRESA_BEN','FLG_NOREL','FLG_ROS_BEN','FLG_ROS_SOL']
columna_periodo = 'PERIODO'
modelo = 'EPIC029'
version = '202207'

if df_actual.shape[0] != 0:
    salida, periodo = stability_function(df_desarrollo,df_actual,columnas_numericas,columnas_categoricas,columna_periodo,modelo,version)

    ruta_seg = r".\..\SEGUIMIENTO_VARIABLES\Temporal"
    nombre_file = "RESULTADOS_"+modelo+"_"+str(periodo)+".xlsx"
    salida.to_excel(os.path.join(ruta_seg, nombre_file),index=False)