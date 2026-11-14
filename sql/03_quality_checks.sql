PRAGMA foreign_keys = ON;

-- Cada duplicado aparece como fila problematica, con su tabla, clave natural y
-- cantidad de repeticiones. LinkIndec se excluye de la clave de localidad.
CREATE VIEW quality_source_duplicate_keys AS
WITH keyed AS (
    SELECT 'stg_accesos_tecnologia_provincia' AS source_table, source_row,
           printf('%s|%s|%s', anio_raw, trimestre_raw, provincia_key) AS natural_key,
           COUNT(*) OVER (PARTITION BY anio_valor, trimestre_valor, provincia_key) AS duplicate_rows
    FROM stg_accesos_tecnologia_provincia
    UNION ALL
    SELECT 'stg_velocidad_provincia', source_row,
           printf('%s|%s|%s', anio_raw, trimestre_raw, provincia_key),
           COUNT(*) OVER (PARTITION BY anio_valor, trimestre_valor, provincia_key)
    FROM stg_velocidad_provincia
    UNION ALL
    SELECT 'stg_penetracion_provincia', source_row,
           printf('%s|%s|%s', anio_raw, trimestre_raw, provincia_key),
           COUNT(*) OVER (PARTITION BY anio_valor, trimestre_valor, provincia_key)
    FROM stg_penetracion_provincia
    UNION ALL
    SELECT 'stg_accesos_categoria_provincia', source_row,
           printf('%s|%s|%s|%s', anio_raw, trimestre_raw, provincia_key, velocidad_raw),
           COUNT(*) OVER (PARTITION BY anio_valor, trimestre_valor, provincia_key, velocidad_raw)
    FROM stg_accesos_categoria_provincia
    UNION ALL
    SELECT 'stg_accesos_tecnologia_localidad', source_row,
           printf('%s|%s|%s|%s', provincia_key, departamento_key,
                  localidad_key, upper(trim(tecnologia_raw))),
           COUNT(*) OVER (PARTITION BY provincia_key, departamento_key,
                          localidad_key, upper(trim(tecnologia_raw)))
    FROM stg_accesos_tecnologia_localidad
    UNION ALL
    SELECT 'stg_accesos_categoria_localidad', source_row,
           printf('%s|%s|%s|%s', provincia_key, departamento_key,
                  localidad_key, velocidad_raw),
           COUNT(*) OVER (PARTITION BY provincia_key, departamento_key,
                          localidad_key, velocidad_raw)
    FROM stg_accesos_categoria_localidad
), counted AS (
    SELECT source_table, source_row, natural_key, duplicate_rows
    FROM keyed
)
SELECT source_table, source_row, natural_key, duplicate_rows
FROM counted
WHERE duplicate_rows > 1;

-- Valores ausentes se distinguen de ceros publicados. Los accesos y métricas
-- ausentes son advertencias y permanecen NULL; texto numérico inválido y
-- medidas negativas son errores.
CREATE VIEW quality_numeric_anomalies AS
WITH numeric_values AS (
    SELECT 'stg_accesos_tecnologia_provincia' AS source_table, source_row,
           'anio' AS field, anio_raw AS raw_value, anio_valor AS parsed_value, 1 AS required_key
    FROM stg_accesos_tecnologia_provincia
    UNION ALL SELECT 'stg_accesos_tecnologia_provincia', source_row, 'trimestre', trimestre_raw, trimestre_valor, 1
    FROM stg_accesos_tecnologia_provincia
    UNION ALL SELECT 'stg_accesos_tecnologia_provincia', source_row, 'adsl', adsl_raw, adsl_valor, 0
    FROM stg_accesos_tecnologia_provincia
    UNION ALL SELECT 'stg_accesos_tecnologia_provincia', source_row, 'cablemodem', cablemodem_raw, cablemodem_valor, 0
    FROM stg_accesos_tecnologia_provincia
    UNION ALL SELECT 'stg_accesos_tecnologia_provincia', source_row, 'fibra_optica', fibra_optica_raw, fibra_optica_valor, 0
    FROM stg_accesos_tecnologia_provincia
    UNION ALL SELECT 'stg_accesos_tecnologia_provincia', source_row, 'wireless', wireless_raw, wireless_valor, 0
    FROM stg_accesos_tecnologia_provincia
    UNION ALL SELECT 'stg_accesos_tecnologia_provincia', source_row, 'otros', otros_raw, otros_valor, 0
    FROM stg_accesos_tecnologia_provincia
    UNION ALL SELECT 'stg_accesos_tecnologia_provincia', source_row, 'total', total_raw, total_valor, 0
    FROM stg_accesos_tecnologia_provincia

    UNION ALL SELECT 'stg_velocidad_provincia', source_row, 'anio', anio_raw, anio_valor, 1
    FROM stg_velocidad_provincia
    UNION ALL SELECT 'stg_velocidad_provincia', source_row, 'trimestre', trimestre_raw, trimestre_valor, 1
    FROM stg_velocidad_provincia
    UNION ALL SELECT 'stg_velocidad_provincia', source_row, 'mbps_media', mbps_raw, mbps_valor, 0
    FROM stg_velocidad_provincia

    UNION ALL SELECT 'stg_penetracion_provincia', source_row, 'anio', anio_raw, anio_valor, 1
    FROM stg_penetracion_provincia
    UNION ALL SELECT 'stg_penetracion_provincia', source_row, 'trimestre', trimestre_raw, trimestre_valor, 1
    FROM stg_penetracion_provincia
    UNION ALL SELECT 'stg_penetracion_provincia', source_row, 'accesos_100_hogares', accesos_100_hogares_raw, accesos_100_hogares_valor, 0
    FROM stg_penetracion_provincia
    UNION ALL SELECT 'stg_penetracion_provincia', source_row, 'accesos_100_habitantes', accesos_100_habitantes_raw, accesos_100_habitantes_valor, 0
    FROM stg_penetracion_provincia

    UNION ALL SELECT 'stg_accesos_categoria_provincia', source_row, 'anio', anio_raw, anio_valor, 1
    FROM stg_accesos_categoria_provincia
    UNION ALL SELECT 'stg_accesos_categoria_provincia', source_row, 'trimestre', trimestre_raw, trimestre_valor, 1
    FROM stg_accesos_categoria_provincia
    UNION ALL SELECT 'stg_accesos_categoria_provincia', source_row, 'accesos', accesos_raw, accesos_valor, 0
    FROM stg_accesos_categoria_provincia

    UNION ALL SELECT 'stg_accesos_tecnologia_localidad', source_row, 'accesos', accesos_raw, accesos_valor, 0
    FROM stg_accesos_tecnologia_localidad
    UNION ALL SELECT 'stg_accesos_categoria_localidad', source_row, 'accesos', accesos_raw, accesos_valor, 0
    FROM stg_accesos_categoria_localidad
), classified AS (
    SELECT *,
           CASE
             WHEN raw_value IS NULL OR length(trim(raw_value)) = 0
               OR lower(trim(raw_value)) IN ('nan', '-', 's/d') THEN 'MISSING'
             WHEN parsed_value IS NULL THEN 'INVALID'
             WHEN parsed_value < 0 THEN 'NEGATIVE'
           END AS anomaly
    FROM numeric_values
)
SELECT source_table, source_row, field, raw_value, anomaly,
       CASE WHEN anomaly = 'MISSING' AND required_key = 0 THEN 'WARNING' ELSE 'ERROR' END AS severity
FROM classified
WHERE anomaly IS NOT NULL;

CREATE VIEW quality_issues AS
SELECT 'DUPLICATE_NATURAL_KEY' AS issue_code, 'ERROR' AS severity,
       source_table, source_row, 'clave_natural' AS field, natural_key AS value,
       printf('La clave aparece en %d filas de staging.', duplicate_rows) AS detail
FROM quality_source_duplicate_keys
UNION ALL
SELECT CASE anomaly
         WHEN 'MISSING' THEN CASE WHEN severity = 'WARNING' THEN 'MISSING_MEASURE' ELSE 'MISSING_REQUIRED_VALUE' END
         WHEN 'INVALID' THEN 'INVALID_NUMERIC'
         WHEN 'NEGATIVE' THEN 'NEGATIVE_VALUE'
       END,
       severity, source_table, source_row, field, raw_value,
       'Valor numerico de origen: ' || anomaly
FROM quality_numeric_anomalies
UNION ALL
SELECT 'MISSING_REQUIRED_FIELD', 'ERROR', source_table, source_row,
       field, value, 'El campo requerido esta vacio.'
FROM (
    SELECT 'stg_accesos_tecnologia_provincia' AS source_table, source_row,
           'provincia' AS field, provincia_raw AS value FROM stg_accesos_tecnologia_provincia
    UNION ALL SELECT 'stg_velocidad_provincia', source_row, 'provincia', provincia_raw FROM stg_velocidad_provincia
    UNION ALL SELECT 'stg_penetracion_provincia', source_row, 'provincia', provincia_raw FROM stg_penetracion_provincia
    UNION ALL SELECT 'stg_accesos_categoria_provincia', source_row, 'provincia', provincia_raw FROM stg_accesos_categoria_provincia
    UNION ALL SELECT 'stg_accesos_tecnologia_localidad', source_row, 'provincia', provincia_raw FROM stg_accesos_tecnologia_localidad
    UNION ALL SELECT 'stg_accesos_categoria_localidad', source_row, 'provincia', provincia_raw FROM stg_accesos_categoria_localidad
) AS required_provinces
WHERE length(trim(value)) = 0
UNION ALL
SELECT 'INVALID_PERIOD', 'ERROR', source_table, source_row, 'trimestre', trimestre_raw,
       'El trimestre debe estar entre 1 y 4.'
FROM (
    SELECT 'stg_accesos_tecnologia_provincia' AS source_table, source_row, trimestre_raw, trimestre_valor
    FROM stg_accesos_tecnologia_provincia
    UNION ALL SELECT 'stg_velocidad_provincia', source_row, trimestre_raw, trimestre_valor
    FROM stg_velocidad_provincia
    UNION ALL SELECT 'stg_penetracion_provincia', source_row, trimestre_raw, trimestre_valor
    FROM stg_penetracion_provincia
    UNION ALL SELECT 'stg_accesos_categoria_provincia', source_row, trimestre_raw, trimestre_valor
    FROM stg_accesos_categoria_provincia
) AS period_quarters
WHERE trimestre_valor NOT BETWEEN 1 AND 4
UNION ALL
SELECT 'MISSING_REQUIRED_FIELD', 'ERROR', source_table, source_row, field, value,
       'El campo geografico requerido esta vacio.'
FROM (
    SELECT 'stg_accesos_tecnologia_localidad' AS source_table, source_row,
           'departamento' AS field, departamento_raw AS value FROM stg_accesos_tecnologia_localidad
    UNION ALL SELECT 'stg_accesos_tecnologia_localidad', source_row, 'localidad', localidad_raw
    FROM stg_accesos_tecnologia_localidad
    UNION ALL SELECT 'stg_accesos_tecnologia_localidad', source_row, 'tecnologia', tecnologia_raw
    FROM stg_accesos_tecnologia_localidad
    UNION ALL SELECT 'stg_accesos_categoria_localidad', source_row, 'departamento', departamento_raw
    FROM stg_accesos_categoria_localidad
    UNION ALL SELECT 'stg_accesos_categoria_localidad', source_row, 'localidad', localidad_raw
    FROM stg_accesos_categoria_localidad
) AS required_locality_fields
WHERE length(trim(value)) = 0
UNION ALL
SELECT 'MISSING_REQUIRED_FIELD', 'ERROR', source_table, source_row,
       'categoria_velocidad', value, 'La etiqueta original esta vacia.'
FROM (
    SELECT 'stg_accesos_categoria_provincia' AS source_table, source_row,
           velocidad_raw AS value
    FROM stg_accesos_categoria_provincia
    UNION ALL SELECT 'stg_accesos_categoria_localidad', source_row, velocidad_raw
    FROM stg_accesos_categoria_localidad
) AS required_speed_labels
WHERE length(trim(value)) = 0
UNION ALL
SELECT 'UNMAPPED_PROVINCE', 'ERROR', 'stg_accesos_tecnologia_provincia', source_row,
       'provincia', provincia_raw, 'No existe una equivalencia en dim_provincia_alias.'
FROM stg_accesos_tecnologia_provincia AS s
WHERE NOT EXISTS (SELECT 1 FROM dim_provincia_alias AS a WHERE a.alias_key = s.provincia_key)
UNION ALL
SELECT 'UNMAPPED_PROVINCE', 'ERROR', 'stg_velocidad_provincia', source_row,
       'provincia', provincia_raw, 'No existe una equivalencia en dim_provincia_alias.'
FROM stg_velocidad_provincia AS s
WHERE NOT EXISTS (SELECT 1 FROM dim_provincia_alias AS a WHERE a.alias_key = s.provincia_key)
UNION ALL
SELECT 'UNMAPPED_PROVINCE', 'ERROR', 'stg_penetracion_provincia', source_row,
       'provincia', provincia_raw, 'No existe una equivalencia en dim_provincia_alias.'
FROM stg_penetracion_provincia AS s
WHERE NOT EXISTS (SELECT 1 FROM dim_provincia_alias AS a WHERE a.alias_key = s.provincia_key)
UNION ALL
SELECT 'UNMAPPED_PROVINCE', 'ERROR', 'stg_accesos_categoria_provincia', source_row,
       'provincia', provincia_raw, 'No existe una equivalencia en dim_provincia_alias.'
FROM stg_accesos_categoria_provincia AS s
WHERE NOT EXISTS (SELECT 1 FROM dim_provincia_alias AS a WHERE a.alias_key = s.provincia_key)
UNION ALL
SELECT 'UNMAPPED_PROVINCE', 'ERROR', 'stg_accesos_tecnologia_localidad', source_row,
       'provincia', provincia_raw, 'No existe una equivalencia en dim_provincia_alias.'
FROM stg_accesos_tecnologia_localidad AS s
WHERE NOT EXISTS (SELECT 1 FROM dim_provincia_alias AS a WHERE a.alias_key = s.provincia_key)
UNION ALL
SELECT 'UNMAPPED_PROVINCE', 'ERROR', 'stg_accesos_categoria_localidad', source_row,
       'provincia', provincia_raw, 'No existe una equivalencia en dim_provincia_alias.'
FROM stg_accesos_categoria_localidad AS s
WHERE NOT EXISTS (SELECT 1 FROM dim_provincia_alias AS a WHERE a.alias_key = s.provincia_key)
UNION ALL
SELECT 'UNKNOWN_TECHNOLOGY', 'ERROR', 'stg_accesos_tecnologia_localidad', s.source_row,
       'tecnologia', s.tecnologia_raw, 'La etiqueta no tiene equivalencia en dim_tecnologia_alias.'
FROM stg_accesos_tecnologia_localidad AS s
WHERE length(trim(s.tecnologia_raw)) > 0
  AND NOT EXISTS (
      SELECT 1 FROM dim_tecnologia_alias AS a
      WHERE a.alias_key = upper(trim(s.tecnologia_raw))
  );

-- Cobertura de los archivos históricos. Las localidades no tienen período y
-- por eso no aparecen como series temporales.
CREATE VIEW quality_period_coverage AS
SELECT 'accesos_tecnologia_provincia' AS source_dataset, 44 AS expected_periods,
       COUNT(DISTINCT anio_valor * 10 + trimestre_valor) AS actual_periods,
       COUNT(*) AS rows_in_scope, MIN(anio_valor) AS first_year, MAX(anio_valor) AS last_year
FROM stg_accesos_tecnologia_provincia WHERE anio_valor BETWEEN 2014 AND 2024
UNION ALL
SELECT 'velocidad_provincia', 44, COUNT(DISTINCT anio_valor * 10 + trimestre_valor),
       COUNT(*), MIN(anio_valor), MAX(anio_valor)
FROM stg_velocidad_provincia WHERE anio_valor BETWEEN 2014 AND 2024
UNION ALL
SELECT 'penetracion_provincia', 44, COUNT(DISTINCT anio_valor * 10 + trimestre_valor),
       COUNT(*), MIN(anio_valor), MAX(anio_valor)
FROM stg_penetracion_provincia WHERE anio_valor BETWEEN 2014 AND 2024
UNION ALL
SELECT 'accesos_categoria_provincia', 29, COUNT(DISTINCT anio_valor * 10 + trimestre_valor),
       COUNT(*), MIN(anio_valor), MAX(anio_valor)
FROM stg_accesos_categoria_provincia WHERE anio_valor BETWEEN 2014 AND 2024
UNION ALL
SELECT 'accesos_tecnologia_localidad', NULL, NULL, COUNT(*), NULL, NULL
FROM stg_accesos_tecnologia_localidad
UNION ALL
SELECT 'accesos_categoria_localidad', NULL, NULL, COUNT(*), NULL, NULL
FROM stg_accesos_categoria_localidad;

CREATE VIEW quality_period_count_issues AS
SELECT source_dataset, expected_periods, actual_periods, rows_in_scope
FROM quality_period_coverage
WHERE expected_periods IS NOT NULL AND actual_periods <> expected_periods;

-- Registros fuera del alcance se muestran como exclusiones esperadas del modelo
-- histórico; no se convierten ni se eliminan de las tablas staging.
CREATE VIEW quality_out_of_scope_source_rows AS
SELECT 'accesos_tecnologia_provincia' AS source_dataset, source_row,
       anio_raw, trimestre_raw, provincia_raw
FROM stg_accesos_tecnologia_provincia
WHERE anio_valor IS NOT NULL AND anio_valor NOT BETWEEN 2014 AND 2024
UNION ALL
SELECT 'velocidad_provincia', source_row, anio_raw, trimestre_raw, provincia_raw
FROM stg_velocidad_provincia
WHERE anio_valor IS NOT NULL AND anio_valor NOT BETWEEN 2014 AND 2024
UNION ALL
SELECT 'penetracion_provincia', source_row, anio_raw, trimestre_raw, provincia_raw
FROM stg_penetracion_provincia
WHERE anio_valor IS NOT NULL AND anio_valor NOT BETWEEN 2014 AND 2024
UNION ALL
SELECT 'accesos_categoria_provincia', source_row, anio_raw, trimestre_raw, provincia_raw
FROM stg_accesos_categoria_provincia
WHERE anio_valor IS NOT NULL AND anio_valor NOT BETWEEN 2014 AND 2024;

CREATE VIEW quality_provincia_periodo_counts AS
SELECT 'accesos_tecnologia_provincia' AS source_dataset, anio, trimestre,
       COUNT(DISTINCT provincia_id) AS provincias
FROM fact_accesos_provincia GROUP BY anio, trimestre
UNION ALL
SELECT 'velocidad_provincia', anio, trimestre, COUNT(DISTINCT provincia_id)
FROM fact_velocidad_provincia GROUP BY anio, trimestre
UNION ALL
SELECT 'penetracion_provincia', anio, trimestre, COUNT(DISTINCT provincia_id)
FROM fact_penetracion_provincia GROUP BY anio, trimestre
UNION ALL
SELECT 'accesos_categoria_provincia', anio, trimestre, COUNT(DISTINCT provincia_id)
FROM fact_accesos_categoria_provincia GROUP BY anio, trimestre;

CREATE VIEW quality_missing_provincia_periodo AS
SELECT 'accesos_tecnologia_provincia' AS source_dataset, d.anio, d.trimestre, p.provincia
FROM dim_periodo AS d CROSS JOIN dim_provincia AS p
WHERE NOT EXISTS (
    SELECT 1 FROM fact_accesos_provincia AS f
    WHERE f.anio = d.anio AND f.trimestre = d.trimestre AND f.provincia_id = p.provincia_id
)
UNION ALL
SELECT 'velocidad_provincia', d.anio, d.trimestre, p.provincia
FROM dim_periodo AS d CROSS JOIN dim_provincia AS p
WHERE NOT EXISTS (
    SELECT 1 FROM fact_velocidad_provincia AS f
    WHERE f.anio = d.anio AND f.trimestre = d.trimestre AND f.provincia_id = p.provincia_id
)
UNION ALL
SELECT 'penetracion_provincia', d.anio, d.trimestre, p.provincia
FROM dim_periodo AS d CROSS JOIN dim_provincia AS p
WHERE NOT EXISTS (
    SELECT 1 FROM fact_penetracion_provincia AS f
    WHERE f.anio = d.anio AND f.trimestre = d.trimestre AND f.provincia_id = p.provincia_id
)
UNION ALL
SELECT 'accesos_categoria_provincia', d.anio, d.trimestre, p.provincia
FROM dim_periodo AS d CROSS JOIN dim_provincia AS p
WHERE (d.anio > 2017 OR (d.anio = 2017 AND d.trimestre >= 4))
  AND NOT EXISTS (
      SELECT 1 FROM fact_accesos_categoria_provincia AS f
      WHERE f.anio = d.anio AND f.trimestre = d.trimestre AND f.provincia_id = p.provincia_id
  );

-- La suma se compara contra el Total informado para la misma provincia y
-- período. La consulta devuelve las filas discrepantes, incluidos NULLs.
CREATE VIEW quality_technology_total_mismatches AS
WITH technology_sums AS (
    SELECT anio, trimestre, provincia_id,
           COUNT(*) AS technology_rows,
           COUNT(accesos) AS nonnull_technology_values,
           SUM(accesos) AS technology_sum
    FROM fact_accesos_tecnologia
    GROUP BY anio, trimestre, provincia_id
)
SELECT f.anio, f.trimestre, p.provincia, f.accesos_total,
       s.technology_rows, s.nonnull_technology_values, s.technology_sum
FROM fact_accesos_provincia AS f
JOIN dim_provincia AS p ON p.provincia_id = f.provincia_id
LEFT JOIN technology_sums AS s
  ON s.anio = f.anio AND s.trimestre = f.trimestre AND s.provincia_id = f.provincia_id
WHERE f.accesos_total IS NULL
   OR s.technology_rows IS NULL OR s.technology_rows <> 5
   OR s.nonnull_technology_values <> 5
   OR s.technology_sum <> f.accesos_total;

-- Diagnóstico independiente: la suma de categorías de velocidad puede diferir
-- del Total del archivo de tecnologías. Se muestran las filas originales y no
-- se ajusta ninguna de las dos fuentes para forzar coincidencias.
CREATE VIEW quality_category_total_mismatches AS
WITH category_sums AS (
    SELECT anio, trimestre, provincia_id,
           COUNT(*) AS category_rows,
           COUNT(accesos) AS nonnull_category_values,
           SUM(accesos) AS category_sum
    FROM fact_accesos_categoria_provincia
    GROUP BY anio, trimestre, provincia_id
)
SELECT d.periodo, p.provincia, c.category_rows, c.nonnull_category_values,
       c.category_sum, a.accesos_total,
       c.category_sum - a.accesos_total AS diferencia
FROM category_sums AS c
JOIN dim_periodo AS d ON d.anio = c.anio AND d.trimestre = c.trimestre
JOIN dim_provincia AS p ON p.provincia_id = c.provincia_id
JOIN fact_accesos_provincia AS a
  ON a.anio = c.anio AND a.trimestre = c.trimestre AND a.provincia_id = c.provincia_id
WHERE c.category_sum IS NULL OR a.accesos_total IS NULL
   OR c.category_sum <> a.accesos_total
   OR c.nonnull_category_values <> c.category_rows;

CREATE VIEW quality_category_period_mismatches AS
WITH category_period_totals AS (
    SELECT anio, trimestre, SUM(accesos) AS category_total
    FROM fact_accesos_categoria_provincia
    GROUP BY anio, trimestre
), reported_period_totals AS (
    SELECT anio, trimestre, SUM(accesos_total) AS reported_total
    FROM fact_accesos_provincia
    GROUP BY anio, trimestre
)
SELECT d.periodo, c.category_total, a.reported_total,
       c.category_total - a.reported_total AS diferencia
FROM category_period_totals AS c
JOIN reported_period_totals AS a USING (anio, trimestre)
JOIN dim_periodo AS d USING (anio, trimestre)
WHERE c.category_total IS NULL OR a.reported_total IS NULL
   OR c.category_total <> a.reported_total;

-- Localidades presentes en una u otra fuente y códigos LinkIndec reutilizados.
CREATE VIEW quality_locality_source_coverage AS
WITH technology_localities AS (
    SELECT DISTINCT localidad_id FROM fact_accesos_tecnologia_localidad
), speed_localities AS (
    SELECT DISTINCT localidad_id FROM fact_accesos_categoria_localidad
)
SELECT (SELECT COUNT(*) FROM technology_localities) AS tecnologia_localidad,
       (SELECT COUNT(*) FROM speed_localities) AS velocidad_localidad,
       (SELECT COUNT(*) FROM technology_localities t JOIN speed_localities s USING (localidad_id)) AS compartidas,
       (SELECT COUNT(*) FROM technology_localities t LEFT JOIN speed_localities s USING (localidad_id)
        WHERE s.localidad_id IS NULL) AS solo_tecnologia,
       (SELECT COUNT(*) FROM speed_localities s LEFT JOIN technology_localities t USING (localidad_id)
        WHERE t.localidad_id IS NULL) AS solo_velocidad;

CREATE VIEW quality_linkindec_cross_source_mismatches AS
WITH technology_codes AS (
    SELECT DISTINCT p.provincia_id, s.departamento_key, s.localidad_key,
           trim(s.departamento_raw) AS departamento,
           trim(s.localidad_raw) AS localidad, s.linkindec_raw
    FROM stg_accesos_tecnologia_localidad AS s
    JOIN dim_provincia_alias AS a ON a.alias_key = s.provincia_key
    JOIN dim_provincia AS p ON p.provincia_id = a.provincia_id
), speed_codes AS (
    SELECT DISTINCT p.provincia_id, s.departamento_key, s.localidad_key,
           trim(s.departamento_raw) AS departamento,
           trim(s.localidad_raw) AS localidad, s.linkindec_raw
    FROM stg_accesos_categoria_localidad AS s
    JOIN dim_provincia_alias AS a ON a.alias_key = s.provincia_key
    JOIN dim_provincia AS p ON p.provincia_id = a.provincia_id
)
SELECT p.provincia, t.departamento, t.localidad,
       t.linkindec_raw AS linkindec_tecnologia,
       s.linkindec_raw AS linkindec_velocidad
FROM technology_codes AS t
JOIN speed_codes AS s USING (provincia_id, departamento_key, localidad_key)
JOIN dim_provincia AS p ON p.provincia_id = t.provincia_id
WHERE t.linkindec_raw <> s.linkindec_raw;

CREATE VIEW quality_linkindec_collisions AS
WITH source_codes AS (
    SELECT 'tecnologia_localidad' AS source_dataset, s.linkindec_raw,
           l.localidad_id, p.provincia, l.departamento, l.localidad
    FROM stg_accesos_tecnologia_localidad AS s
    JOIN dim_provincia_alias AS a ON a.alias_key = s.provincia_key
    JOIN dim_provincia AS p ON p.provincia_id = a.provincia_id
    JOIN dim_localidad AS l ON l.provincia_id = p.provincia_id
      AND l.departamento_key = s.departamento_key AND l.localidad_key = s.localidad_key
    UNION ALL
    SELECT 'velocidad_localidad', s.linkindec_raw,
           l.localidad_id, p.provincia, l.departamento, l.localidad
    FROM stg_accesos_categoria_localidad AS s
    JOIN dim_provincia_alias AS a ON a.alias_key = s.provincia_key
    JOIN dim_provincia AS p ON p.provincia_id = a.provincia_id
    JOIN dim_localidad AS l ON l.provincia_id = p.provincia_id
      AND l.departamento_key = s.departamento_key AND l.localidad_key = s.localidad_key
), distinct_assignments AS (
    SELECT DISTINCT source_dataset, linkindec_raw, localidad_id, provincia, departamento, localidad
    FROM source_codes
)
SELECT source_dataset, linkindec_raw, COUNT(*) AS localidades,
       GROUP_CONCAT(provincia || ' / ' || departamento || ' / ' || localidad, '; ') AS ejemplos
FROM distinct_assignments
GROUP BY source_dataset, linkindec_raw
HAVING COUNT(*) > 1;

CREATE VIEW quality_speed_category_labels AS
SELECT 'provincial' AS source_dataset, c.etiqueta_original,
       COUNT(*) AS filas, SUM(f.accesos) AS accesos
FROM fact_accesos_categoria_provincia AS f
JOIN dim_categoria_velocidad AS c
  ON c.categoria_velocidad_id = f.categoria_velocidad_id
GROUP BY c.categoria_velocidad_id, c.etiqueta_original
UNION ALL
SELECT 'localidad', c.etiqueta_original, COUNT(*), SUM(f.accesos)
FROM fact_accesos_categoria_localidad AS f
JOIN dim_categoria_velocidad AS c
  ON c.categoria_velocidad_id = f.categoria_velocidad_id
GROUP BY c.categoria_velocidad_id, c.etiqueta_original;

-- Ninguna tabla histórica definitiva debe contener períodos fuera del alcance.
CREATE VIEW quality_fact_out_of_scope_rows AS
SELECT 'fact_accesos_provincia' AS source_table, anio, trimestre, provincia_id
FROM fact_accesos_provincia WHERE anio NOT BETWEEN 2014 AND 2024
UNION ALL
SELECT 'fact_accesos_tecnologia', anio, trimestre, provincia_id
FROM fact_accesos_tecnologia WHERE anio NOT BETWEEN 2014 AND 2024
UNION ALL
SELECT 'fact_velocidad_provincia', anio, trimestre, provincia_id
FROM fact_velocidad_provincia WHERE anio NOT BETWEEN 2014 AND 2024
UNION ALL
SELECT 'fact_penetracion_provincia', anio, trimestre, provincia_id
FROM fact_penetracion_provincia WHERE anio NOT BETWEEN 2014 AND 2024
UNION ALL
SELECT 'fact_accesos_categoria_provincia', anio, trimestre, provincia_id
FROM fact_accesos_categoria_provincia WHERE anio NOT BETWEEN 2014 AND 2024;
