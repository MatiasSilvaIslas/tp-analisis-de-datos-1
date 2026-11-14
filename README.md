# Conectividad fija en Argentina (2014–2024)

Dashboard web interactivo para explorar la evolución de los accesos a Internet fijo, las tecnologías de conexión, la velocidad de descarga y las diferencias territoriales entre las 24 jurisdicciones argentinas. El proyecto utiliza exclusivamente los seis archivos de ENACOM incluidos en `data/raw/`.

> **Alcance:** el período histórico analizado es 2014–2024 inclusive. Aunque algunos CSV de origen contienen registros de 2025 y 2026, el proceso los excluye deliberadamente. Los dos archivos del INDEC que venían en el comprimido original no se incorporaron.

## Vista general

- Indicadores de accesos, participación de fibra óptica, velocidad media y penetración provincial.
- Evolución trimestral de accesos y tecnologías.
- Estimación de velocidad media nacional ponderada por accesos provinciales, claramente identificada como estimación.
- Comparaciones provinciales de penetración y velocidad.
- Distribución de las categorías de velocidad informadas por ENACOM.
- Ranking de localidades por accesos y distribución local de categorías de velocidad.
- Filtros por año, trimestre y provincia.

## Estructura del proyecto

```text
conectividad-fija-argentina/
├── index.html                    # Interfaz del dashboard
├── css/
│   └── styles.css                # Estilos y diseño responsive
├── js/
│   └── app.js                    # Filtros, indicadores y gráficos
├── data/
│   ├── raw/                      # Los seis CSV originales de ENACOM
│   └── processed/
│       └── dashboard.json        # Datos normalizados que consume el navegador
├── scripts/
│   └── process_data.py           # Limpieza, validación y transformación
├── docs/
│   ├── METODOLOGIA.md            # Decisiones metodológicas y limitaciones
│   ├── DICCIONARIO_DE_DATOS.md   # Descripción de fuentes y campos
│   └── ANALISIS_INICIAL.md       # Comparación descriptiva 2014-T1 vs 2024-T4
├── requirements.txt
├── .gitignore
└── README.md
```

## Requisitos

- Python 3.10 o superior.
- Navegador moderno (Chrome, Firefox, Edge o Safari).
- Conexión a Internet para cargar Chart.js y las fuentes tipográficas desde sus CDN/servicios externos.

## Ejecutar localmente

Desde una terminal, ubicarse en la carpeta raíz del proyecto.

### 1. Instalar dependencias

```bash
python -m venv .venv
```

Activar el entorno virtual:

**Windows (PowerShell):**

```powershell
.venv\Scripts\Activate.ps1
```

**Linux / macOS:**

```bash
source .venv/bin/activate
```

Instalar dependencias:

```bash
python -m pip install -r requirements.txt
```

### 2. Regenerar los datos procesados (opcional)

El repositorio ya incluye `data/processed/dashboard.json`, por lo que este paso no es necesario para abrir el dashboard. Si se modifican o reemplazan los CSV originales, ejecutar:

```bash
python scripts/process_data.py
```

El script lee los seis CSV de `data/raw/`, limita los datos históricos a 2014–2024 y vuelve a generar `data/processed/dashboard.json`.

### 3. Iniciar el servidor web local

No abrir `index.html` directamente con doble clic: el navegador puede bloquear la lectura del JSON por políticas de seguridad. Desde la raíz del proyecto ejecutar:

```bash
python -m http.server 8000
```

Abrir en el navegador:

```text
http://localhost:8000
```

Para detener el servidor, presionar `Ctrl + C` en la terminal.

## Publicar en GitHub

1. Crear un repositorio nuevo en GitHub, por ejemplo `conectividad-fija-argentina`.
2. Copiar la carpeta completa del proyecto.
3. Desde la raíz, ejecutar:

```bash
git init
git add .
git commit -m "Primer release del dashboard de conectividad fija"
git branch -M main
git remote add origin https://github.com/USUARIO/conectividad-fija-argentina.git
git push -u origin main
```

Reemplazar `USUARIO` por el nombre de la cuenta u organización de GitHub.

### Publicarlo con GitHub Pages

El dashboard es estático. Para publicarlo:

1. Entrar en **Settings → Pages** del repositorio.
2. En **Build and deployment**, elegir **Deploy from a branch**.
3. Seleccionar la rama `main` y la carpeta `/ (root)`.
4. Guardar y esperar la publicación.

GitHub Pages publicará el sitio en una URL con el formato `https://USUARIO.github.io/conectividad-fija-argentina/`.

## Fuentes y tratamiento

Los CSV originales están guardados sin modificar en `data/raw/`. El script de procesamiento interpreta los separadores numéricos usados en los archivos argentinos, normaliza los nombres de provincias, filtra el período y genera las estructuras que utiliza el dashboard.

**Fuentes incluidas:**

1. `Internet Accesos Tecnologias Provincias.csv`
2. `Internet Velocidad Media de Descarga Provincias.csv`
3. `Internet Penetración Provincias.csv`
4. `Internet Accesos Velocidad Provincias.csv`
5. `Internet Accesos Tecnologias Localidades.csv`
6. `Internet Accesos Velocidad Localidades.csv`

Los archivos de localidades no contienen año ni trimestre. Se utilizan únicamente para análisis territorial transversal y no se mezclan con las series históricas. Para más detalles, consultar [`docs/METODOLOGIA.md`](docs/METODOLOGIA.md), [`docs/DICCIONARIO_DE_DATOS.md`](docs/DICCIONARIO_DE_DATOS.md) y [`docs/ANALISIS_INICIAL.md`](docs/ANALISIS_INICIAL.md).

## Limitaciones conocidas

- La velocidad media nacional no viene como un único dato nacional en el conjunto utilizado. El dashboard calcula una estimación ponderada a partir de las medias provinciales y los accesos de cada provincia.
- La penetración se muestra por provincia. No se calcula una tasa nacional promediando porcentajes provinciales.
- El CSV de accesos por velocidad contiene categorías originales, pero no aporta en el propio archivo la definición de sus rangos/unidades. Se muestran sin asignarles una interpretación no documentada.
- Las visualizaciones de localidades no representan una evolución temporal porque sus CSV no tienen período.
- Chart.js y las tipografías se cargan desde servicios externos; sin conexión, el dashboard no podrá cargar correctamente esos recursos.

## Tecnologías

- HTML5
- CSS3
- JavaScript (ES6+)
- [Chart.js](https://www.chartjs.org/)
- Python + pandas para preparar los datos

## Licencia

Este proyecto se distribuye bajo licencia MIT. Los datos mantienen la atribución y condiciones de uso que correspondan a ENACOM.
