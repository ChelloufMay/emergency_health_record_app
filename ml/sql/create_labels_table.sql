-- =====================================================================
-- Stores the real supervised-learning outcomes for the ML project.
--
-- Recommended outcome_name values for this project:
--   - triage_risk_30d
--   - triage_risk_90d
--   - hospitalization_90d
--   - urgent_review_90d
--
-- outcome_value can be:
--   - low / medium / high     (3-class triage)
--   - 0 / 1                   (binary outcome)
--   - any other controlled label you define
-- =====================================================================

create table if not exists public.patient_risk_labels (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.patient_profiles(id) on delete cascade,
  outcome_name text not null,
  outcome_value text not null,
  outcome_date date not null,
  label_source text not null default 'manual_review',
  is_active boolean not null default true,
  notes text,
  created_at timestamp without time zone not null default now(),
  updated_at timestamp without time zone not null default now(),
  constraint patient_risk_labels_outcome_name_chk
    check (btrim(outcome_name) <> ''),
  constraint patient_risk_labels_outcome_value_chk
    check (btrim(outcome_value) <> ''),
  constraint patient_risk_labels_label_source_chk
    check (btrim(label_source) <> '')
);

create index if not exists idx_patient_risk_labels_patient_outcome_date
  on public.patient_risk_labels (patient_id, outcome_name, outcome_date desc);

create index if not exists idx_patient_risk_labels_active
  on public.patient_risk_labels (patient_id, outcome_name, is_active);

create or replace function public.set_patient_risk_labels_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_patient_risk_labels_updated_at on public.patient_risk_labels;
create trigger trg_patient_risk_labels_updated_at
before update on public.patient_risk_labels
for each row
execute function public.set_patient_risk_labels_updated_at();

comment on table public.patient_risk_labels is
'Real supervised-learning labels for patient risk prediction; one patient may have multiple outcomes over time.';
