# CSV normalizados

Esta carpeta contiene salidas derivadas y regenerables de `scripts/load_sqlite.py`. La fuente maestra son los CSV originales de `data/raw/`, que el cargador no modifica.

El cargador exporta seis archivos: accesos por tecnología, velocidad media, penetración y categorías de velocidad por provincia, más tecnologías y categorías por localidad. Los tres primeros cubren 2014–2024; las categorías provinciales cubren 2017-T4–2024-T4. Los archivos locales no tienen período; la dimensión SQL unifica diferencias de mayúsculas en nombres geográficos y preserva `LinkIndec` como atributo, no como identificador único. Cada salida incluye `source_row` para rastrear la fila del CSV fuente.

| Archivo | Filas de datos |
|---|---:|
| `accesos_tecnologia_provincia.csv` | 1.056 |
| `velocidad_provincia.csv` | 1.056 |
| `penetracion_provincia.csv` | 1.056 |
| `accesos_categoria_provincia.csv` | 20.737 |
| `accesos_tecnologia_localidad.csv` | 12.100 |
| `accesos_categoria_localidad.csv` | 24.990 |

Para regenerar esta carpeta junto con SQLite, ejecutar desde la raíz del repo:

```bash
python scripts/load_sqlite.py
```
