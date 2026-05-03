class SurgeryModel {
  final String id;
  final String patientId;
  final String surgeryName;
  final DateTime? surgeryDate;
  final String? place;
  final String? prostheticOrImplant;
  final String? notes;
  final DateTime createdAt;

  SurgeryModel({
    required this.id,
    required this.patientId,
    required this.surgeryName,
    this.surgeryDate,
    this.place,
    this.prostheticOrImplant,
    this.notes,
    required this.createdAt,
  });

  factory SurgeryModel.fromMap(Map<String, dynamic> map) {
    return SurgeryModel(
      id: map['id'] as String,
      patientId: map['patient_id'] as String,
      surgeryName: map['surgery_name'] as String,
      surgeryDate: map['surgery_date'] != null
          ? DateTime.tryParse(map['surgery_date'].toString())
          : null,
      place: map['place'] as String?,
      prostheticOrImplant: map['prosthetic_or_implant'] as String?,
      notes: map['notes'] as String?,
      createdAt:
      DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patient_id': patientId,
      'surgery_name': surgeryName,
      'surgery_date': surgeryDate?.toIso8601String().split('T').first,
      'place': place,
      'prosthetic_or_implant': prostheticOrImplant,
      'notes': notes,
    };
  }
}