class PatientProfileModel {
  final String id;
  final String userId;
  final String? legalId;
  final String firstName;
  final String familyName;
  final String sex; // male, female, unknown
  final DateTime? dateOfBirth;
  final String? bloodType;
  final String? phone;
  final String? addressId;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? insurancePlan;
  final String? covidVaccineType;
  final String? familyDoctorId;
  final DateTime createdAt;
  final DateTime updatedAt;

  String? verificationStatus;

  PatientProfileModel({
    required this.id,
    required this.userId,
    this.legalId,
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
    required this.createdAt,
    required this.updatedAt,
  });

  factory PatientProfileModel.fromMap(Map<String, dynamic> map) {
    return PatientProfileModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      legalId: map['legal_id'] as String?,
      firstName: map['first_name'] as String,
      familyName: map['family_name'] as String,
      sex: map['sex'] as String? ?? 'unknown',
      dateOfBirth: map['date_of_birth'] != null
          ? DateTime.tryParse(map['date_of_birth'].toString())
          : null,
      bloodType: map['blood_type'] as String?,
      phone: map['phone'] as String?,
      addressId: map['address_id'] as String?,
      emergencyContactName: map['emergency_contact_name'] as String?,
      emergencyContactPhone: map['emergency_contact_phone'] as String?,
      insurancePlan: map['insurance_plan'] as String?,
      covidVaccineType: map['covid_vaccine_type'] as String?,
      familyDoctorId: map['family_doctor_id'] as String?,
      createdAt: DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'legal_id': legalId,
      'first_name': firstName,
      'family_name': familyName,
      'sex': sex,
      'date_of_birth': dateOfBirth?.toIso8601String().split('T').first,
      'blood_type': bloodType,
      'phone': phone,
      'address_id': addressId,
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_phone': emergencyContactPhone,
      'insurance_plan': insurancePlan,
      'covid_vaccine_type': covidVaccineType,
      'family_doctor_id': familyDoctorId,
    };
  }
}