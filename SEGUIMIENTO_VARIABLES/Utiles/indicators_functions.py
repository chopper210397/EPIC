import os
import sys
import logging
import numpy as np
import pandas as pd
from scipy.spatial.distance import cdist
from sklearn.cluster import KMeans
from sklearn.preprocessing import MinMaxScaler
from sklearn.preprocessing import StandardScaler
from sklearn.preprocessing import scale
from sklearn.metrics import silhouette_score
from datetime import date
import pickle
import os
import warnings
import matplotlib.pyplot as plt
import math
warnings.filterwarnings('ignore')

# Función para calcular score de silueta
def score_silueta(ruta_modelo,ruta_production_predicted, base, variables_modelo, variable_periodo, variable_codigo_unico, modelo, periodo, fecha_de_carga):
    # Silhouette Score
    # ruta_modelo: Ruta donde se tiene el modelo pre entrenado
    # ruta_production_predicted: Ruta donde se guardará la data de producción
    # base: Data de producción limpia/transformada la cual servirá como base para nuestra funcion
    # variables_modelo: Variables del modelo que se usarán para replicar el modelo
    # variable_periodo: Columna que contiene las fechas/periodo,                    Ejem: (NUMPERIODO)
    # variable_codigo_unico: Columna que contiene el identificador del cliente,     Ejem: (CODCLAVECIC)
    # modelo: Modelo al cual se analiza,                                            Ejem: (EPIC020)
    # periodo: Primer dia del mes en el cual se realiza el analisis,                Ejem: (2023-12-01)
    # fecha_de_carga: Dia exacto en el cual se realiza el analisis,                 Ejem: (2023-12-04)

    #****************************************************************#
    #                          Normalizando                          #
    #****************************************************************#
    
    # Escogemos la normalización/estándarización según el modelo que estamos haciendo seguimiento
    if modelo == "EPIC020":
        # Seleccionamos las variables del modelo
        base2=base[ [variable_periodo, variable_codigo_unico] 
                    + variables_modelo]
        # Normalizamos las variables
        minmax = MinMaxScaler()
        base_scalada_step1 = minmax.fit_transform(base2[variables_modelo])
        base_scalada = pd.DataFrame(base_scalada_step1, columns=[variables_modelo])
    elif modelo == "EPIC019":
        # Seleccionamos las variables del modelo
        base2=base[variables_modelo]
        # Normalizamos las variables
        base_scalada = base2.values
        base_scalada = scale(base_scalada)
    elif modelo == "EPIC017":
        base2=base[ [variable_periodo, variable_codigo_unico] 
                    + variables_modelo]
        cuantis = base[['CTDNP', 'CTDLSB', 'CTDEVALS', 'CTD_CTAS_NUEVAS', 'MTO_TOTAL', 'MTO_CASH', 'MTO_TIB', 'MTO_DEL_TTEE', 
                        'MTO_EMP_REL_NOPDH', 'CTD_DEPO_10K', 'CTD_INGR_REL_NPLSP', 'MTO_EGRESO','MTO_AL_TTEE']]
        flags = base[['FLGARCHIVONEGATIVO', 'FLG_INGR_TER_NP_LSB', 'FLG_INGR_TER_AN', 'FLG_PERFIL_INGTOTAL_3DS', 'FLG_PERFIL_INGCASH_3DS', 
                    'FLG_PERFIL_EGR_3DS', 'FLG_PERFIL_ING_EGR_3DS', 'FLG_PERFIL_AL_DEL_TTEE_3DS', 'FLG_PERFIL_INGR_VS_ESTIM']]
        cuantis_aux = StandardScaler().fit_transform(cuantis)
        cuantis_std = pd.DataFrame(cuantis_aux, index=cuantis.index, columns=cuantis.columns)
        #Join df
        base_scalada = cuantis_std.join(flags)
    elif modelo == "EPIC016":
        base2=base[variables_modelo]
        base_scalada = base2  
    elif modelo == "EPIC014":
        base2=base[variables_modelo]
        base_scalada = StandardScaler().fit_transform(base2)
    elif modelo == "EPIC003":
        ''' Primero modelo kmeans y luego isolation forest '''
        base2=base[variables_modelo]
        base_scalada_0 = MinMaxScaler().fit_transform(base2)
        loaded_KM = pickle.load(open(r'EPIC003\src\03_models\KMeans1_9seg_stairs.model', "rb"))
        base2['N_CLUSTER']=loaded_KM.predict(base_scalada_0)
        base2=base2[base2['N_CLUSTER'].isin([4,5,6,7,8])]
        base_scalada=base2[variables_modelo]
    elif modelo == "EPIC029":
        '''La transformación y normalización se realizó en el propio script'''
        base2=base[variables_modelo]
        base_scalada = base2  
    else:
        print("Modelo no creado en indicators_functions.py, por favor corregirlo")
        sys.exit()

    # Abrimos el modelo pre-entrenado
    km = pickle.load(open(ruta_modelo, "rb"))
    base2['cluster_kmeans'] = km.predict(base_scalada)

    # Guardamos la data de produccion "scoreada"(clusters) para utilizarla más adelante
    base2.to_csv(ruta_production_predicted,index=False)
    # Cálculo del score de silueta en producción
    # en este caso se esta utilizando la base normalizada para hacer el calculo del score de silueta
    # score = silhouette_score(base2[variables_modelo], base2['cluster_kmeans'], metric='euclidean')
    score = silhouette_score(base_scalada, base2['cluster_kmeans'], metric='euclidean')

    # definiendo estado score silueta
    def score_silueta_estado(score):
        estado = []
        score = score
        if  score >= 0.5:
            estado = 'Verde'
        elif score >= 0.1:
            estado = 'Amarillo'
        elif score >= -1:
            estado = 'Rojo'
        return estado

    estado_score = score_silueta_estado(score)

    # Definiendo variables
    metrica = 'Score Silueta'
    valor = score
    estado = estado_score
    model_indicator_silueta = [modelo, periodo, fecha_de_carga, metrica, valor, estado]
    return(model_indicator_silueta)

# Funcion para calcular el psi
def psi(df_entrenamiento_scoreado, df_produccion_scoreado, columna_clusters, modelo, periodo, fecha_de_carga):
    # Population Stability Index (PSI)
    # Se busca ver el PSI sobre los clusters asignados
    # df_entrenamiento_scoreado: dataframe con data de entrenamiento que contiene los labels/clusters
    # df_produccion_scoreado: dataframe con data de produccion que contiene los labels/clusters
    # columna_clusters: nombre de la columna que contiene los clusters, debe ser la misma para entrenamiento y produccion
    # modelo: Modelo al cual se analiza,                                            Ejem: (EPIC020)
    # periodo: Primer dia del mes en el cual se realiza el analisis,                Ejem: (2023-12-01)
    # fecha_de_carga: Dia exacto en el cual se realiza el analisis,                 Ejem: (2023-12-04)

    psi = pd.DataFrame(columns= ["VARIABLE","VALOR"])

    clusters_produccion = df_produccion_scoreado[columna_clusters]
    clusters_entrenamiento = df_entrenamiento_scoreado[columna_clusters]
    
    # Creamos cortes
    percentiles_entrenamiento = clusters_entrenamiento.unique()
    cortes=sorted(percentiles_entrenamiento.tolist())

    # Contar la cantidad de valores en cada categoría
    conteo_produccion = df_produccion_scoreado.groupby(columna_clusters).size().fillna(0)
    conteo_entrenamiento = df_entrenamiento_scoreado.groupby(columna_clusters).size().fillna(0)

    # Calcular los porcentajes de cada categoría
    porcentajes_produccion = conteo_produccion.div(conteo_produccion.sum(), axis=0) 
    porcentajes_entrenamiento = conteo_entrenamiento.div(conteo_entrenamiento.sum(), axis=0) 

    # Crear y poblar tabla con los pasos para el cálculo del psi
    comparativo_train_prod = pd.DataFrame()
    comparativo_train_prod["produccion"] = porcentajes_produccion
    comparativo_train_prod["training"] = porcentajes_entrenamiento
    comparativo_train_prod["A-B"] = comparativo_train_prod["produccion"] - comparativo_train_prod["training"]
    comparativo_train_prod["ln(a/b)"] = np.log(comparativo_train_prod["produccion"]/comparativo_train_prod["training"]) 
    comparativo_train_prod["psi"] = comparativo_train_prod["A-B"] * comparativo_train_prod["ln(a/b)"]

    # Dando estructura y poblando tablas que retornará nuestra función psi()
    psi_numeric = comparativo_train_prod["psi"].sum() 
    psi = psi._append({"VARIABLE": "PSI", "VALOR":psi_numeric}, ignore_index=True)
    comparativo_train_prod = comparativo_train_prod.reset_index()

    # Definiendo estado psi
    condiciones = [
    (psi['VALOR'] <  0.1),
    (psi['VALOR'] <  0.2),
    (psi['VALOR'] >= 0.2)
    ]
    categorias = ['Verde', 'Amarillo', 'Rojo']

    # Asignando estado psi
    psi['ESTADO'] = np.select(condiciones, categorias)

    # Asignando las variables faltantes
    metrica = psi["VARIABLE"][0]
    valor   = psi['VALOR'][0]
    estado  = psi['ESTADO'][0]

    # Asignando y dando formato a psi para poder subirlo a tabla model_indicators
    psi = [modelo, periodo, fecha_de_carga, metrica, valor, estado]

    return(comparativo_train_prod, psi )

# Definimos función que calculará el CSI
def csi(df_entrenamiento, df_produccion, columnas_numericas, columnas_categoricas, columna_periodo, modelo, periodo, fecha_de_carga):
    # Characteristic Stability Index (CSI)
    # Se define como el PSI pero para cada variable individualmente
    # df_entrenamiento: data con la cual se entrenó el modelo
    # df_produccion: data de testeo o de puesta en produccion
    # columnas_numericas: columnas de nuestro modelo que son integer o float
    
    comparativo_train_prod_tabla = pd.DataFrame(columns= ["Variable","Categoria","produccion", "training", "A-B", "ln(a/b)", "psi"])
    cortes_numericas = pd.DataFrame(columns= ["Variable","Corte"])
    psi = pd.DataFrame(columns= ["Variable","CSI"])

    for i in columnas_numericas:
        # Calcular los percentiles/rangos en base al periodo entrenamiento
        percentiles_entrenamiento = df_entrenamiento[i].sort_values().drop_duplicates().quantile([0.2, 0.4, 0.6, 0.8])
        cortes=percentiles_entrenamiento.to_list()

        cortes.insert(0, -math.inf)
        cortes.append(math.inf)

        cortes_numericas=cortes_numericas._append({"Variable": i, "Corte":cortes}, ignore_index=True)
        # Aplicando cortes creados a data de producción y entrenamiento
        df_produccion['Categoria'] = pd.cut(df_produccion[i], bins=cortes) 

        df_entrenamiento['Categoria'] = pd.cut(df_entrenamiento[i], bins=cortes) 

        # Contar la cantidad de valores en cada categoría para cada periodo
        conteo_por_periodo_produccion = df_produccion.groupby([columna_periodo, 'Categoria']).size().unstack().fillna(0)
        conteo_por_periodo_entrenamiento = df_entrenamiento.groupby(['Categoria']).size().fillna(0)

        # Calcular los porcentajes de cada categoría para cada periodo
        porcentajes_por_periodo_produccion = conteo_por_periodo_produccion.div(conteo_por_periodo_produccion.sum(axis=1), axis=0) 
        porcentajes_por_periodo_entrenamiento = conteo_por_periodo_entrenamiento.div(conteo_por_periodo_entrenamiento.sum(), axis=0) 

        # Reordenar y transponer las filas según el orden de los percentiles
        porcentajes_produccion = porcentajes_por_periodo_produccion.T
        porcentajes_entrenamiento = porcentajes_por_periodo_entrenamiento.T

        # Crear y poblar tabla con los pasos para el cálculo del psi
        comparativo_train_prod = pd.DataFrame()
        comparativo_train_prod["produccion"] = porcentajes_produccion
        comparativo_train_prod["training"] = porcentajes_entrenamiento
        comparativo_train_prod["A-B"] = comparativo_train_prod["produccion"] - comparativo_train_prod["training"]
        comparativo_train_prod["ln(a/b)"] = np.log(comparativo_train_prod["produccion"]/comparativo_train_prod["training"]) 
        comparativo_train_prod["psi"] = comparativo_train_prod["A-B"] * comparativo_train_prod["ln(a/b)"]

        # Dando estructura y poblando tablas que retornará nuestra función csi()
        psi_numeric = comparativo_train_prod["psi"].sum() 
        psi = psi._append({"Variable": i, "CSI":psi_numeric}, ignore_index=True)
        comparativo_train_prod["Variable"] = i
        comparativo_train_prod = comparativo_train_prod.reset_index()
        comparativo_train_prod_tabla = comparativo_train_prod_tabla._append(comparativo_train_prod)

    # Se devuelven 3 dataframes
    # comparativo_train_prod_tabla: Tabla que almacena por variable(columna) y por categoría todos los pasos hasta llegar al psi 
    # Ejemplo: Variable                 Categoría       produccion  training    A-B     ln(a/b)  psi
    #          MTO_EGRESOS          (-inf, 6024.358]        0.27      0.21      0.06     0.27   0.02
    #          MTO_EGRESOS     (6024.358, 33800.363]        0.22      0.20      0.03     0.12   0.00

    # cortes_numericas: Tabla que contiene los cortes(limites) usados por cada variable
    # Ejemplo:   Variable                              Corte
    #           MTO_EGRESOS         [-inf, 6024.358035000006, 33800.36270600001, 1...
    #           MTO_EXT             [-inf, 9018.0, 41606.6, 148650.27, 570999.66, ...

    # psi: Tabla que contiene el valor final del csi(psi) por cada variable de la data de produccion/entrenamiento
    # Ejemplo:   Variable       CSI
    #           MTO_EGRESOS     0.04
    #           MTO_EXT         0.01

    for i in columnas_categoricas:
        # Como son variables categóricas solo hay que calcular la estabilidad en base a cada valor
        # por lo general son 0 y 1 dado que son flags
        # A diferencia de las columnas numericas que generabamos una categoría, aquí la columna es la categoría como tal
        percentiles_entrenamiento = df_entrenamiento[i].unique()
        cortes=percentiles_entrenamiento.tolist()

        # Agregamos los cortes identificados a nuestro dataframe cortes_numericas que retornaremos mas adelante
        cortes_numericas=cortes_numericas._append({"Variable": i, "Corte":cortes}, ignore_index=True)

        # Definimos categorias
        df_produccion['Categoria'] = df_produccion[i]
        df_entrenamiento['Categoria'] = df_entrenamiento[i]
        # Contar la cantidad de valores en cada categoría para cada periodo
        conteo_por_periodo_produccion = df_produccion.groupby([columna_periodo, 'Categoria']).size().unstack().fillna(0)
        conteo_por_periodo_entrenamiento = df_entrenamiento.groupby(['Categoria']).size().fillna(0)

        # Calcular los porcentajes de cada categoría para cada periodo
        porcentajes_por_periodo_produccion = conteo_por_periodo_produccion.div(conteo_por_periodo_produccion.sum(axis=1), axis=0) 
        porcentajes_por_periodo_entrenamiento = conteo_por_periodo_entrenamiento.div(conteo_por_periodo_entrenamiento.sum(), axis=0) 

        # Reordenar y transponer las filas según el orden de los percentiles
        porcentajes_produccion = porcentajes_por_periodo_produccion.T
        porcentajes_entrenamiento = porcentajes_por_periodo_entrenamiento.T

        # Crear y poblar tabla con los pasos para el cálculo del psi
        comparativo_train_prod = pd.DataFrame()
        comparativo_train_prod["produccion"] = porcentajes_produccion
        comparativo_train_prod["training"] = porcentajes_entrenamiento
        comparativo_train_prod["A-B"] = comparativo_train_prod["produccion"] - comparativo_train_prod["training"]
        comparativo_train_prod["ln(a/b)"] = np.log(comparativo_train_prod["produccion"]/comparativo_train_prod["training"]) 
        comparativo_train_prod["psi"] = comparativo_train_prod["A-B"] * comparativo_train_prod["ln(a/b)"]

        # Dando estructura y poblando tablas que retornará nuestra función csi()
        psi_numeric = comparativo_train_prod["psi"].sum() 
        psi = psi._append({"Variable": i, "CSI":psi_numeric}, ignore_index=True)
        comparativo_train_prod["Variable"] = i
        comparativo_train_prod = comparativo_train_prod.reset_index()
        comparativo_train_prod_tabla = comparativo_train_prod_tabla._append(comparativo_train_prod)

    # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
    # Esta sección esta fuera de los for, corre recién cuando se corrió todo lo de arriba
    # Definir condiciones y categorias para asignarlas
    condiciones = [
    (psi['CSI'] <  0.1),
    (psi['CSI'] <  0.2),
    (psi['CSI'] >= 0.2)
    ]
    categorias = ['Verde', 'Amarillo', 'Rojo']

    # Asignando estados
    psi['ESTADO'] = np.select(condiciones, categorias)

    # Definiendo variables
    metrica = 'CSI'

    # Preparando data a subir a model_stability
    psi["MODELO"] = modelo
    psi["PERIODO"] = periodo
    psi["FECHA_DE_CARGA"] = fecha_de_carga
    psi["METRICA"] = metrica
    psi=psi.rename(columns={"CSI": "VALOR", "Variable":"VARIABLE"})

    return(comparativo_train_prod_tabla , cortes_numericas, psi )

# Definimos la función que calculará medidas de calidad en los datos
def data_quality_function(df_produccion, variables_modelo, variable_periodo, variable_codigo_unico, modelo, periodo, fecha_de_carga, variables_a_evaluar = "modelo"):
    # Calidad de datos ETL/Modelo
    # df_produccion: data de testeo o de puesta en produccion
    # variables_modelo: Variables que se utilizan para entrenar el modelo
    # variable_periodo: Columna que contiene las fechas/periodo,                    Ejem: (NUMPERIODO)
    # variable_codigo_unico: Columna que contiene el identificador del cliente,     Ejem: (CODCLAVECIC)
    # modelo: Modelo al cual se analiza,                                            Ejem: (EPIC020)
    # periodo: Primer dia del mes en el cual se realiza el analisis,                Ejem: (2023-12-01)
    # fecha_de_carga: Dia exacto en el cual se realiza el analisis,                 Ejem: (2023-12-04)
    # variables_a_evaluar: Indica si se evaluarán todas las variables que nos brinda el ETL (opción "etl") o por defecto solo las que utiliza el modelo (opción "modelo")

    #Evaluando distintas metricas de calidad de datos y uniendo todo en data_quality
    data_quality = pd.DataFrame(columns=['MODELO','PERIODO','FECHA_DE_CARGA','METRICA','VARIABLE','VALOR'])
    if variables_a_evaluar == "modelo":
        variables = variables_modelo
        df_produccion = df_produccion[variables + [variable_periodo,variable_codigo_unico]]
    elif variables_a_evaluar == "etl":
        variables = df_produccion.columns
        df_produccion = df_produccion[variables]
    else:
        print("No seleccionaste un grupo de variables a evaluar correcto, reemplázalo por modelo o etl")

    # Evaluación nulos
    # Porcentaje de valores nulos del total de filas por variable
    metrica = "PORCENTAJE VALORES NULOS"
    nulos_por_variable = df_produccion.isnull().sum()
    nulos_por_variable_relevantes=nulos_por_variable[nulos_por_variable > 0]
    nulos_por_variable_relevantes = nulos_por_variable_relevantes.reset_index(name="nulos")
    nulos_por_variable_relevantes["MODELO"] = modelo
    nulos_por_variable_relevantes["PERIODO"] = periodo
    nulos_por_variable_relevantes["FECHA_DE_CARGA"] = fecha_de_carga
    nulos_por_variable_relevantes["METRICA"] = metrica
    nulos_por_variable_relevantes = nulos_por_variable_relevantes.rename(columns={"index":"VARIABLE","nulos":"VALOR"})
    nulos_por_variable_relevantes["VALOR"] = nulos_por_variable_relevantes["VALOR"]/len(df_produccion)*100
    # agregando a la tabla data_quality
    data_quality = data_quality._append(nulos_por_variable_relevantes)

    # Evaluación duplicados
    # Cantidad de filas duplicadas
    metrica = "FILAS DUPLICADAS"
    cantidad_duplicados=len(df_produccion[df_produccion.duplicated()])
    variable = "MODELO|PERIODO|CODIGO_UNICO"
    valor = cantidad_duplicados
    # agregando a la tabla data_quality
    data_quality.loc[len(data_quality.index)] = [modelo, periodo, fecha_de_carga, metrica, variable, valor]

    # Cantidad de observaciones/filas de la data sobre la cual se correrá el modelo
    metrica = "CANTIDAD FILAS"
    cantidad_filas = len(df_produccion)
    variable = "MODELO|PERIODO|CODIGO_UNICO"
    valor = cantidad_filas
    # agregando a la tabla data_quality
    data_quality.loc[len(data_quality.index)] = [modelo, periodo, fecha_de_carga, metrica, variable, valor]
    return data_quality