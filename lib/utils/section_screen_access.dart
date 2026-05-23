import '../services/patient_session_service.dart';

/// Effective access flags for patient section screens.
///
/// SQL decides whether a row can be read.
/// This helper only decides whether the current screen may mutate data.
class SectionScreenAccess {
  final bool canEdit;
  final bool isEmergencyOnly;

  SectionScreenAccess({
    required bool widgetCanEdit,
    required bool widgetIsEmergencyOnly,
  })  : canEdit = widgetCanEdit ||
      (PatientSessionService.instance.current?.canEdit ?? false),
        isEmergencyOnly = widgetIsEmergencyOnly ||
            (PatientSessionService.instance.current?.isEmergencyOnly ?? false);

  /// Preferred name going forward.
  bool get canMutate => canEdit && !isEmergencyOnly;

  /// Backward-compatible alias used by existing screens.
  bool get allowMutations => canMutate;
}