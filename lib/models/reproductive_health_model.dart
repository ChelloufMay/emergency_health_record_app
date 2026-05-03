// single row per patient --> only relevant when sex == 'female'
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

  ReproductiveHealthModel({
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
  });

  factory ReproductiveHealthModel.fromMap(Map<String, dynamic> map) {
    return ReproductiveHealthModel(
      id: map['id'] as String?,
      patientId: map['patient_id'] as String,
      hasMenstrualCycle: map['has_menstrual_cycle'] as bool?,
      cycleRegular: map['cycle_regular'] as bool?,
      cyclePainful: map['cycle_painful'] as bool?,
      painLevel: map['pain_level'] as String?,
      lastPeriodStart: map['last_period_start'] != null
          ? DateTime.tryParse(map['last_period_start'].toString())
          : null,
      lastPeriodEnd: map['last_period_end'] != null
          ? DateTime.tryParse(map['last_period_end'].toString())
          : null,
      currentlyPregnant: map['currently_pregnant'] as bool?,
      pregnancyTermWeeks: map['pregnancy_term_weeks'] as int?,
      gestity: map['gestity'] as int?,
      parity: map['parity'] as int?,
      abortions: map['abortions'] as int?,
      pubertyAge: map['puberty_age'] as int?,
      breastExamNotes: map['breast_exam_notes'] as String?,
      pregnancyHistory: map['pregnancy_history'] as String?,
      birthHistory: map['birth_history'] as String?,
      abortionHistory: map['abortion_history'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patient_id': patientId,
      'has_menstrual_cycle': hasMenstrualCycle,
      'cycle_regular': cycleRegular,
      'cycle_painful': cyclePainful,
      'pain_level': painLevel,
      'last_period_start': lastPeriodStart?.toIso8601String().split('T').first,
      'last_period_end': lastPeriodEnd?.toIso8601String().split('T').first,
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
    };
  }
}