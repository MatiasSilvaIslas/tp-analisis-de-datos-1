#!/usr/bin/env python3
"""Reconstruye la base SQLite desde los seis CSV originales de ENACOM.

Uso desde la raíz del repositorio:
    python scripts/load_sqlite.py

El archivo de salida se reemplaza solo si la carga y los controles terminan
correctamente. Si Windows deniega el reemplazo atómico, se conserva una copia
de recuperación durante la escritura y se restaura ante errores. No requiere pandas.
"""
from __future__ import annotations

import argparse
import csv
import math
import os
import re
import shutil
import sqlite3
import sys
import tempfile
import unicodedata
from pathlib import Path
from typing import Callable, Sequence


ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / "data" / "raw"
SQL = ROOT / "sql"
DEFAULT_DATABASE = ROOT / "database" / "conectividad.db"
DEFAULT_MODIFIED_DIRECTORY = ROOT / "data" / "modified"
MISSING_MARKERS = {"", "nan", "-", "s/d"}


def raw_text(row: dict[str, str | None], field: str) -> str:
    """Keep the decoded CSV field exactly; empty source cells stay empty text."""
    value = row.get(field)
    return "" if value is None else value


def parse_ar_number(value: str, *, integer: bool) -> int | float | None:
    """Parse Argentine numeric notation without turning missing/invalid into 0."""
    text = value.strip().replace("\u00a0", "").replace(" ", "")
    if text.lower() in MISSING_MARKERS:
        return None
    if "," in text:
        text = text.replace(".", "").replace(",", ".")
    elif re.fullmatch(r"-?\d{1,3}(?:\.\d{3})+", text):
        text = text.replace(".", "")
    try:
        number = float(text)
    except ValueError:
        return None
    if not math.isfinite(number):
        return None
    if integer:
        if not number.is_integer():
            return None
        return int(number)
    return number


def province_key(value: str) -> str | None:
    """Create the accent/case-insensitive join key used by process_data.py."""
    normalized = " ".join(value.strip().upper().split())
    if not normalized:
        return None
    folded = unicodedata.normalize("NFKD", normalized)
    folded = "".join(char for char in folded if not unicodedata.combining(char))
    if folded == "CAPITAL FEDERAL":
        return "CABA"
    return folded


def locality_name_key(value: str) -> str:
    """Case-insensitive NFC key; keep the original spelling in staging."""
    return unicodedata.normalize("NFC", value.strip()).casefold()


def historical_base(row: dict[str, str | None], province_field: str = "Provincia") -> list[object]:
    year_raw = raw_text(row, "Año")
    quarter_raw = raw_text(row, "Trimestre")
    province_raw = raw_text(row, province_field)
    return [
        year_raw,
        quarter_raw,
        province_raw,
        province_key(province_raw),
        parse_ar_number(year_raw, integer=True),
        parse_ar_number(quarter_raw, integer=True),
    ]


def integer_pair(row: dict[str, str | None], source_field: str) -> list[object]:
    value = raw_text(row, source_field)
    return [value, parse_ar_number(value, integer=True)]


def real_pair(row: dict[str, str | None], source_field: str) -> list[object]:
    value = raw_text(row, source_field)
    return [value, parse_ar_number(value, integer=False)]


def tech_province(row: dict[str, str | None]) -> list[object]:
    values = historical_base(row)
    for field in ("ADSL", "Cablemodem", "Fibra Optica", "Wireless", "Otros", "Total"):
        values.extend(integer_pair(row, field))
    return values


def speed_province(row: dict[str, str | None]) -> list[object]:
    return historical_base(row) + real_pair(row, "Mbps (Media de bajada)")


def penetration_province(row: dict[str, str | None]) -> list[object]:
    values = historical_base(row, "Provincias")
    values.extend(real_pair(row, "Accesos cada 100 Hogares"))
    values.extend(real_pair(row, "Accesos cada 100 Habitantes"))
    return values


def speed_province_category(row: dict[str, str | None]) -> list[object]:
    return (
        historical_base(row)
        + [raw_text(row, "Velocidad")]
        + integer_pair(row, "Accesos")
    )


def technology_locality(row: dict[str, str | None]) -> list[object]:
    province = raw_text(row, "Provincia")
    department = raw_text(row, "Partido")
    locality = raw_text(row, "Localidad")
    return [
        raw_text(row, "LinkIndec"),
        province,
        province_key(province),
        department,
        locality,
        locality_name_key(department),
        locality_name_key(locality),
        raw_text(row, "Tecnologia"),
        *integer_pair(row, "Accesos"),
    ]


def speed_locality_category(row: dict[str, str | None]) -> list[object]:
    province = raw_text(row, "Provincia")
    department = raw_text(row, "Partido")
    locality = raw_text(row, "Localidad")
    return [
        raw_text(row, "LinkIndec"),
        province,
        province_key(province),
        department,
        locality,
        locality_name_key(department),
        locality_name_key(locality),
        raw_text(row, "Velocidad"),
        *integer_pair(row, "Accesos"),
    ]


Dataset = tuple[str, str, tuple[str, ...], tuple[str, ...], Callable[[dict[str, str | None]], list[object]]]
DATASETS: tuple[Dataset, ...] = (
    (
        "stg_accesos_tecnologia_provincia",
        "Internet Accesos Tecnologias Provincias.csv",
        ("Año", "Trimestre", "Provincia", "ADSL", "Cablemodem", "Fibra Optica", "Wireless", "Otros", "Total"),
        (
            "anio_raw", "trimestre_raw", "provincia_raw", "provincia_key", "anio_valor", "trimestre_valor",
            "adsl_raw", "adsl_valor", "cablemodem_raw", "cablemodem_valor",
            "fibra_optica_raw", "fibra_optica_valor", "wireless_raw", "wireless_valor",
            "otros_raw", "otros_valor", "total_raw", "total_valor",
        ),
        tech_province,
    ),
    (
        "stg_velocidad_provincia",
        "Internet Velocidad Media de Descarga Provincias.csv",
        ("Año", "Trimestre", "Provincia", "Mbps (Media de bajada)"),
        ("anio_raw", "trimestre_raw", "provincia_raw", "provincia_key", "anio_valor", "trimestre_valor", "mbps_raw", "mbps_valor"),
        speed_province,
    ),
    (
        "stg_penetracion_provincia",
        "Internet Penetración Provincias.csv",
        ("Año", "Trimestre", "Provincias", "Accesos cada 100 Hogares", "Accesos cada 100 Habitantes"),
        (
            "anio_raw", "trimestre_raw", "provincia_raw", "provincia_key", "anio_valor", "trimestre_valor",
            "accesos_100_hogares_raw", "accesos_100_hogares_valor",
            "accesos_100_habitantes_raw", "accesos_100_habitantes_valor",
        ),
        penetration_province,
    ),
    (
        "stg_accesos_categoria_provincia",
        "Internet Accesos Velocidad Provincias.csv",
        ("Año", "Trimestre", "Provincia", "Velocidad", "Accesos"),
        (
            "anio_raw", "trimestre_raw", "provincia_raw", "provincia_key", "anio_valor", "trimestre_valor",
            "velocidad_raw", "accesos_raw", "accesos_valor",
        ),
        speed_province_category,
    ),
    (
        "stg_accesos_tecnologia_localidad",
        "Internet Accesos Tecnologias Localidades.csv",
        ("LinkIndec", "Provincia", "Partido", "Localidad", "Tecnologia", "Accesos"),
        (
            "linkindec_raw", "provincia_raw", "provincia_key", "departamento_raw", "localidad_raw",
            "departamento_key", "localidad_key", "tecnologia_raw", "accesos_raw", "accesos_valor",
        ),
        technology_locality,
    ),
    (
        "stg_accesos_categoria_localidad",
        "Internet Accesos Velocidad Localidades.csv",
        ("LinkIndec", "Provincia", "Partido", "Localidad", "Velocidad", "Accesos"),
        (
            "linkindec_raw", "provincia_raw", "provincia_key", "departamento_raw", "localidad_raw",
            "departamento_key", "localidad_key", "velocidad_raw", "accesos_raw", "accesos_valor",
        ),
        speed_locality_category,
    ),
)


def load_dataset(connection: sqlite3.Connection, dataset: Dataset) -> int:
    table, filename, expected_headers, columns, transform = dataset
    path = RAW / filename
    if not path.is_file():
        raise FileNotFoundError(f"No se encontró el CSV requerido: {path}")

    placeholders = ", ".join("?" for _ in range(len(columns) + 1))
    column_sql = ", ".join(("source_row", *columns))
    insert_sql = f"INSERT INTO {table} ({column_sql}) VALUES ({placeholders})"
    count = 0
    with path.open("r", encoding="utf-8-sig", newline="") as source:
        reader = csv.DictReader(source)
        if tuple(reader.fieldnames or ()) != expected_headers:
            raise ValueError(
                f"Encabezados inesperados en {filename}: {reader.fieldnames!r}; "
                f"se esperaban {expected_headers!r}"
            )
        for source_row, row in enumerate(reader, start=1):
            if None in row:
                raise ValueError(f"Fila CSV con columnas sobrantes en {filename}, fila {source_row + 1}")
            connection.execute(insert_sql, (source_row, *transform(row)))
            count += 1
    return count


def print_rows(title: str, rows: Sequence[sqlite3.Row]) -> None:
    print(title)
    for row in rows:
        print("  " + " | ".join(f"{key}={row[key]}" for key in row.keys()))


def validate_database(connection: sqlite3.Connection) -> None:
    issues = connection.execute(
        "SELECT issue_code, severity, source_table, source_row, field, value, detail "
        "FROM quality_issues ORDER BY CASE severity WHEN 'ERROR' THEN 0 ELSE 1 END, "
        "source_table, source_row, issue_code"
    ).fetchall()
    if issues:
        print_rows("Incidencias de staging:", issues)
    else:
        print("Incidencias de staging: 0")
    errors = [row for row in issues if row["severity"] == "ERROR"]
    if errors:
        raise ValueError(f"Se encontraron {len(errors)} errores de calidad; no se reemplaza la base.")

    foreign_key_errors = connection.execute("PRAGMA foreign_key_check").fetchall()
    if foreign_key_errors:
        print_rows("Violaciones de claves foráneas:", foreign_key_errors)
        raise ValueError(f"Se encontraron {len(foreign_key_errors)} violaciones de claves foráneas.")
    print("Integridad referencial: 0 violaciones")

    integrity = connection.execute("PRAGMA integrity_check").fetchone()[0]
    if integrity != "ok":
        raise ValueError(f"PRAGMA integrity_check: {integrity}")
    print("PRAGMA integrity_check: ok")

    checks = (
        ("períodos inesperados", "SELECT * FROM quality_period_count_issues"),
        ("provincia ausente por período", "SELECT * FROM quality_missing_provincia_periodo"),
        ("suma de tecnologías distinta de Total", "SELECT * FROM quality_technology_total_mismatches"),
        ("LinkIndec inconsistente en localidades compartidas", "SELECT * FROM quality_linkindec_cross_source_mismatches"),
        ("hechos fuera de 2014–2024", "SELECT * FROM quality_fact_out_of_scope_rows"),
    )
    for label, query in checks:
        rows = connection.execute(query).fetchall()
        if rows:
            print_rows(f"Control con problemas — {label}:", rows)
            raise ValueError(f"El control '{label}' encontró {len(rows)} filas.")
        print(f"Control {label}: 0 filas problemáticas")

    category_mismatch_periods = connection.execute(
        "SELECT * FROM quality_category_period_mismatches ORDER BY periodo"
    ).fetchall()
    if category_mismatch_periods:
        print_rows(
            "Diferencias entre categorías de velocidad y Total (diagnóstico; no se ajustan):",
            category_mismatch_periods,
        )
    category_mismatch_rows = connection.execute(
        "SELECT periodo, COUNT(*) AS provincias_con_diferencia "
        "FROM quality_category_total_mismatches GROUP BY periodo ORDER BY periodo"
    ).fetchall()
    print_rows("Provincia-trimestres con diferencia en suma de categorías:", category_mismatch_rows)

    period_coverage = connection.execute(
        "SELECT source_dataset, expected_periods, actual_periods, rows_in_scope "
        "FROM quality_period_coverage ORDER BY source_dataset"
    ).fetchall()
    print_rows("Cobertura temporal y territorial:", period_coverage)

    source_scope = connection.execute(
        "SELECT source_dataset, COUNT(*) AS filas_fuera_de_alcance "
        "FROM quality_out_of_scope_source_rows GROUP BY source_dataset ORDER BY source_dataset"
    ).fetchall()
    print_rows("Filas fuente excluidas del modelo histórico (se conservan en staging):", source_scope)

    locality_coverage = connection.execute("SELECT * FROM quality_locality_source_coverage").fetchall()
    print_rows("Cruce de localidades por clave compuesta:", locality_coverage)
    collisions = connection.execute(
        "SELECT source_dataset, COUNT(*) AS codigos_reutilizados "
        "FROM quality_linkindec_collisions GROUP BY source_dataset ORDER BY source_dataset"
    ).fetchall()
    print_rows("LinkIndec reutilizados (diagnóstico; no es clave primaria):", collisions)

    category_counts = connection.execute(
        "SELECT source_dataset, COUNT(*) AS etiquetas_distintas "
        "FROM quality_speed_category_labels GROUP BY source_dataset ORDER BY source_dataset"
    ).fetchall()
    print_rows("Etiquetas originales de velocidad:", category_counts)


def table_counts(connection: sqlite3.Connection) -> list[tuple[str, int]]:
    names = [
        "dim_provincia", "dim_provincia_alias", "dim_periodo", "dim_tecnologia",
        "dim_tecnologia_alias", "dim_categoria_velocidad", "dim_localidad",
        "stg_accesos_tecnologia_provincia", "stg_velocidad_provincia",
        "stg_penetracion_provincia", "stg_accesos_categoria_provincia",
        "stg_accesos_tecnologia_localidad", "stg_accesos_categoria_localidad",
        "fact_accesos_provincia", "fact_accesos_tecnologia", "fact_velocidad_provincia",
        "fact_penetracion_provincia", "fact_accesos_categoria_provincia",
        "fact_accesos_tecnologia_localidad", "fact_accesos_categoria_localidad",
    ]
    return [
        (name, connection.execute(f"SELECT COUNT(*) FROM {name}").fetchone()[0])
        for name in names
    ]



def copy_file_contents(source_path: Path, destination_path: Path) -> None:
    """Copy to an existing file, flush it, and truncate any old trailing bytes."""
    with source_path.open("rb") as source, destination_path.open("r+b") as destination:
        shutil.copyfileobj(source, destination)
        destination.truncate()
        destination.flush()
        os.fsync(destination.fileno())


def replace_file_with_recovery(temporary: Path, destination: Path) -> None:
    """Replace a file; retain and use a recovery copy if Windows denies replace."""
    try:
        os.replace(temporary, destination)
        return
    except PermissionError:
        if not destination.is_file():
            raise

    handle = tempfile.NamedTemporaryFile(
        prefix=f".{destination.stem}-", suffix=".recovery",
        dir=destination.parent, delete=False
    )
    backup = Path(handle.name)
    handle.close()
    try:
        shutil.copy2(destination, backup)
    except OSError:
        try:
            backup.unlink(missing_ok=True)
        except OSError:
            pass
        raise
    try:
        copy_file_contents(temporary, destination)
    except BaseException:
        try:
            copy_file_contents(backup, destination)
        except OSError as recovery_error:
            raise RuntimeError(
                f"Falló la escritura de {destination}; conserve el respaldo "
                f"{backup} para recuperar el archivo."
            ) from recovery_error
        try:
            backup.unlink(missing_ok=True)
        except OSError:
            pass
        raise
    else:
        temporary.unlink(missing_ok=True)
        try:
            backup.unlink(missing_ok=True)
        except OSError:
            print(f"Aviso: quedó una copia de recuperación: {backup}", file=sys.stderr)


def write_csv_export(
    connection: sqlite3.Connection,
    destination: Path,
    headers: Sequence[str],
    query: str,
) -> int:
    destination.parent.mkdir(parents=True, exist_ok=True)
    handle = tempfile.NamedTemporaryFile(
        prefix=f".{destination.stem}-", suffix=".tmp", dir=destination.parent, delete=False
    )
    temporary = Path(handle.name)
    handle.close()
    count = 0
    try:
        with temporary.open("w", encoding="utf-8-sig", newline="") as output:
            writer = csv.writer(output)
            writer.writerow(headers)
            for row in connection.execute(query):
                writer.writerow(tuple(row))
                count += 1
            output.flush()
            os.fsync(output.fileno())
        replace_file_with_recovery(temporary, destination)
        return count
    finally:
        temporary.unlink(missing_ok=True)


def export_modified_csvs(connection: sqlite3.Connection, directory: Path) -> list[tuple[str, int]]:
    exports: tuple[tuple[str, tuple[str, ...], str], ...] = (
        (
            "accesos_tecnologia_provincia.csv",
            ("anio", "trimestre", "periodo", "provincia", "adsl", "cablemodem",
             "fibra_optica", "wireless", "otros", "accesos_total", "source_row"),
            """
            SELECT f.anio, f.trimestre, d.periodo, p.provincia,
                   MAX(CASE WHEN t.tecnologia = 'ADSL' THEN ft.accesos END),
                   MAX(CASE WHEN t.tecnologia = 'Cablemodem' THEN ft.accesos END),
                   MAX(CASE WHEN t.tecnologia = 'Fibra Optica' THEN ft.accesos END),
                   MAX(CASE WHEN t.tecnologia = 'Wireless' THEN ft.accesos END),
                   MAX(CASE WHEN t.tecnologia = 'Otros' THEN ft.accesos END),
                   f.accesos_total, f.source_row
            FROM fact_accesos_provincia AS f
            JOIN dim_periodo AS d ON d.anio = f.anio AND d.trimestre = f.trimestre
            JOIN dim_provincia AS p ON p.provincia_id = f.provincia_id
            LEFT JOIN fact_accesos_tecnologia AS ft
              ON ft.anio = f.anio AND ft.trimestre = f.trimestre
             AND ft.provincia_id = f.provincia_id
            LEFT JOIN dim_tecnologia AS t ON t.tecnologia_id = ft.tecnologia_id
            GROUP BY f.anio, f.trimestre, d.periodo, p.provincia,
                     f.provincia_id, f.accesos_total, f.source_row
            ORDER BY f.anio, f.trimestre, p.provincia
            """,
        ),
        (
            "velocidad_provincia.csv",
            ("anio", "trimestre", "periodo", "provincia", "mbps_media", "source_row"),
            """
            SELECT f.anio, f.trimestre, d.periodo, p.provincia, f.mbps_media, f.source_row
            FROM fact_velocidad_provincia AS f
            JOIN dim_periodo AS d ON d.anio = f.anio AND d.trimestre = f.trimestre
            JOIN dim_provincia AS p ON p.provincia_id = f.provincia_id
            ORDER BY f.anio, f.trimestre, p.provincia
            """,
        ),
        (
            "penetracion_provincia.csv",
            ("anio", "trimestre", "periodo", "provincia", "accesos_100_hogares",
             "accesos_100_habitantes", "source_row"),
            """
            SELECT f.anio, f.trimestre, d.periodo, p.provincia,
                   f.accesos_100_hogares, f.accesos_100_habitantes, f.source_row
            FROM fact_penetracion_provincia AS f
            JOIN dim_periodo AS d ON d.anio = f.anio AND d.trimestre = f.trimestre
            JOIN dim_provincia AS p ON p.provincia_id = f.provincia_id
            ORDER BY f.anio, f.trimestre, p.provincia
            """,
        ),
        (
            "accesos_categoria_provincia.csv",
            ("anio", "trimestre", "periodo", "provincia", "categoria_velocidad",
             "accesos", "source_row"),
            """
            SELECT f.anio, f.trimestre, d.periodo, p.provincia,
                   c.etiqueta_original, f.accesos, f.source_row
            FROM fact_accesos_categoria_provincia AS f
            JOIN dim_periodo AS d ON d.anio = f.anio AND d.trimestre = f.trimestre
            JOIN dim_provincia AS p ON p.provincia_id = f.provincia_id
            JOIN dim_categoria_velocidad AS c
              ON c.categoria_velocidad_id = f.categoria_velocidad_id
            ORDER BY f.anio, f.trimestre, p.provincia, c.etiqueta_original
            """,
        ),
        (
            "accesos_tecnologia_localidad.csv",
            ("provincia", "partido", "localidad", "tecnologia", "accesos",
             "LinkIndec", "source_row"),
            """
            SELECT p.provincia, l.departamento, l.localidad, t.tecnologia,
                   f.accesos, s.linkindec_raw, f.source_row
            FROM fact_accesos_tecnologia_localidad AS f
            JOIN dim_localidad AS l ON l.localidad_id = f.localidad_id
            JOIN dim_provincia AS p ON p.provincia_id = l.provincia_id
            JOIN dim_tecnologia AS t ON t.tecnologia_id = f.tecnologia_id
            JOIN stg_accesos_tecnologia_localidad AS s ON s.source_row = f.source_row
            ORDER BY p.provincia, l.departamento, l.localidad, t.tecnologia
            """,
        ),
        (
            "accesos_categoria_localidad.csv",
            ("provincia", "partido", "localidad", "categoria_velocidad", "accesos",
             "LinkIndec", "source_row"),
            """
            SELECT p.provincia, l.departamento, l.localidad, c.etiqueta_original,
                   f.accesos, s.linkindec_raw, f.source_row
            FROM fact_accesos_categoria_localidad AS f
            JOIN dim_localidad AS l ON l.localidad_id = f.localidad_id
            JOIN dim_provincia AS p ON p.provincia_id = l.provincia_id
            JOIN dim_categoria_velocidad AS c
              ON c.categoria_velocidad_id = f.categoria_velocidad_id
            JOIN stg_accesos_categoria_localidad AS s ON s.source_row = f.source_row
            ORDER BY p.provincia, l.departamento, l.localidad, c.etiqueta_original
            """,
        ),
    )
    return [
        (filename, write_csv_export(connection, directory / filename, headers, query))
        for filename, headers, query in exports
    ]


def build_database(output: Path, modified_directory: Path) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    handle = tempfile.NamedTemporaryFile(
        prefix=f".{output.stem}-", suffix=".building.db", dir=output.parent, delete=False
    )
    temporary = Path(handle.name)
    handle.close()

    connection: sqlite3.Connection | None = None
    try:
        connection = sqlite3.connect(temporary)
        connection.row_factory = sqlite3.Row
        connection.execute("PRAGMA foreign_keys = ON")
        connection.executescript((SQL / "01_schema.sql").read_text(encoding="utf-8"))

        loaded: list[tuple[str, int]] = []
        with connection:
            for dataset in DATASETS:
                table, filename = dataset[0], dataset[1]
                loaded.append((filename, load_dataset(connection, dataset)))
        print_rows(
            "Filas leídas en staging:",
            [dict_to_row({"dataset": name, "rows": count}) for name, count in loaded],
        )

        # Revisar filas fuente antes de transformarlas. Así una PK/CHECK no
        # oculta la fila problemática y nunca se descarta silenciosamente.
        connection.executescript((SQL / "03_quality_checks.sql").read_text(encoding="utf-8"))
        stage_issues = connection.execute(
            "SELECT issue_code, severity, source_table, source_row, field, value, detail "
            "FROM quality_issues ORDER BY source_table, source_row, issue_code"
        ).fetchall()
        errors = [row for row in stage_issues if row["severity"] == "ERROR"]
        if stage_issues:
            print_rows("Incidencias detectadas en origen:", stage_issues)
        if errors:
            raise ValueError(f"Se encontraron {len(errors)} errores de calidad; no se reemplaza la base.")

        connection.executescript((SQL / "02_transform.sql").read_text(encoding="utf-8"))
        validate_database(connection)
        modified_exports = export_modified_csvs(connection, modified_directory)
        print_rows(
            f"CSV normalizados exportados a {modified_directory}:",
            [dict_to_row({"archivo": filename, "filas": count}) for filename, count in modified_exports],
        )
        counts = table_counts(connection)
        print_rows("Registros por tabla:", [dict_to_row({"tabla": name, "filas": count}) for name, count in counts])

        connection.close()
        connection = None
        replace_file_with_recovery(temporary, output)
        print(f"Base reconstruida correctamente: {output}")
        print("Controles ejecutados: claves foráneas, integridad SQLite, períodos, provincias, tecnologías, categorías y alcance temporal.")
    finally:
        if connection is not None:
            connection.close()
        for candidate in (temporary, Path(f"{temporary}-journal"), Path(f"{temporary}-wal"), Path(f"{temporary}-shm")):
            try:
                candidate.unlink(missing_ok=True)
            except OSError:
                pass


def dict_to_row(values: dict[str, object]) -> sqlite3.Row:
    """Build a small sqlite3.Row-like object for the common report printer."""
    class Row(dict):
        def keys(self):  # type: ignore[override]
            return super().keys()

    return Row(values)  # type: ignore[return-value]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--output", type=Path, default=DEFAULT_DATABASE,
        help=f"base de salida (por defecto: {DEFAULT_DATABASE.relative_to(ROOT)})",
    )
    parser.add_argument(
        "--modified-dir", type=Path, default=DEFAULT_MODIFIED_DIRECTORY,
        help="carpeta de CSV normalizados (por defecto: data/modified)",
    )
    args = parser.parse_args()
    output = args.output if args.output.is_absolute() else ROOT / args.output
    modified_directory = (
        args.modified_dir if args.modified_dir.is_absolute() else ROOT / args.modified_dir
    )
    try:
        build_database(output.resolve(), modified_directory.resolve())
    except (OSError, sqlite3.Error, ValueError, RuntimeError) as error:
        print(f"Error al reconstruir SQLite: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
