import 'dart:async';

import 'package:flutter/material.dart';

import '../services/access_realtime_service.dart';
import '../services/access_service.dart';
import '../services/patient_session_service.dart';

/// Backward-compatible patient access context.
///
/// Supports both styles:
/// 1) Old value-object usage:
///    final ctx = PatientAccessContext(...);
///
/// 2) New reactive singleton usage:
///    await PatientAccessContext.instance.bindPatient(patientId);
///    PatientAccessContext.instance.addListener(...)
///
/// This version also enforces grant expiry locally:
/// - it stores the active grant expiry time when available
/// - it schedules a timer for the expiry moment
/// - when the timer fires, it re-checks the DB and drops access if the grant
///   is expired, revoked, or otherwise no longer active
class PatientAccessContext extends ChangeNotifier {
  /// Old-style constructor used by existing screens.
  PatientAccessContext({
    required String patientId,
    required bool canEdit,
    required bool isEmergencyOnly,
    String? actorUserId,
    String? actorRole,
  })  : _patientId = patientId.trim(),
        _legacyCanEdit = canEdit,
        _legacyIsEmergencyOnly = isEmergencyOnly,
        _actorUserId = actorUserId,
        _actorRole = actorRole;

  /// Internal constructor for the reactive singleton.
  PatientAccessContext._reactive()
      : _patientId = '',
        _legacyCanEdit = false,
        _legacyIsEmergencyOnly = false,
        _actorUserId = null,
        _actorRole = null;

  static final PatientAccessContext instance = PatientAccessContext._reactive();

  final AccessService _accessService = AccessService();
  StreamSubscription<void>? _realtimeSub;
  Timer? _expiryTimer;

  String _patientId;
  String? _grantId;
  String _permission = 'none';
  DateTime? _expiresAt;

  final bool _legacyCanEdit;
  final bool _legacyIsEmergencyOnly;

  final String? _actorUserId;
  final String? _actorRole;

  bool _isListening = false;
  bool _isRefreshing = false;
  int _revision = 0;

  String get patientId => _patientId;
  String? get grantId => _grantId;

  /// Canonical permission value for the current patient context.
  /// Expected values:
  /// - none
  /// - read
  /// - edit
  /// - emergency_only
  String get permission => _permission;

  /// Active grant expiry, when known.
  DateTime? get expiresAt => _expiresAt;

  /// Used by UI keys to force rebuilds when the context changes.
  int get revision => _revision;

  String? get actorUserId => _actorUserId;
  String? get actorRole => _actorRole;

  /// Backward-compatible access flags.
  bool get canEdit => _legacyCanEdit || _permission == 'edit';
  bool get isEmergencyOnly =>
      _legacyIsEmergencyOnly || _permission == 'emergency_only';

  /// Read access for normal sections.
  bool get canViewProfile => !isEmergencyOnly;

  /// Medical summary is visible in read/edit modes.
  bool get canViewMedicalSummary => !isEmergencyOnly;

  /// Emergency screen is available only in emergency-only mode.
  bool get canViewEmergency => isEmergencyOnly;

  /// QR screen is available only in emergency-only mode.
  bool get canViewQr => isEmergencyOnly;

  /// Mutation access for section screens.
  bool get canMutate => canEdit && !isEmergencyOnly;

  /// Backward-compatible alias used by existing screens.
  bool get allowMutations => canMutate;

  /// True only when the current grant is known to be expired locally.
  /// This is mainly useful for UI messaging.
  bool get isExpired =>
      _expiresAt != null && DateTime.now().isAfter(_expiresAt!);

  /// Build a context from route arguments and session fallback.
  static PatientAccessContext resolve({
    Map<String, dynamic>? arguments,
    String? fallbackPatientId,
    String? fallbackActorRole,
  }) {
    final args = arguments ?? const <String, dynamic>{};
    final session = PatientSessionService.instance.current;

    final routePatientId = args['patientId'] as String?;
    final sessionPatientId = session?.patientId;

    final patientId = _firstNonEmpty([
      routePatientId,
      sessionPatientId,
      fallbackPatientId,
    ]);

    final canEditFromArgs = args['canEdit'] as bool?;
    final isEmergencyFromArgs = args['isEmergencyOnly'] as bool?;

    final canEdit = canEditFromArgs ?? session?.canEdit ?? false;
    final isEmergencyOnly =
        isEmergencyFromArgs ?? session?.isEmergencyOnly ?? false;

    final routeActorRole = args['actorRole'] as String?;
    final actorRole = _firstNonEmpty([
      routeActorRole,
      fallbackActorRole,
      session?.permission,
    ]);

    final actorUserId = args['actorUserId'] as String?;

    return PatientAccessContext(
      patientId: patientId,
      canEdit: canEdit,
      isEmergencyOnly: isEmergencyOnly,
      actorUserId: actorUserId,
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

  /// Bind the reactive singleton to a patient and refresh it.
  Future<void> bindPatient(String patientId) async {
    final normalized = patientId.trim();
    if (normalized.isEmpty) return;

    if (_patientId == normalized && _isListening) {
      await refresh();
      return;
    }

    _patientId = normalized;
    await _ensureListening();
    await refresh();
  }

  Future<void> _ensureListening() async {
    if (_isListening) return;

    await AccessRealtimeService.instance.subscribe();
    _realtimeSub = AccessRealtimeService.instance.onChanged.listen((_) {
      refresh();
    });

    _isListening = true;
  }

  Future<void> refresh() async {
    if (_patientId.isEmpty || _isRefreshing) return;

    _isRefreshing = true;
    try {
      final rows = await _accessService.fetchActiveAccessForPatient(_patientId);

      if (rows.isEmpty) {
        _apply(permission: 'none', grantId: null, expiresAt: null);
        return;
      }

      final row = rows.first;
      final permission = row['permission']?.toString().trim().toLowerCase();
      final grantId = row['id']?.toString();
      final expiresAt = _parseDateTime(row['expires_at']);

      _apply(
        permission: (permission == null || permission.isEmpty)
            ? 'none'
            : permission,
        grantId: grantId,
        expiresAt: expiresAt,
      );
    } finally {
      _isRefreshing = false;
    }
  }

  void _apply({
    required String permission,
    required String? grantId,
    required DateTime? expiresAt,
  }) {
    final normalizedPermission = permission.trim().toLowerCase();

    final changed = _permission != normalizedPermission ||
        _grantId != grantId ||
        _expiresAt != expiresAt;

    _permission = normalizedPermission;
    _grantId = grantId;
    _expiresAt = expiresAt;

    _scheduleExpiryTimer(expiresAt);

    if (changed) {
      _revision++;
      notifyListeners();
    }
  }

  void _scheduleExpiryTimer(DateTime? expiresAt) {
    _expiryTimer?.cancel();
    _expiryTimer = null;

    if (expiresAt == null) return;

    final delay = expiresAt.difference(DateTime.now());

    if (delay.isNegative || delay == Duration.zero) {
      _expiryTimer = Timer(Duration.zero, _onExpiryTimer);
      return;
    }

    _expiryTimer = Timer(delay, _onExpiryTimer);
  }

  void _onExpiryTimer() {
    if (_patientId.isEmpty) return;
    unawaited(refresh());
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      final text = value.trim();
      if (text.isEmpty) return null;
      try {
        return DateTime.parse(text);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Manual override for screens that already know the permission.
  ///
  /// If you do not provide [expiresAt], the current expiry value is kept.
  void setPermission({
    required String permission,
    String? grantId,
    DateTime? expiresAt,
  }) {
    _apply(
      permission: permission,
      grantId: grantId,
      expiresAt: expiresAt ?? _expiresAt,
    );
  }

  /// Reset the reactive singleton when leaving a patient.
  Future<void> clear() async {
    _expiryTimer?.cancel();
    _expiryTimer = null;

    _patientId = '';
    _grantId = null;
    _expiresAt = null;
    _permission = 'none';
    _revision++;
    notifyListeners();
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    _expiryTimer = null;

    _realtimeSub?.cancel();
    _realtimeSub = null;
    _isListening = false;

    unawaited(AccessRealtimeService.instance.unsubscribe());

    super.dispose();
  }

  static String _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return '';
  }
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