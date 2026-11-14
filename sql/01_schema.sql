PRAGMA foreign_keys = ON;

CREATE TABLE dim_provincia (
    provincia_id INTEGER PRIMARY KEY,
    provincia TEXT NOT NULL UNIQUE CHECK (length(trim(provincia)) > 0)
);

INSERT INTO dim_provincia (provincia) VALUES
    ('Buenos Aires'), ('CABA'), ('Catamarca'), ('Chaco'), ('Chubut'),
    ('Córdoba'), ('Corrientes'), ('Entre Ríos'), ('Formosa'), ('Jujuy'),
    ('La Pampa'), ('La Rioja'), ('Mendoza'), ('Misiones'), ('Neuquén'),
    ('Río Negro'), ('Salta'), ('San Juan'), ('San Luis'), ('Santa Cruz'),
    ('Santa Fe'), ('Santiago del Estero'), ('Tierra del Fuego'), ('Tucumán');

CREATE TABLE dim_provincia_alias (
    alias_key TEXT PRIMARY KEY,
    provincia_id INTEGER NOT NULL REFERENCES dim_provincia (provincia_id),
    CHECK (length(trim(alias_key)) > 0)
);

INSERT INTO dim_provincia_alias (alias_key, provincia_id)
SELECT 'BUENOS AIRES', provincia_id FROM dim_provincia WHERE provincia = 'Buenos Aires'
UNION ALL SELECT 'CABA', provincia_id FROM dim_provincia WHERE provincia = 'CABA'
UNION ALL SELECT 'CAPITAL FEDERAL', provincia_id FROM dim_provincia WHERE provincia = 'CABA'
UNION ALL SELECT 'CATAMARCA', provincia_id FROM dim_provincia WHERE provincia = 'Catamarca'
UNION ALL SELECT 'CHACO', provincia_id FROM dim_provincia WHERE provincia = 'Chaco'
UNION ALL SELECT 'CHUBUT', provincia_id FROM dim_provincia WHERE provincia = 'Chubut'
UNION ALL SELECT 'CORDOBA', provincia_id FROM dim_provincia WHERE provincia = 'Córdoba'
UNION ALL SELECT 'CORRIENTES', provincia_id FROM dim_provincia WHERE provincia = 'Corrientes'
UNION ALL SELECT 'ENTRE RIOS', provincia_id FROM dim_provincia WHERE provincia = 'Entre Ríos'
UNION ALL SELECT 'FORMOSA', provincia_id FROM dim_provincia WHERE provincia = 'Formosa'
UNION ALL SELECT 'JUJUY', provincia_id FROM dim_provincia WHERE provincia = 'Jujuy'
UNION ALL SELECT 'LA PAMPA', provincia_id FROM dim_provincia WHERE provincia = 'La Pampa'
UNION ALL SELECT 'LA RIOJA', provincia_id FROM dim_provincia WHERE provincia = 'La Rioja'
UNION ALL SELECT 'MENDOZA', provincia_id FROM dim_provincia WHERE provincia = 'Mendoza'
UNION ALL SELECT 'MISIONES', provincia_id FROM dim_provincia WHERE provincia = 'Misiones'
UNION ALL SELECT 'NEUQUEN', provincia_id FROM dim_provincia WHERE provincia = 'Neuquén'
UNION ALL SELECT 'RIO NEGRO', provincia_id FROM dim_provincia WHERE provincia = 'Río Negro'
UNION ALL SELECT 'SALTA', provincia_id FROM dim_provincia WHERE provincia = 'Salta'
UNION ALL SELECT 'SAN JUAN', provincia_id FROM dim_provincia WHERE provincia = 'San Juan'
UNION ALL SELECT 'SAN LUIS', provincia_id FROM dim_provincia WHERE provincia = 'San Luis'
UNION ALL SELECT 'SANTA CRUZ', provincia_id FROM dim_provincia WHERE provincia = 'Santa Cruz'
UNION ALL SELECT 'SANTA FE', provincia_id FROM dim_provincia WHERE provincia = 'Santa Fe'
UNION ALL SELECT 'SANTIAGO DEL ESTERO', provincia_id FROM dim_provincia WHERE provincia = 'Santiago del Estero'
UNION ALL SELECT 'TIERRA DEL FUEGO', provincia_id FROM dim_provincia WHERE provincia = 'Tierra del Fuego'
UNION ALL SELECT 'TUCUMAN', provincia_id FROM dim_provincia WHERE provincia = 'Tucumán';

CREATE TABLE dim_periodo (
    periodo_id INTEGER PRIMARY KEY,
    anio INTEGER NOT NULL CHECK (anio BETWEEN 2014 AND 2024),
    trimestre INTEGER NOT NULL CHECK (trimestre BETWEEN 1 AND 4),
    periodo TEXT NOT NULL UNIQUE,
    UNIQUE (anio, trimestre)
);

CREATE TABLE dim_tecnologia (
    tecnologia_id INTEGER PRIMARY KEY,
    tecnologia TEXT NOT NULL UNIQUE CHECK (length(trim(tecnologia)) > 0)
);

INSERT INTO dim_tecnologia (tecnologia) VALUES
    ('ADSL'), ('Cablemodem'), ('Celular'), ('Dial Up'), ('Fibra Optica'),
    ('Otros'), ('Satelital'), ('WIMAX'), ('Wireless');

CREATE TABLE dim_tecnologia_alias (
    alias_key TEXT PRIMARY KEY,
    tecnologia_id INTEGER NOT NULL REFERENCES dim_tecnologia (tecnologia_id),
    CHECK (length(trim(alias_key)) > 0)
);

INSERT INTO dim_tecnologia_alias (alias_key, tecnologia_id)
SELECT 'ADSL', tecnologia_id FROM dim_tecnologia WHERE tecnologia = 'ADSL'
UNION ALL SELECT 'CABLEMODEM', tecnologia_id FROM dim_tecnologia WHERE tecnologia = 'Cablemodem'
UNION ALL SELECT 'CELULAR', tecnologia_id FROM dim_tecnologia WHERE tecnologia = 'Celular'
UNION ALL SELECT 'DIAL UP', tecnologia_id FROM dim_tecnologia WHERE tecnologia = 'Dial Up'
UNION ALL SELECT 'FIBRA OPTICA', tecnologia_id FROM dim_tecnologia WHERE tecnologia = 'Fibra Optica'
UNION ALL SELECT 'OTROS', tecnologia_id FROM dim_tecnologia WHERE tecnologia = 'Otros'
UNION ALL SELECT 'SATELITAL', tecnologia_id FROM dim_tecnologia WHERE tecnologia = 'Satelital'
UNION ALL SELECT 'WIMAX', tecnologia_id FROM dim_tecnologia WHERE tecnologia = 'WIMAX'
UNION ALL SELECT 'WIRELESS', tecnologia_id FROM dim_tecnologia WHERE tecnologia = 'Wireless';

CREATE TABLE dim_categoria_velocidad (
    categoria_velocidad_id INTEGER PRIMARY KEY,
    etiqueta_original TEXT NOT NULL UNIQUE CHECK (length(trim(etiqueta_original)) > 0)
);

CREATE TABLE dim_localidad (
    localidad_id INTEGER PRIMARY KEY,
    provincia_id INTEGER NOT NULL REFERENCES dim_provincia (provincia_id),
    departamento_key TEXT NOT NULL CHECK (length(trim(departamento_key)) > 0),
    localidad_key TEXT NOT NULL CHECK (length(trim(localidad_key)) > 0),
    departamento TEXT NOT NULL CHECK (length(trim(departamento)) > 0),
    localidad TEXT NOT NULL CHECK (length(trim(localidad)) > 0),
    UNIQUE (provincia_id, departamento_key, localidad_key)
);

-- Staging conserva los campos textuales tal como los entrega CSV.DictReader.
-- Las columnas *_valor son conversiones revisables; un dato ausente o inválido
-- queda NULL y nunca se sustituye por cero.
CREATE TABLE stg_accesos_tecnologia_provincia (
    source_row INTEGER PRIMARY KEY,
    anio_raw TEXT NOT NULL, trimestre_raw TEXT NOT NULL,
    provincia_raw TEXT NOT NULL, provincia_key TEXT,
    anio_valor INTEGER, trimestre_valor INTEGER,
    adsl_raw TEXT NOT NULL, adsl_valor INTEGER,
    cablemodem_raw TEXT NOT NULL, cablemodem_valor INTEGER,
    fibra_optica_raw TEXT NOT NULL, fibra_optica_valor INTEGER,
    wireless_raw TEXT NOT NULL, wireless_valor INTEGER,
    otros_raw TEXT NOT NULL, otros_valor INTEGER,
    total_raw TEXT NOT NULL, total_valor INTEGER
);

CREATE TABLE stg_velocidad_provincia (
    source_row INTEGER PRIMARY KEY,
    anio_raw TEXT NOT NULL, trimestre_raw TEXT NOT NULL,
    provincia_raw TEXT NOT NULL, provincia_key TEXT,
    anio_valor INTEGER, trimestre_valor INTEGER,
    mbps_raw TEXT NOT NULL, mbps_valor REAL
);

CREATE TABLE stg_penetracion_provincia (
    source_row INTEGER PRIMARY KEY,
    anio_raw TEXT NOT NULL, trimestre_raw TEXT NOT NULL,
    provincia_raw TEXT NOT NULL, provincia_key TEXT,
    anio_valor INTEGER, trimestre_valor INTEGER,
    accesos_100_hogares_raw TEXT NOT NULL, accesos_100_hogares_valor REAL,
    accesos_100_habitantes_raw TEXT NOT NULL, accesos_100_habitantes_valor REAL
);

CREATE TABLE stg_accesos_categoria_provincia (
    source_row INTEGER PRIMARY KEY,
    anio_raw TEXT NOT NULL, trimestre_raw TEXT NOT NULL,
    provincia_raw TEXT NOT NULL, provincia_key TEXT,
    anio_valor INTEGER, trimestre_valor INTEGER,
    velocidad_raw TEXT NOT NULL,
    accesos_raw TEXT NOT NULL, accesos_valor INTEGER
);

CREATE TABLE stg_accesos_tecnologia_localidad (
    source_row INTEGER PRIMARY KEY,
    linkindec_raw TEXT NOT NULL,
    provincia_raw TEXT NOT NULL, provincia_key TEXT,
    departamento_raw TEXT NOT NULL, localidad_raw TEXT NOT NULL,
    departamento_key TEXT NOT NULL, localidad_key TEXT NOT NULL,
    tecnologia_raw TEXT NOT NULL,
    accesos_raw TEXT NOT NULL, accesos_valor INTEGER
);

CREATE TABLE stg_accesos_categoria_localidad (
    source_row INTEGER PRIMARY KEY,
    linkindec_raw TEXT NOT NULL,
    provincia_raw TEXT NOT NULL, provincia_key TEXT,
    departamento_raw TEXT NOT NULL, localidad_raw TEXT NOT NULL,
    departamento_key TEXT NOT NULL, localidad_key TEXT NOT NULL,
    velocidad_raw TEXT NOT NULL,
    accesos_raw TEXT NOT NULL, accesos_valor INTEGER
);

CREATE TABLE fact_accesos_provincia (
    anio INTEGER NOT NULL,
    trimestre INTEGER NOT NULL,
    provincia_id INTEGER NOT NULL REFERENCES dim_provincia (provincia_id),
    accesos_total INTEGER CHECK (accesos_total IS NULL OR accesos_total >= 0),
    source_row INTEGER NOT NULL UNIQUE REFERENCES stg_accesos_tecnologia_provincia (source_row),
    PRIMARY KEY (anio, trimestre, provincia_id),
    FOREIGN KEY (anio, trimestre) REFERENCES dim_periodo (anio, trimestre)
);

CREATE TABLE fact_accesos_tecnologia (
    anio INTEGER NOT NULL,
    trimestre INTEGER NOT NULL,
    provincia_id INTEGER NOT NULL REFERENCES dim_provincia (provincia_id),
    tecnologia_id INTEGER NOT NULL REFERENCES dim_tecnologia (tecnologia_id),
    accesos INTEGER CHECK (accesos IS NULL OR accesos >= 0),
    source_row INTEGER NOT NULL REFERENCES stg_accesos_tecnologia_provincia (source_row),
    PRIMARY KEY (anio, trimestre, provincia_id, tecnologia_id),
    FOREIGN KEY (anio, trimestre) REFERENCES dim_periodo (anio, trimestre)
);

CREATE TABLE fact_velocidad_provincia (
    anio INTEGER NOT NULL,
    trimestre INTEGER NOT NULL,
    provincia_id INTEGER NOT NULL REFERENCES dim_provincia (provincia_id),
    mbps_media REAL CHECK (mbps_media IS NULL OR mbps_media >= 0),
    source_row INTEGER NOT NULL UNIQUE REFERENCES stg_velocidad_provincia (source_row),
    PRIMARY KEY (anio, trimestre, provincia_id),
    FOREIGN KEY (anio, trimestre) REFERENCES dim_periodo (anio, trimestre)
);

CREATE TABLE fact_penetracion_provincia (
    anio INTEGER NOT NULL,
    trimestre INTEGER NOT NULL,
    provincia_id INTEGER NOT NULL REFERENCES dim_provincia (provincia_id),
    accesos_100_hogares REAL CHECK (accesos_100_hogares IS NULL OR accesos_100_hogares >= 0),
    accesos_100_habitantes REAL CHECK (accesos_100_habitantes IS NULL OR accesos_100_habitantes >= 0),
    source_row INTEGER NOT NULL UNIQUE REFERENCES stg_penetracion_provincia (source_row),
    PRIMARY KEY (anio, trimestre, provincia_id),
    FOREIGN KEY (anio, trimestre) REFERENCES dim_periodo (anio, trimestre)
);

CREATE TABLE fact_accesos_categoria_provincia (
    anio INTEGER NOT NULL,
    trimestre INTEGER NOT NULL,
    provincia_id INTEGER NOT NULL REFERENCES dim_provincia (provincia_id),
    categoria_velocidad_id INTEGER NOT NULL REFERENCES dim_categoria_velocidad (categoria_velocidad_id),
    accesos INTEGER CHECK (accesos IS NULL OR accesos >= 0),
    source_row INTEGER NOT NULL UNIQUE REFERENCES stg_accesos_categoria_provincia (source_row),
    PRIMARY KEY (anio, trimestre, provincia_id, categoria_velocidad_id),
    FOREIGN KEY (anio, trimestre) REFERENCES dim_periodo (anio, trimestre)
);

CREATE TABLE fact_accesos_tecnologia_localidad (
    localidad_id INTEGER NOT NULL REFERENCES dim_localidad (localidad_id),
    tecnologia_id INTEGER NOT NULL REFERENCES dim_tecnologia (tecnologia_id),
    accesos INTEGER CHECK (accesos IS NULL OR accesos >= 0),
    source_row INTEGER NOT NULL UNIQUE REFERENCES stg_accesos_tecnologia_localidad (source_row),
    PRIMARY KEY (localidad_id, tecnologia_id)
);

CREATE TABLE fact_accesos_categoria_localidad (
    localidad_id INTEGER NOT NULL REFERENCES dim_localidad (localidad_id),
    categoria_velocidad_id INTEGER NOT NULL REFERENCES dim_categoria_velocidad (categoria_velocidad_id),
    accesos INTEGER CHECK (accesos IS NULL OR accesos >= 0),
    source_row INTEGER NOT NULL UNIQUE REFERENCES stg_accesos_categoria_localidad (source_row),
    PRIMARY KEY (localidad_id, categoria_velocidad_id)
);

CREATE INDEX idx_fact_tecnologia_tecnologia_periodo
    ON fact_accesos_tecnologia (tecnologia_id, anio, trimestre);
CREATE INDEX idx_fact_categoria_provincia_categoria_periodo
    ON fact_accesos_categoria_provincia (categoria_velocidad_id, anio, trimestre);
CREATE INDEX idx_fact_tecnologia_localidad_tecnologia
    ON fact_accesos_tecnologia_localidad (tecnologia_id, localidad_id);
