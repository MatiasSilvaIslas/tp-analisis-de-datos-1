-- QUERY 1: Evolución de accesos totales por trimestre
-- Pregunta: ¿Cómo evolucionó el total de accesos de Internet fijo en Argentina?
-- Lógica: suma el total publicado para las jurisdicciones del mismo período.
-- Tablas: fact_accesos_provincia, dim_periodo.
-- Interpretación: cada fila es una existencia trimestral, no una suma acumulada.
SELECT d.anio, d.trimestre, d.periodo,
       SUM(f.accesos_total) AS accesos_totales
FROM fact_accesos_provincia AS f
JOIN dim_periodo AS d ON d.anio = f.anio AND d.trimestre = f.trimestre
GROUP BY d.anio, d.trimestre, d.periodo
ORDER BY d.anio, d.trimestre;

-- QUERY 2: Participación de fibra óptica
-- Pregunta: ¿Qué porcentaje del total corresponde a fibra óptica en cada período?
-- Lógica: agrega fibra y total por separado antes de unirlos para evitar duplicar
-- el denominador al combinar hechos con distinta granularidad.
-- Tablas: fact_accesos_tecnologia, fact_accesos_provincia, dim_tecnologia, dim_periodo.
-- Interpretación: numerador y denominador incluyen las mismas provincias y fechas.
WITH totals AS (
    SELECT anio, trimestre, SUM(accesos_total) AS accesos_totales
    FROM fact_accesos_provincia
    GROUP BY anio, trimestre
), fiber AS (
    SELECT f.anio, f.trimestre, SUM(f.accesos) AS accesos_fibra
    FROM fact_accesos_tecnologia AS f
    JOIN dim_tecnologia AS t ON t.tecnologia_id = f.tecnologia_id
    WHERE t.tecnologia = 'Fibra Optica'
    GROUP BY f.anio, f.trimestre
)
SELECT d.anio, d.trimestre, d.periodo, f.accesos_fibra, t.accesos_totales,
       ROUND(100.0 * f.accesos_fibra / NULLIF(t.accesos_totales, 0), 2) AS participacion_fibra_pct
FROM totals AS t
JOIN fiber AS f USING (anio, trimestre)
JOIN dim_periodo AS d USING (anio, trimestre)
ORDER BY d.anio, d.trimestre;

-- QUERY 3: Comparación de tecnologías entre 2014-T1 y 2024-T4
-- Pregunta: ¿Cómo cambió cada tecnología entre ambos trimestres?
-- Lógica: condicionales agregados calculan valores iniciales/finales y variaciones.
-- Tablas: fact_accesos_tecnologia, dim_tecnologia, dim_periodo.
-- Interpretación: la variación porcentual es NULL si el valor inicial es cero.
SELECT t.tecnologia,
       SUM(CASE WHEN d.periodo = '2014-T1' THEN f.accesos END) AS accesos_2014_t1,
       SUM(CASE WHEN d.periodo = '2024-T4' THEN f.accesos END) AS accesos_2024_t4,
       SUM(CASE WHEN d.periodo = '2024-T4' THEN f.accesos END)
         - SUM(CASE WHEN d.periodo = '2014-T1' THEN f.accesos END) AS variacion_absoluta,
       ROUND(
           100.0 * (
               SUM(CASE WHEN d.periodo = '2024-T4' THEN f.accesos END)
               - SUM(CASE WHEN d.periodo = '2014-T1' THEN f.accesos END)
           ) / NULLIF(SUM(CASE WHEN d.periodo = '2014-T1' THEN f.accesos END), 0),
           2
       ) AS variacion_porcentual
FROM fact_accesos_tecnologia AS f
JOIN dim_tecnologia AS t ON t.tecnologia_id = f.tecnologia_id
JOIN dim_periodo AS d ON d.anio = f.anio AND d.trimestre = f.trimestre
GROUP BY t.tecnologia
HAVING COUNT(DISTINCT CASE WHEN d.periodo IN ('2014-T1', '2024-T4') THEN d.periodo END) = 2
ORDER BY t.tecnologia;

-- QUERY 4: Ranking de penetración provincial por hogar
-- Pregunta: ¿Qué provincias registran más accesos cada 100 hogares en 2024-T4?
-- Lógica: ordena el indicador publicado por ENACOM en el último trimestre de 2024.
-- Tablas: fact_penetracion_provincia, dim_provincia, dim_periodo.
-- Interpretación: es una tasa de accesos, no un porcentaje de hogares únicos.
SELECT p.provincia, d.periodo, f.accesos_100_hogares,
       f.accesos_100_habitantes
FROM fact_penetracion_provincia AS f
JOIN dim_provincia AS p ON p.provincia_id = f.provincia_id
JOIN dim_periodo AS d ON d.anio = f.anio AND d.trimestre = f.trimestre
WHERE d.periodo = '2024-T4'
ORDER BY f.accesos_100_hogares DESC, p.provincia
LIMIT 24;

-- QUERY 5: Aumento absoluto provincial de fibra óptica
-- Pregunta: ¿Qué provincias sumaron más accesos de fibra entre los extremos?
-- Lógica: agrega cada extremo y ordena primero por el aumento absoluto.
-- Tablas: fact_accesos_tecnologia, dim_tecnologia, dim_provincia, dim_periodo.
-- Interpretación: si el valor inicial es cero, el porcentaje queda NULL y se
-- conserva la variación absoluta para no dividir por cero.
WITH fiber_by_province AS (
    SELECT f.provincia_id,
           SUM(CASE WHEN d.periodo = '2014-T1' THEN f.accesos END) AS accesos_inicio,
           SUM(CASE WHEN d.periodo = '2024-T4' THEN f.accesos END) AS accesos_final
    FROM fact_accesos_tecnologia AS f
    JOIN dim_tecnologia AS t ON t.tecnologia_id = f.tecnologia_id
    JOIN dim_periodo AS d ON d.anio = f.anio AND d.trimestre = f.trimestre
    WHERE t.tecnologia = 'Fibra Optica'
    GROUP BY f.provincia_id
)
SELECT p.provincia, b.accesos_inicio, b.accesos_final,
       b.accesos_final - b.accesos_inicio AS variacion_absoluta,
       ROUND(100.0 * (b.accesos_final - b.accesos_inicio)
             / NULLIF(b.accesos_inicio, 0), 2) AS variacion_porcentual
FROM fiber_by_province AS b
JOIN dim_provincia AS p ON p.provincia_id = b.provincia_id
ORDER BY variacion_absoluta DESC, variacion_porcentual DESC NULLS LAST, p.provincia;

-- QUERY 6: Distribución provincial por etiquetas de velocidad
-- Pregunta: ¿Cómo se distribuyen los accesos entre las etiquetas informadas?
-- Lógica: toma el último período disponible y agrega primero por etiqueta.
-- Tablas: fact_accesos_categoria_provincia, dim_categoria_velocidad, dim_periodo.
-- Interpretación: etiqueta_original se conserva como texto; no se asignan rangos
-- ni unidades que los CSV no documentan.
WITH latest_period AS (
    SELECT anio, trimestre
    FROM fact_accesos_categoria_provincia
    ORDER BY anio DESC, trimestre DESC
    LIMIT 1
), by_category AS (
    SELECT f.categoria_velocidad_id, SUM(f.accesos) AS accesos
    FROM fact_accesos_categoria_provincia AS f
    JOIN latest_period AS l USING (anio, trimestre)
    GROUP BY f.categoria_velocidad_id
), total AS (
    SELECT SUM(accesos) AS accesos_totales FROM by_category
)
SELECT d.periodo, c.etiqueta_original, b.accesos,
       ROUND(100.0 * b.accesos / NULLIF(t.accesos_totales, 0), 4) AS participacion_pct
FROM by_category AS b
JOIN dim_categoria_velocidad AS c
  ON c.categoria_velocidad_id = b.categoria_velocidad_id
CROSS JOIN latest_period AS l
JOIN dim_periodo AS d ON d.anio = l.anio AND d.trimestre = l.trimestre
CROSS JOIN total AS t
ORDER BY b.accesos DESC, c.etiqueta_original;

-- QUERY 7: Ranking transversal de localidades
-- Pregunta: ¿Qué localidades tienen más accesos registrados en el archivo territorial?
-- Lógica: suma tecnologías por clave compuesta de localidad y ordena el total.
-- Tablas: fact_accesos_tecnologia_localidad, dim_localidad, dim_provincia.
-- Interpretación: el archivo no contiene período; el ranking no es una serie
-- histórica ni se atribuye a 2024-T4.
SELECT p.provincia, l.departamento, l.localidad,
       SUM(f.accesos) AS accesos_registrados
FROM fact_accesos_tecnologia_localidad AS f
JOIN dim_localidad AS l ON l.localidad_id = f.localidad_id
JOIN dim_provincia AS p ON p.provincia_id = l.provincia_id
WHERE f.accesos IS NOT NULL
GROUP BY l.localidad_id, p.provincia, l.departamento, l.localidad
HAVING SUM(f.accesos) > 0
ORDER BY accesos_registrados DESC, p.provincia, l.departamento, l.localidad
LIMIT 20;

-- QUERY 8: Evolución de velocidad media ponderada estimada
-- Pregunta: ¿Cómo evolucionó la velocidad media estimada para Argentina?
-- Lógica: SUM(velocidad provincial × accesos provinciales) / SUM(accesos).
-- Tablas: fact_velocidad_provincia, fact_accesos_provincia, dim_periodo.
-- Interpretación: estimación del proyecto, no valor nacional publicado
-- directamente por ENACOM. Se usan pesos del mismo período.
SELECT d.anio, d.trimestre, d.periodo,
       SUM(v.mbps_media * a.accesos_total) / NULLIF(SUM(a.accesos_total), 0)
           AS velocidad_media_ponderada_estimada_mbps,
       COUNT(*) AS provincias_ponderadas
FROM fact_velocidad_provincia AS v
JOIN fact_accesos_provincia AS a
  ON a.anio = v.anio AND a.trimestre = v.trimestre AND a.provincia_id = v.provincia_id
JOIN dim_periodo AS d ON d.anio = v.anio AND d.trimestre = v.trimestre
WHERE v.mbps_media IS NOT NULL
  AND a.accesos_total IS NOT NULL
  AND a.accesos_total > 0
GROUP BY d.anio, d.trimestre, d.periodo
ORDER BY d.anio, d.trimestre;
