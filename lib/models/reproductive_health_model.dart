import 'model_utils.dart';

// Represents a patient's reproductive health history and current status. --> maps to the 'reproductive_health' table in the database.
class ReproductiveHealthModel {
  final String? id;
  final String patientId;
  final bool? hasMenstrualCycle;
  final bool? cycleRegular;
  final bool? cyclePainful;
  final String? painLevel;
  final DateTime? lastPeriodStart;
  final DateTime? lastPeriodEnd;
  final bool? currentlyPregnant;
  final int? pregnancyTermWeeks;
  final int? gestity;
  final int? parity;
  final int? abortions;
  final int? pubertyAge;
  final String? breastExamNotes;
  final String? pregnancyHistory;
  final String? birthHistory;
  final String? abortionHistory;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ReproductiveHealthModel({
    this.id,
    required this.patientId,
    this.hasMenstrualCycle,
    this.cycleRegular,
    this.cyclePainful,
    this.painLevel,
    this.lastPeriodStart,
    this.lastPeriodEnd,
    this.currentlyPregnant,
    this.pregnancyTermWeeks,
    this.gestity,
    this.parity,
    this.abortions,
    this.pubertyAge,
    this.breastExamNotes,
    this.pregnancyHistory,
    this.birthHistory,
    this.abortionHistory,
    this.createdAt,
    this.updatedAt,
  });

  // Formats a DateTime to a YYYY-MM-DD.
  static String? _dateOnly(DateTime? value) {
    if (value == null) return null;
    return value.toIso8601String().split('T').first;
  }

  factory ReproductiveHealthModel.fromMap(Map map) {
    return ReproductiveHealthModel(
      id: map['id']?.toString(),
      patientId: map['patient_id']?.toString() ?? '',
      hasMenstrualCycle: asBool(map['has_menstrual_cycle']),
      cycleRegular: asBool(map['cycle_regular']),
      cyclePainful: asBool(map['cycle_painful']),
      painLevel: map['pain_level']?.toString(),
      lastPeriodStart: asDateTime(map['last_period_start']),
      lastPeriodEnd: asDateTime(map['last_period_end']),
      currentlyPregnant: asBool(map['currently_pregnant']),
      pregnancyTermWeeks: asInt(map['pregnancy_term_weeks']),
      gestity: asInt(map['gestity']),
      parity: asInt(map['parity']),
      abortions: asInt(map['abortions']),
      pubertyAge: asInt(map['puberty_age']),
      breastExamNotes: map['breast_exam_notes']?.toString(),
      pregnancyHistory: map['pregnancy_history']?.toString(),
      birthHistory: map['birth_history']?.toString(),
      abortionHistory: map['abortion_history']?.toString(),
      createdAt: asDateTime(map['created_at']),
      updatedAt: asDateTime(map['updated_at']),
    );
  }

  Map<String, dynamic> toInsertMap() => cleanMap({
    'patient_id': patientId,
    'has_menstrual_cycle': hasMenstrualCycle,
    'cycle_regular': cycleRegular,
    'cycle_painful': cyclePainful,
    'pain_level': painLevel,
    'last_period_start': _dateOnly(lastPeriodStart),
    'last_period_end': _dateOnly(lastPeriodEnd),
    'currently_pregnant': currentlyPregnant,
    'pregnancy_term_weeks': pregnancyTermWeeks,
    'gestity': gestity,
    'parity': parity,
    'abortions': abortions,
    'puberty_age': pubertyAge,
    'breast_exam_notes': breastExamNotes,
    'pregnancy_history': pregnancyHistory,
    'birth_history': birthHistory,
    'abortion_history': abortionHistory,
  });

  Map<String, dynamic> toUpdateMap() => cleanMap({
    'has_menstrual_cycle': hasMenstrualCycle,
    'cycle_regular': cycleRegular,
    'cycle_painful': cyclePainful,
    'pain_level': painLevel,
    'last_period_start': _dateOnly(lastPeriodStart),
    'last_period_end': _dateOnly(lastPeriodEnd),
    'currently_pregnant': currentlyPregnant,
    'pregnancy_term_weeks': pregnancyTermWeeks,
    'gestity': gestity,
    'parity': parity,
    'abortions': abortions,
    'puberty_age': pubertyAge,
    'breast_exam_notes': breastExamNotes,
    'pregnancy_history': pregnancyHistory,
    'birth_history': birthHistory,
    'abortion_history': abortionHistory,
  });

  Map<String, dynamic> toMap() => toInsertMap();
}
