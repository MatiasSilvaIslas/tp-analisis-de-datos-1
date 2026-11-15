# Punto 5 · Cierre: respuesta a la hipótesis, conclusiones, limitaciones y mejoras

Síntesis para la exposición. Las cifras salen de `notebooks/03_cierre_hipotesis.ipynb`, que se ejecuta sobre `database/conectividad.db`. El desarrollo completo, con las tablas por provincia, está en [`outputs/Cierre_TP_analisis_conclusiones.md`](../outputs/Cierre_TP_analisis_conclusiones.md).

En Power BI, este cierre corresponde a la página **4 · Conclusiones**.

---

## 1. Pregunta e hipótesis (recordatorio)

**Pregunta:** ¿la evolución de la conectividad fija en Argentina entre 2014-T1 y 2024-T4 fue homogénea entre jurisdicciones?

**Hipótesis:** hubo expansión del parque y cambio de matriz tecnológica, pero el crecimiento se concentró en las jurisdicciones de mayor escala y la brecha de penetración por hogar persistió.

## 2. Respuesta: veredicto por componente

| Componente de la hipótesis | Resultado | Evidencia |
|---|---|---|
| 1. Expansión del parque | ✅ Confirmado | 6,40 → 11,93 millones de accesos (+86,4 %) |
| 2. Cambio de matriz tecnológica | ✅ Confirmado, con matiz | ADSL −85,9 %; fibra 2,35 % → 40,88 % del total. El **cablemódem sigue primero** (47,2 %). |
| 3. Concentración en provincias grandes | ⚠️ Parcial | Buenos Aires, Córdoba y Santa Fe aportan el 62 % del aumento, pero **ya tenían el 60 % del parque en 2014** (61 % en 2024). |
| 4. Persistencia de la brecha | ✅ Confirmado | CV entre provincias 60 % (2014) → 32 % (2020) → 32 % (2024). **Estancado desde 2020.** CABA 105 vs Formosa 32 accesos/100 hogares. |

**Respuesta a la pregunta:** no, la evolución **no fue homogénea**. El país se conectó más y con mejor tecnología, pero la distancia entre provincias dejó de achicarse hace cuatro años.

## 3. Hallazgos que aporta el cierre

1. **La convergencia se frenó en 2020.** La dispersión entre provincias bajó fuerte entre 2017 y 2020 (CV de 51 % a 32 %) y desde ahí quedó estable (CV entre 30 % y 33 %, rango entre 73 y 80 puntos). Comparar solo 2014 con 2024 esconde este estancamiento.
2. **La concentración del crecimiento refleja la escala, no un sesgo.** Las tres provincias grandes crecieron 89,8 % y el resto 81,4 %: ritmos parecidos. Su peso en el total casi no cambió (59,6 % → 60,7 %).
3. **Un valor atípico infla la mejora.** La razón máximo/mínimo cae de 12 a 3,3 veces, pero el 12 se explica por San Luis 2014 (9,35 accesos/100 hogares). Sin San Luis, la razón inicial era 6,9 veces: la brecha relativa igual se redujo a la mitad, pero menos de lo que parece.
4. **Más fibra no implica más cobertura.** En 2024-T4, la correlación entre % de fibra y penetración es negativa (r ≈ −0,39) y la de velocidad con penetración es débil (r ≈ 0,27). CABA y Tierra del Fuego tienen alta cobertura con cablemódem, mientras que provincias como Chaco migraron a fibra con cobertura baja. **Modernizar no es lo mismo que incluir.** Además, correlación no implica causalidad.

## 4. Conclusión (para el informe)

> Entre 2014 y 2024 los accesos fijos crecieron 86 % y la fibra pasó del 2 % al 41 % del total, mientras el ADSL prácticamente desapareció. Sin embargo, la evolución no fue homogénea: la brecha de penetración entre provincias se redujo a la mitad hasta 2020 y desde entonces está estancada. En 2024, CABA tiene 105 accesos cada 100 hogares y Formosa 32. La región central concentra el volumen de nuevas conexiones, pero en proporción a su tamaño previo. Los datos permiten describir estas brechas con precisión, pero no explicar sus causas.

## 5. Limitaciones del análisis

1. **Descriptivo, no causal:** datos agregados por provincia y trimestre. No incluyen ingresos, precios, inversión ni políticas públicas.
2. **Cambio de denominador en 2022:** la penetración usa hogares del Censo 2022 desde ese año, así que la serie no es del todo comparable antes y después.
3. **La penetración no es "% de hogares conectados":** incluye accesos no residenciales y puede superar 100 (CABA).
4. **Sensibilidad a outliers:** las medidas de brecha (razón, rango) cambian mucho con un solo valor extremo.
5. **Localidades sin período:** solo permiten una foto, no una evolución local.
6. **Inconsistencias entre fuentes:** en 165 de 696 pares provincia-trimestre, el total por categorías de velocidad no coincide con el total por tecnologías.
7. **Velocidad nacional estimada:** es un promedio ponderado propio, no un dato publicado.

## 6. Mejoras futuras

- Cruzar con la **EPH** (ingresos) y el **Censo 2022** (ruralidad, densidad) para buscar factores asociados a la brecha.
- Sumar **precios y tarifas**, y **calidad del servicio** (latencia, cortes), para no equiparar velocidad con experiencia.
- Extender la serie a **2025 en adelante** para ver si el estancamiento de la brecha continúa.
- Repetir el análisis **por localidad** si ENACOM publica esos datos con período.
- Automatizar la actualización (CSV → SQLite → Power BI) para seguir los indicadores trimestre a trimestre.

## 7. Guion oral (aprox. 3 minutos, sobre la página 4 de Power BI)

> "Volvemos a la pregunta del principio: ¿la conectividad creció de forma pareja en todo el país? La respuesta corta es **no**.
>
> La hipótesis tenía cuatro partes. Las dos primeras se confirman claramente: los accesos casi se duplicaron, de 6,4 a 11,9 millones, y la fibra pasó del 2 % al 41 %. Un matiz: el cablemódem sigue siendo la tecnología con más accesos.
>
> La tercera parte se confirma solo a medias. Buenos Aires, Córdoba y Santa Fe aportaron el 62 % de las nuevas conexiones, pero ya tenían el 60 % en 2014. Crecieron en proporción a su tamaño, no más rápido que el resto.
>
> La cuarta es la más importante, y la ven en este gráfico. Es el coeficiente de variación de la penetración entre provincias. Entre 2014 y 2020 la brecha se achicó a la mitad, pero desde 2020 la línea está plana: la brecha dejó de cerrarse. Hoy CABA tiene 105 accesos cada 100 hogares y Formosa 32.
>
> Dos aclaraciones. Primero, parte de la mejora inicial se explica por un valor atípico, San Luis en 2014. Segundo, encontramos que las provincias con más fibra no son las de mayor cobertura: modernizar no es lo mismo que incluir.
>
> En cuanto a las limitaciones, estos datos describen pero no explican. No tenemos ingresos, precios ni inversión, y desde 2022 cambió el denominador de hogares por el nuevo censo.
>
> Como mejora futura, proponemos cruzar con la EPH y el Censo para entender por qué la brecha se estancó, y seguir la serie desde 2025."
