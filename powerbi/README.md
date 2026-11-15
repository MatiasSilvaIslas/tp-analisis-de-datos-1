# Dashboard en Power BI

Versión en Power BI del dashboard de conectividad fija (2014–2024), armada como **proyecto de Power BI (.pbip)**, es decir, en archivos de texto que se pueden versionar con Git.

## Cómo abrirlo

1. Clonar el repositorio (o hacer `git pull` si ya lo tenés).
2. Abrir `powerbi/Conectividad.pbip` con **Power BI Desktop** (versión 2025 o posterior).
3. Tocar **Actualizar** (o "Actualizar ahora" en la barra amarilla) para cargar los datos.

Si Power BI pregunta cómo acceder a `raw.githubusercontent.com`, elegir **Anónimo** → Conectar. Si pregunta por niveles de privacidad, elegir **Público**.

## De dónde salen los datos

Los datos se leen de los CSV de `data/modified/` **directamente desde GitHub** (rama `main`). Para ver datos nuevos, alcanza con subir los CSV actualizados al repo y tocar **Actualizar** en Power BI.

Para trabajar sin Internet o con CSV locales: **Transformar datos → Editar parámetros → `CarpetaDatos`** y poner la ruta local terminada en barra, por ejemplo:

```
C:\ruta\al\repo\tp-analisis-de-datos-1\data\modified\
```

> No subas al repo el cambio del parámetro con tu ruta local: volvé a dejar la URL de GitHub antes de hacer commit.

## Páginas

| Página | Contenido |
|---|---|
| 1 · Resumen | KPIs (último período del filtro) y evolución de accesos totales y de fibra |
| 2 · Cambio tecnológico | Composición tecnológica (100 %) y velocidad media ponderada |
| 3 · Brechas provinciales | Penetración y velocidad por provincia (3 más altas / 3 más bajas resaltadas) |
| Anexo | Categorías de velocidad, localidades y metodología |

Los filtros de Año, Trimestre y Provincia están sincronizados entre las páginas 1 a 3.

## Estructura

```
powerbi/
├── Conectividad.pbip              # Abrir este archivo
├── Conectividad.SemanticModel/    # Modelo: tablas, relaciones y medidas DAX (formato TMDL)
├── Presentacion.Report/           # Páginas y visuales (formato PBIR)
└── TemaConectividad.json          # Tema de colores (ya incluido en el reporte)
```

Los archivos locales de caché de Power BI (`.pbi/cache.abf`, `.pbi/localSettings.json`) están excluidos en `.gitignore`.

## Metodología

Las medidas replican los cálculos del dashboard web; ver `docs/METODOLOGIA.md`. En particular, la velocidad nacional es una **estimación ponderada por accesos** y la penetración se informa solo por provincia.
