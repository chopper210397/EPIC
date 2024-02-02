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
df_cortes = pd.read_csv(r".\data\modeling\00_variables.csv",encoding= "latin",sep=",")
#Limpieza de dataframe
df_actual.loc[df_actual["EDAD"].isnull(), 'EDAD'] =  np.nanmean(df_actual["EDAD"])
# ============================ CALCULO DE ESTABILIDAD ======================================================
# Variables
columnas_numericas = ['ANTIGUEDADCLI', 'EDAD', 'MTO_TOTAL_CASH', 'MTO_TOTAL', 'CTD_TOTAL_CASH','MTO_CHQGEN','PORC_CHQGEN', 'MTO_TOTAL_CASH_ZAED', 'CTD_CASH_ZAED','CTD_DIAS_DEBAJOLAVA']
columnas_categoricas = []
columna_periodo = 'PERIODO'
modelo = 'EPIC022'
version = '202207'
if df_actual.shape[0] != 0:
    salida, periodo = stablity_function_from_R(df_cortes,df_actual,columnas_numericas,columnas_categoricas,columna_periodo,modelo,version)
    ruta_seg = r".\..\SEGUIMIENTO_VARIABLES\Temporal"
    nombre_file = "RESULTADOS_"+modelo+"_"+str(periodo)+".xlsx"
    salida.to_excel(os.path.join(ruta_seg, nombre_file),index=False)