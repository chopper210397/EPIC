# ============================ LIBRERIAS ==================================================================
import sys
import os
import pandas as pd
import numpy as np
import warnings
warnings.filterwarnings('ignore')

#Agregamos path para importar funcion de PSI
sys.path.append(r".\..\SEGUIMIENTO_VARIABLES\Utiles")
from Seguimiento import stability_function,stablity_function_from_R

# ============================ LECTURA DE DATAFRAMES + VARIABLES ===========================================
df_actual = pd.read_csv(r".\data\production\01_raw.csv",encoding= "latin",sep="|")
df_desarrollo = pd.read_csv(r".\data\modeling\01_raw.csv",encoding= "latin",sep=",")

#Filtramos y aplicamos transformaciones
df_desarrollo = df_desarrollo[pd.notnull(df_desarrollo['VARIACIO_1M_TOTAL_DEUDA'])]
df_desarrollo = df_desarrollo[df_desarrollo['RATIO_NO_TOTAL_SF_HAB']>0]
df_desarrollo.loc[df_desarrollo.VARIACIO_1M_TOTAL_DEUDA < 0, 'VARIACIO_1M_TOTAL_DEUDA'] = 0
df_desarrollo = df_desarrollo[(df_desarrollo['CODMES'] >= 201906) & (df_desarrollo['CODMES'] <= 202108)].reset_index(drop=True) # CODIGO BASE DE TRAIN

# ============================ CALCULO DE ESTABILIDAD ======================================================
# Variables
columnas_numericas = ['RATIO_NO_TOTAL_SF_HAB','VARIACIO_1M_TOTAL_DEUDA']
columnas_categoricas = []
columna_periodo = 'CODMES'
modelo = 'EPIC027'
version = '202207'

if df_actual.shape[0] != 0:
    salida, periodo = stability_function(df_desarrollo,df_actual,columnas_numericas,columnas_categoricas,columna_periodo,modelo,version)
    ruta_seg = r".\..\SEGUIMIENTO_VARIABLES\Temporal"
    nombre_file = "RESULTADOS_"+modelo+"_"+str(periodo)+".xlsx"
    salida.to_excel(os.path.join(ruta_seg, nombre_file),index=False)