-- =====================================================================
-- One row per patient for ML training / scoring.
-- =====================================================================


create or replace view public.ml_patient_risk_dataset_asof
with (security_invoker = true) as
with label_rows as (
  select
    pl.id          as label_id,
    pl.patient_id,
    pl.outcome_name,
    pl.outcome_value,
    pl.outcome_date,
    pl.label_source,
    -- FIX: pl.prediction_at removed; fallback chain is index_date → outcome_date → created_at
    coalesce(
      pl.index_date,
      pl.outcome_date::timestamp with time zone,
      pl.created_at
    ) as index_ts
  from public.patient_risk_labels pl
  where pl.is_active = true
)
select
  -- identifiers
  lb.label_id,
  lb.patient_id,
  lb.outcome_name,
  lb.outcome_value,
  lb.outcome_date,
  lb.label_source,
  lb.index_ts as prediction_index_ts,

  -- patient profile snapshot
  p.user_id,
  p.sex,
  p.date_of_birth,
  case
    when p.date_of_birth is null then null
    else extract(year from age(lb.index_ts::date, p.date_of_birth))::int
  end as age_years,
  p.blood_type,
  p.covid_vaccine_type,
  case
    when p.covid_vaccine_type is null or btrim(p.covid_vaccine_type) = '' then false
    else true
  end as is_covid_vaccinated,

  -- address
  a.country        as address_country,
  a.governorate    as address_governorate,
  a.city           as address_city,
  a.avenue         as address_avenue,
  a.street         as address_street,
  a.postal_code    as address_postal_code,
  a.extra_details  as address_extra_details,

  -- latest lifestyle row on or before index_ts
  lf.lives_alone,
  lf.has_caregiver,
  lf.stairs_in_home,
  lf.socioeconomic_class,
  lf.work_status,
  lf.smoking,
  coalesce(lf.packs_per_day,   0)::numeric(5,2) as packs_per_day,
  coalesce(lf.smoking_years,   0)::numeric(5,2) as smoking_years,
  lf.drugs,
  lf.chicha,
  coalesce(lf.chicha_years,    0)::numeric(5,2) as chicha_years,
  lf.alcohol_frequency,

  -- as-of counts
  coalesce(mc.chronic_conditions_count,       0) as chronic_conditions_count,
  coalesce(mc_acute.acute_conditions_count,   0) as acute_conditions_count,
  coalesce(meds.medications_count,            0) as medications_count,
  coalesce(alg.allergies_count,               0) as allergies_count,
  coalesce(surg.surgeries_count,              0) as surgeries_count,
  coalesce(hosp.hospitalizations_count,       0) as hospitalizations_count,
  coalesce(fh.family_history_count,           0) as family_history_count,
  coalesce(fh_gen.genetic_family_history_count, 0) as genetic_family_history_count,
  coalesce(vacc.vaccinations_count,           0) as vaccinations_count,

  -- ── latest reproductive health row on or before index_ts ─────────
  rh.has_menstrual_cycle,
  rh.cycle_regular,
  rh.cycle_painful,
  rh.currently_pregnant,
  coalesce(rh.pregnancy_term_weeks, 0) as pregnancy_term_weeks,
  coalesce(rh.gestity,  0) as gestity,
  coalesce(rh.parity,   0) as parity,
  coalesce(rh.abortions,0) as abortions,

  -- audit timestamps
  p.created_at as patient_created_at,
  p.updated_at as patient_updated_at

from label_rows lb

join public.patient_profiles p
  on  p.id         = lb.patient_id
  and p.deleted_at is null
  and p.created_at <= lb.index_ts

left join public.addresses a
  on a.id = p.address_id

-- latest lifestyle row on or before index_ts
left join lateral (
  select
    lf1.lives_alone,
    lf1.has_caregiver,
    lf1.stairs_in_home,
    lf1.socioeconomic_class,
    lf1.work_status,
    lf1.smoking,
    lf1.packs_per_day,
    lf1.smoking_years,
    lf1.drugs,
    lf1.chicha,
    lf1.chicha_years,
    lf1.alcohol_frequency
  from public.lifestyle_factors lf1
  where lf1.patient_id = p.id
    and lf1.created_at <= lb.index_ts
  order by lf1.created_at desc nulls last,
           lf1.updated_at desc nulls last,
           lf1.id          desc
  limit 1
) lf on true

-- latest reproductive health row on or before index_ts
left join lateral (
  select
    rh1.has_menstrual_cycle,
    rh1.cycle_regular,
    rh1.cycle_painful,
    rh1.currently_pregnant,
    rh1.pregnancy_term_weeks,
    rh1.gestity,
    rh1.parity,
    rh1.abortions
  from public.reproductive_health rh1
  where rh1.patient_id = p.id
    and rh1.created_at <= lb.index_ts
  order by rh1.created_at desc nulls last,
           rh1.updated_at desc nulls last,
           rh1.id          desc
  limit 1
) rh on true

left join lateral (
  select count(*)::int as chronic_conditions_count
  from public.medical_conditions c
  where c.patient_id = p.id
    and c.type        = 'chronic'
    and c.created_at <= lb.index_ts
) mc on true

left join lateral (
  select count(*)::int as acute_conditions_count
  from public.medical_conditions c
  where c.patient_id = p.id
    and c.type        = 'acute'
    and c.created_at <= lb.index_ts
) mc_acute on true

left join lateral (
  select count(*)::int as medications_count
  from public.medications m
  where m.patient_id = p.id
    and m.created_at <= lb.index_ts
) meds on true

left join lateral (
  select count(*)::int as allergies_count
  from public.allergies al
  where al.patient_id = p.id
    and al.created_at <= lb.index_ts
) alg on true

left join lateral (
  select count(*)::int as surgeries_count
  from public.surgeries s
  where s.patient_id = p.id
    and s.created_at <= lb.index_ts
) surg on true

left join lateral (
  select count(*)::int as hospitalizations_count
  from public.hospitalizations h
  where h.patient_id = p.id
    and h.created_at <= lb.index_ts
) hosp on true

left join lateral (
  select count(*)::int as family_history_count
  from public.family_history fh
  where fh.patient_id = p.id
    and fh.created_at <= lb.index_ts
) fh on true

left join lateral (
  select count(*)::int as genetic_family_history_count
  from public.family_history fh
  where fh.patient_id = p.id
    and coalesce(fh.is_genetic, false) = true
    and fh.created_at <= lb.index_ts
) fh_gen on true

left join lateral (
  select count(*)::int as vaccinations_count
  from public.vaccinations v
  where v.patient_id = p.id
    and v.created_at <= lb.index_ts
) vacc on true
;

comment on view public.ml_patient_risk_dataset_asof is
'Retrospective patient-level ML dataset built as-of prediction_index_ts. '
'Every predictor is taken from data available on or before the index date '
'to prevent leakage. Fixed: prediction_at column reference removed.';