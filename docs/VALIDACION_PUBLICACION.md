# Validación de la publicación inicial

**Versión:** 0.7 · **Fecha:** 8 de noviembre de 2026 · **Entorno:** MATLAB R2026a, Windows.

Se verificó una copia limpia generada desde el árbol Git preparado para publicación. Esa copia no contenía el repositorio IRRADIANCE, preferencias de ubicación, cachés de mapas/husos ni los resultados anteriores de `outputs/`. La aplicación se ejecutó desde su propia carpeta y sus paquetes incluidos.

## Comprobaciones realizadas

| Comprobación | Resultado |
|---|---|
| Arranque, navegación por los siete laboratorios y Créditos, validez de 03/04/05 y limpieza del temporizador | PASS |
| Ubicación inicial de Béjar y precarga de las 684 orientaciones de su carta CSV | PASS |
| Datos horarios locales, último año disponible y temperatura T2m | PASS |
| Lectura del TMY incluido para Béjar: 8760 registros | PASS |
| Posición solar de referencia y ecuación de Kepler | PASS |
| `verificarCreditosSuite` | PASS |
| `verificarTemperaturaSeries` | PASS |
| `verificarNavegacionLeyenda(false)` | PASS |
| `verificarSeriesHorariasSuite` | PASS |
| Revisión de texto/código preparado: sin credenciales detectadas ni rutas absolutas de desarrollo en archivos MATLAB | PASS |
| Conservación de los bytes originales de los CSV horarios PVGIS | PASS |

Las comprobaciones de la copia limpia usaron los datos incluidos, sin realizar nuevas descargas PVGIS. Los enlaces externos se comprobaron por sus destinos configurados; la página de Créditos no los abre automáticamente.

## Integridad de los datos horarios

SHA-256 de los archivos originales incluidos en `data/series_horarias`:

- ERA5: `FEA30790886451846658F67A579E001ED7861E57F8CC8332C8D88024B9B3B082`.
- SARAH3: `38451336BBB2B087CAF09D4B96AE3229F66634529B9B03DCD5F737DD1215EEEF`.

`.gitattributes` conserva esos CSV sin convertir sus finales de línea. Las cabeceras, fechas UTC y metadatos permanecen en los archivos.

## Comparaciones con el proyecto original

Se comprobaron localmente la resolución configurable de las fuentes de referencia y la equivalencia numérica con IRRADIANCE para filas fijas, conjuntos E–O, diseño y estado de seguimiento e irradiación anual del seguidor con el TMY incluido. Estas comparaciones usan las fuentes originales como referencia externa, no como dependencia de ejecución de la suite.

## Reproducción de los verificadores incluidos

Desde la carpeta del proyecto, en MATLAB:

```matlab
verificarCreditosSuite
verificarTemperaturaSeries
verificarNavegacionLeyenda(false)
verificarSeriesHorariasSuite
```

Los resultados se generan en `outputs/`, excluido de Git. El README describe el resto de verificadores, los que requieren conexión y la configuración opcional `GEOSOLAR_IRRADIANCE_ROOT` para comparaciones con el código original.

Esta validación no constituye certificación de cálculo para proyectos reales ni sustituye la revisión docente o una matriz completa de compatibilidad con otras versiones de MATLAB y sistemas operativos.
