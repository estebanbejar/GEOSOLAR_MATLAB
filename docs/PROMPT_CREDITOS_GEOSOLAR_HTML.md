# Encargo: integrar Créditos en la versión HTML de GEOSOLAR

Implementa una nueva sección «Créditos» en la versión HTML de GEOSOLAR, equivalente a la ya aprobada e integrada en la suite MATLAB. El alcance de este encargo es implementar y validar el cambio; la publicación se hará en el paso acordado con el autor.

## Proyecto y referencias

- Web: https://estebanbejar.github.io/GEOSOLAR/
- Repositorio HTML: https://github.com/estebanbejar/GEOSOLAR
- Repositorio de la suite MATLAB: https://github.com/estebanbejar/GEOSOLAR_MATLAB
- Copia publicada de este prompt: https://github.com/estebanbejar/GEOSOLAR_MATLAB/blob/main/docs/PROMPT_CREDITOS_GEOSOLAR_HTML.md
- Referencia local del texto aprobado y sus enlaces: `C:\PROJECTSIA\GEOSOLAR_MATLAB\GeosolarCredits.m`.
- La última corrección aprobada añade https://industriales.usal.es/ inmediatamente después de la referencia a la Escuela en el primer párrafo. Es imprescindible incluirla.

Localiza el checkout real del repositorio HTML y lee sus instrucciones, estado de Git y fuentes actuales. La carpeta `C:\PROJECTSIA\GEOSOLAR` puede contener un inventario inicial y no debe suponerse que sea el checkout de la aplicación publicada. Usa el proyecto que corresponda a este hilo. Respeta los cambios actuales y las correcciones posteriores a la versión histórica 0.7.0; no restaures commits antiguos para este trabajo.

## Integración en la interfaz

1. Añade «Créditos» al extremo derecho de la navegación existente. Es una página informativa, no un nuevo laboratorio numerado. La suite MATLAB tiene siete laboratorios y un octavo botón «Créditos»; adapta la ubicación a las secciones que realmente tenga HTML, sin incorporar laboratorios adicionales.
2. Título de la página: «Créditos y aviso de uso». Nombre de la aplicación: «GEOSOLAR», o la denominación web ya existente.
3. Usa los componentes, estilos, identidad institucional y mecanismos de navegación del proyecto. Mantén una lectura cómoda y enlaces accesibles en ordenador y móvil; permite desplazamiento sin cortar texto.
4. Entrar en Créditos debe detener la reproducción activa y conservar los parámetros de los laboratorios. Al volver, se recuperará su estado.
5. Los enlaces externos serán enlaces HTML normales, con apertura segura si se usa otra pestaña (`rel="noopener noreferrer"`). La página de Créditos debe ser legible sin consultar APIs ni descargar contenido externo.
6. Incluye la versión real de la aplicación HTML y su fecha de actualización. Evita copiar la versión MATLAB o mostrar la fecha de apertura como si fuera la fecha de publicación.

## Texto aprobado para incorporar

Adapta únicamente las referencias «GEOSOLAR MATLAB» al nombre de la versión web y las afirmaciones sobre dependencias/datos para que describan el uso real de HTML, según las notas del apartado siguiente. Mantén íntegros la autoría, la asignatura, el aviso docente y los enlaces.

### Finalidad docente

GEOSOLAR es una herramienta didáctica para la asignatura **Tecnología e Instalaciones Fotovoltaicas**, del **Grado en Electrónica Industrial y Automática** de la **Escuela Técnica Superior de Ingeniería Industrial de la Universidad de Salamanca**.

https://industriales.usal.es/

Su finalidad es facilitar la comprensión de la geometría solar, la irradiación y el comportamiento de las instalaciones fotovoltaicas mediante simulaciones y visualizaciones interactivas.

Los modelos incorporan simplificaciones y aproximaciones con fines docentes. Sus resultados no sustituyen el cálculo, la verificación normativa ni la evaluación técnica necesarios para proyectar una instalación real. El software se proporciona sin garantías de ausencia de errores.

### Autoría y desarrollo

Desarrollado por **Esteban Sánchez Hernández**, Catedrático de Escuela Universitaria del Área de Tecnología Electrónica, Departamento de Física Aplicada, Universidad de Salamanca.

ORCID: https://orcid.org/0000-0003-1341-8767

Programado con **Codex de OpenAI**, bajo la dirección del autor.

**Modelos:** en el desarrollo de la suite MATLAB está documentado **GPT-6.1 Sol** (`gpt-6.1-sol`). Para completar la frase de la versión HTML, contrasta los modelos efectivamente utilizados en el historial o la documentación de ese proyecto. Incluye únicamente modelos documentados; no atribuyas automáticamente a todo el desarrollo HTML el modelo de MATLAB ni un modelo que solo figure como configuración predeterminada. Si solo puedes acreditar el de la implementación de Créditos, delimita esa participación. No inventes una lista de modelos.

### Datos y servicios de PVGIS

Texto de referencia de MATLAB:

«Esta aplicación utiliza datos y resultados del **Photovoltaic Geographical Information System (PVGIS)** de la **Comisión Europea, Joint Research Centre (JRC)**.

**PVGIS © European Union, 2001–2026.**

La documentación y los resultados de PVGIS no reflejan necesariamente la posición de la Comisión Europea. El uso de sus datos no implica respaldo institucional a esta aplicación.»

Enlaces:

- Web oficial: https://joint-research-centre.ec.europa.eu/photovoltaic-geographical-information-system-pvgis_en
- Condiciones de uso y atribución: https://joint-research-centre.ec.europa.eu/photovoltaic-geographical-information-system-pvgis/general-information/usage-conditions-data-protection_en

Las condiciones oficiales piden reconocer a PVGIS, de la Comisión Europea/JRC, y enlazar a su web principal. Conserva también las atribuciones de los datos incorporados y sus metadatos.

### Otros componentes y servicios

Créditos existentes en la suite MATLAB:

- **OpenStreetMap:** cartografía © colaboradores de OpenStreetMap, disponible bajo licencia ODbL. https://www.openstreetmap.org/copyright
- **Leaflet:** biblioteca del selector de mapas, distribuida bajo licencia BSD de dos cláusulas. https://leafletjs.com/
- **Open-Meteo:** servicios de búsqueda de localidades y determinación del huso horario. Su geocodificación utiliza datos de **GeoNames**. https://open-meteo.com/en/docs/geocoding-api

### Código fuente y versiones relacionadas

- Repositorio de la versión HTML, **GEOSOLAR**: https://github.com/estebanbejar/GEOSOLAR
- Aplicación web: https://estebanbejar.github.io/GEOSOLAR/
- Suite MATLAB asociada, **GEOSOLAR_MATLAB**: https://github.com/estebanbejar/GEOSOLAR_MATLAB

La dirección del repositorio MATLAB está acordada, aunque su publicación puede estar pendiente. Mantén el enlace solicitado sin afirmar que ya está publicado si no se ha comprobado.

### Licencia

Texto aprobado de referencia:

«El código de GEOSOLAR se distribuye bajo **licencia MIT**, conservando las atribuciones y licencias de sus componentes y datos externos. Los logotipos y marcas pertenecen a sus respectivos titulares.»

Comprueba que coincide con la licencia del repositorio HTML y conserva sus avisos de copyright y los de terceros. Facilita acceso al texto de la licencia que se distribuye con la aplicación. Si ya existe `ATRIBUCIONES.md`, actualízalo de forma coherente.

## Precisión de las atribuciones en HTML

- La equivalencia buscada es de reconocimiento y contenido docente, no una afirmación de que ambas aplicaciones tienen las mismas dependencias o prestaciones.
- Comprueba qué servicios y bibliotecas usa realmente HTML. Mantén sus créditos y los de otros componentes presentes que falten en la lista.
- Si HTML no utiliza directamente PVGIS ni incorpora sus datos, reconoce su uso en la suite MATLAB asociada y enlaza al recurso, sin afirmar que HTML realiza esas consultas.
- Si Open-Meteo, Leaflet u otra dependencia solo se usa en MATLAB, identifica ese ámbito cuando corresponda, en lugar de atribuirle una función inexistente en la web.
- Conserva los derechos de las marcas y logotipos ya presentes. No añadas logotipos de terceros como sustituto de la atribución textual.

## Verificación y entrega

1. Ejecuta los controles y la generación de la distribución que establezca el proyecto. Edita las fuentes y regenera los archivos de distribución mediante su procedimiento habitual.
2. Comprueba la navegación hacia Créditos y de vuelta, la conservación del estado y la parada de la animación.
3. Verifica los textos, los destinos de los enlaces y, especialmente, nombre completo, ORCID, asignatura, titulación, Escuela, enlace institucional, autoría de Codex/modelos y atribución a PVGIS/JRC.
4. Revisa visualmente en escritorio y móvil que no haya texto cortado, enlaces inaccesibles o problemas de contraste y foco. Genera capturas de la nueva página.
5. Mantén los modelos científicos, las gráficas y las exportaciones de los laboratorios fuera del alcance de este cambio, salvo ajustes imprescindibles de navegación compartida.
6. Entrega un resumen de los cambios, las verificaciones, las capturas y cualquier atribución que haya requerido adaptación por diferencias entre MATLAB y HTML.

No es necesario volver a pedir aprobación del texto docente, la autoría o los enlaces anteriores: ya están aprobados. Resuelve las decisiones habituales de implementación y señala únicamente discrepancias reales que no puedan resolverse con las fuentes del proyecto.
