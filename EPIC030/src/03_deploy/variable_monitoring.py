# ============================ LIBRERIAS ==================================================================
import sys
import os
import logging
import pandas as pd
import numpy as np
import math
import warnings
warnings.filterwarnings('ignore')

#Agregamos path para importar funcion de PSI
sys.path.append(r".\..\SEGUIMIENTO_VARIABLES\Utiles")
from Seguimiento import stability_function,stablity_function_from_R

# ============================ LECTURA DE DATAFRAMES + VARIABLES ===========================================

df_actual = pd.read_csv(r".\data\production\01_raw.csv",encoding= "latin",sep="|")
df_desarrollo = pd.read_csv(r".\data\modeling\01_raw.csv",encoding= "latin",sep=",")

#Filtramos y aplicamos transformaciones
df_actual.rename(columns={'CODMES':'PERIODO'},inplace=True)
df_actual['RATIO']=df_actual['MTO_INGRESO']/df_actual['MTO_ESTIMADOR']
df_actual=df_actual.loc[df_actual['MTO_ESTIMADOR'].notnull()]

df_desarrollo.rename(columns={'CODMES':'PERIODO'},inplace=True)
df_desarrollo['RATIO']=df_desarrollo['MTO_INGRESO']/df_desarrollo['MTO_ESTIMADOR']
df_desarrollo=df_desarrollo.loc[df_desarrollo['MTO_ESTIMADOR'].notnull()]

# ============================ CALCULO DE ESTABILIDAD ======================================================

# Variables
columnas_numericas = ['RATIO','CTD_INGRESO','CTDEVAL']
columnas_categoricas = ['FLG_PERFIL_DEPOSITOS_3DS']
columna_periodo = 'PERIODO'
modelo = 'EPIC030'
version= '202207'

if df_actual.shape[0] != 0:
    salida, periodo = stability_function(df_desarrollo,df_actual,columnas_numericas,columnas_categoricas,columna_periodo,modelo,version)

    ruta_seg = r".\..\SEGUIMIENTO_VARIABLES\Temporal"
    nombre_file = "RESULTADOS_"+modelo+"_"+str(periodo)+".xlsx"
    salida.to_excel(os.path.join(ruta_seg, nombre_file),index=False)
