# ============================ LIBRERIAS ==================================================================
import sys
import os
import logging
import pandas as pd
import numpy as np
import warnings
warnings.filterwarnings('ignore')

#Agregamos path para importar funcion de PSI
sys.path.append(r".\..\SEGUIMIENTO_VARIABLES\Utiles")
from Seguimiento import stability_function,stablity_function_from_R

# ============================ LECTURA DE DATAFRAMES + VARIABLES ===========================================
df_actual = pd.read_csv(r".\data\production\01_raw.csv",encoding= "latin",sep="|")
df_cortes = pd.read_csv(r".\data\modeling\00_variables.csv",encoding= "latin",sep=",")
df_actual['EDAD'].fillna(value=df_actual['EDAD'].mean(), inplace=True)
df_actual['ANTIGUEDAD'].fillna(value=df_actual['ANTIGUEDAD'].mean(), inplace=True)

# ============================ CALCULO DE ESTABILIDAD ======================================================
# Variables
columnas_numericas = ['EDAD','ANTIGUEDAD','CTD_AN_NP_LSB','CTDEVAL','CTD_ORDENATES_DISTINTOS','MTO_COMPRA','MTO_VENTA','CTD_COMPRA','CTD_VENTA','MTO_ZAED','CTD_ZAED','CTD_DIAS','CTD_TRX_LIM']
columnas_categoricas = ['FLGNOCLIENTE','FLG_PERFIL_DEPOSITOS_3DS']
columna_periodo = 'PERIODO'
modelo = 'EPIC023'
version = '202207'
if df_actual.shape[0] != 0:
    salida, periodo = stablity_function_from_R(df_cortes,df_actual,columnas_numericas,columnas_categoricas,columna_periodo,modelo,version)
    ruta_seg = r".\..\SEGUIMIENTO_VARIABLES\Temporal"
    nombre_file = "RESULTADOS_"+modelo+"_"+str(periodo)+".xlsx"
    salida.to_excel(os.path.join(ruta_seg, nombre_file),index=False)