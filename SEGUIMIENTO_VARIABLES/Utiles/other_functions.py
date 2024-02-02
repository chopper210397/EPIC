#----------------------------------- DISTRIBUCIÓN POR MES --------------------------------------------------#
# Aqui falta darle estructura de función a todo el código.
def distrib_mensual():

# Vamos a calcular el psi por cada variable de nuestro modelo a fin de ver su estabilidad a través del tiempo
df_produccion = pd.read_csv(r'EPIC020\data\modeling\02_preprocessed.csv', sep="|")
df_entrenamiento = pd.read_csv(r'EPIC020\data\modeling\02_preprocessed.csv', sep="|")
columnas_numericas = ['MTO_EGRESOS','MTO_EXT','PCTJE_EXT','CTD_DIAS_DEBAJOLAVA02']
columnas_categoricas = ['FLG_PERFIL_3DESVT','FLG_ROS_REL','FLG_REL_EXTRANJ','FLG_AN_BEN','FLG_REL_PEP','FLG_LSB_NP_BEN']
columna_periodo = 'NUMPERIODO'

primer_mes = df_entrenamiento[ df_entrenamiento["NUMPERIODO"] == 201911]
meses_siguientes = df_entrenamiento[ df_entrenamiento["NUMPERIODO"] != 201911]
meses_siguientes = df_entrenamiento
# Calcular los percentiles del primer mes
percentiles_primer_mes = primer_mes['MTO_EGRESOS'].quantile([0.10004384, 0.50004384, 0.89995616])
limites_percentiles = percentiles_primer_mes.to_dict()

# Función para clasificar los valores de los meses siguientes en base a los percentiles del primer mes
def clasificar_por_percentiles(valor, percentiles):
    if valor <= 73230.6:
        return 'Percentil 1'
    elif valor <= 310096.1:
        return 'Percentil 5'
    elif valor <= 2454799.8:
        return 'Percentil 9'
    else:
        return 'Percentil 10'
    
# Aplicar la función de clasificación a los valores de los meses siguientes
meses_siguientes['Categoría'] = meses_siguientes['MTO_EGRESOS'].apply(clasificar_por_percentiles, args=(limites_percentiles,))

# Contar la cantidad de valores en cada categoría para cada periodo
conteo_por_periodo = meses_siguientes.groupby(['NUMPERIODO', 'Categoría']).size().unstack().fillna(0)

# Calcular los porcentajes de cada categoría para cada periodo
porcentajes_por_periodo = conteo_por_periodo.div(conteo_por_periodo.sum(axis=1), axis=0) * 100

# Ordenar los percentiles
orden_percentiles = [
    'Percentil 1', 'Percentil 5',
    'Percentil 9', 'Percentil 10'
]

# Reordenar y transponer las filas según el orden de los percentiles
porcentajes_ordenados = porcentajes_por_periodo.T.reindex(orden_percentiles)

data_201911_201912=porcentajes_ordenados[[201911, 201912]]
production_data = data_201911_201912[201912]
training_data = data_201911_201912[201911]
data_201911_201912["A-B"] = production_data - training_data
data_201911_201912["ln(a/b)"] = np.log(production_data/training_data) 
data_201911_201912["psi"] = data_201911_201912["A-B"] * data_201911_201912["ln(a/b)"]
data_201911_201912["psi"].sum() 