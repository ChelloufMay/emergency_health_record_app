import 'package:flutter/foundation.dart';

enum PatientAccessMode {
  owner,
  read,
  edit,
  emergencyOnly,
}

class PatientSession {
  final String patientId;
  final String? patientName;
  final String? permission;
  final PatientAccessMode mode;

  const PatientSession({
    required this.patientId,
    this.patientName,
    this.permission,
    required this.mode,
  });

  bool get canEdit => mode == PatientAccessMode.owner || mode == PatientAccessMode.edit;
  bool get isEmergencyOnly => mode == PatientAccessMode.emergencyOnly;
}

class PatientSessionService {
  PatientSessionService._();

  static final PatientSessionService instance = PatientSessionService._();

  final ValueNotifier<PatientSession?> notifier = ValueNotifier<PatientSession?>(null);

  PatientSession? get current => notifier.value;

  void setSession({
    required String patientId,
    String? patientName,
    String? permission,
  }) {
    final mode = _modeFromPermission(permission);
    notifier.value = PatientSession(
      patientId: patientId,
      patientName: patientName,
      permission: permission,
      mode: mode,
    );
  }

  void clear() {
    notifier.value = null;
  }

  bool get hasSession => notifier.value != null;

  PatientAccessMode _modeFromPermission(String? permission) {
    final p = permission?.toLowerCase().trim();
    if (p == 'edit') return PatientAccessMode.edit;
    if (p == 'emergency_only') return PatientAccessMode.emergencyOnly;
    if (p == 'read') return PatientAccessMode.read;
    return PatientAccessMode.owner;
  }
}