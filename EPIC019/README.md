# EPIC019 - TOP Solicitantes y Beneficiarios de ingreso cash dolares

- *Desarrollado por: Freddy Bustamante*
- *Fecha de produccion: Setiembre 2020*

---

## 1. Objetivo

Identificar solicitantes y beneficiarios TOP con ingresos cash dolares.

## 2. Documentación

- [Ficha tecnica](https://confluence.lima.bcp.com.pe/pages/viewpage.action?pageId=634222651)
- [Manual Metodologico](https://confluence.lima.bcp.com.pe/pages/viewpage.action?pageId=634221430)
- [Anexos](https://confluence.lima.bcp.com.pe/display/CUMPPRIVAD/EPIC019+-+Anexos)

## 3. Configuracion del entorno

### 3.1 Programas requisito

- [Miniconda para Python 3.9](https://repo.anaconda.com/miniconda/Miniconda3-py39_4.12.0-Windows-x86_64.exe)
- [Git para su uso con Bitbucket](https://git-scm.com/download/win)

### 3.1 Clonacion o actualizar de repositorio

1. Abrir una carpeta donde clonara el proyecto.
2. Clic derecho y abrir gitbash en la ruta deseada.
3. Clonar proyecto copiando la url del repo y remplazandola por XXXXX: `<code>`git clone XXXXX `</code>`
4. Descargar los últimos cambios de la rama de producción si ya lo tiene clonado: `<code>`git pull `</code>`

### 3.2 Configuración de carpetas

1. El proyecto debe tener la siguiente estructura, en caso no lo tenga debera de completarse las carpetas faltantes. Si desea validar la estrucura de produccion lo puede hacer [aquí](https://confluence.lima.bcp.com.pe/display/CUMPPRIVAD/Estructura+de+proyectos)

├── requeriments39.txt
├── .gitignore
├── SEGUIMIENTO_VARIABLES
└── EPIC019
    ├── data
    │   ├── modeling
    │   └── production
    ├── logs
    │   ├── 01_etl
    │   ├── 02_models
    │   └── 03_deploy
    ├── notebooks
    ├── src
    │   ├── 00_ddl
    │   ├── 01_etl
    │   ├── 02_models
    │   └── 03_deploy
    │       └── packages
    ├── run.cmd
    ├── steps.cmd
    └── README.md

### 3.3 Configuracion de ambiente virtual (solo la primera vez)

1. Abrir anaconda prompt (Miniconda3) o gitbash en la ruta del proyecto.
2. Crear ambiente virtual:
   - Activar conda: `<code>`conda activate `</code>`
   - Crear ambiente virtual: `<code>`python -m venv .venv39 `</code>`
   - Activar ambiente virtual: `<code>`source .venv39/scripts/activate `</code>`
3. Instalar librerias de dependencias:
   - Abrir archivo *requeriments39.txt* donde se encuentran las librerias usadas.
   - Inslatar las librerias del txt con el siguiente comando en el cmd:
     `<code>`pip install --trusted-host artifactory.lima.bcp.com.pe --index-url https://artifactory.lima.bcp.com.pe/artifactory/api/pypi/python-pypi/simple XXXXX `</code>`

## 4. Ejecución

### 4.1 Prerequisitos:

Crear el archivo packages_loop.sql dentro de la ruta EPIC019/src/03_deploy/packages.

Validar el acceso a las siguientes tablas. De no poder leerlas solicitar el acceso a las personas que se encuentran entre paréntesis:

- *T00985.QRY_EFECTPARTICIPE (Ashly Aguilar)*
- *T00985.EFE_DIMDEPARTAMENTO (Ashly Aguilar)*
- *T00985.EFE_DIMCLIENTE (Ashly Aguilar)*
- *S61751.SAPY_DMCASO (Antony Ortiz)*
- *S61751.SAPY_DMINVESTIGACION (Antony Ortiz)*
- *S61751.SAPY_DMEVALUACION (Antony Ortiz)*
- *S61751.SAPY_DMALERTA (Antony Ortiz)*
- *S55632.MM_DESCODPROFESION (Antony Ortiz)*

### 4.2 Corrida del modelo:

1. Ejecutar el archivo: `<code>`run.cmd `</code>`
2. Validar que el cmd acabe sin errores.

### 4.3 Validación:

1. Dado que bitbucket no permite subir ciertos archivos/carpetas entonces se deberá crear la carpeta **Data** y **Temporal** dentro de la carpeta SEGUIMIENTO_VARIABLES.
2. Dentro de la carpeta **Data** de **SEGUIMIENTO_VARIABLES** crear la carpeta **EPIC019** y dentro incluir los archivos **02_preprocessed.csv** y **04_predicted.csv** que se encuentran en la parte final de los **Anexos** en la sección **e. Data de validación**