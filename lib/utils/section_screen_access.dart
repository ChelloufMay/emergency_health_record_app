import '../services/patient_session_service.dart';
import 'patient_access_context.dart';

// Effective access flags for patient section screens.
// SQL decides whether a row can be read.
// This helper decides what the current Flutter screen may show or mutate.
// Visibility rules:
// - edit permission --> full add/edit/delete on all sections + medical summary
// - read permission --> profile view + medical summary read-only, no mutations
// - emergency_only --> only emergency view + QR screen
class SectionScreenAccess {
  final bool canEdit;
  final bool isEmergencyOnly;

  // Creates a new instance of SectionScreenAccess based on widget and session states.
  SectionScreenAccess({
    required bool widgetCanEdit,
    required bool widgetIsEmergencyOnly,
  }) : canEdit =
           widgetCanEdit ||
           PatientAccessContext.instance.canEdit ||
           (PatientSessionService.instance.current?.canEdit ?? false),
       isEmergencyOnly =
           widgetIsEmergencyOnly ||
           PatientAccessContext.instance.isEmergencyOnly ||
           (PatientSessionService.instance.current?.isEmergencyOnly ?? false);

  // Returns true if the user has full mutation access
  bool get canMutate => canEdit && !isEmergencyOnly;

  // Backward compatible alias for canMutate.
  bool get allowMutations => canMutate;

  // Returns true if the profile section should be visible.
  bool get canViewProfile => !isEmergencyOnly;

  // Returns true if the medical summary should be visible.
  bool get canViewMedicalSummary => !isEmergencyOnly;

  // Returns true if the emergency screen should be visible.
  bool get canViewEmergency => isEmergencyOnly;

  // Returns true if the QR screen should be visible.
  bool get canViewQr => isEmergencyOnly;

  // Returns true if add, edit, or delete controls should be shown.
  bool get canAddEditDelete => canMutate;
}
