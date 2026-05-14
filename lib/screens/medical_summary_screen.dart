import 'package:flutter/material.dart';

import '../models/allergy_model.dart';
import '../models/attachment_model.dart';
import '../models/family_doctor_model.dart';
import '../models/family_history_model.dart';
import '../models/hospitalization_model.dart';
import '../models/lifestyle_model.dart';
import '../models/medical_condition_model.dart';
import '../models/medication_model.dart';
import '../models/reproductive_health_model.dart';
import '../models/surgery_model.dart';
import '../models/vaccination_model.dart';
import '../services/allergy_service.dart';
import '../services/attachment_service.dart';
import '../services/family_doctor_service.dart';
import '../services/family_history_service.dart';
import '../services/hospitalization_service.dart';
import '../services/lifestyle_service.dart';
import '../services/medical_condition_service.dart';
import '../services/medication_service.dart';
import '../services/patient_service.dart';
import '../services/patient_session_service.dart';
import '../services/reproductive_health_service.dart';
import '../services/surgery_service.dart';
import '../services/vaccination_service.dart';

class MedicalSummaryScreen extends StatefulWidget {
  final String? patientId;
  final bool canEdit;
  final bool isEmergencyOnly;

  const MedicalSummaryScreen({
    super.key,
    this.patientId,
    this.canEdit = false,
    this.isEmergencyOnly = false,
  });

  @override
  State<MedicalSummaryScreen> createState() => _MedicalSummaryScreenState();
}

class _MedicalSummaryScreenState extends State<MedicalSummaryScreen> {
  final PatientService _patientService = PatientService();
  final AllergyService _allergyService = AllergyService();
  final MedicationService _medicationService = MedicationService();
  final MedicalConditionService _conditionService = MedicalConditionService();
  final SurgeryService _surgeryService = SurgeryService();
  final HospitalizationService _hospitalizationService = HospitalizationService();
  final VaccinationService _vaccinationService = VaccinationService();
  final LifestyleService _lifestyleService = LifestyleService();
  final FamilyHistoryService _familyHistoryService = FamilyHistoryService();
  final ReproductiveHealthService _reproductiveHealthService = ReproductiveHealthService();
  final FamilyDoctorService _familyDoctorService = FamilyDoctorService();
  final AttachmentService _attachmentService = AttachmentService();

  bool _loading = true;
  String? _patientId;
  Map<String, dynamic>? _summary;
  List<AllergyModel> _allergies = [];
  List<MedicationModel> _medications = [];
  List<MedicalConditionModel> _conditions = [];
  List<SurgeryModel> _surgeries = [];
  List<HospitalizationModel> _hospitalizations = [];
  List<VaccinationModel> _vaccinations = [];
  LifestyleModel? _lifestyle;
  List<FamilyHistoryModel> _familyHistory = [];
  ReproductiveHealthModel? _reproductiveHealth;
  FamilyDoctorModel? _familyDoctor;
  List<AttachmentModel> _attachments = [];

  String? _resolvePatientId() => widget.patientId ?? PatientSessionService.instance.current?.patientId;

  Future<void> _load() async {
    final patientId = _resolvePatientId();
    if (patientId == null || patientId.isEmpty) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    final results = await Future.wait([
      _patientService.fetchPatientSummary(patientId),
      _allergyService.fetchByPatient(patientId),
      _medicationService.fetchByPatient(patientId),
      _conditionService.fetchByPatient(patientId),
      _surgeryService.fetchByPatient(patientId),
      _hospitalizationService.fetchByPatient(patientId),
      _vaccinationService.fetchByPatient(patientId),
      _lifestyleService.fetchByPatient(patientId),
      _familyHistoryService.fetchByPatient(patientId),
      _reproductiveHealthService.fetchByPatient(patientId),
      _familyDoctorService.fetchForPatient(patientId),
      _attachmentService.fetchByPatient(patientId),
    ]);

    if (!mounted) return;

    setState(() {
      _patientId = patientId;
      _summary = results[0] as Map<String, dynamic>?;
      _allergies = List<AllergyModel>.from(results[1] as List);
      _medications = List<MedicationModel>.from(results[2] as List);
      _conditions = List<MedicalConditionModel>.from(results[3] as List);
      _surgeries = List<SurgeryModel>.from(results[4] as List);
      _hospitalizations = List<HospitalizationModel>.from(results[5] as List);
      _vaccinations = List<VaccinationModel>.from(results[6] as List);
      _lifestyle = results[7] as LifestyleModel?;
      _familyHistory = List<FamilyHistoryModel>.from(results[8] as List);
      _reproductiveHealth = results[9] as ReproductiveHealthModel?;
      _familyDoctor = results[10] as FamilyDoctorModel?;
      _attachments = List<AttachmentModel>.from(results[11] as List);
      _loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Widget _sectionCard(String title, IconData icon, List<Widget> children) {
    return Card(
      child: ExpansionTile(
        leading: Icon(icon),
        title: Text(title),
        children: children.isEmpty ? [const ListTile(title: Text('No records'))] : children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = [
      _summary?['first_name']?.toString() ?? '',
      _summary?['family_name']?.toString() ?? '',
    ].join(' ').trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical summary'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _patientId == null
          ? const Center(child: Text('No patient selected.'))
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.person),
              title: Text(name.isEmpty ? 'Unknown patient' : name),
              subtitle: Text([
                'Age: ${_summary?['age_years']?.toString() ?? '-'}',
                'Sex: ${_summary?['sex']?.toString() ?? '-'}',
                'Blood type: ${_summary?['blood_type']?.toString() ?? '-'}',
                'Phone: ${_summary?['phone']?.toString() ?? '-'}',
              ].join('\n')),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              title: const Text('Emergency contact'),
              subtitle: Text([
                _summary?['emergency_contact_name']?.toString() ?? '-',
                _summary?['emergency_contact_phone']?.toString() ?? '-',
              ].join('\n')),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              title: const Text('Address'),
              subtitle: Text([
                _summary?['address_country']?.toString(),
                _summary?['address_governorate']?.toString(),
                _summary?['address_city']?.toString(),
                _summary?['address_avenue']?.toString(),
                _summary?['address_street']?.toString(),
                _summary?['address_postal_code']?.toString(),
              ].where((v) => v != null && v.trim().isNotEmpty).join(', ')),
            ),
          ),
          const SizedBox(height: 12),
          _sectionCard(
            'Allergies (${_allergies.length})',
            Icons.warning_amber,
            _allergies.map((a) {
              return ListTile(
                title: Text(a.allergenName),
                subtitle: Text([
                  'Type: ${a.allergyType}',
                  if ((a.reaction ?? '').isNotEmpty) 'Reaction: ${a.reaction}',
                  if ((a.severity ?? '').isNotEmpty) 'Severity: ${a.severity}',
                ].join('\n')),
              );
            }).toList(),
          ),
          _sectionCard(
            'Medications (${_medications.length})',
            Icons.medication,
            _medications.map((m) {
              return ListTile(
                title: Text(m.medicationName),
                subtitle: Text([
                  if ((m.dosage ?? '').isNotEmpty) 'Dosage: ${m.dosage}',
                  if ((m.frequency ?? '').isNotEmpty) 'Frequency: ${m.frequency}',
                  if ((m.purpose ?? '').isNotEmpty) 'Purpose: ${m.purpose}',
                ].join('\n')),
              );
            }).toList(),
          ),
          _sectionCard(
            'Conditions (${_conditions.length})',
            Icons.local_hospital,
            _conditions.map((c) {
              return ListTile(
                title: Text(c.conditionName),
                subtitle: Text([
                  'Type: ${c.type}',
                  if (c.diagnosisDate != null) 'Diagnosed: ${c.diagnosisDate!.toIso8601String().split('T').first}',
                  if ((c.treatment ?? '').isNotEmpty) 'Treatment: ${c.treatment}',
                ].join('\n')),
              );
            }).toList(),
          ),
          _sectionCard(
            'Surgeries (${_surgeries.length})',
            Icons.cut,
            _surgeries.map((s) {
              return ListTile(
                title: Text(s.surgeryName),
                subtitle: Text([
                  if (s.surgeryDate != null) 'Date: ${s.surgeryDate!.toIso8601String().split('T').first}',
                  if ((s.place ?? '').isNotEmpty) 'Place: ${s.place}',
                  if ((s.prostheticOrImplant ?? '').isNotEmpty) 'Implant: ${s.prostheticOrImplant}',
                ].join('\n')),
              );
            }).toList(),
          ),
          _sectionCard(
            'Hospitalizations (${_hospitalizations.length})',
            Icons.bed_outlined,
            _hospitalizations.map((h) {
              return ListTile(
                title: Text(h.hospitalName ?? 'Hospitalization'),
                subtitle: Text([
                  if (h.admissionDate != null) 'Admission: ${h.admissionDate!.toIso8601String().split('T').first}',
                  if (h.dischargeDate != null) 'Discharge: ${h.dischargeDate!.toIso8601String().split('T').first}',
                  if ((h.reason ?? '').isNotEmpty) 'Reason: ${h.reason}',
                ].join('\n')),
              );
            }).toList(),
          ),
          _sectionCard(
            'Vaccinations (${_vaccinations.length})',
            Icons.vaccines,
            _vaccinations.map((v) {
              return ListTile(
                title: Text(v.vaccineName),
                subtitle: Text([
                  'Category: ${v.category}',
                  if (v.doseNumber != null) 'Dose: ${v.doseNumber}',
                  if (v.dateAdministered != null) 'Date: ${v.dateAdministered!.toIso8601String().split('T').first}',
                ].join('\n')),
              );
            }).toList(),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.self_improvement),
              title: const Text('Lifestyle'),
              subtitle: Text(
                _lifestyle == null
                    ? 'No record'
                    : [
                  'Socioeconomic class: ${_lifestyle!.socioeconomicClass}',
                  'Lives alone: ${_lifestyle!.livesAlone ?? '-'}',
                  'Has caregiver: ${_lifestyle!.hasCaregiver ?? '-'}',
                  'Stairs in home: ${_lifestyle!.stairsInHome ?? '-'}',
                  if ((_lifestyle!.workStatus ?? '').isNotEmpty) 'Work status: ${_lifestyle!.workStatus}',
                  if (_lifestyle!.smoking != null) 'Smoking: ${_lifestyle!.smoking}',
                  if (_lifestyle!.drugs != null) 'Drugs: ${_lifestyle!.drugs}',
                ].join('\n'),
              ),
            ),
          ),
          _sectionCard(
            'Family history (${_familyHistory.length})',
            Icons.family_restroom,
            _familyHistory.map((f) {
              return ListTile(
                title: Text(f.conditionName),
                subtitle: Text([
                  if ((f.relation ?? '').isNotEmpty) 'Relation: ${f.relation}',
                  if ((f.category ?? '').isNotEmpty) 'Category: ${f.category}',
                  if (f.isGenetic != null) 'Genetic: ${f.isGenetic}',
                  if ((f.notes ?? '').isNotEmpty) 'Notes: ${f.notes}',
                ].join('\n')),
              );
            }).toList(),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.healing),
              title: const Text('Reproductive health'),
              subtitle: Text(
                _reproductiveHealth == null
                    ? 'No record'
                    : [
                  if (_reproductiveHealth!.currentlyPregnant != null) 'Currently pregnant: ${_reproductiveHealth!.currentlyPregnant}',
                  if (_reproductiveHealth!.cycleRegular != null) 'Cycle regular: ${_reproductiveHealth!.cycleRegular}',
                  if (_reproductiveHealth!.cyclePainful != null) 'Cycle painful: ${_reproductiveHealth!.cyclePainful}',
                  if (_reproductiveHealth!.pregnancyTermWeeks != null) 'Pregnancy term weeks: ${_reproductiveHealth!.pregnancyTermWeeks}',
                  if (_reproductiveHealth!.gestity != null) 'Gestity: ${_reproductiveHealth!.gestity}',
                  if (_reproductiveHealth!.parity != null) 'Parity: ${_reproductiveHealth!.parity}',
                  if (_reproductiveHealth!.abortions != null) 'Abortions: ${_reproductiveHealth!.abortions}',
                ].join('\n'),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.person_search),
              title: const Text('Family doctor'),
              subtitle: Text(
                _familyDoctor == null
                    ? 'No record'
                    : [
                  _familyDoctor!.fullName,
                  if ((_familyDoctor!.phone ?? '').isNotEmpty) _familyDoctor!.phone!,
                  if ((_familyDoctor!.notes ?? '').isNotEmpty) _familyDoctor!.notes!,
                ].join('\n'),
              ),
            ),
          ),
          _sectionCard(
            'Attachments (${_attachments.length})',
            Icons.attach_file,
            _attachments.map((a) {
              return ListTile(
                title: Text(a.fileName),
                subtitle: Text([
                  'Kind: ${a.fileKind}',
                  if ((a.fileType ?? '').isNotEmpty) 'Type: ${a.fileType}',
                  if (a.documentDate != null) 'Date: ${a.documentDate!.toIso8601String().split('T').first}',
                  if ((a.description ?? '').isNotEmpty) 'Description: ${a.description}',
                ].join('\n')),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}