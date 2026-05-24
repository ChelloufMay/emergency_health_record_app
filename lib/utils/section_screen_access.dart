import '../services/patient_session_service.dart';
import 'patient_access_context.dart';

/// Effective access flags for patient section screens.
///
/// SQL decides whether a row can be read.
/// This helper decides what the current Flutter screen may show or mutate.
///
/// Visibility rules:
/// - edit permission -> full add/edit/delete on all sections + medical summary
/// - read permission -> profile view + medical summary read-only, no mutations
/// - emergency_only -> only emergency view + QR screen
class SectionScreenAccess {
  final bool canEdit;
  final bool isEmergencyOnly;

  SectionScreenAccess({
    required bool widgetCanEdit,
    required bool widgetIsEmergencyOnly,
  })  : canEdit = widgetCanEdit ||
      PatientAccessContext.instance.canEdit ||
      (PatientSessionService.instance.current?.canEdit ?? false),
        isEmergencyOnly = widgetIsEmergencyOnly ||
            PatientAccessContext.instance.isEmergencyOnly ||
            (PatientSessionService.instance.current?.isEmergencyOnly ?? false);

  /// Full mutation access for editable sections.
  bool get canMutate => canEdit && !isEmergencyOnly;

  /// Backward-compatible alias used by existing screens.
  bool get allowMutations => canMutate;

  /// Profile sections are visible in read and edit modes.
  bool get canViewProfile => !isEmergencyOnly;

  /// The medical summary is visible in read and edit modes.
  bool get canViewMedicalSummary => !isEmergencyOnly;

  /// Emergency screen is only exposed in emergency-only mode.
  bool get canViewEmergency => isEmergencyOnly;

  /// QR screen is only exposed in emergency-only mode.
  bool get canViewQr => isEmergencyOnly;

  /// Explicit helper for screens that want to hide add/edit/delete controls.
  bool get canAddEditDelete => canMutate;
}