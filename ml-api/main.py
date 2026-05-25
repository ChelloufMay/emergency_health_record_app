import json
from pathlib import Path
from typing import Literal, Optional

import joblib
import numpy as np
from fastapi import FastAPI
from pydantic import BaseModel, Field

APP_DIR = Path(__file__).resolve().parent
ARTIFACT_DIR = APP_DIR / "artifacts"

model = joblib.load(ARTIFACT_DIR / "gradient_boosting_risk_model.joblib")

with open(ARTIFACT_DIR / "risk_model_metadata.json", "r", encoding="utf-8") as f:
    META = json.load(f)

FEATURE_ORDER = META["feature_order"]
ALCOHOL_MAP = META["alcohol_map"]
SOCIO_MAP = META["socio_map"]
WORK_MAP = META["work_map"]

app = FastAPI(title="Patient Risk Prediction API", version="1.0.0")


class RiskInput(BaseModel):
    age: int = Field(ge=0, le=120)
    sex: Literal["male", "female"]
    smoking: bool = False
    packs_per_day: float = 0.0
    smoking_years: float = 0.0
    chicha: bool = False
    chicha_years: float = 0.0
    drugs: bool = False
    alcohol_frequency: Literal["never", "rarely", "monthly", "weekly", "daily"] = "never"
    socioeconomic_class: Literal["low", "middle", "high", "unknown"] = "unknown"
    work_status: Literal["employed", "unemployed", "retired", "student"] = "employed"
    lives_alone: bool = False
    has_caregiver: bool = False
    chronic_conditions_count: int = Field(ge=0, le=50)
    acute_conditions_count: int = Field(ge=0, le=50)
    medications_count: int = Field(ge=0, le=100)
    allergies_count: int = Field(ge=0, le=100)
    surgeries_count: int = Field(ge=0, le=100)
    hospitalizations_count: int = Field(ge=0, le=100)
    is_covid_vaccinated: bool = False


def encode_payload(payload: RiskInput) -> dict:
    sex_encoded = 1 if payload.sex == "male" else 0
    alcohol_encoded = ALCOHOL_MAP.get(payload.alcohol_frequency, 0)
    socio_encoded = SOCIO_MAP.get(payload.socioeconomic_class, 1)
    work_encoded = WORK_MAP.get(payload.work_status, 1)

    # keep consumption fields consistent with the notebook rules
    packs_per_day = payload.packs_per_day if payload.smoking else 0.0
    smoking_years = payload.smoking_years if payload.smoking else 0.0
    chicha_years = payload.chicha_years if payload.chicha else 0.0

    return {
        "age": float(payload.age),
        "sex_encoded": float(sex_encoded),
        "smoking": float(payload.smoking),
        "packs_per_day": float(packs_per_day),
        "smoking_years": float(smoking_years),
        "chicha": float(payload.chicha),
        "chicha_years": float(chicha_years),
        "drugs": float(payload.drugs),
        "alcohol_encoded": float(alcohol_encoded),
        "socio_encoded": float(socio_encoded),
        "work_encoded": float(work_encoded),
        "lives_alone": float(payload.lives_alone),
        "has_caregiver": float(payload.has_caregiver),
        "chronic_conditions_count": float(payload.chronic_conditions_count),
        "acute_conditions_count": float(payload.acute_conditions_count),
        "medications_count": float(payload.medications_count),
        "allergies_count": float(payload.allergies_count),
        "surgeries_count": float(payload.surgeries_count),
        "hospitalizations_count": float(payload.hospitalizations_count),
        "is_covid_vaccinated": float(payload.is_covid_vaccinated),
    }


def make_reasons(raw: RiskInput) -> list[str]:
    reasons = []

    if raw.smoking:
        if raw.packs_per_day >= 1:
            reasons.append(f"Smoking at {raw.packs_per_day:.1f} packs/day")
        else:
            reasons.append("Current smoker")

    if raw.chicha:
        reasons.append("Chicha use")

    if raw.drugs:
        reasons.append("Drug use")

    if raw.alcohol_frequency in {"weekly", "daily"}:
        reasons.append(f"Alcohol frequency: {raw.alcohol_frequency}")

    if raw.chronic_conditions_count >= 3:
        reasons.append(f"{raw.chronic_conditions_count} chronic conditions")

    if raw.medications_count >= 5:
        reasons.append(f"{raw.medications_count} medications")

    if raw.hospitalizations_count >= 2:
        reasons.append(f"{raw.hospitalizations_count} prior hospitalizations")

    if raw.age >= 60:
        reasons.append(f"Age {raw.age}")

    if not raw.is_covid_vaccinated:
        reasons.append("Not COVID vaccinated")

    if raw.lives_alone and not raw.has_caregiver:
        reasons.append("Lives alone without caregiver")

    if not reasons:
        reasons.append("Few risk factors detected")

    return reasons[:5]


@app.get("/health")
def health():
    return {"ok": True}


@app.post("/predict")
def predict(input_data: RiskInput):
    row = encode_payload(input_data)
    X = np.array([[row[name] for name in FEATURE_ORDER]], dtype=float)

    proba = model.predict_proba(X)[0]
    pred = model.predict(X)[0]

    classes = list(model.classes_)
    probability_map = {cls: float(p) for cls, p in zip(classes, proba)}
    confidence = float(np.max(proba))

    return {
        "risk_level": str(pred),
        "confidence": confidence,
        "probabilities": probability_map,
        "reasons": make_reasons(input_data),
    }