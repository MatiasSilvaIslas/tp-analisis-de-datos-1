# Cierre del análisis: evolución de la conectividad en Argentina (2014-T1 a 2024-T4)

Documento analítico de síntesis para el informe final y la exposición oral del Trabajo Práctico Integrador. Basado exclusivamente en el procesamiento, modelado relacional en SQLite y análisis exploratorio de los seis conjuntos de datos abiertos de ENACOM (período 2014-T1 a 2024-T4).

---

## 1. Definición del caso y pregunta de análisis

- **Rol analítico:** Equipo de analistas de datos que evalúa la infraestructura de telecomunicaciones públicas y privadas en Argentina.
- **Público objetivo:** Cátedra de Análisis de Datos I (Licenciatura en Ciencia de Datos), planificadores de políticas de conectividad y operadores del sector.
- **Problema:** Describir la dinámica temporal y geográfica del acceso fijo a Internet en Argentina durante una década, evaluando si el crecimiento del parque de conexiones y la modernización de tecnologías redujeron las asimetrías territoriales o si persistieron brechas estructurales entre jurisdicciones.
- **Pregunta central:** ¿La evolución de la conectividad fija en Argentina entre 2014-T1 y 2024-T4 fue homogénea entre las jurisdicciones del país o persistieron diferencias significativas en volumen, tecnología y penetración por hogar?
- **Hipótesis descriptiva:** En el período 2014-T1 a 2024-T4 se produjo una expansión del parque total de accesos fijos acompañada de una transformación en la matriz tecnológica (retroceso del ADSL y avance marcado de fibra óptica y cablemódem). Sin embargo, este crecimiento no fue territorialmente homogéneo: el volumen de accesos y el despliegue de nueva fibra se concentró en las jurisdicciones de mayor escala poblacional y económica, mientras que la brecha de penetración por hogar mantuvo una distancia persistente entre los distritos de mayor y menor cobertura.

---

## 2. Respuesta fundada a la pregunta central

La evolución de la conectividad fija en Argentina **no fue homogénea**. Los datos evidencian dos dinámicas contrapuestas:

1. **Crecimiento agregado y convergencia relativa:** A nivel nacional, los accesos crecieron un **86,38 %** (de 6.398.398 a 11.925.620). En penetración de hogares, la dispersión relativa interprovincial disminuyó: el Coeficiente de Variación cayó de **60,06 %** en 2014-T1 a **31,52 %** en 2024-T4, y la razón entre la provincia con mayor y menor penetración se redujo de **12,01 veces** a **3,30 veces**.
2. **Persistencia de asimetrías estructurales y concentración de volumen:**
   - **Concentración del crecimiento:** Solo tres jurisdicciones (Buenos Aires, Córdoba y Santa Fe) explicaron el **61,95 %** de los nuevos accesos totales y el **62,42 %** de los nuevos accesos de fibra óptica del país.
   - **Brecha de penetración:** En 2024-T4, la diferencia absoluta entre el distrito con mayor tasa (CABA: 105,26 accesos cada 100 hogares) y el de menor tasa (Formosa: 31,92) continuó siendo de **73,34 accesos cada 100 hogares**. Jurisdicciones del NEA y NOA (Formosa, Santiago del Estero, Chaco y Corrientes) no alcanzan los 43 accesos cada 100 hogares, menos de la mitad del grupo líder.
   - **Asimetría tecnológica:** Mientras distritos como Tucumán (83,15 %), Catamarca (78,44 %) o Mendoza (71,08 %) reconvirtieron mayoritariamente su parque hacia fibra óptica, en CABA (21,28 %) y Tierra del Fuego (14,93 %) la fibra tiene baja participación frente al predominio histórico del cablemódem.

---

## 3. Cuantificación del crecimiento por jurisdicción (2014-T1 vs 2024-T4)

Entre 2014-T1 y 2024-T4, el parque nacional sumó **5.527.222 accesos netos**. La siguiente tabla detalla la evolución en las 24 jurisdicciones (23 provincias y CABA), ordenada por volumen de crecimiento absoluto:

| Jurisdicción | Accesos 2014-T1 | Accesos 2024-T4 | Variación absoluta | Variación % | Contribución al aumento nacional |
|:---|---:|---:|---:|---:|---:|
| Buenos Aires | 2.739.876 | 5.221.181 | +2.481.305 | +90,56 % | 44,89 % |
| Córdoba | 566.910 | 1.107.308 | +540.398 | +95,32 % | 9,78 % |
| Santa Fe | 506.612 | 908.776 | +402.164 | +79,38 % | 7,28 % |
| Mendoza | 165.845 | 337.935 | +172.090 | +103,77 % | 3,11 % |
| Entre Ríos | 134.331 | 300.845 | +166.514 | +123,96 % | 3,01 % |
| CABA | 1.299.918 | 1.464.187 | +164.269 | +12,64 % | 2,97 % |
| San Luis | 12.557 | 175.769 | +163.212 | +1.299,77 % | 2,95 % |
| Tucumán | 130.032 | 270.188 | +140.156 | +107,79 % | 2,54 % |
| Misiones | 73.950 | 211.185 | +137.235 | +185,58 % | 2,48 % |
| Chubut | 70.221 | 181.048 | +110.827 | +157,83 % | 2,01 % |
| Chaco | 62.556 | 163.860 | +101.304 | +161,94 % | 1,83 % |
| Salta | 91.290 | 189.705 | +98.415 | +107,80 % | 1,78 % |
| Corrientes | 62.236 | 159.756 | +97.520 | +156,69 % | 1,76 % |
| Jujuy | 33.827 | 130.707 | +96.880 | +286,40 % | 1,75 % |
| Neuquén | 90.380 | 187.112 | +96.732 | +107,03 % | 1,75 % |
| Río Negro | 95.066 | 179.472 | +84.406 | +88,79 % | 1,53 % |
| San Juan | 51.298 | 126.839 | +75.541 | +147,26 % | 1,37 % |
| La Pampa | 54.193 | 128.341 | +74.148 | +136,82 % | 1,34 % |
| Santiago del Estero | 37.133 | 110.882 | +73.749 | +198,61 % | 1,33 % |
| La Rioja | 15.711 | 87.809 | +72.098 | +458,90 % | 1,30 % |
| Santa Cruz | 26.764 | 82.859 | +56.095 | +209,59 % | 1,01 % |
| Catamarca | 24.232 | 77.427 | +53.195 | +219,52 % | 0,96 % |
| Formosa | 25.422 | 65.155 | +39.733 | +156,29 % | 0,72 % |
| Tierra del Fuego | 28.038 | 57.274 | +29.236 | +104,27 % | 0,53 % |
| **Total Nacional** | **6.398.398** | **11.925.620** | **+5.527.222** | **+86,38 %** | **100,00 %** |

### Análisis de rankings: volumen absoluto vs. tasa porcentual

- **Ranking por volumen absoluto:** Buenos Aires (+2.481.305), Córdoba (+540.398) y Santa Fe (+402.164) concentraron más de 3,42 millones de los 5,53 millones de accesos creados en el país. En el extremo opuesto, Tierra del Fuego (+29.236), Formosa (+39.733) y Catamarca (+53.195) sumaron menos de 60.000 accesos cada una.
- **Ranking por variación porcentual:** Las mayores tasas relativas correspondieron a San Luis (+1.299,77 %), La Rioja (+458,90 %), Jujuy (+286,40 %), Catamarca (+219,52 %) y Santa Cruz (+209,59 %).
- **Advertencia metodológica sobre bases pequeñas:** Un porcentaje de crecimiento muy elevado no equivale a un aporte cuantitativo significativo al total nacional cuando la base inicial es reducida. Por ejemplo, el incremento de 1.299,77 % de San Luis partió de apenas 12.557 accesos en 2014 y representó el 2,95 % del aumento nacional. En contraste, CABA registró la menor tasa porcentual (+12,64 %), pero sumó 164.269 conexiones netas debido a que ya contaba con un mercado consolidado de 1,3 millones de accesos en 2014.

---

## 4. Evolución y distribución territorial de la fibra óptica

La fibra óptica fue el principal motor tecnológico de la década: a nivel nacional pasó de **150.323 accesos (2,35 % del total)** en 2014-T1 a **4.875.163 accesos (40,88 %)** en 2024-T4 (+4.724.840 conexiones netas; +38,53 puntos porcentuales de participación).

| Jurisdicción | Fibra 2014-T1 | Fibra 2024-T4 | Aumento neto fibra | Participación nacional fibra | % Fibra 2014 | % Fibra 2024 | Variación (pp) |
|:---|---:|---:|---:|---:|---:|---:|---:|
| Buenos Aires | 120.960 | 2.128.800 | +2.007.840 | 42,50 % | 4,41 % | 40,77 % | +36,36 pp |
| Córdoba | 347 | 502.489 | +502.142 | 10,63 % | 0,06 % | 45,38 % | +45,32 pp |
| Santa Fe | 3.059 | 442.579 | +439.520 | 9,30 % | 0,60 % | 48,70 % | +48,10 pp |
| CABA | 17.767 | 311.545 | +293.778 | 6,22 % | 1,37 % | 21,28 % | +19,91 pp |
| Mendoza | 2.480 | 240.219 | +237.739 | 5,03 % | 1,50 % | 71,08 % | +69,58 pp |
| Tucumán | 121 | 224.665 | +224.544 | 4,75 % | 0,09 % | 83,15 % | +83,06 pp |
| Misiones | 4 | 97.233 | +97.229 | 2,06 % | 0,01 % | 46,04 % | +46,03 pp |
| Chaco | 30 | 89.971 | +89.941 | 1,90 % | 0,05 % | 54,91 % | +54,86 pp |
| Río Negro | 876 | 81.289 | +80.413 | 1,70 % | 0,92 % | 45,29 % | +44,37 pp |
| San Juan | 722 | 78.030 | +77.308 | 1,64 % | 1,41 % | 61,52 % | +60,11 pp |
| Entre Ríos | 49 | 76.767 | +76.718 | 1,62 % | 0,04 % | 25,52 % | +25,48 pp |
| Salta | 45 | 75.717 | +75.672 | 1,60 % | 0,05 % | 39,91 % | +39,86 pp |
| Chubut | 866 | 66.475 | +65.609 | 1,39 % | 1,23 % | 36,72 % | +35,49 pp |
| Neuquén | 997 | 65.959 | +64.962 | 1,37 % | 1,10 % | 35,25 % | +34,15 pp |
| Catamarca | 17 | 60.732 | +60.715 | 1,29 % | 0,07 % | 78,44 % | +78,37 pp |
| Jujuy | 23 | 49.992 | +49.969 | 1,06 % | 0,07 % | 38,25 % | +38,18 pp |
| Santa Cruz | 381 | 49.618 | +49.237 | 1,04 % | 1,42 % | 59,88 % | +58,46 pp |
| Corrientes | 31 | 47.570 | +47.539 | 1,01 % | 0,05 % | 29,78 % | +29,73 pp |
| La Pampa | 513 | 45.105 | +44.592 | 0,94 % | 0,95 % | 35,14 % | +34,19 pp |
| San Luis | 354 | 43.839 | +43.485 | 0,92 % | 2,82 % | 24,94 % | +22,12 pp |
| Santiago del Estero | 19 | 42.604 | +42.585 | 0,90 % | 0,05 % | 38,42 % | +38,37 pp |
| La Rioja | 14 | 24.199 | +24.185 | 0,51 % | 0,09 % | 27,56 % | +27,47 pp |
| Formosa | 0 | 21.217 | +21.217 | 0,45 % | 0,00 % | 32,56 % | +32,56 pp |
| Tierra del Fuego | 648 | 8.549 | +7.901 | 0,17 % | 2,31 % | 14,93 % | +12,62 pp |
| **Total Nacional** | **150.323** | **4.875.163** | **+4.724.840** | **100,00 %** | **2,35 %** | **40,88 %** | **+38,53 pp** |

### Contrastes territoriales del despliegue de fibra

1. **Concentración del volumen físico:** Buenos Aires (+2.007.840), Córdoba (+502.142) y Santa Fe (+439.520) acumulan el **62,42 %** del aumento neto de accesos de fibra de Argentina. Si se agrega CABA (6,22 %) y Mendoza (5,03 %), cinco distritos concentran el **73,67 %** del crecimiento nacional.
2. **Reconversión tecnológica profunda en el interior:** En términos de composición interna provincial, la fibra se transformó en la tecnología dominante en varias provincias que antes dependían de ADSL. Lideran Tucumán (83,15 % de penetración interna de fibra), Catamarca (78,44 %), Mendoza (71,08 %), San Juan (61,52 %), Santa Cruz (59,88 %) y Chaco (54,91 %).
3. **Casos con baja penetración relativa de fibra:** En distritos con redes de cable coaxial altamente desarrolladas (como CABA, con 21,28 %, o Tierra del Fuego, con 14,93 %) y en provincias con despliegues alternativos o wireless (San Luis con 24,94 % y Entre Ríos con 25,52 %), la participación de la fibra óptica es sensiblemente inferior al promedio nacional (40,88 %).

---

## 5. Brecha territorial y análisis de dispersión en accesos cada 100 hogares

### Evolución comparada de la tasa por jurisdicción

| Jurisdicción | Tasa 2014-T1 | Tasa 2024-T4 | Variación neta (puntos) |
|:---|---:|---:|---:|
| CABA | 112,25 | 105,26 | -6,99 |
| San Luis | 9,35 | 96,01 | +86,66 |
| Tierra del Fuego | 63,97 | 88,49 | +24,52 |
| La Pampa | 48,43 | 87,17 | +38,74 |
| Buenos Aires | 54,57 | 86,71 | +32,14 |
| Chubut | 41,24 | 82,86 | +41,62 |
| Córdoba | 52,52 | 77,18 | +24,66 |
| Neuquén | 49,79 | 73,76 | +23,97 |
| Santa Cruz | 28,94 | 69,97 | +41,03 |
| Santa Fe | 47,85 | 67,83 | +19,98 |
| La Rioja | 16,29 | 66,29 | +50,00 |
| Río Negro | 44,91 | 61,41 | +16,50 |
| Entre Ríos | 34,37 | 58,77 | +24,40 |
| Catamarca | 24,25 | 56,15 | +31,90 |
| Jujuy | 18,42 | 53,99 | +35,57 |
| Tucumán | 33,42 | 52,26 | +18,84 |
| Mendoza | 31,91 | 51,79 | +19,88 |
| San Juan | 27,60 | 49,86 | +22,26 |
| Misiones | 23,14 | 47,39 | +24,25 |
| Salta | 28,70 | 44,05 | +15,35 |
| Corrientes | 22,32 | 42,53 | +20,21 |
| Chaco | 20,72 | 41,04 | +20,32 |
| Santiago del Estero | 16,31 | 35,17 | +18,86 |
| Formosa | 17,42 | 31,92 | +14,50 |

### Medidas de dispersión interjurisdiccional

| Métrica | 2014-T1 | 2024-T4 | Variación observada | Interpretación |
|:---|---:|---:|---:|:---|
| **Valor Mínimo** | 9,35 (San Luis) | 31,92 (Formosa) | +22,57 puntos | El piso de conectividad provincial aumentó significativamente. |
| **Valor Máximo** | 112,25 (CABA) | 105,26 (CABA) | -6,99 puntos | El techo se mantuvo en torno a 100-112 accesos/100 hogares. |
| **Rango Absoluto (Brecha)** | 102,90 puntos | 73,34 puntos | -29,56 puntos | La distancia absoluta entre extremos disminuyó casi 30 puntos. |
| **Razón Extremos (Max / Min)** | 12,01 veces | 3,30 veces | -8,71 veces | La brecha multiplicativa se redujo drásticamente. |
| **Media no ponderada** | 36,20 | 63,66 | +27,46 puntos | Crecimiento generalizado del promedio interjurisdiccional. |
| **Desviación Estándar** | 21,74 | 20,07 | -1,67 puntos | Dispersión absoluta en torno a la media levemente menor. |
| **Coeficiente de Variación (CV)** | **60,06 %** | **31,52 %** | **-28,54 pp** | **Reducción de casi la mitad en la dispersión relativa.** |

### Advertencias metodológicas críticas

1. **Naturaleza del indicador:** La tasa representa la cantidad de accesos registrados sobre el total de hogares proyectados multiplicada por 100. Debido a que el numerador incluye tanto accesos residenciales como conexiones corporativas (comercios, empresas, dependencias públicas), **no equivale al porcentaje de hogares únicos con conexión** y puede legítimamente superar el valor de 100 (como ocurre en CABA con 105,26 en 2024-T4 y 112,25 en 2014-T1).
2. **Revisión de proyecciones censales en 2022:** A partir del ejercicio 2022, ENACOM actualizó las estimaciones demográficas de hogares y habitantes tomando como referencia los resultados del Censo Nacional 2022 del INDEC. Al contabilizarse una cantidad de hogares mayor a la proyectada previamente desde el Censo 2010, se produjo un incremento en el denominador que generó una corrección hacia la baja en las tasas publicadas. Por ende, la comparación entre 2014 y 2024 presenta una discontinuidad metodológica en el denominador que debe ser considerada al evaluar variaciones de largo plazo.

---

## 6. Corte territorial de localidades y límites temporales

Los dos archivos de localidades provistos (`Internet Accesos Tecnologias Localidades.csv` e `Internet Accesos Velocidad Localidades.csv`) **no contienen columnas de año ni trimestre**. 

- **Lo que sí se puede afirmar:** Es posible analizar la distribución geográfica estática del corte disponible. En él se observa una marcada primacía urbana: las 10 localidades con mayor cantidad de accesos concentran el **28,6 %** de todas las conexiones registradas por tecnología (lideradas por CABA con 1.631.231, Córdoba Capital con 568.595, Rosario con 357.753, Mar del Plata con 304.101 y La Plata con 252.382).
- **Lo que no se puede afirmar:** No se puede determinar qué localidades crecieron, decrecieron o incorporaron tecnologías entre 2014 y 2024. Asignar este archivo al último trimestre o evaluar tendencias temporales a nivel localidad carece de fundamento metodológico.

---

## 7. Alcance de las recomendaciones: qué sí y qué no se puede recomendar

### Qué SÍ se puede recomendar (con fundamento en los datos)

- **Focalización diagnóstica en distritos rezagados:** Priorizar estudios de relevamiento técnico y territorial en las jurisdicciones que presentan valores de penetración por debajo de 45 accesos cada 100 hogares (Formosa: 31,92; Santiago del Estero: 35,17; Chaco: 41,04; Corrientes: 42,53).
- **Líneas de investigación sobre determinantes estructurales:** Proponer a futuro el cruce de estos resultados con variables que no forman parte de este proyecto (niveles de ingreso de la EPH, dispersión poblacional y ruralidad del Censo 2022, estructura de costos e inversión de los operadores, y precios relativos de las tarifas).
- **Estandarización y gobernanza de datos:** Recomendar a los organismos reguladores la publicación de un diccionario formal para las categorías de velocidad y auditar las discrepancias identificadas entre las fuentes de tecnologías y categorías de velocidad (presentes en 165 de los 696 pares provincia-trimestre analizados).

### Qué NO se puede recomendar ni afirmar (límites causales)

- **Prohibido atribuir causalidades sin variables:** No se puede atribuir el rezago o el avance de una provincia a la eficiencia de una política pública particular, a la regulación de precios, a la gestión de un gobierno o a la presencia exclusiva de una empresa, ya que el dataset carece de variables institucionales, tarifarias o financieras.
- **No inferir migraciones individuales de hogares:** No es válido afirmar que un hogar específico migró de ADSL a fibra óptica. Los datos reflejan existencias agregadas netas trimestrales por tecnología, producto tanto de recableados como de altas nuevas y bajas comerciales simultáneas.
- **No equiparar velocidad informada con calidad percibida:** No se puede concluir que una provincia con mayor velocidad media contratada o informada brinde mejor experiencia de usuario, dado que no se miden latencias, caídas de servicio, estabilidad de red ni patrones de consumo de ancho de banda.

---

## 8. Conclusión lista para el informe final

> Entre 2014-T1 y 2024-T4, los accesos fijos a Internet en Argentina crecieron un 86,38 %, pasando de 6.398.398 a 11.925.620 conexiones registradas, traccionados por una profunda reconversión tecnológica en la que la fibra óptica avanzó de representar el 2,35 % al 40,88 % del total, mientras que el ADSL cayó un 85,90 %. Sin embargo, la evidencia demuestra que esta evolución no fue homogénea en el territorio nacional. El volumen de crecimiento físico se concentró marcadamente en la región central: Buenos Aires, Córdoba y Santa Fe explicaron el 61,95 % de los nuevos accesos totales y el 62,42 % del despliegue de nueva fibra. En términos de penetración por hogar, si bien se verificó una convergencia relativa que redujo el Coeficiente de Variación de 60,06 % a 31,52 %, persistió una profunda brecha estructural: en 2024-T4, la diferencia entre la Ciudad Autónoma de Buenos Aires (105,26 accesos cada 100 hogares) y Formosa (31,92) se ubicó en 73,34 accesos cada 100 hogares, manteniéndose varias provincias del norte con tasas inferiores a la mitad del grupo líder. Estos resultados sustentan la hipótesis de expansión y cambio de composición tecnológica, pero confirman la continuidad de desigualdades territoriales que requieren investigaciones complementarias sobre factores socioeconómicos y geográficos para explicar sus causas determinantes.

---

## 9. Guion oral para la exposición (aproximadamente 1 minuto)

> “Para cerrar la presentación, respondemos a la pregunta central que nos planteamos como equipo: ¿fue homogénea la evolución de la conectividad en Argentina? 
>
> La evidencia muestra que no. Si miramos las cifras globales, el crecimiento es indiscutible: el total de accesos casi se duplicó, pasando de 6,4 a casi 11,9 millones, y la fibra óptica pasó de ser marginal, con poco más del 2 %, a representar más del 40 % de los accesos del país. En penetración de hogares, la dispersión relativa disminuyó notablemente: el coeficiente de variación cayó del 60 % al 31 %.
>
> Sin embargo, persisten fuertes asimetrías territoriales. En volumen, solo tres provincias —Buenos Aires, Córdoba y Santa Fe— concentraron más del 60 % de todos los nuevos accesos y de la nueva fibra. Y en cobertura de hogares, la brecha sigue siendo enorme: CABA supera los 105 accesos cada 100 hogares, mientras que Formosa apenas llega a 32, con una distancia de más de 73 puntos entre extremos.
>
> En conclusión, los datos de ENACOM nos permiten describir con precisión esta expansión y sus brechas geográficas, pero no atribuir causas automáticas: explicar por qué persisten estas diferencias exigirá, en futuros trabajos, incorporar datos de ingresos, ruralidad y costos de infraestructura.”

---

## 10. Limitaciones metodológicas y líneas de investigación futuras

1. **Carácter descriptivo de las fuentes:** Los seis datasets describen existencias trimestrales y promedios agregados. No permiten establecer relaciones causales ni modelos explicativos de comportamiento sin variables de control externas.
2. **Denominador censal de penetración:** La serie de penetración incorpora una ruptura metodológica en 2022 por la actualización al Censo 2022 del INDEC, que ajustó a la baja los valores relativos en comparación con los años precedentes.
3. **Discrepancias cuantitativas entre tablas:** En 165 de 696 pares provincia-trimestre, la suma de accesos por categorías de velocidad no coincide con el total por tecnologías. Se conservaron ambos registros sin alterar para respetar la integridad de las fuentes originales.
4. **Agregación de velocidad:** La velocidad media ponderada estimada por el proyecto para 2024-T4 es de 181,22 Mbps, calculada a partir de los 24 valores provinciales y sus pesos de acceso, mientras que la serie nacional directa de ENACOM reporta 182,21 Mbps (diferencia de 0,99 Mbps). Al responder a agregaciones metodológicas distintas, se presentan por separado.
5. **Agenda futura:** Queda planteada como línea de investigación la vinculación del modelo con microdatos de la Encuesta Permanente de Hogares (EPH) e indicadores educativos del INDEC, permitiendo evaluar la relación entre brecha digital, nivel de ingresos y capital humano.
