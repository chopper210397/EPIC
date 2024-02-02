# EPIC028 - ESCENARIO YAPE
- *Desarrollado por: Jorge Del Rio*
- *Producción:*
    - *Francesca Melgar*
- *Fecha de producción: 02/08/2023*


---

## 1. Objetivo
Identificar operaciones inusuales realizadas mediante Yape.

## 2. Documentación
- [Ficha tecnica](https://confluence.devsecopsbcp.com/pages/viewpage.action?pageId=645697194)
- [Manual Metodológico](https://confluence.devsecopsbcp.com/pages/viewpage.action?pageId=645697203)
- [Anexos](https://confluence.devsecopsbcp.com/display/CUMPPRIVAD/EPIC028+-+Anexos)

## 3. Configuración del entorno

### 3.1 Programas requisito
Deberá validar tener los siguientes programas para su ejecución:
- [Miniconda para Python 3.9](https://repo.anaconda.com/miniconda/Miniconda3-py39_4.12.0-Windows-x86_64.exe)
- [Git para su uso con Bitbucket](https://git-scm.com/download/win)

### 3.2 Clonación o actualización de repositorio
Proceda con la opción A o B según sea su caso: 

A. En caso sea la primera vez en trabajar con este repositorio, por favor seguir los siguientes pasos para clonar:
1. Crear una carpeta llamada GIT_CUMP en su disco C:.
2. Ingresar a la ruta anterior y dar clic derecho y clic en Abrir Gitbash Aqui.
3. Clonar proyecto copiando la url del repo y reemplazandola por [url de repositorio]: <code>git clone [url de repositorio]</code>
4. Abrir Anaconda Prompt y escribir <code>code</code> para que anaconda abra VSCode.
5. Clic en Archivos -> Abrir Folder y seleccionar el folder del repositorio clonado.
6. . Clic en Terminal -> Nuevo Terminal para abrir un terminal de Gitbash en VSCode.
7. Ubicarse en la rama que desee trabajar con <code>git checkout [nombre de rama]</code>

B. En caso ya haya trabajado con este repositorio, por favor seguir los siguientes pasos para actualizarlo:
1. Abrir Anaconda Prompt y escribir <code>code</code> para que anaconda abra VSCode.
2. Clic en Archivos -> Abrir Folder y seleccionar el folder del repositorio clonado.
3. Clic en Terminal -> Nuevo Terminal para abrir un terminal de Gitbash en VSCode.
5. Ubicarse en la rama que desee trabajar con <code>git checkout [nombre de rama]</code>
6. Descargar los últimos cambio del repositorio: <code>git pull</code>

### 3.3 Configuración de carpetas
1. El proyecto debe tener la siguiente estructura.
```bash
├── requeriments39.txt
├── .gitignore
├── SEGUIMIENTO_VARIABLES
└── EPIC028
    ├── data
    │   ├── modeling
    │   ├── production
    │   └── tmp
    ├── logs
    │   ├── 00_ddl
    │   ├── 01_etl
    │   ├── 02_models
    │   └── 03_deploy
    ├── notebooks
    ├── utils
    ├── reports
    ├── src
    │   ├── 00_ddl
    │   ├── 01_etl
    │   ├── 02_models
    │   └── 03_deploy
    │           └── packages
    ├── run.cmd
    ├── steps.cmd
    └── README.md
```

### 3.4 Creación o actualización de ambiente virtual
En caso haya realizado el paso 3.1 (A) por favor siga los siguientes pasos:

1. Clic en Terminal -> Nuevo Terminal para abrir un terminal de Gitbash en VSCode.
2. Crear ambiente virtual:
    - Activar ambiente de anaconda: <code>conda activate</code>
    - Crear ambiente virtual: <code>python -m venv .venv39</code>
3. Activar el ambiente virtual:
    - En Linux/gitbash: <code>source .venv39/scripts/activate</code>
    - En Windows: <code>.venv39\scripts\activate</code>
4. Instalar librerias de dependencias:
    - Inslatar las librerias del txt *requeriments39.txt* con el siguiente comando en el cmd:
    <code>pip install --trusted-host artifactory.lima.bcp.com.pe --index-url https://artifactory.lima.bcp.com.pe/artifactory/api/pypi/python-pypi/simple -r requeriments39.txt</code>

En caso haya realizado el paso 3.1 (B) por favor siga los siguientes pasos:
1. Activar el ambiente virtual:
    - Activar ambiente de anaconda: <code>conda activate</code>
    - Activar venv en Linux/gitbash: <code>source .venv39/scripts/activate</code>
    - Activar venv en Windows: <code>.venv39\scripts\activate</code>
4. Actualizar librerias de dependencias:
    - Inslatar las librerias del txt *requeriments39.txt* con el siguiente comando en el cmd:
    <code>pip install --trusted-host artifactory.lima.bcp.com.pe --index-url https://artifactory.lima.bcp.com.pe/artifactory/api/pypi/python-pypi/simple -r requeriments39.txt</code>

### 3.5 Configuración de archivos de ejecución
#### a. Sqlldr y sqlplus
1. Deberá tener creado los siguientes archivos en la PC donde ejecutara el escenario:
    - sqlldr.par
    - sqlplus.usr

    Los cuales tendrán las credenciales del usuario PLSQL que ejecutará las sentencias SQL. Para configurarlos revisar esta [guia](https://confluence.lima.bcp.com.pe/display/CUMPPUB/Archivos+sqlldr.par+y+sqlplus.usr).

#### b. Run y steps
1. Ubicarse en el apartado de "Archivos de ejecución" de los Anexos del punto 2.
2. Crear debajo de la ruta del escenario los siguientes archivos:
    - steps.cmd
    - run.cmd
3. Copiar y pegar el contenido de los archivos de Confluence en run.cmd y steps.cmd segun sea el caso.
4. Para el archivo <code>steps.cmd</code> deberá cambiar las rutas de los archivos sqlldr.par y sqlplus.usr por la ruta de su PC.
5. Para el archivo <code>run.cmd</code> deberá cambiar la ruta del proyecto clonado por la ruta de su PC.

#### c. Data
1. Ubicarse en el apartado de "Data" de los Anexos del punto 2.
2. Descargar los archivos y pegarlos en las rutas especificadas en confluence.

#### d. Packages
1. Deberá crear el archivo *03_deploy/packages_loop.sql* ya que este archivo no se trackea con Git.


#### e. Seguimiento de variables
1. Deberá crear la carpeta *SEGUIMIENTO_VARIABLES/Temporal* en caso no exista.

### 3.6 Pre-requisitos de accesos:
1. Otro pre-requisito.
2. El usuario PLSQL que correrá el escenario deberá validar el acceso a las siguientes tablas sandbox:
- *s70948.md_trx_yape_dac_view* (Victor Suarez Alpaca)
- *s70948.md_stock_yape_dac_view* (Victor Suarez Alpaca)
- *s61751.sapy_dmevaluacion* (Antony Ortiz)
- *s61751.sapy_origen* (Antony Ortiz)
- *s61751.sapy_dminvestigacion* (Antony Ortiz)
- *s61751.sapy_dmalerta* (Antony Ortiz)
- *s61751.sapy_empresa* (Antony Ortiz)
- *s61751.sapy_dmcaso* (Antony Ortiz)

## 4. Ejecución
Para poder continuar con este paso deberá haber culminado sin errores los pasos previos.

### 4.1 Actualización de archivo create_tables.
**IMPORTANTE**: Solo realizar este paso en caso sea la primera vez que vayas a ejecutar el escenario, sino omitir.
1. Abrir el archivo create_tables.sql.
2. Comentar con (--) toda linea que contenga una sentencia <code>drop table</code>.
3. Al terminar de ejecutar todo el escenario no olvidar quitar los comentarios.

### 4.2 Corrida del modelo:
1. Modificar los parámetros del archivo <code>steps.cmd</code> en caso se requiera un mes pasado, sino mantener los publicados en Anexa.
2. Ejecutar el archivo: <code>run.cmd</code>
3. Validar que el cmd acabe sin errores.

### 4.3 Validación:
1. Se deberá validar en los logs una correcta finalización del programa.
2. Se deberá validar que se haya escrito el seguimiento del mes ejecutado en la ruta: <code>SEGUIMIENTO_VARIABLES/Temporal/RESULTADOS_EPIC028_[FECHA].xlsx</code>