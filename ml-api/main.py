import json
import logging
from pathlib import Path
from typing import Literal

import joblib
import numpy as np
import pandas as pd
from fastapi import FastAPI
from pydantic import BaseModel, Field

# ----------------------------------- Logging -----------------------------------

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(message)s",
)

logger = logging.getLogger("risk-api")

# ----------------------------------- Paths / model loading -----------------------------------


APP_DIR = Path(__file__).resolve().parent
ARTIFACT_DIR = APP_DIR / "artifacts"

model = joblib.load(ARTIFACT_DIR / "gradient_boosting_risk_model.joblib")

with open(ARTIFACT_DIR / "risk_model_metadata.json", "r", encoding="utf-8") as f:
    META = json.load(f)

FEATURE_ORDER = META["feature_order"]
ALCOHOL_MAP = META["alcohol_map"]
SOCIO_MAP = META["socio_map"]
WORK_MAP = META["work_map"]

logger.info("Model loaded successfully")
logger.info("Expected feature order: %s", FEATURE_ORDER)

# ----------------------------------- FastAPI app -----------------------------------

app = FastAPI(
    title="Patient Risk Prediction API",
    version="1.0.0",
)


# ----------------------------------- Request model -----------------------------------

class RiskInput(BaseModel):
    age: int = Field(ge=0, le=120)

    sex: Literal["male", "female"]

    smoking: bool = False
    packs_per_day: float = 0.0
    smoking_years: float = 0.0

    chicha: bool = False
    chicha_years: float = 0.0

    drugs: bool = False

    alcohol_frequency: Literal[
        "never",
        "rarely",
        "monthly",
        "weekly",
        "daily",
    ] = "never"

    socioeconomic_class: Literal[
        "low",
        "middle",
        "high",
        "unknown",
    ] = "unknown"

    work_status: Literal[
        "employed",
        "unemployed",
        "retired",
        "student",
    ] = "employed"

    lives_alone: bool = False
    has_caregiver: bool = False

    chronic_conditions_count: int = Field(ge=0, le=50)
    acute_conditions_count: int = Field(ge=0, le=50)

    medications_count: int = Field(ge=0, le=100)
    allergies_count: int = Field(ge=0, le=100)
    surgeries_count: int = Field(ge=0, le=100)
    hospitalizations_count: int = Field(ge=0, le=100)

    is_covid_vaccinated: bool = False


# Feature encoding


def encode_payload(payload: RiskInput) -> dict:
    sex_encoded = 1 if payload.sex == "male" else 0

    alcohol_encoded = ALCOHOL_MAP.get(
        payload.alcohol_frequency,
        0,
    )

    socio_encoded = SOCIO_MAP.get(
        payload.socioeconomic_class,
        1,
    )

    work_encoded = WORK_MAP.get(
        payload.work_status,
        1,
    )

    packs_per_day = (
        payload.packs_per_day
        if payload.smoking
        else 0.0
    )

    smoking_years = (
        payload.smoking_years
        if payload.smoking
        else 0.0
    )

    chicha_years = (
        payload.chicha_years
        if payload.chicha
        else 0.0
    )

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
        "chronic_conditions_count": float(
            payload.chronic_conditions_count
        ),
        "acute_conditions_count": float(
            payload.acute_conditions_count
        ),
        "medications_count": float(payload.medications_count),
        "allergies_count": float(payload.allergies_count),
        "surgeries_count": float(payload.surgeries_count),
        "hospitalizations_count": float(
            payload.hospitalizations_count
        ),
        "is_covid_vaccinated": float(
            payload.is_covid_vaccinated
        ),
    }


# ----------------------------------- Explanation generation -----------------------------------


def make_reasons(raw: RiskInput) -> list[str]:
    reasons = []

    if raw.smoking:
        if raw.packs_per_day >= 1:
            reasons.append(
                f"Smoking at {raw.packs_per_day:.1f} packs/day"
            )
        else:
            reasons.append("Current smoker")

    if raw.chicha:
        reasons.append("Chicha use")

    if raw.drugs:
        reasons.append("Drug use")

    if raw.alcohol_frequency in {"weekly", "daily"}:
        reasons.append(
            f"Alcohol frequency: {raw.alcohol_frequency}"
        )

    if raw.chronic_conditions_count >= 3:
        reasons.append(
            f"{raw.chronic_conditions_count} chronic conditions"
        )

    if raw.medications_count >= 5:
        reasons.append(
            f"{raw.medications_count} medications"
        )

    if raw.hospitalizations_count >= 2:
        reasons.append(
            f"{raw.hospitalizations_count} prior hospitalizations"
        )

    if raw.age >= 60:
        reasons.append(f"Age {raw.age}")

    if not raw.is_covid_vaccinated:
        reasons.append("Not COVID vaccinated")

    if raw.lives_alone and not raw.has_caregiver:
        reasons.append("Lives alone without caregiver")

    if not reasons:
        reasons.append("Few risk factors detected")

    return reasons[:5]


# ----------------------------------- Routes -----------------------------------


@app.get("/")
def root():
    return {
        "message": "Risk Prediction API running"
    }


@app.get("/health")
def health():
    return {
        "ok": True
    }


@app.post("/predict")
def predict(input_data: RiskInput):
    logger.info("Received /predict request")
    logger.info("Input: %s", input_data.model_dump())

    encoded = encode_payload(input_data)

    logger.info("Encoded payload: %s", encoded)

    X = pd.DataFrame(
        [[encoded[col] for col in FEATURE_ORDER]],
        columns=FEATURE_ORDER,
    )

    logger.info("Prediction dataframe:")
    logger.info("\n%s", X)

    proba = model.predict_proba(X)[0]
    pred = model.predict(X)[0]

    classes = list(model.classes_)

    probability_map = {
        str(cls): float(p)
        for cls, p in zip(classes, proba)
    }

    confidence = float(np.max(proba))

    logger.info("Prediction result: %s", pred)
    logger.info("Confidence: %s", confidence)

    return {
        "risk_level": str(pred),
        "confidence": confidence,
        "probabilities": probability_map,
        "reasons": make_reasons(input_data),
    }
