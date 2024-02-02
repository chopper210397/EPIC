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
df_desarrollo = pd.read_csv(r".\data\modeling\00_variables.csv",encoding= "latin",sep=",")

#Filtramos solo empresas
df_desarrollo=df_desarrollo.loc[((df_desarrollo['MTODOLARIZADO']>10000) & (df_desarrollo['MTODOLARIZADO']<200000) &
                                 (df_desarrollo['PERIODO']>202102) & (df_desarrollo['PERIODO']<202108))].reset_index(drop=True)
df_actual=df_actual.loc[((df_actual['MTODOLARIZADO']>10000) & (df_actual['MTODOLARIZADO']<200000))].reset_index(drop=True)

# ============================ CALCULO DE ESTABILIDAD ======================================================
# Variables
columnas_numericas = ['MTODOLARIZADO', 'PAISRIESGO_MONTO' ,'CTDEVAL','CTD_BENEFICIARIO','INDICE_CONCENTRADOR', 'RATIO']
columnas_categoricas = ['FLGARCHIVONEGATIVO','TIPPER']
columna_periodo = 'PERIODO'
modelo = 'EPIC026'
version = '202207'

if df_actual.shape[0] != 0:
    salida, periodo = stability_function(df_desarrollo,df_actual,columnas_numericas,columnas_categoricas,columna_periodo,modelo,version)
    ruta_seg = r".\..\SEGUIMIENTO_VARIABLES\Temporal"
    nombre_file = "RESULTADOS_"+modelo+"_"+str(periodo)+".xlsx"
    salida.to_excel(os.path.join(ruta_seg, nombre_file),index=False)