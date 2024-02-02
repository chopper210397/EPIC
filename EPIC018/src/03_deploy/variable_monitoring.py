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
from Seguimiento import stability_function

# ============================ LECTURA DE DATAFRAMES + VARIABLES ===========================================
df_actual = pd.read_csv(r".\data\production\01_raw.csv",encoding= "latin",sep="|")
df_desarrollo = pd.read_csv(r".\data\modeling\01_raw.csv",encoding= "latin",sep=",")
#Filtramos y aplicamos transformaciones
df_actual.rename(columns = {'NUMPERIODO':'PERIODO'}, inplace = True)

# ============================ CALCULO DE ESTABILIDAD ======================================================
columnas_numericas = ['MTO_INGRESO', 'NUM_INGRESO', 'MTO_CTAS_RECIENTES', 'POR_CASH', 'CTD_DIAS_DEBAJOLAVA02','PORC_CASH_MESANTERIOR' ]
columnas_categoricas = ['FLG_PERFIL', 'FLG_AN_LSB_NP', 'FLG_ACT_ECO','FLG_REL_AN_LSB_NP','FLG_ACTECO_PLAFT', 'FLG_MARCASENSIBLE_PLAFT']
columna_periodo = 'PERIODO'
modelo = 'EPIC018'
version = '202208'

if df_actual.shape[0] != 0:
    salida, periodo = stability_function(df_desarrollo,df_actual,columnas_numericas,columnas_categoricas,columna_periodo,modelo,version)
    ruta_seg = r".\..\SEGUIMIENTO_VARIABLES\Temporal"
    nombre_file = "RESULTADOS_"+modelo+"_"+str(periodo)+".xlsx"
    salida.to_excel(os.path.join(ruta_seg, nombre_file),index=False)