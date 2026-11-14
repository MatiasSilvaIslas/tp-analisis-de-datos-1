# Diccionario de datos y fuentes

Los nombres de archivo y columnas que siguen corresponden a los CSV originales incluidos en `data/raw/`. Los campos normalizados del JSON se describen después de las fuentes.

## 1. Accesos por tecnología — provincias

**Archivo:** `Internet Accesos Tecnologias Provincias.csv`

| Columna original | Descripción utilizada |
|---|---|
| Año | Año del registro |
| Trimestre | Trimestre del registro (1 a 4) |
| Provincia | Jurisdicción |
| ADSL | Accesos informados para tecnología ADSL |
| Cablemodem | Accesos informados para cablemódem |
| Fibra Optica | Accesos informados para fibra óptica |
| Wireless | Accesos informados para tecnología inalámbrica |
| Otros | Accesos de otras tecnologías agrupadas |
| Total | Total de accesos informado para la provincia y período |

Es la fuente principal para los accesos y la composición tecnológica histórica.

## 2. Velocidad media de descarga — provincias

**Archivo:** `Internet Velocidad Media de Descarga Provincias.csv`

| Columna original | Descripción utilizada |
|---|---|
| Año | Año del registro |
| Trimestre | Trimestre del registro |
| Provincia | Jurisdicción |
| Mbps (Media de bajada) | Velocidad media de descarga informada, en Mbps |

Se utiliza para la serie de velocidad por provincia y para calcular la estimación nacional ponderada descrita en metodología.

## 3. Penetración — provincias

**Archivo:** `Internet Penetración Provincias.csv`

| Columna original | Descripción utilizada |
|---|---|
| Año | Año del registro |
| Trimestre | Trimestre del registro |
| Provincias | Jurisdicción |
| Accesos cada 100 Hogares | Indicador de accesos cada 100 hogares |
| Accesos cada 100 Habitantes | Indicador de accesos cada 100 habitantes |

El dashboard grafica la primera tasa y permite consultar la segunda en los datos procesados. La tasa no se interpreta como porcentaje de hogares únicos: es una cantidad de accesos por cada 100 hogares y puede superar 100.

## 4. Accesos por categoría de velocidad — provincias

**Archivo:** `Internet Accesos Velocidad Provincias.csv`

| Columna original | Descripción utilizada |
|---|---|
| Año | Año del registro |
| Trimestre | Trimestre del registro |
| Provincia | Jurisdicción |
| Velocidad | Etiqueta/categoría original informada por ENACOM |
| Accesos | Cantidad de accesos de esa categoría |

El archivo no contiene una descripción de los límites de las categorías ni de sus unidades. El proyecto conserva la etiqueta original y evita asignarle una interpretación no documentada.

## 5. Accesos por tecnología — localidades

**Archivo:** `Internet Accesos Tecnologias Localidades.csv`

| Columna original | Descripción utilizada |
|---|---|
| LinkIndec | Código de referencia geográfica del registro |
| Provincia | Provincia |
| Partido | Partido/departamento |
| Localidad | Localidad |
| Tecnologia | Tecnología informada |
| Accesos | Cantidad de accesos informada |

No contiene año ni trimestre. Se utiliza para sumar accesos por localidad y elaborar el ranking territorial.

## 6. Accesos por categoría de velocidad — localidades

**Archivo:** `Internet Accesos Velocidad Localidades.csv`

| Columna original | Descripción utilizada |
|---|---|
| LinkIndec | Código de referencia geográfica del registro |
| Provincia | Provincia |
| Partido | Partido/departamento |
| Localidad | Localidad |
| Velocidad | Etiqueta/categoría original informada |
| Accesos | Cantidad de accesos informada |

No contiene año ni trimestre. Se utiliza como distribución territorial transversal.

## 7. Campos principales del JSON procesado

| Campo | Significado |
|---|---|
| `year`, `quarter`, `period` | Año, trimestre y clave `AAAA-Tn` |
| `province` | Nombre provincial normalizado |
| `total_accesses` | Total de accesos |
| `tech_ADSL` | Accesos ADSL |
| `tech_Cablemodem` | Accesos Cablemodem |
| `tech_Fibra Optica` | Accesos de fibra óptica |
| `tech_Wireless` | Accesos Wireless |
| `tech_Otros` | Accesos de otras tecnologías |
| `mean_mbps` | Velocidad media provincial publicada |
| `weighted_mean_mbps_estimate` | Estimación nacional ponderada por accesos |
| `per_100_households` | Accesos cada 100 hogares |
| `per_100_people` | Accesos cada 100 habitantes |
| `speed_category` | Etiqueta original de categoría de velocidad |
| `accesses` | Accesos asociados a la categoría/localidad |

## 8. Normalización de provincias

Se unifican variantes de escritura debidas a mayúsculas, acentos y denominaciones equivalentes. En particular, `Capital Federal` se normaliza como `CABA`. Los nombres normalizados se utilizan solo como claves de integración y presentación; los CSV originales permanecen sin modificar.
