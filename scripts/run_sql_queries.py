#!/usr/bin/env python3
"""Ejecuta las consultas numeradas de sql/04_analysis_queries.sql."""
from __future__ import annotations

import argparse
import json
import re
import sqlite3
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_DATABASE = ROOT / "database" / "conectividad.db"
QUERY_FILE = ROOT / "sql" / "04_analysis_queries.sql"
MARKER = re.compile(r"^-- QUERY (\d+):\s*(.+)$")


def read_queries() -> dict[int, tuple[str, str]]:
    queries: dict[int, tuple[str, str]] = {}
    number: int | None = None
    title = ""
    lines: list[str] = []

    def save() -> None:
        if number is None:
            return
        statement = "\n".join(
            line for line in lines
            if line.strip() and not line.lstrip().startswith("--")
        ).strip()
        if not statement.endswith(";"):
            raise ValueError(f"La consulta {number} no termina en punto y coma.")
        queries[number] = (title, statement)

    for line in QUERY_FILE.read_text(encoding="utf-8").splitlines():
        match = MARKER.match(line)
        if match:
            save()
            number = int(match.group(1))
            title = match.group(2)
            lines = []
        elif number is not None:
            lines.append(line)
    save()
    return queries


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--database", type=Path, default=DEFAULT_DATABASE)
    parser.add_argument("--query", type=int, action="append", help="número de consulta (1–8); repetible")
    args = parser.parse_args()
    database = args.database if args.database.is_absolute() else ROOT / args.database
    if not database.is_file():
        print(f"No existe la base SQLite: {database}", file=sys.stderr)
        return 1

    try:
        queries = read_queries()
        selected = args.query or sorted(queries)
        unknown = [number for number in selected if number not in queries]
        if unknown:
            raise ValueError(f"Números de consulta inválidos: {unknown}")
        with sqlite3.connect(database) as connection:
            connection.row_factory = sqlite3.Row
            connection.execute("PRAGMA foreign_keys = ON")
            for number in selected:
                title, statement = queries[number]
                rows = connection.execute(statement).fetchall()
                print(f"\nConsulta {number}: {title} ({len(rows)} filas)")
                for row in rows:
                    print(json.dumps(dict(row), ensure_ascii=False, default=str))
    except (OSError, sqlite3.Error, ValueError) as error:
        print(f"Error al ejecutar consultas: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
