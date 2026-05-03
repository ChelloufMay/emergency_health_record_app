class VaccinationModel {
  final String id;
  final String patientId;
  final String vaccineName;
  final String category; // covid, pnv, other
  final int? doseNumber;
  final DateTime? dateAdministered;
  final String? notes;
  final DateTime createdAt;

  VaccinationModel({
    required this.id,
    required this.patientId,
    required this.vaccineName,
    required this.category,
    this.doseNumber,
    this.dateAdministered,
    this.notes,
    required this.createdAt,
  });

  factory VaccinationModel.fromMap(Map<String, dynamic> map) {
    return VaccinationModel(
      id: map['id'] as String,
      patientId: map['patient_id'] as String,
      vaccineName: map['vaccine_name'] as String,
      category: map['category'] as String? ?? 'other',
      doseNumber: map['dose_number'] as int?,
      dateAdministered: map['date_administered'] != null
          ? DateTime.tryParse(map['date_administered'].toString())
          : null,
      notes: map['notes'] as String?,
      createdAt:
      DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patient_id': patientId,
      'vaccine_name': vaccineName,
      'category': category,
      'dose_number': doseNumber,
      'date_administered': dateAdministered?.toIso8601String().split('T').first,
      'notes': notes,
    };
  }
}