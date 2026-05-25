-- =====================================================================
-- Cohort export queries for ML training and validation.
--
-- FIX: all queries now target ml_patient_risk_dataset_asof
--      (the view that actually exists). The old name
--      ml_patient_risk_dataset was never created.
--
-- Recommended split strategy:
--   1) Training cohort        → older patient records
--   2) Internal validation   → held-out newer records, same source
--   3) External validation   → a later time window / different site
--
-- Adjust the date boundaries to match your real project timeline.
-- =====================================================================


-- ---------------------------------------------------------------------
-- A) TRAINING COHORT
-- Older patients only: the model learns from these rows.
-- ---------------------------------------------------------------------
select *
from public.ml_patient_risk_dataset_asof
where patient_created_at <  date '2025-01-01'
  and outcome_name        is not null
order by patient_created_at asc;


-- ---------------------------------------------------------------------
-- B) INTERNAL VALIDATION COHORT
-- Held-out records from the same source, slightly newer.
-- ---------------------------------------------------------------------
select *
from public.ml_patient_risk_dataset_asof
where patient_created_at >= date '2025-01-01'
  and patient_created_at <  date '2025-04-01'
  and outcome_name        is not null
order by patient_created_at asc;


-- ---------------------------------------------------------------------
-- C) EXTERNAL VALIDATION COHORT
-- A later time window (or a different clinic/site if you add that field).
-- ---------------------------------------------------------------------
select *
from public.ml_patient_risk_dataset_asof
where patient_created_at >= date '2025-04-01'
  and outcome_name        is not null
order by patient_created_at asc;


-- ---------------------------------------------------------------------
-- D) MODEL INPUT COLUMNS + TARGET LABEL (lean export)
-- Use this when you only need the predictor columns and one outcome.
-- Replace 'hospitalization_90d' with your actual outcome_name value.
-- ---------------------------------------------------------------------
select
  -- identifiers
  patient_id,
  label_id,
  outcome_name,
  outcome_value,          -- this is the label / target

  -- demographics
  age_years,
  sex,
  blood_type,
  is_covid_vaccinated,

  -- social / lifestyle
  lives_alone,
  has_caregiver,
  stairs_in_home,
  socioeconomic_class,
  work_status,
  smoking,
  packs_per_day,
  smoking_years,
  chicha,
  chicha_years,
  drugs,
  alcohol_frequency,

  -- clinical counts (as of index date: no leakage)
  chronic_conditions_count,
  acute_conditions_count,
  medications_count,
  allergies_count,
  surgeries_count,
  hospitalizations_count,
  family_history_count,
  genetic_family_history_count,
  vaccinations_count,

  -- reproductive health
  currently_pregnant,
  pregnancy_term_weeks,
  parity,
  abortions

from public.ml_patient_risk_dataset_asof
where outcome_name = 'hospitalization_90d'
  and outcome_value is not null
order by prediction_index_ts asc;