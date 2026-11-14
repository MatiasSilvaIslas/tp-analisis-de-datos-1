# Metodología del análisis

## 1. Objetivo y alcance

El proyecto describe la evolución de la conectividad fija a Internet en Argentina entre el primer trimestre de 2014 y el cuarto trimestre de 2024. Se utilizan exclusivamente los seis CSV de ENACOM que forman parte del conjunto recibido.

Los archivos originales contienen información posterior a 2024 en algunas series. El procesamiento aplica un filtro explícito `2014 <= Año <= 2024`; por lo tanto, los registros de 2025 y 2026 no aparecen en el dashboard.

Los dos archivos del INDEC incluidos en el comprimido de origen no forman parte de este análisis.

## 2. Fuentes incorporadas

| Archivo | Nivel | Registros en el archivo recibido | Uso |
|---|---|---:|---|
| Internet Accesos Tecnologias Provincias.csv | Provincia y trimestre | 1.200 | Serie histórica de accesos y tecnologías |
| Internet Velocidad Media de Descarga Provincias.csv | Provincia y trimestre | 1.200 | Velocidad media provincial |
| Internet Penetración Provincias.csv | Provincia y trimestre | 1.200 | Accesos cada 100 hogares y habitantes |
| Internet Accesos Velocidad Provincias.csv | Provincia, trimestre y categoría | 26.614 | Distribución de accesos por categoría de velocidad |
| Internet Accesos Tecnologias Localidades.csv | Localidad y tecnología | 12.100 | Ranking territorial y tecnologías a nivel local |
| Internet Accesos Velocidad Localidades.csv | Localidad y categoría | 24.990 | Distribución local por categoría de velocidad |

Los recuentos corresponden a las filas de los CSV originales recibidos, antes de aplicar filtros.

## 3. Preparación de los datos

El script `scripts/process_data.py` realiza las siguientes operaciones:

1. Lee los seis CSV originales como texto para evitar conversiones automáticas incorrectas.
2. Interpreta los valores numéricos con convenciones locales: punto como separador de miles y coma como separador decimal cuando corresponde.
3. Normaliza los nombres de provincias: elimina diferencias de mayúsculas/minúsculas y acentos, y unifica variantes como `Capital Federal` y `CABA`.
4. Convierte año y trimestre a campos numéricos y crea una clave de período con formato `AAAA-Tn`.
5. Filtra los archivos históricos al intervalo 2014–2024.
6. Agrega accesos por tecnología y provincia para obtener totales nacionales trimestrales.
7. Une las fuentes provinciales por año, trimestre y provincia.
8. Agrupa los datos de localidad por provincia, departamento y localidad, sin asignarles una fecha que no está presente en el archivo.
9. Exporta las estructuras procesadas a `data/processed/dashboard.json`.

## 4. Indicadores y fórmulas

### Total de accesos

Para cada trimestre, se suman los valores de `Total` de las 24 jurisdicciones del archivo de accesos por tecnología.

\[
Accesos_{Argentina,t}=\sum_{p=1}^{24} Total_{p,t}
\]

El indicador de la tarjeta muestra el último período disponible dentro de los filtros seleccionados, no la suma de todos los trimestres del rango. Sumar los accesos de todos los trimestres produciría una acumulación de observaciones repetidas en el tiempo y no representaría una cantidad de conexiones únicas.

### Participación de fibra óptica

\[
ParticipaciónFibra_t=\frac{\sum_p FibraOptica_{p,t}}{\sum_p Total_{p,t}}\times100
\]

El cálculo se realiza para el mismo período y el mismo ámbito geográfico que se muestra en la tarjeta.

### Velocidad media nacional estimada

El archivo utilizado contiene una velocidad media para cada provincia, no un valor nacional único. Para ofrecer una referencia agregada, se calcula:

\[
VelocidadEstimada_t=\frac{\sum_p VelocidadMedia_{p,t}\times Accesos_{p,t}}{\sum_p Accesos_{p,t}}
\]

Es un promedio provincial ponderado por accesos. **Debe interpretarse como una estimación calculada para este proyecto, no como un indicador nacional publicado directamente por ENACOM.** Para una provincia seleccionada, se muestra el valor de velocidad media provincial publicado en el archivo.

### Penetración

Se utilizan directamente las columnas `Accesos cada 100 Hogares` y `Accesos cada 100 Habitantes` del archivo de penetración. El dashboard compara las provincias para un período y muestra el dato de hogares para la provincia seleccionada.

No se calcula un promedio aritmético de las 24 tasas provinciales para presentarlo como penetración nacional, porque ese promedio no está ponderado por la cantidad de hogares y no equivale a una tasa nacional.

### Categorías de velocidad

Se agrupan los accesos del último período disponible dentro de los filtros por el valor original de la columna `Velocidad`. El CSV no incorpora un diccionario que indique los límites o las unidades de cada categoría. Por eso las visualizaciones las denominan **categorías reportadas** y no las convierten en rangos de Mbps.

## 5. Archivos de localidades

Los archivos `Internet Accesos Tecnologias Localidades.csv` e `Internet Accesos Velocidad Localidades.csv` no contienen columnas de año ni trimestre. Por esa razón:

- Se utilizan para rankings y distribuciones territoriales.
- No se incorporan a las series históricas 2014–2024.
- No se afirma que representen el último trimestre de 2024 ni una fecha específica.
- El ranking de localidades agrega las tecnologías para cada combinación de provincia, departamento y localidad.

## 6. Controles de calidad realizados

- Los cuatro archivos históricos provinciales contienen 24 jurisdicciones para cada período disponible dentro del intervalo 2014–2024.
- Los tres archivos provinciales de accesos/penetración/velocidad media tienen 44 períodos trimestrales en el intervalo (2014-T1 a 2024-T4).
- El archivo de accesos por velocidad provincial comienza en 2017-T4 dentro del intervalo analizado; no se fuerza información para períodos anteriores.
- No se detectaron filas duplicadas exactas en los archivos originales al realizar la inspección.
- Para las 1.056 filas provincia-trimestre del archivo de tecnologías dentro de 2014–2024, la suma de ADSL, Cablemodem, Fibra Optica, Wireless y Otros coincide con `Total`.
- Los nombres de provincias con diferencias de acentos, mayúsculas y variantes se normalizan antes de unir fuentes.

## 7. Límites del análisis

- El conjunto no contiene en estos seis archivos la población ni el total de hogares por provincia que permitiría reconstruir denominadores propios; por eso se usan las tasas de penetración publicadas por ENACOM.
- La estimación nacional de velocidad depende del método de ponderación explicitado y no reemplaza una serie nacional oficial.
- Las categorías de velocidad se conservan como aparecen en el CSV; no se supone una equivalencia con rangos comerciales o tecnológicos.
- Los datos de localidades carecen de dimensión temporal.
- No se incorporaron variables del Censo/INDEC ni fuentes externas.
