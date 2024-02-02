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
df_actual["FLG_ZAED"] = np.where(df_actual["TIPO_ZONA"] == 2, "1", "0")

# ============================ CALCULO DE ESTABILIDAD ======================================================
# Variables
columnas_numericas=['MTO_CASH_DEPO','ANTIGUEDAD','CTD_AN_NP_LSB','CTD_CASH_DEPO','CTD_CASH_RET','CTD_DIASDEPO','CTD_EVALS_PROP','CTD_TRXS_SINCTAAGENTE','CTD_TRXSFUERAHORARIO','MTO_AN_NP_LSB','MTO_CASH_RET','PROM_DEPODIARIOS']
columnas_categoricas = ['FLG_ACTECO_NODEF','FLG_PERFIL_CASH_DEPO_3DS','FLG_ZAED']
columna_periodo = 'PERIODO'
modelo = 'EPIC021'
version = '202207'

if df_actual.shape[0] != 0:
    #salida, periodo = stability_function(df_desarrollo,df_actual,columnas_numericas,columnas_categoricas,columna_periodo,modelo)
    salida, periodo = stablity_function_from_R(df_cortes,df_actual,columnas_numericas,columnas_categoricas,columna_periodo,modelo,version)

    ruta_seg = r".\..\SEGUIMIENTO_VARIABLES\Temporal"
    nombre_file = "RESULTADOS_"+modelo+"_"+str(periodo)+".xlsx"
    salida.to_excel(os.path.join(ruta_seg, nombre_file),index=False)