class PatientProfileModel {
  final String? id;
  final String userId;
  final String? legalId;
  final String firstName;
  final String familyName;
  final String sex;
  final DateTime? dateOfBirth;
  final String? bloodType;
  final String? phone;

  // This links the patient profile to the row in public.addresses.
  final String? addressId;

  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? insurancePlan;
  final String? covidVaccineType;
  final String? familyDoctorId;

  PatientProfileModel({
    this.id,
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
  });

  factory PatientProfileModel.fromMap(Map<String, dynamic> map) {
    return PatientProfileModel(
      id: map['id']?.toString(),
      userId: map['user_id']?.toString() ?? '',
      legalId: map['legal_id']?.toString(),
      firstName: map['first_name']?.toString() ?? '',
      familyName: map['family_name']?.toString() ?? '',
      sex: map['sex']?.toString() ?? 'unknown',
      dateOfBirth: map['date_of_birth'] == null
          ? null
          : DateTime.tryParse(map['date_of_birth'].toString()),
      bloodType: map['blood_type']?.toString(),
      phone: map['phone']?.toString(),

      //keep the patient-address relation in the model.
      addressId: map['address_id']?.toString(),

      emergencyContactName: map['emergency_contact_name']?.toString(),
      emergencyContactPhone: map['emergency_contact_phone']?.toString(),
      insurancePlan: map['insurance_plan']?.toString(),
      covidVaccineType: map['covid_vaccine_type']?.toString(),
      familyDoctorId: map['family_doctor_id']?.toString(),
    );
  }

  Map<String, dynamic> toInsertMap() {
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

  // Keep update payload identical to insert payload.
  // This helps the RPC/service layer treat profile save as an upsert.
  Map<String, dynamic> toUpdateMap() => toInsertMap();
}