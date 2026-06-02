import 'package:flutter/foundation.dart';

// Modes of access allowed for a patient's health records.
enum PatientAccessMode { owner, read, edit, emergencyOnly }

// Represents an active patient session with associated access permissions
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

  // Whether the current session allows editing patient data.
  bool get canEdit =>
      mode == PatientAccessMode.owner || mode == PatientAccessMode.edit;

  // Whether the current session is for emergency access only.
  bool get isEmergencyOnly => mode == PatientAccessMode.emergencyOnly;
}

// Service that manages the state of the currently active patient session.
class PatientSessionService {
  PatientSessionService._();

  // Singleton instance of [PatientSessionService].
  static final PatientSessionService instance = PatientSessionService._();

  // Notifier for the current [PatientSession].
  final ValueNotifier<PatientSession?> notifier = ValueNotifier(null);

  // Gets the current active [PatientSession].
  PatientSession? get current => notifier.value;

  // Whether a patient session is currently active.
  bool get hasSession => notifier.value != null;

  // Sets the active patient session based on the provided credentials and permissions
  void setSession({
    required String patientId,
    String? patientName,
    String? permission,
  }) {
    notifier.value = PatientSession(
      patientId: patientId,
      patientName: patientName,
      permission: permission,
      mode: _modeFromPermission(permission),
    );
  }

  // Clears the current active patient session.
  Future<void> clear() async {
    notifier.value = null;
  }

  // Maps a permission string to a [PatientAccessMode]
  PatientAccessMode _modeFromPermission(String? permission) {
    final p = permission?.toLowerCase().trim();
    if (p == 'edit') return PatientAccessMode.edit;
    if (p == 'emergency_only') return PatientAccessMode.emergencyOnly;
    if (p == 'read') return PatientAccessMode.read;
    return PatientAccessMode.owner;
  }
}
