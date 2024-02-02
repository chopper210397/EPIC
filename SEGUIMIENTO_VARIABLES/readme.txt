Autor: Luis Barrios
Fecha: 29/12/23

================= POR PRIMERA VEZ ================

1. Ejecutar indicators_tablas.sql para crear las tablas MODEL_INDICATORS, MODEL_STABILITY y DATA_QUALIY
================= CADA QUE SE EJECUTE EPICS ================

Por cada carpeta EPIC/OUT

1. Seleccionar una EPIC a correr
2. Ejecutar el indicators.py de la EPIC respectiva
3. Validar que en la ruta SEGUIMIENTO_VARIABLES/Temporal se hayan creado los archivos de seguimiento del EPIC corrido.

Finalizado la corrida de la EPIC:
- Ejecutar el indicators_to_oracle.loader (lee los csv de MODEL_INDICATORS, MODEL_STABILITY y DATA_QUALIY y los sube a Oracle )
