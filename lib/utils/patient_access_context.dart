import 'package:flutter/material.dart';

import '../services/patient_session_service.dart';

/// Resolved permission context for patient-scoped screens and services.
class PatientAccessContext {
  final String patientId;
  final bool canEdit;
  final bool isEmergencyOnly;
  final String? actorUserId;
  final String? actorRole;

  const PatientAccessContext({
    required this.patientId,
    required this.canEdit,
    required this.isEmergencyOnly,
    this.actorUserId,
    this.actorRole,
  });

  /// Build from route [arguments] with session fallback.
  static PatientAccessContext resolve({
    Map<String, dynamic>? arguments,
    String? fallbackPatientId,
    String? fallbackActorRole,
  }) {
    final args = arguments ?? const <String, dynamic>{};
    final session = PatientSessionService.instance.current;

    final patientId = (args['patientId'] as String?)?.trim().isNotEmpty == true
        ? (args['patientId'] as String).trim()
        : (session?.patientId.trim().isNotEmpty == true
            ? session!.patientId
            : (fallbackPatientId?.trim().isNotEmpty == true
                ? fallbackPatientId!.trim()
                : ''));

    final canEditFromArgs = args['canEdit'] as bool?;
    final isEmergencyFromArgs = args['isEmergencyOnly'] as bool?;

    final canEdit = canEditFromArgs ?? session?.canEdit ?? false;
    final isEmergencyOnly =
        isEmergencyFromArgs ?? session?.isEmergencyOnly ?? false;

    final actorRole = (args['actorRole'] as String?)?.trim().isNotEmpty == true
        ? (args['actorRole'] as String).trim()
        : (fallbackActorRole?.trim().isNotEmpty == true
            ? fallbackActorRole!.trim()
            : session?.permission);

    return PatientAccessContext(
      patientId: patientId,
      canEdit: canEdit,
      isEmergencyOnly: isEmergencyOnly,
      actorUserId: args['actorUserId'] as String?,
      actorRole: actorRole,
    );
  }

  Map<String, dynamic> toRouteArguments() => {
    'patientId': patientId,
    'canEdit': canEdit,
    'isEmergencyOnly': isEmergencyOnly,
    if (actorUserId != null) 'actorUserId': actorUserId,
    if (actorRole != null) 'actorRole': actorRole,
  };
}

/// Merges widget route args with [PatientSessionService] for section screens.
PatientAccessContext resolveScreenAccess({
  required BuildContext context,
  String? widgetPatientId,
  bool widgetCanEdit = false,
  bool widgetIsEmergencyOnly = false,
}) {
  final args = ModalRoute.of(context)?.settings.arguments;
  final map = args is Map<String, dynamic> ? args : null;
  final resolved = PatientAccessContext.resolve(
    arguments: map,
    fallbackPatientId: widgetPatientId,
  );

  return PatientAccessContext(
    patientId: resolved.patientId.isNotEmpty
        ? resolved.patientId
        : (widgetPatientId ?? ''),
    canEdit: widgetCanEdit || resolved.canEdit,
    isEmergencyOnly: widgetIsEmergencyOnly || resolved.isEmergencyOnly,
    actorUserId: resolved.actorUserId,
    actorRole: resolved.actorRole,
  );
}
