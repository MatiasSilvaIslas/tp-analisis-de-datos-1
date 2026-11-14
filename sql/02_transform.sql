PRAGMA foreign_keys = ON;
BEGIN;

-- El calendario esperado se genera de forma explícita para que los controles
-- detecten períodos faltantes aun si faltara un trimestre en los archivos.
WITH RECURSIVE periodos(anio, trimestre) AS (
    SELECT 2014, 1
    UNION ALL
    SELECT CASE WHEN trimestre = 4 THEN anio + 1 ELSE anio END,
           CASE WHEN trimestre = 4 THEN 1 ELSE trimestre + 1 END
    FROM periodos
    WHERE anio < 2024 OR trimestre < 4
)
INSERT INTO dim_periodo (periodo_id, anio, trimestre, periodo)
SELECT (anio - 2014) * 4 + trimestre,
       anio,
       trimestre,
       printf('%04d-T%d', anio, trimestre)
FROM periodos;

-- Las categorías se conservan exactamente como etiquetas del CSV. No se les
-- asignan unidades ni límites que no aparecen documentados en los archivos.
INSERT INTO dim_categoria_velocidad (etiqueta_original)
SELECT velocidad_raw
FROM stg_accesos_categoria_provincia
WHERE length(trim(velocidad_raw)) > 0
UNION
SELECT velocidad_raw
FROM stg_accesos_categoria_localidad
WHERE length(trim(velocidad_raw)) > 0;

-- La dimensión usa claves territoriales con trim + NFC + casefold; diferencias
-- de mayúsculas no crean otras localidades. Se prefiere la primera grafía del
-- CSV de tecnologías y se conservan todos los textos originales en staging.
-- LinkIndec queda fuera de la clave porque no identifica localidades de forma única.
WITH source_localities AS (
    SELECT p.provincia_id, s.departamento_key, s.localidad_key,
           trim(s.departamento_raw) AS departamento,
           trim(s.localidad_raw) AS localidad, 1 AS source_priority, s.source_row
    FROM stg_accesos_tecnologia_localidad AS s
    JOIN dim_provincia_alias AS a ON a.alias_key = s.provincia_key
    JOIN dim_provincia AS p ON p.provincia_id = a.provincia_id
    WHERE length(trim(s.departamento_key)) > 0
      AND length(trim(s.localidad_key)) > 0
    UNION ALL
    SELECT p.provincia_id, s.departamento_key, s.localidad_key,
           trim(s.departamento_raw), trim(s.localidad_raw), 2, s.source_row
    FROM stg_accesos_categoria_localidad AS s
    JOIN dim_provincia_alias AS a ON a.alias_key = s.provincia_key
    JOIN dim_provincia AS p ON p.provincia_id = a.provincia_id
    WHERE length(trim(s.departamento_key)) > 0
      AND length(trim(s.localidad_key)) > 0
), ranked_localities AS (
    SELECT *, ROW_NUMBER() OVER (
        PARTITION BY provincia_id, departamento_key, localidad_key
        ORDER BY source_priority, source_row
    ) AS display_priority
    FROM source_localities
)
INSERT INTO dim_localidad
    (provincia_id, departamento_key, localidad_key, departamento, localidad)
SELECT provincia_id, departamento_key, localidad_key, departamento, localidad
FROM ranked_localities
WHERE display_priority = 1;

-- Total provincial informado y composición tecnológica se guardan en hechos
-- separados para que las consultas puedan comparar ambos valores sin duplicar
-- el total al sumar tecnologías.
INSERT INTO fact_accesos_provincia
    (anio, trimestre, provincia_id, accesos_total, source_row)
SELECT s.anio_valor, s.trimestre_valor, p.provincia_id, s.total_valor, s.source_row
FROM stg_accesos_tecnologia_provincia AS s
JOIN dim_periodo AS d
  ON d.anio = s.anio_valor AND d.trimestre = s.trimestre_valor
JOIN dim_provincia_alias AS a ON a.alias_key = s.provincia_key
JOIN dim_provincia AS p ON p.provincia_id = a.provincia_id;

-- Unpivot de las cinco columnas de tecnologías provinciales. El valor NULL de
-- una observación permanece NULL; el cero publicado permanece como cero.
WITH tecnologia_provincia AS (
    SELECT source_row, anio_valor AS anio, trimestre_valor AS trimestre,
           provincia_key, 'ADSL' AS tecnologia, adsl_valor AS accesos
    FROM stg_accesos_tecnologia_provincia
    UNION ALL
    SELECT source_row, anio_valor, trimestre_valor, provincia_key,
           'Cablemodem', cablemodem_valor
    FROM stg_accesos_tecnologia_provincia
    UNION ALL
    SELECT source_row, anio_valor, trimestre_valor, provincia_key,
           'Fibra Optica', fibra_optica_valor
    FROM stg_accesos_tecnologia_provincia
    UNION ALL
    SELECT source_row, anio_valor, trimestre_valor, provincia_key,
           'Wireless', wireless_valor
    FROM stg_accesos_tecnologia_provincia
    UNION ALL
    SELECT source_row, anio_valor, trimestre_valor, provincia_key,
           'Otros', otros_valor
    FROM stg_accesos_tecnologia_provincia
)
INSERT INTO fact_accesos_tecnologia
    (anio, trimestre, provincia_id, tecnologia_id, accesos, source_row)
SELECT t.anio, t.trimestre, p.provincia_id, x.tecnologia_id, t.accesos, t.source_row
FROM tecnologia_provincia AS t
JOIN dim_periodo AS d ON d.anio = t.anio AND d.trimestre = t.trimestre
JOIN dim_provincia_alias AS a ON a.alias_key = t.provincia_key
JOIN dim_provincia AS p ON p.provincia_id = a.provincia_id
JOIN dim_tecnologia AS x ON x.tecnologia = t.tecnologia;

INSERT INTO fact_velocidad_provincia
    (anio, trimestre, provincia_id, mbps_media, source_row)
SELECT s.anio_valor, s.trimestre_valor, p.provincia_id, s.mbps_valor, s.source_row
FROM stg_velocidad_provincia AS s
JOIN dim_periodo AS d
  ON d.anio = s.anio_valor AND d.trimestre = s.trimestre_valor
JOIN dim_provincia_alias AS a ON a.alias_key = s.provincia_key
JOIN dim_provincia AS p ON p.provincia_id = a.provincia_id;

INSERT INTO fact_penetracion_provincia
    (anio, trimestre, provincia_id, accesos_100_hogares,
     accesos_100_habitantes, source_row)
SELECT s.anio_valor, s.trimestre_valor, p.provincia_id,
       s.accesos_100_hogares_valor, s.accesos_100_habitantes_valor, s.source_row
FROM stg_penetracion_provincia AS s
JOIN dim_periodo AS d
  ON d.anio = s.anio_valor AND d.trimestre = s.trimestre_valor
JOIN dim_provincia_alias AS a ON a.alias_key = s.provincia_key
JOIN dim_provincia AS p ON p.provincia_id = a.provincia_id;

INSERT INTO fact_accesos_categoria_provincia
    (anio, trimestre, provincia_id, categoria_velocidad_id, accesos, source_row)
SELECT s.anio_valor, s.trimestre_valor, p.provincia_id,
       c.categoria_velocidad_id, s.accesos_valor, s.source_row
FROM stg_accesos_categoria_provincia AS s
JOIN dim_periodo AS d
  ON d.anio = s.anio_valor AND d.trimestre = s.trimestre_valor
JOIN dim_provincia_alias AS a ON a.alias_key = s.provincia_key
JOIN dim_provincia AS p ON p.provincia_id = a.provincia_id
JOIN dim_categoria_velocidad AS c ON c.etiqueta_original = s.velocidad_raw;

-- Las grafías tecnológicas se estandarizan para análisis; el texto original
-- sigue disponible en la fila staging referenciada por source_row.
INSERT INTO fact_accesos_tecnologia_localidad
    (localidad_id, tecnologia_id, accesos, source_row)
SELECT l.localidad_id, a.tecnologia_id, s.accesos_valor, s.source_row
FROM stg_accesos_tecnologia_localidad AS s
JOIN dim_provincia_alias AS pa ON pa.alias_key = s.provincia_key
JOIN dim_localidad AS l
  ON l.provincia_id = pa.provincia_id
 AND l.departamento_key = s.departamento_key
 AND l.localidad_key = s.localidad_key
JOIN dim_tecnologia_alias AS a ON a.alias_key = upper(trim(s.tecnologia_raw));

INSERT INTO fact_accesos_categoria_localidad
    (localidad_id, categoria_velocidad_id, accesos, source_row)
SELECT l.localidad_id, c.categoria_velocidad_id, s.accesos_valor, s.source_row
FROM stg_accesos_categoria_localidad AS s
JOIN dim_provincia_alias AS pa ON pa.alias_key = s.provincia_key
JOIN dim_localidad AS l
  ON l.provincia_id = pa.provincia_id
 AND l.departamento_key = s.departamento_key
 AND l.localidad_key = s.localidad_key
JOIN dim_categoria_velocidad AS c ON c.etiqueta_original = s.velocidad_raw;

COMMIT;
