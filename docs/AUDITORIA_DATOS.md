# Auditoría de datos para SQLite

La auditoría se realizó sobre la base de `main` en `8d8f83c` y los seis CSV
originales de `data/raw/`, sin modificarlos. Los seis CSV normalizados se
generan de manera reproducible en `data/modified/`; `data/raw/` permanece como
única copia maestra. Se contrastaron también
`data/processed/dashboard.json`, `scripts/process_data.py` y la documentación
existente.

## Inventario de fuentes

Los CSV almacenan todos los campos como texto. Año, trimestre, accesos y medidas
son valores numéricos representados como texto; provincia, localidad, tecnología
y velocidad categórica son etiquetas. Las columnas `*_raw` de staging mantienen
el texto decodificado y las columnas `*_valor` guardan una conversión tipada.

| Archivo | Filas originales | Granularidad / clave candidata | Período / alcance |
|---|---:|---|---|
| `Internet Accesos Tecnologias Provincias.csv` | 1.200 | Año + trimestre + provincia | 44 períodos, 2014-T1 a 2024-T4; 24 jurisdicciones por período; 1.056 filas en alcance |
| `Internet Velocidad Media de Descarga Provincias.csv` | 1.200 | Año + trimestre + provincia | 44 períodos; 24 jurisdicciones; 1.056 filas en alcance |
| `Internet Penetración Provincias.csv` | 1.200 | Año + trimestre + provincia | 44 períodos; 24 jurisdicciones; 1.056 filas en alcance |
| `Internet Accesos Velocidad Provincias.csv` | 26.614 | Año + trimestre + provincia + etiqueta original `Velocidad` | 29 períodos, 2017-T4 a 2024-T4; 24 jurisdicciones; 20.737 filas en alcance |
| `Internet Accesos Tecnologias Localidades.csv` | 12.100 | Provincia + partido + localidad + tecnología normalizada | Corte territorial sin período; no se fuerza una fecha |
| `Internet Accesos Velocidad Localidades.csv` | 24.990 | Provincia + partido + localidad + etiqueta original `Velocidad` | Corte territorial sin período; no se fuerza una fecha |

Las claves candidatas provinciales no presentan duplicados en los registros de
origen. En localidad, `LinkIndec` se excluye de la clave natural. Provincia se
normaliza por alias; partido y localidad usan claves Unicode NFC + `casefold()`
tras quitar espacios externos. La grafía de presentación se toma de la primera
fila de tecnologías para cada clave, y staging conserva cada grafía original.
La observación agrega tecnología o etiqueta de velocidad.

## Columnas y tipos inferidos para SQL

Los archivos CSV codifican físicamente todos los campos como texto. La tabla
indica el tipo inferido para el modelo SQL; las etiquetas y códigos se conservan
como texto para no perder grafías ni ceros iniciales.

| Archivo | Columnas y tipos inferidos |
|---|---|
| `Internet Accesos Tecnologias Provincias.csv` | `Año INTEGER`, `Trimestre INTEGER`, `Provincia TEXT`, `ADSL INTEGER`, `Cablemodem INTEGER`, `Fibra Optica INTEGER`, `Wireless INTEGER`, `Otros INTEGER`, `Total INTEGER` |
| `Internet Velocidad Media de Descarga Provincias.csv` | `Año INTEGER`, `Trimestre INTEGER`, `Provincia TEXT`, `Mbps (Media de bajada) REAL` |
| `Internet Penetración Provincias.csv` | `Año INTEGER`, `Trimestre INTEGER`, `Provincias TEXT`, `Accesos cada 100 Hogares REAL`, `Accesos cada 100 Habitantes REAL` |
| `Internet Accesos Velocidad Provincias.csv` | `Año INTEGER`, `Trimestre INTEGER`, `Provincia TEXT`, `Velocidad TEXT`, `Accesos INTEGER` |
| `Internet Accesos Tecnologias Localidades.csv` | `LinkIndec TEXT`, `Provincia TEXT`, `Partido TEXT`, `Localidad TEXT`, `Tecnologia TEXT`, `Accesos INTEGER` |
| `Internet Accesos Velocidad Localidades.csv` | `LinkIndec TEXT`, `Provincia TEXT`, `Partido TEXT`, `Localidad TEXT`, `Velocidad TEXT`, `Accesos INTEGER` |

`source_row` (INTEGER) se agrega en staging para rastrear la fila de origen; no
es una columna del CSV. En los CSV derivados de `data/modified/`, `anio`,
`trimestre`, conteos y `source_row` son enteros; medidas y tasas conservan el
tipo numérico; etiquetas y nombres son texto.

## Valores y controles observados

- Los seis CSV tienen cero celdas vacías, cero valores numéricos inválidos y
  cero medidas negativas. Los ceros de accesos son valores presentes y se
  conservan como cero.
- No se encontraron filas duplicadas exactas ni claves naturales repetidas en
  los seis conjuntos con la clave documentada.
- Las columnas de acceso contienen enteros; Mbps y las tasas de penetración se
  almacenan como reales. `Año` y `Trimestre` se convierten a enteros.
- Accesos por tecnología: cada combinación provincia-trimestre suma cinco
  tecnologías y se compara con el `Total` informado. La validación ejecutada
  sobre las 1.056 filas históricas no encontró diferencias.
- El archivo completo de categorías provinciales contiene 239 etiquetas
  distintas; dentro de 2014–2024 se observan 207. Accesos locales por
  categoría contiene 138 etiquetas distintas. Incluyen valores
  numéricos como texto, algunos con coma decimal (por ejemplo, `0,26`, `0,5` y
  `1,25`). El CSV no define una unidad o un diccionario de rangos; no se
  reinterpretan como Mbps ni se agrupan en intervalos inventados.
- El archivo local de tecnologías contiene diez grafías de tecnología; al
  unificar mayúsculas/minúsculas quedan nueve nombres analíticos. Se conservan
  las grafías originales en staging.
- Los tres CSV provinciales de 1.200 filas contienen 144 registros posteriores
  a 2024 cada uno. El de categorías provinciales contiene 5.877 registros fuera
  del período. Corresponden a períodos posteriores (2025–2026) y quedan en
  staging, fuera de las tablas históricas.

## Diferencia entre categorías y total informado

La suma de las categorías provinciales de velocidad se comparó por provincia y
trimestre con el `Total` del archivo de accesos por tecnología. En el tramo
compartido hay 696 pares provincia-trimestre (29 períodos × 24 jurisdicciones):
165 tienen valores distintos. Al sumar por período a nivel nacional, 27 de los
29 períodos coinciden; hay diferencias en:

| Período | Suma de categorías | Total informado | Diferencia |
|---|---:|---:|---:|
| 2022-T3 | 11.632.228 | 11.091.128 | 541.100 |
| 2023-T2 | 11.633.052 | 11.251.897 | 381.155 |

En 2024-T4 ambos archivos suman 11.925.620. El motivo de las discrepancias no
se puede establecer con estos seis CSV. Se preservan ambas fuentes sin
reconciliarlas; la consulta de distribución por categoría usa como denominador
la suma de categorías del período. La vista
`quality_category_total_mismatches` expone cada provincia-trimestre diferente y
`quality_category_period_mismatches` muestra los períodos cuya suma nacional
también difiere.

## Validación de `LinkIndec` y relación territorial

En el archivo de tecnologías locales hay 3.491 códigos `LinkIndec` distintos.
Tras unificar variantes de caja, 191 códigos se asignan a más de una combinación
provincia-partido-localidad; el código `0` aparece en 476 combinaciones de
tecnologías y 484 de categorías. Por eso `LinkIndec` no identifica una
localidad de forma única y no se usa como PK ni como vínculo entre tablas.

Había 71 direcciones con variantes de mayúsculas en tecnologías y 97 en
categorías; normalizarlas unifica 103 claves que de otro modo quedarían
duplicadas. Después de normalizar, hay 4.686 localidades en tecnologías y 4.691
en categorías: 4.683 compartidas, 3 solo en tecnologías y 8 solo en categorías.
La dimensión contiene su unión de 4.694 claves. Las 4.683 direcciones
compartidas informan el mismo `LinkIndec`; la vista
`quality_linkindec_cross_source_mismatches` detecta futuras diferencias.

## Comparación con los datos procesados

`dashboard.json` contiene 44 períodos nacionales, 1.056 filas provinciales,
20.737 filas provinciales por categoría de velocidad, 2.892 combinaciones
nacionales de período-categoría, 4.757 localidades con la agrupación original
sensible a caja, 12.100 filas de tecnología local y 24.990 filas de velocidad
local. SQLite conserva los recuentos de hechos locales y, además, consolida las
variantes de mayúsculas en 4.686 localidades de tecnologías y 4.694 claves en la
unión dimensional. Los registros fuente siguen trazables en staging.

`scripts/process_data.py` convierte los accesos provinciales y por categoría con
`fillna(0)`. La auditoría actual no encontró faltantes o errores numéricos, por
lo que no cambia los resultados observados; sí es una diferencia de tratamiento
para futuras fuentes. La carga SQLite conserva como `NULL` un dato faltante o
inválido y preserva el cero informado. No se modificó el procesamiento Python
existente.

El procesamiento existente normaliza variantes de provincia y `Capital
Federal` a `CABA`, y agrupa localidades conservando diferencias de caja. El
modelo SQL mejora la clave territorial con `casefold()` para no separar una
misma localidad por mayúsculas; `scripts/process_data.py` y el dashboard no se
modificaron. Los archivos locales continúan separados de las series históricas.

## Límites de integración

- El total provincial y las cinco tecnologías proceden de la misma fuente, pero
  se guardan en hechos separados para impedir que un `JOIN` multiplique el
  denominador nacional.
- Velocidad media y penetración se enlazan con accesos por provincia y período;
  se agregan antes de combinarlos cuando el análisis lo requiere.
- Los datos territoriales no tienen año ni trimestre y no se cruzan con una
  fecha histórica.
- `LinkIndec` queda preservado en staging, junto con el archivo y el número
  de fila de origen. El cruce territorial usa provincia normalizada y claves
  Unicode NFC + `casefold()` de partido/localidad, quitando espacios externos;
  los textos fuente siguen disponibles en staging.
- Las etiquetas de `Velocidad` son texto original. La base puede enumerarlas y
  contarlas, pero no puede decidir si una nueva etiqueta es inválida porque las
  fuentes no incluyen una taxonomía externa de referencia.
