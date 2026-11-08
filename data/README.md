# Datos incluidos

Los datos de ejemplo proceden de **PVGIS, European Commission, Joint Research Centre (JRC)**. Se distribuyen para explorar la suite y reproducir las comprobaciones, conservando los archivos originales y sus metadatos. [Atribuciones y condiciones](../docs/ATRIBUCIONES.md).

| Carpeta / archivo | Contenido | Uso |
|---|---|---|
| `productividad/PVGIS_Béjar_40.459_-5.815.csv` | Carta de 684 orientaciones; coordenadas exactas 40.459133°, −5.814857° | Precarga del laboratorio 06 y ubicación inicial |
| `productividad/PVGIS_Béjar_40.387_-5.765.mat` | Carta histórica de Béjar, punto distinto | Compatibilidad MAT/CSV y comprobaciones |
| `series_horarias/*ERA5*horario.csv` | Registros originales UTC de PVGIS-ERA5, 2005–2023 | Laboratorio 07; 166 536 registros |
| `series_horarias/*SARAH3*horario.csv` | Registros originales UTC de PVGIS-SARAH3, 2005–2023 | Comparación en 07; 166 536 registros |
| `series_horarias/referencia_python.json` | Resultados de referencia del dashboard Python original | Comparaciones numéricas de los verificadores |
| `pvgis_tmy/tmy_v53_40.459133_-5.814857.json` | Respuesta TMY de PVGIS para Béjar | Ejemplo disponible sin nueva descarga en 05 |
| `pvgis_tmy/tmy_v53_40.000000_-5.000000.json` | Respuesta TMY del punto de referencia 40° N, −5° | Verificación del modelo anual de seguimiento |

Las series horarias corresponden al punto histórico **40.387°, −5.765°**, inclinación 30°, acimut PVGIS 0°, con horizonte. No se trasladan a la ubicación común de la aplicación. La carta precargada de Productividad corresponde al punto **40.459133°, −5.814857°**.

`Gb(i)`, `Gd(i)` y `Gr(i)` son irradiancias directa, difusa y reflejada sobre el plano del CSV, en W/m². No son automáticamente DNI, DHI y GHI. La global se calcula como su suma. En diaria/mensual/anual se estima irradiación mediante suma × 1 h / 1000, en kWh/m². SARAH3 y ERA5 conservan sus minutos originales; no se interpolan ni se fuerzan coincidencias.

`T2m` es temperatura del aire a 2 m, en °C. Horaria conserva cada registro; las otras resoluciones muestran la media de los registros del intervalo. `WS10m` es la velocidad del viento a 10 m, en m/s.

La suite genera localmente cachés de mapas, husos y otras consultas TMY, y guarda la última ubicación elegida. Esos archivos y `outputs/` se excluyen de Git. Los dos ejemplos TMY de esta tabla se incluyen expresamente.

El visor 07 utiliza archivos locales; el descargador Python permanece externo en el proyecto original IRRADIANCE. No se realizan descargas PVGIS al iniciar la aplicación.
