import 'model_utils.dart';

// Represents a patient's lifestyle and social history factors. --> maps to the 'lifestyle' table in the database.
class LifestyleModel {
  final String? id;
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
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const LifestyleModel({
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

  factory LifestyleModel.fromMap(Map map) {
    return LifestyleModel(
      id: map['id']?.toString(),
      patientId: map['patient_id']?.toString() ?? '',
      livesAlone: asBool(map['lives_alone']),
      hasCaregiver: asBool(map['has_caregiver']),
      stairsInHome: asBool(map['stairs_in_home']),
      socioeconomicClass: map['socioeconomic_class']?.toString() ?? 'unknown',
      workStatus: map['work_status']?.toString(),
      smoking: asBool(map['smoking']),
      packsPerDay: asDouble(map['packs_per_day']),
      smokingYears: asDouble(map['smoking_years']),
      drugs: asBool(map['drugs']),
      drugType: map['drug_type']?.toString(),
      drugQuantity: map['drug_quantity']?.toString(),
      chicha: asBool(map['chicha']),
      chichaYears: asDouble(map['chicha_years']),
      alcoholFrequency: map['alcohol_frequency']?.toString(),
      foodQuality: map['food_quality']?.toString(),
      milkType: map['milk_type']?.toString(),
      waterType: map['water_type']?.toString(),
      createdAt: asDateTime(map['created_at']),
      updatedAt: asDateTime(map['updated_at']),
    );
  }

  Map<String, dynamic> toInsertMap() => cleanMap({
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
  });

  Map<String, dynamic> toUpdateMap() => cleanMap({
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
  });

  Map<String, dynamic> toMap() => toInsertMap();
}
