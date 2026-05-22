import '../services/patient_session_service.dart';

/// Effective edit/emergency flags for patient section screens.
class SectionScreenAccess {
  final bool canEdit;
  final bool isEmergencyOnly;

  SectionScreenAccess({
    required bool widgetCanEdit,
    required bool widgetIsEmergencyOnly,
  })  : canEdit =
            widgetCanEdit || (PatientSessionService.instance.current?.canEdit ?? false),
        isEmergencyOnly = widgetIsEmergencyOnly ||
            (PatientSessionService.instance.current?.isEmergencyOnly ?? false);

  bool get allowMutations => canEdit && !isEmergencyOnly;
}
