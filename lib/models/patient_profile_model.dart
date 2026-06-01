import 'model_utils.dart';

// Represents a patient's core profile information. --> maps to the 'patient_profiles' table in the database.
class PatientProfileModel {
  final String? id;
  final String userId;
  final String firstName;
  final String familyName;
  final String sex;
  final DateTime? dateOfBirth;
  final String? bloodType;
  final String? phone;
  final String? addressId;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? insurancePlan;
  final String? covidVaccineType;
  final String? familyDoctorId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PatientProfileModel({
    this.id,
    required this.userId,
    required this.firstName,
    required this.familyName,
    required this.sex,
    this.dateOfBirth,
    this.bloodType,
    this.phone,
    this.addressId,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.insurancePlan,
    this.covidVaccineType,
    this.familyDoctorId,
    this.createdAt,
    this.updatedAt,
  });

  // Formats a DateTime to a YYYY-MM-DD.
  static String? _dateOnly(DateTime? value) {
    if (value == null) return null;
    return value.toIso8601String().split('T').first;
  }

  factory PatientProfileModel.fromMap(Map map) {
    return PatientProfileModel(
      id: map['id']?.toString(),
      userId: map['user_id']?.toString() ?? '',
      firstName: map['first_name']?.toString() ?? '',
      familyName: map['family_name']?.toString() ?? '',
      sex: map['sex']?.toString() ?? 'unknown',
      dateOfBirth: asDateTime(map['date_of_birth']),
      bloodType: map['blood_type']?.toString(),
      phone: map['phone']?.toString(),
      addressId: map['address_id']?.toString(),
      emergencyContactName: map['emergency_contact_name']?.toString(),
      emergencyContactPhone: map['emergency_contact_phone']?.toString(),
      insurancePlan: map['insurance_plan']?.toString(),
      covidVaccineType: map['covid_vaccine_type']?.toString(),
      familyDoctorId: map['family_doctor_id']?.toString(),
      createdAt: asDateTime(map['created_at']),
      updatedAt: asDateTime(map['updated_at']),
    );
  }

  Map<String, dynamic> toInsertMap() => cleanMap({
    'user_id': userId,
    'first_name': firstName,
    'family_name': familyName,
    'sex': sex,
    'date_of_birth': _dateOnly(dateOfBirth),
    'blood_type': bloodType,
    'phone': phone,
    'address_id': addressId,
    'emergency_contact_name': emergencyContactName,
    'emergency_contact_phone': emergencyContactPhone,
    'insurance_plan': insurancePlan,
    'covid_vaccine_type': covidVaccineType,
    'family_doctor_id': familyDoctorId,
  });

  Map<String, dynamic> toUpdateMap() => cleanMap({
    'first_name': firstName,
    'family_name': familyName,
    'sex': sex,
    'date_of_birth': _dateOnly(dateOfBirth),
    'blood_type': bloodType,
    'phone': phone,
    'address_id': addressId,
    'emergency_contact_name': emergencyContactName,
    'emergency_contact_phone': emergencyContactPhone,
    'insurance_plan': insurancePlan,
    'covid_vaccine_type': covidVaccineType,
    'family_doctor_id': familyDoctorId,
  });

  Map<String, dynamic> toMap() => toInsertMap();
}
