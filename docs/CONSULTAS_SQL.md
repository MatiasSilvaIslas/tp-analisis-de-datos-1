# Consultas analíticas SQL

Las ocho consultas ejecutables están en
[`sql/04_analysis_queries.sql`](../sql/04_analysis_queries.sql). Se ejecutan
todas con `python scripts/run_sql_queries.py`; una consulta puntual se ejecuta,
por ejemplo, con `python scripts/run_sql_queries.py --query 6`.


## Uso desde Python / EDA

La base puede leerse directamente con la biblioteca estándar `sqlite3`; este
ejemplo devuelve una serie trimestral de accesos para pandas u otro flujo EDA:

```python
import sqlite3
import pandas as pd

with sqlite3.connect("database/conectividad.db") as connection:
    serie = pd.read_sql_query(
        """
        SELECT p.periodo, SUM(f.accesos_total) AS accesos
        FROM fact_accesos_provincia AS f
        JOIN dim_periodo AS p USING (anio, trimestre)
        GROUP BY p.anio, p.trimestre, p.periodo
        ORDER BY p.anio, p.trimestre
        """,
        connection,
    )
```

`pandas` es opcional para consultar la base; el cargador y el ejecutor SQL no lo
requieren.

## Resultados y lectura

| # | Pregunta / tablas | Conceptos SQL | Resultado obtenido e interpretación | Límite |
|---:|---|---|---|---|
| 1 | Evolución de accesos totales. `fact_accesos_provincia`, `dim_periodo` | `SUM`, `JOIN`, `GROUP BY`, `ORDER BY` | Devuelve 44 trimestres. El total pasa de 6.398.398 en 2014-T1 a 11.925.620 en 2024-T4, aproximadamente +86,4 %. | Es una cantidad observada en cada trimestre; no se suman las conexiones a lo largo del tiempo. |
| 2 | Participación de fibra. `fact_accesos_tecnologia`, `fact_accesos_provincia`, `dim_tecnologia`, `dim_periodo` | CTE, agregaciones separadas, `JOIN`, `NULLIF`, `ROUND` | Devuelve 44 filas: 2,35 % en 2014-T1 y 40,88 % en 2024-T4. Fibra y total se agregan por separado para el mismo período y jurisdicciones. | La composición depende de los accesos provinciales publicados por ENACOM. |
| 3 | Tecnologías entre 2014-T1 y 2024-T4. `fact_accesos_tecnologia`, `dim_tecnologia`, `dim_periodo` | `SUM`, `CASE`, `HAVING`, `NULLIF` | ADSL cae y cablemódem, fibra, otros y Wireless crecen. Los valores están detallados debajo. | La variación porcentual sería `NULL` si el valor inicial fuera cero. |
| 4 | Ranking provincial de penetración. `fact_penetracion_provincia`, `dim_provincia`, `dim_periodo` | `WHERE`, `JOIN`, `ORDER BY`, `LIMIT` | En 2024-T4 lideran CABA (105,26), San Luis (96,01), Tierra del Fuego (88,49), La Pampa (87,17) y Buenos Aires (86,71) accesos cada 100 hogares. | Es una tasa de accesos por hogares, no porcentaje de hogares únicos; puede superar 100. |
| 5 | Aumento provincial absoluto de fibra. `fact_accesos_tecnologia`, `dim_tecnologia`, `dim_provincia`, `dim_periodo` | CTE, `CASE`, `SUM`, `NULLIF`, orden por variación absoluta | La consulta prioriza la cantidad neta agregada entre 2014-T1 y 2024-T4; también muestra el cambio porcentual. Los valores se detallan debajo. | Las variaciones relativas pueden ser grandes cuando la base inicial es pequeña. |
| 6 | Distribución por categorías de velocidad. `fact_accesos_categoria_provincia`, `dim_categoria_velocidad`, `dim_periodo` | CTE, `SUM`, `GROUP BY`, `ORDER BY` | El último período disponible es 2024-T4, con 130 etiquetas observadas. Las etiquetas `300`, `100` y `50` reúnen 30,2778 %, 22,2052 % y 13,3365 % de la suma clasificada, respectivamente. | Se mantienen las etiquetas originales. No tienen unidad/rango documentado; el denominador es la suma de categorías, no una reinterpretación de cada etiqueta. |
| 7 | Ranking territorial de localidades. `fact_accesos_tecnologia_localidad`, `dim_localidad`, `dim_provincia` | `SUM`, `GROUP BY`, `HAVING`, `ORDER BY`, `LIMIT` | Las primeras son Ciudad Autónoma de Buenos Aires (1.631.231), Córdoba (568.595), Rosario (357.753), Mar del Plata (304.101) y La Plata (252.382) accesos registrados. | Es transversal y sin período; la dimensión consolida diferencias de mayúsculas con claves Unicode y mantiene las grafías fuente en staging. |
| 8 | Velocidad media ponderada estimada. `fact_velocidad_provincia`, `fact_accesos_provincia`, `dim_periodo` | `JOIN`, `SUM`, `GROUP BY`, `NULLIF` | Devuelve 44 períodos y pondera 24 provincias por período. La estimación es 3,6162 Mbps en 2014-T1 y 181,2190 Mbps en 2024-T4 (3,62 y 181,22 redondeados). | Es una estimación del proyecto; ENACOM no publica en estos archivos una única velocidad nacional. |

## Valores de la comparación por tecnología

| Tecnología | 2014-T1 | 2024-T4 | Variación absoluta | Variación porcentual |
|---|---:|---:|---:|---:|
| ADSL | 3.697.066 | 521.297 | -3.175.769 | -85,90 % |
| Cablemodem | 2.407.330 | 5.625.728 | 3.218.398 | 133,69 % |
| Fibra Optica | 150.323 | 4.875.163 | 4.724.840 | 3.143,13 % |
| Otros | 72.930 | 304.133 | 231.203 | 317,02 % |
| Wireless | 70.749 | 599.299 | 528.550 | 747,08 % |

## Provincias con mayor aumento absoluto de fibra

| Provincia | Inicio | Final | Variación absoluta | Variación porcentual |
|---|---:|---:|---:|---:|
| Buenos Aires | 120.960 | 2.128.800 | 2.007.840 | 1.659,92 % |
| Córdoba | 347 | 502.489 | 502.142 | 144.709,51 % |
| Santa Fe | 3.059 | 442.579 | 439.520 | 14.368,09 % |
| CABA | 17.767 | 311.545 | 293.778 | 1.653,50 % |
| Mendoza | 2.480 | 240.219 | 237.739 | 9.586,25 % |

## Diferencia entre el hecho de categorías y el total

La consulta 6 calcula participaciones dentro de la suma de categorías de
velocidad. Para 2024-T4 esa suma (11.925.620) coincide con el total del archivo
de tecnologías. En el rango compartido de 29 períodos, las sumas nacionales
difieren en 2022-T3 (categorías: 11.632.228; total: 11.091.128) y 2023-T2
(categorías: 11.633.052; total: 11.251.897). Por provincia y período, 165 de
696 filas difieren. El origen de la discrepancia no está determinado con las
fuentes disponibles. No se ajusta una fuente para hacerla coincidir con la otra;
`quality_category_total_mismatches` y `quality_category_period_mismatches`
exponen las filas y períodos afectados.
