# EPIC016 - Alertas de Conocimiento de Mercado
- *Desarrollado por: Jorge del Rio*
- *Produccion:*
    - *Joshua Suasnabar*
    - *Francesca Melgar*
- *Fecha de produccion: 15/11/22*

---

## 1. Objetivo
El presente escenario busca identificar casos de lavado de activos a partir de una clasificación de clientes denominada de “Alto riesgo”. Este se obtiene a partir de los resultados del Score de Riesgo Cliente PLAFT, donde a todos los clientes con un valor por encima del 0.81 se les considera dentro de la categoría "Riesgo Alto".

## 2. Documentación
- [Ficha tecnica](https://confluence.lima.bcp.com.pe/pages/viewpage.action?pageId=624661989)
- [Manual Metodologico](https://confluence.lima.bcp.com.pe/pages/viewpage.action?pageId=622781222)
- [Anexos](https://confluence.lima.bcp.com.pe/display/CUMPPRIVAD/EPIC016+-+Anexos)

## 3. Configuracion del entorno

### 3.1 Programas requisito
- [Miniconda para Python 3.9](https://repo.anaconda.com/miniconda/Miniconda3-py39_4.12.0-Windows-x86_64.exe)
- [Git para su uso con Bitbucket](https://git-scm.com/download/win)

### 3.1 Clonacion o actualizar de repositorio
1. Abrir una carpeta donde clonara el proyecto.
2. Clic derecho y abrir gitbash en la ruta deseada.
3. Clonar proyecto copiando la url del repo y remplazandola por XXXXX: <code>git clone XXXXX</code>
4. Descargar los últimos cambios de la rama de producción si ya lo tiene clonado: <code>git pull</code>

### 3.2 Configuración de carpetas
1. El proyecto debe tener la siguiente estructura, en caso no lo tenga debera de completarse las carpetas faltantes. Si desea validar la estrucura de produccion lo puede hacer [aquí](https://confluence.lima.bcp.com.pe/display/CUMPPRIVAD/Estructura+de+proyectos)
```bash
├── requeriments.txt
├── .gitignore
├── SEGUIMIENTO_VARIABLES
└── EPICXXX
    ├── data
    │   ├── modeling
    │   ├── production
    │   └── tmp
    ├── logs
    │   ├── 01_etl
    │   ├── 02_test
    │   ├── 03_models
    │   └── 04_deploy
    ├── notebooks
    ├── reports
    │   ├── figures
    │   └── others
    ├── utils
    ├── src
    │   ├── 01_etl
    │   │   └── train
    │   ├── 02_test
    │   ├── 03_models
    │   └── 04_deploy
    │       ├── loaders
    │       └── packages
    ├── run.cmd
    ├── steps.cmd
    └── README.md
```

### 3.3 Configuracion de ambiente virtual (solo la primera vez)
1. Abrir anaconda prompt (Miniconda3) o gitbash en la ruta del proyecto.
2. Crear ambiente virtual:
    - Activar conda: <code>conda activate</code>
    - Crear ambiente virtual: <code>python -m venv .venv39</code>
    - Activar ambiente virtual: <code>source .venv39/scripts/activate</code>
3. Instalar librerias de dependencias:
    - Abrir archivo *requeriments39.txt* donde se encuentran las librerias usadas.
    - Inslatar las librerias del txt con el siguiente comando en el cmd:
    <code>pip install --trusted-host artifactory.lima.bcp.com.pe --index-url https://artifactory.lima.bcp.com.pe/artifactory/api/pypi/python-pypi/simple XXXXX</code>

## 4. Ejecución
### 4.1 Prerequisitos:
Validar las siguientes tablas:

- *S85645.SCORECLIENTECUMP* (el periodo del score de las personas debe concidir con la del mes a ejecutar)
- *S55632.MD_CODIGOPAIS*
- *T23377.TMP_MOVAGENTE_I*
- *T23377.TMP_MOVAGENTE_P*
- *T23377.TMP_MOVBCAMOVIL_I*
- *T23377.TMP_MOVBCAMOVIL_P*
- *S85645.SAPY_DMALERTA*
- *S85645.QRY_EFECTPARTICIPE*

### 4.2 Corrida del modelo:
1. Ejecutar el archivo: <code>run.cmd</code>
3. Validar que el cmd acabe sin errores.

### 4.3 Validación:
1. Dado que bitbucket no permite subir ciertos archivos/carpetas entonces se deberá crear la carpeta **Data** y **Temporal** dentro de la carpeta SEGUIMIENTO_VARIABLES.
2. Dentro de la carpeta **Data** de **SEGUIMIENTO_VARIABLES** crear la carpeta **EPIC016** y dentro incluir los archivos **02_preprocessed.csv** y **04_predicted.csv** que se encuentran en la parte final de los **Anexos** en la sección **e. Data de validación**