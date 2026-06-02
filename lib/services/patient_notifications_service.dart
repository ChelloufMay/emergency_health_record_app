import '../models/notification_event_model.dart';
import 'notification_event_service.dart';

// Patient facing notification timeline --> delegates to NotificationEventService .
class PatientNotificationsService {
  final NotificationEventService _events = NotificationEventService();

  // Fetches all notification events for a specific patient.
  Future<List<NotificationEventModel>> fetchForPatient(String patientId) {
    return _events.fetchByPatient(patientId);
  }

  // Fetches notification events related to access management for a specific patient.
  Future<List<NotificationEventModel>> fetchAccessRelatedForPatient(
    String patientId,
  ) {
    return _events.fetchAccessRelatedForPatient(patientId);
  }
}
