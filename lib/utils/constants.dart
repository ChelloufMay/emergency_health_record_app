import 'package:flutter/material.dart';

// Centralized constants for the application, including UI dimensions, deep link schemes, and database enum options.
class AppConstants {
  static const String appName = 'Health Record App';
  static const double screenPadding = 16.0;
  static const double cardRadius = 16.0;

  // Custom scheme used by your deep links and QR flow.
  static const String deepLinkScheme = 'healthapp';
  static const String authCallbackHost = 'auth-callback';
  static const String emergencyHost = 'emergency';

  // Keep role and permission values centralized so dropdowns stay in sync with the database enums.
  static const List<String> roleOptions = [
    'owner',
    'caregiver',
    'clinician',
    'guardian',
  ];

  static const List<String> permissionOptions = [
    'read',
    'edit',
    'emergency_only',
  ];

  static const List<String> verificationStatusOptions = [
    'unverified',
    'user_entered',
    'caregiver_entered',
    'clinician_verified',
  ];

  static const List<String> auditActionOptions = [
    'create',
    'update',
    'delete',
    'view',
    'break_glass',
  ];
}

// Standard colors used throughout the application for consistent branding and status indication.
class AppColors {
  static const Color primary = Colors.teal;
  static const Color success = Colors.green;
  static const Color warning = Colors.orange;
  static const Color danger = Colors.red;
  static const Color info = Colors.blue;
}
