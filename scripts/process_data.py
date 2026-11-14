#!/usr/bin/env python3
"""Prepara los seis CSV de ENACOM para el dashboard (2014-2024).

Uso desde la raíz del proyecto:
    python -m pip install -r requirements.txt
    python scripts/process_data.py
"""
from __future__ import annotations

import json
import re
import unicodedata
from pathlib import Path
from typing import Any

import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / "data" / "raw"
OUT = ROOT / "data" / "processed" / "dashboard.json"
YEAR_MIN = 2014
YEAR_MAX = 2024

FILES = {
    "tech_prov": "Internet Accesos Tecnologias Provincias.csv",
    "speed_prov": "Internet Velocidad Media de Descarga Provincias.csv",
    "penetration": "Internet Penetración Provincias.csv",
    "speed_bands": "Internet Accesos Velocidad Provincias.csv",
    "tech_local": "Internet Accesos Tecnologias Localidades.csv",
    "speed_local": "Internet Accesos Velocidad Localidades.csv",
}

PROVINCE_NAMES = {
    "BUENOS AIRES": "Buenos Aires", "CABA": "CABA", "CAPITAL FEDERAL": "CABA",
    "CATAMARCA": "Catamarca", "CHACO": "Chaco", "CHUBUT": "Chubut",
    "CORDOBA": "Córdoba", "CORRIENTES": "Corrientes", "ENTRE RIOS": "Entre Ríos",
    "FORMOSA": "Formosa", "JUJUY": "Jujuy", "LA PAMPA": "La Pampa",
    "LA RIOJA": "La Rioja", "MENDOZA": "Mendoza", "MISIONES": "Misiones",
    "NEUQUEN": "Neuquén", "RIO NEGRO": "Río Negro", "SALTA": "Salta",
    "SAN JUAN": "San Juan", "SAN LUIS": "San Luis", "SANTA CRUZ": "Santa Cruz",
    "SANTA FE": "Santa Fe", "SANTIAGO DEL ESTERO": "Santiago del Estero",
    "TIERRA DEL FUEGO": "Tierra del Fuego", "TUCUMAN": "Tucumán",
}
TECH_COLUMNS = ["ADSL", "Cablemodem", "Fibra Optica", "Wireless", "Otros"]
TECH_LABELS = {
    "ADSL": "ADSL", "Cablemodem": "Cablemódem", "Fibra Optica": "Fibra óptica",
    "Wireless": "Wireless", "Otros": "Otros",
}


def read_csv(name: str) -> pd.DataFrame:
    path = RAW / name
    if not path.exists():
        raise FileNotFoundError(f"No se encontró el archivo requerido: {path}")
    return pd.read_csv(path, dtype=str, encoding="utf-8-sig")


def parse_ar_number(value: Any) -> float | None:
    """Interpreta números con coma decimal y punto de miles usados en los CSV."""
    if value is None or pd.isna(value):
        return None
    s = str(value).strip().replace("\u00a0", "")
    if not s or s.lower() in {"nan", "-", "s/d"}:
        return None
    if "," in s:
        s = s.replace(".", "").replace(",", ".")
    else:
        # En los archivos de accesos, el punto es separador de miles.
        if re.fullmatch(r"-?\d{1,3}(\.\d{3})+", s):
            s = s.replace(".", "")
    try:
        return float(s)
    except ValueError:
        return None


def normalize_province(value: Any) -> str:
    raw = " ".join(str(value).strip().upper().split())
    folded = unicodedata.normalize("NFKD", raw).encode("ascii", "ignore").decode("ascii")
    return PROVINCE_NAMES.get(folded, str(value).strip().title())


def add_period(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()
    df["year"] = pd.to_numeric(df["Año"], errors="coerce").astype("Int64")
    df["quarter"] = pd.to_numeric(df["Trimestre"], errors="coerce").astype("Int64")
    df = df[df["year"].between(YEAR_MIN, YEAR_MAX)].copy()
    df["period"] = df.apply(lambda r: f"{int(r.year)}-T{int(r.quarter)}", axis=1)
    df["province"] = df["Provincia" if "Provincia" in df else "Provincias"].map(normalize_province)
    return df


def records(df: pd.DataFrame) -> list[dict[str, Any]]:
    return json.loads(df.to_json(orient="records", force_ascii=False))


def main() -> None:
    # 1) Accesos por tecnología y provincia: base para totales nacionales.
    tech = add_period(read_csv(FILES["tech_prov"]))
    for col in TECH_COLUMNS + ["Total"]:
        tech[col] = tech[col].map(parse_ar_number).fillna(0)
    tech["year"] = tech["year"].astype(int)
    tech["quarter"] = tech["quarter"].astype(int)
    tech_prov = tech[["year", "quarter", "period", "province"] + TECH_COLUMNS + ["Total"]].copy()
    tech_prov = tech_prov.rename(columns={c: f"tech_{c}" for c in TECH_COLUMNS} | {"Total": "total_accesses"})

    national = tech_prov.groupby(["year", "quarter", "period"], as_index=False)[
        [f"tech_{c}" for c in TECH_COLUMNS] + ["total_accesses"]
    ].sum()
    national["province"] = "Argentina"

    # 2) Velocidad media provincial. El promedio nacional que se presenta es una
    # estimación ponderada por accesos provinciales, no un dato nacional publicado.
    speed = add_period(read_csv(FILES["speed_prov"]))
    speed["mean_mbps"] = speed["Mbps (Media de bajada)"].map(parse_ar_number)
    speed["year"] = speed["year"].astype(int)
    speed["quarter"] = speed["quarter"].astype(int)
    speed = speed[["year", "quarter", "period", "province", "mean_mbps"]]
    merged_speed = speed.merge(tech_prov[["year", "quarter", "province", "total_accesses"]],
                               on=["year", "quarter", "province"], how="left")
    weighted = merged_speed.dropna(subset=["mean_mbps", "total_accesses"]).copy()
    weighted["weighted_value"] = weighted["mean_mbps"] * weighted["total_accesses"]
    nat_speed = weighted.groupby(["year", "quarter", "period"], as_index=False).agg(
        weighted_value=("weighted_value", "sum"), weight=("total_accesses", "sum"))
    nat_speed["weighted_mean_mbps_estimate"] = nat_speed["weighted_value"] / nat_speed["weight"].replace(0, pd.NA)
    nat_speed = nat_speed[["year", "quarter", "period", "weighted_mean_mbps_estimate"]]

    # 3) Penetración: se conserva a nivel provincial. No se calcula un promedio
    # simple como si fuera la penetración nacional.
    penetration = add_period(read_csv(FILES["penetration"]))
    penetration["per_100_households"] = penetration["Accesos cada 100 Hogares"].map(parse_ar_number)
    penetration["per_100_people"] = penetration["Accesos cada 100 Habitantes"].map(parse_ar_number)
    penetration["year"] = penetration["year"].astype(int)
    penetration["quarter"] = penetration["quarter"].astype(int)
    penetration = penetration[["year", "quarter", "period", "province", "per_100_households", "per_100_people"]]

    # 4) Distribución de accesos por categoría de velocidad (categorías originales).
    bands = add_period(read_csv(FILES["speed_bands"]))
    bands["accesses"] = bands["Accesos"].map(parse_ar_number).fillna(0)
    bands["speed_category"] = bands["Velocidad"].astype(str).str.strip()
    bands["year"] = bands["year"].astype(int)
    bands["quarter"] = bands["quarter"].astype(int)
    bands = bands[["year", "quarter", "period", "province", "speed_category", "accesses"]]
    bands_total = bands.groupby(["year", "quarter", "period", "speed_category"], as_index=False)["accesses"].sum()

    # 5) Archivos de localidad: son cortes sin año/trimestre. No se usan para
    # inferir tendencias temporales.
    local = read_csv(FILES["tech_local"])
    local["province"] = local["Provincia"].map(normalize_province)
    local["accesses"] = local["Accesos"].map(parse_ar_number).fillna(0)
    local["technology"] = local["Tecnologia"].astype(str).str.strip()
    local["locality"] = local["Localidad"].astype(str).str.strip()
    local["department"] = local["Partido"].astype(str).str.strip()
    locality = local.groupby(["province", "department", "locality"], as_index=False).agg(
        total_accesses=("accesses", "sum"))
    local_tech = local.groupby(["province", "department", "locality", "technology"], as_index=False)["accesses"].sum()

    # 6) Archivos de velocidad por localidad: se preservan como distribución
    # transversal por localidad, sin fecha asociada.
    local_speed = read_csv(FILES["speed_local"])
    local_speed["province"] = local_speed["Provincia"].map(normalize_province)
    local_speed["accesses"] = local_speed["Accesos"].map(parse_ar_number).fillna(0)
    local_speed["speed_category"] = local_speed["Velocidad"].astype(str).str.strip()
    local_speed["locality"] = local_speed["Localidad"].astype(str).str.strip()
    local_speed["department"] = local_speed["Partido"].astype(str).str.strip()
    locality_speed = local_speed.groupby(["province", "department", "locality", "speed_category"], as_index=False)["accesses"].sum()

    # Auditorías resumidas para documentar el procesamiento.
    tech_check = tech_prov.copy()
    tech_sum = tech_check[[f"tech_{c}" for c in TECH_COLUMNS]].sum(axis=1)
    diff = (tech_sum - tech_check["total_accesses"]).abs()
    province_count = int(tech_prov["province"].nunique())
    period_count = int(tech_prov["period"].nunique())

    payload = {
        "meta": {
            "title": "Conectividad fija en Argentina (2014–2024)",
            "source": "ENACOM — datasets de conectividad fija incluidos por el usuario",
            "year_min": YEAR_MIN, "year_max": YEAR_MAX,
            "period_count": period_count, "province_count": province_count,
            "technology_labels": TECH_LABELS,
            "methodology": {
                "national_accesses": "Suma de los totales publicados para las 24 jurisdicciones provinciales en cada trimestre.",
                "fiber_share": "Suma de accesos de Fibra Optica dividida por la suma de Total, para el mismo período y filtro.",
                "national_speed": "Estimación: promedio de velocidades medias provinciales ponderado por el total de accesos de cada provincia. No es un valor nacional publicado directamente por ENACOM.",
                "penetration": "Se presenta exclusivamente por provincia. No se calcula un promedio simple como sustituto de la penetración nacional.",
                "localities": "Los dos archivos de localidad no contienen año ni trimestre; se muestran como cortes transversales y no se mezclan con la serie histórica.",
                "speed_categories": "Se conservan las categorías originales de la columna Velocidad. No se asignan unidades ni rangos que no estén definidos en el archivo."
            },
            "quality": {
                "technology_total_max_abs_difference": float(diff.max()),
                "technology_rows_checked": int(len(diff)),
                "technology_rows_with_difference": int((diff > 0).sum()),
                "source_years_outside_scope_excluded": "2025–2026"
            }
        },
        "technologies": [
            {"key": f"tech_{c}", "label": TECH_LABELS[c]} for c in TECH_COLUMNS
        ],
        "national": records(national.merge(nat_speed, on=["year", "quarter", "period"], how="left")),
        "provinces": records(tech_prov.merge(speed, on=["year", "quarter", "period", "province"], how="left")
                              .merge(penetration, on=["year", "quarter", "period", "province"], how="left")),
        "speed_bands": records(bands),
        "speed_bands_national": records(bands_total),
        "localities": records(locality.sort_values("total_accesses", ascending=False)),
        "locality_technologies": records(local_tech),
        "locality_speed_bands": records(locality_speed),
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(payload, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    print(f"OK: {OUT.relative_to(ROOT)}")
    print(f"Períodos: {period_count}; provincias: {province_count}; filas provinciales: {len(tech_prov)}")
    print(f"Diferencias entre suma de tecnologías y Total: {int((diff > 0).sum())} filas; máximo absoluto {diff.max():.0f}")
    print(f"Localidades: {len(locality)}; categorías de velocidad por provincia/período: {len(bands)}")


if __name__ == "__main__":
    main()
