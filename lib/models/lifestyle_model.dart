// single row per patient (UNIQUE constraint in DB)
class LifestyleModel {
  final String? id; // null if the row doesn't exist yet
  final String patientId;
  final bool? livesAlone;
  final bool? hasCaregiver;
  final bool? stairsInHome;
  final String socioeconomicClass;
  final String? workStatus;
  final bool? smoking;
  final double? packsPerDay;
  final double? smokingYears;
  final bool? drugs;
  final String? drugType;
  final String? drugQuantity;
  final bool? chicha;
  final double? chichaYears;
  final String? alcoholFrequency;
  final String? foodQuality;
  final String? milkType;
  final String? waterType;

  // Database timestamps
  final DateTime? createdAt;
  final DateTime? updatedAt;

  LifestyleModel({
    this.id,
    required this.patientId,
    this.livesAlone,
    this.hasCaregiver,
    this.stairsInHome,
    this.socioeconomicClass = 'unknown',
    this.workStatus,
    this.smoking,
    this.packsPerDay,
    this.smokingYears,
    this.drugs,
    this.drugType,
    this.drugQuantity,
    this.chicha,
    this.chichaYears,
    this.alcoholFrequency,
    this.foodQuality,
    this.milkType,
    this.waterType,
    this.createdAt,
    this.updatedAt,
  });

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  factory LifestyleModel.fromMap(Map<String, dynamic> map) {
    return LifestyleModel(
      id: map['id'] as String?,
      patientId: map['patient_id'] as String,
      livesAlone: map['lives_alone'] as bool?,
      hasCaregiver: map['has_caregiver'] as bool?,
      stairsInHome: map['stairs_in_home'] as bool?,
      socioeconomicClass: map['socioeconomic_class'] as String? ?? 'unknown',
      workStatus: map['work_status'] as String?,
      smoking: map['smoking'] as bool?,
      packsPerDay: map['packs_per_day'] != null
          ? double.tryParse(map['packs_per_day'].toString())
          : null,
      smokingYears: map['smoking_years'] != null
          ? double.tryParse(map['smoking_years'].toString())
          : null,
      drugs: map['drugs'] as bool?,
      drugType: map['drug_type'] as String?,
      drugQuantity: map['drug_quantity'] as String?,
      chicha: map['chicha'] as bool?,
      chichaYears: map['chicha_years'] != null
          ? double.tryParse(map['chicha_years'].toString())
          : null,
      alcoholFrequency: map['alcohol_frequency'] as String?,
      foodQuality: map['food_quality'] as String?,
      milkType: map['milk_type'] as String?,
      waterType: map['water_type'] as String?,
      createdAt: _parseDateTime(map['created_at']),
      updatedAt: _parseDateTime(map['updated_at']),
    );
  }

  /// For inserts/updates: timestamps are managed by the database.
  Map<String, dynamic> toMap() {
    return {
      'patient_id': patientId,
      'lives_alone': livesAlone,
      'has_caregiver': hasCaregiver,
      'stairs_in_home': stairsInHome,
      'socioeconomic_class': socioeconomicClass,
      'work_status': workStatus,
      'smoking': smoking,
      'packs_per_day': packsPerDay,
      'smoking_years': smokingYears,
      'drugs': drugs,
      'drug_type': drugType,
      'drug_quantity': drugQuantity,
      'chicha': chicha,
      'chicha_years': chichaYears,
      'alcohol_frequency': alcoholFrequency,
      'food_quality': foodQuality,
      'milk_type': milkType,
      'water_type': waterType,
    };
  }
}