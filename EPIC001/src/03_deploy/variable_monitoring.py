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
df_desarrollo['FLG_PAISRIESGO'].replace([0,1],[0,50],inplace=True)
df_desarrollo['MTO_TOTAL_OPE']=df_desarrollo['MTO_OPEPOS']+df_desarrollo['MTO_OPEATM']
df_desarrollo['CTD_TOTAL_OPE']=df_desarrollo['CTD_OPEPOS']+df_desarrollo['CTD_OPEATM']
df_actual['FLG_PAISRIESGO'].replace([0,1],[0,50],inplace=True)
df_actual['MTO_TOTAL_OPE']=df_actual['MTO_OPEPOS']+df_actual['MTO_OPEATM']
df_actual['CTD_TOTAL_OPE']=df_actual['CTD_OPEPOS']+df_actual['CTD_OPEATM']
df_desarrollo=df_desarrollo.loc[(df_desarrollo['PERIODO']<202111) & (df_desarrollo['MTO_TOTAL_OPE']>1000)].reset_index(drop=True)
df_actual=df_actual.loc[(df_actual['MTO_TOTAL_OPE']>1000)].reset_index(drop=True)

# ============================ CALCULO DE ESTABILIDAD ======================================================
# Variables
columnas_numericas = ['MTO_TOTAL_OPE','CTD_TOTAL_OPE']
columnas_categoricas = []
columna_periodo = 'PERIODO'
modelo = 'EPIC001'
version = '202207'
if df_actual.shape[0] != 0:
    salida, periodo = stability_function(df_desarrollo,df_actual,columnas_numericas,columnas_categoricas,columna_periodo,modelo,version)
    ruta_seg = r".\..\SEGUIMIENTO_VARIABLES\Temporal"
    nombre_file = "RESULTADOS_"+modelo+"_"+str(periodo)+".xlsx"
    salida.to_excel(os.path.join(ruta_seg, nombre_file),index=False)