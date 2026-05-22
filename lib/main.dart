import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'screens/access_dashboard_screen.dart';
import 'screens/allergies_screen.dart';
import 'screens/attachments_screen.dart';
import 'screens/audit_log_screen.dart';
import 'screens/caregiver_choice_screen.dart';
import 'screens/caregiver_dashboard_screen.dart';
import 'screens/caregiver_patient_detail_screen.dart';
import 'screens/caregiver_profile_screen.dart';
import 'screens/caregiver_settings_screen.dart';
import 'screens/caregiver_screen.dart';
import 'screens/clinician_choice_screen.dart';
import 'screens/clinician_dashboard_screen.dart';
import 'screens/clinician_profile_screen.dart';
import 'screens/clinician_settings_screen.dart';
import 'screens/conditions_screen.dart';
import 'screens/emergency_access_token_screen.dart';
import 'screens/emergency_screen.dart';
import 'screens/family_doctor_screen.dart';
import 'screens/family_history_screen.dart';
import 'screens/guardian_choice_screen.dart';
import 'screens/guardian_dashboard_screen.dart';
import 'screens/guardian_profile_screen.dart';
import 'screens/guardian_settings_screen.dart';
import 'screens/home_screen.dart';
import 'screens/hospitalizations_screen.dart';
import 'screens/lifestyle_screen.dart';
import 'screens/login_screen.dart';
import 'screens/medical_summary_screen.dart';
import 'screens/medications_screen.dart';
import 'screens/password_reset_screen.dart';
import 'screens/patient_detail_screen.dart';
import 'screens/patient_notifications_screen.dart';
import 'screens/patient_risk_predictions_screen.dart';
import 'screens/patient_settings_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/qr_screen.dart';
import 'screens/register_screen.dart';
import 'screens/reproductive_health_screen.dart';
import 'screens/role_router_screen.dart';
import 'screens/surgeries_screen.dart';
import 'screens/verification_labels_screen.dart';
import 'screens/vaccinations_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/emergency_payload_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription? _authSubscription;
  StreamSubscription? _linkSubscription;
  final AppLinks _appLinks = AppLinks();

  bool _startupHandled = false;
  bool _initialLinkHandled = false;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
    _setupDeepLinks();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrapFromExistingSession();
    });
  }

  Future<void> _bootstrapFromExistingSession() async {
    if (_startupHandled) return;
    _startupHandled = true;

    final session = Supabase.instance.client.auth.currentSession;
    if (session != null && !_initialLinkHandled) {
      _goEntry();
    }
  }

  void _setupAuthListener() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
          (data) async {
        debugPrint('Auth event: ${data.event}');
        switch (data.event) {
          case AuthChangeEvent.signedOut:
            _goLogin();
            break;
          case AuthChangeEvent.passwordRecovery:
          // CHANGED: keep recovery flow on the required password-reset route.
            _goPasswordReset();
            break;
          case AuthChangeEvent.signedIn:
          case AuthChangeEvent.initialSession:
          default:
            break;
        }
      },
      onError: (Object error) {
        debugPrint('Auth stream error (treating as sign-out): $error');
        Supabase.instance.client.auth.signOut().ignore();
        _goLogin();
      },
    );
  }

  Future<void> _setupDeepLinks() async {
    Future<void> handleUri(Uri uri) async {
      final nav = navigatorKey.currentState;
      if (nav == null) return;

      if (uri.scheme != 'healthapp') return;

      if (uri.host == 'auth-callback') {
        final isRecovery = uri.queryParameters['type'] == 'recovery' ||
            uri.queryParameters['recovery'] == 'true' ||
            uri.toString().contains('type=recovery');

        // CHANGED: route now uses /auth_callback and /password_reset.
        nav.pushNamedAndRemoveUntil(
          isRecovery ? '/password_reset' : '/auth_callback',
              (route) => false,
          arguments: {
            'uri': uri.toString(),
            'isRecovery': isRecovery,
          },
        );
        return;
      }

      if (uri.host == 'emergency') {
        final payload = EmergencyPayloadService.extractPayloadFromUri(uri);
        nav.pushNamedAndRemoveUntil(
          '/emergency',
              (route) => false,
          arguments: (payload != null && payload.isNotEmpty)
              ? {'payload': payload}
              : null,
        );
      }
    }

    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _initialLinkHandled = true;
        await handleUri(initialUri);
      }
    } catch (e) {
      debugPrint('Initial deep link error: $e');
    }

    _linkSubscription = _appLinks.uriLinkStream.listen(
          (uri) {
        _initialLinkHandled = true;
        handleUri(uri);
      },
      onError: (Object error) {
        debugPrint('Deep link stream error: $error');
      },
    );
  }

  void _goEntry() {
    final nav = navigatorKey.currentState;
    if (nav == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _goEntry());
      return;
    }
    nav.pushNamedAndRemoveUntil('/entry', (route) => false);
  }

  void _goLogin() {
    final nav = navigatorKey.currentState;
    if (nav == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _goLogin());
      return;
    }
    nav.pushNamedAndRemoveUntil('/login', (route) => false);
  }

  void _goPasswordReset() {
    final nav = navigatorKey.currentState;
    if (nav == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _goPasswordReset());
      return;
    }
    nav.pushNamedAndRemoveUntil('/password_reset', (route) => false);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Health Record App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        final args = settings.arguments is Map
            ? Map<String, dynamic>.from(settings.arguments as Map)
            : <String, dynamic>{};

        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => const WelcomeScreen());

          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginScreen());

          case '/register':
            return MaterialPageRoute(builder: (_) => const RegisterScreen());

          case '/entry':
            return MaterialPageRoute(builder: (_) => const RoleRouterScreen());

          case '/home':
            return MaterialPageRoute(builder: (_) => const HomeScreen());

          case '/profile':
            return MaterialPageRoute(builder: (_) => const ProfileScreen());

          case '/emergency':
            return MaterialPageRoute(
              builder: (_) => EmergencyScreen(
                payload: args['payload'] as String?,
              ),
            );

          case '/qr':
            return MaterialPageRoute(builder: (_) => const QrScreen());

          case '/caregivers':
            return MaterialPageRoute(builder: (_) => const CaregiverScreen());

          case '/caregiver_choice':
            return MaterialPageRoute(
              builder: (_) => const CaregiverChoiceScreen(),
            );

          case '/guardian_choice':
            return MaterialPageRoute(
              builder: (_) => const GuardianChoiceScreen(),
            );

          case '/clinician_choice':
            return MaterialPageRoute(
              builder: (_) => const ClinicianChoiceScreen(),
            );

          case '/access_dashboard':
            return MaterialPageRoute(
              builder: (_) => const AccessDashboardScreen(),
            );

          case '/caregiver_dashboard':
            return MaterialPageRoute(
              builder: (_) => const CaregiverDashboardScreen(),
            );

          case '/guardian_dashboard':
            return MaterialPageRoute(
              builder: (_) => const GuardianDashboardScreen(),
            );

          case '/clinician_dashboard':
            return MaterialPageRoute(
              builder: (_) => const ClinicianDashboardScreen(),
            );

          case '/clincian_dashboard':
          // CHANGED: temporary compatibility route for the old typo.
            return MaterialPageRoute(
              builder: (_) => const ClinicianDashboardScreen(),
            );

          case '/patient_detail':
            return MaterialPageRoute(
              builder: (_) => PatientDetailScreen(
                patientId: args['patientId'] as String? ?? '',
                patientName: args['patientName'] as String? ?? 'Patient',
                permission: args['permission'] as String? ?? 'read',
                roleLabel: args['roleLabel'] as String? ?? 'unknown',
              ),
            );

          case '/caregiver_patient_detail':
            return MaterialPageRoute(
              builder: (_) => CaregiverPatientDetailScreen(
                patientId: args['patientId'] as String?,
              ),
            );

          case '/caregiver_profile':
            return MaterialPageRoute(
              builder: (_) => const CaregiverProfileScreen(),
            );

          case '/guardian_profile':
            return MaterialPageRoute(
              builder: (_) => const GuardianProfileScreen(),
            );

          case '/clinician_profile':
            return MaterialPageRoute(
              builder: (_) => const ClinicianProfileScreen(),
            );

          case '/audit_log':
            return MaterialPageRoute(builder: (_) => const AuditLogScreen());

          case '/medical_summary':
            return MaterialPageRoute(
              builder: (_) => MedicalSummaryScreen(
                patientId: args['patientId'] as String?,
                canEdit: args['canEdit'] as bool? ?? false,
                isEmergencyOnly: args['isEmergencyOnly'] as bool? ?? false,
              ),
            );

          case '/allergies':
            return MaterialPageRoute(
              builder: (_) => AllergiesScreen(
                patientId: args['patientId'] as String?,
                canEdit: args['canEdit'] as bool? ?? false,
                isEmergencyOnly: args['isEmergencyOnly'] as bool? ?? false,
              ),
            );

          case '/medications':
            return MaterialPageRoute(
              builder: (_) => MedicationsScreen(
                patientId: args['patientId'] as String?,
                canEdit: args['canEdit'] as bool? ?? false,
                isEmergencyOnly: args['isEmergencyOnly'] as bool? ?? false,
              ),
            );

          case '/conditions':
            return MaterialPageRoute(
              builder: (_) => ConditionsScreen(
                patientId: args['patientId'] as String?,
                canEdit: args['canEdit'] as bool? ?? false,
                isEmergencyOnly: args['isEmergencyOnly'] as bool? ?? false,
              ),
            );

          case '/surgeries':
            return MaterialPageRoute(
              builder: (_) => SurgeriesScreen(
                patientId: args['patientId'] as String?,
                canEdit: args['canEdit'] as bool? ?? false,
                isEmergencyOnly: args['isEmergencyOnly'] as bool? ?? false,
              ),
            );

          case '/hospitalizations':
            return MaterialPageRoute(
              builder: (_) => HospitalizationsScreen(
                patientId: args['patientId'] as String?,
                canEdit: args['canEdit'] as bool? ?? false,
                isEmergencyOnly: args['isEmergencyOnly'] as bool? ?? false,
              ),
            );

          case '/vaccinations':
            return MaterialPageRoute(
              builder: (_) => VaccinationsScreen(
                patientId: args['patientId'] as String?,
                canEdit: args['canEdit'] as bool? ?? false,
                isEmergencyOnly: args['isEmergencyOnly'] as bool? ?? false,
              ),
            );

          case '/lifestyle':
            return MaterialPageRoute(
              builder: (_) => LifestyleScreen(
                patientId: args['patientId'] as String?,
                canEdit: args['canEdit'] as bool? ?? false,
                isEmergencyOnly: args['isEmergencyOnly'] as bool? ?? false,
              ),
            );

          case '/family_history':
            return MaterialPageRoute(
              builder: (_) => FamilyHistoryScreen(
                patientId: args['patientId'] as String?,
                canEdit: args['canEdit'] as bool? ?? false,
                isEmergencyOnly: args['isEmergencyOnly'] as bool? ?? false,
              ),
            );

          case '/reproductive_health':
            return MaterialPageRoute(
              builder: (_) => ReproductiveHealthScreen(
                patientId: args['patientId'] as String?,
                canEdit: args['canEdit'] as bool? ?? false,
                isEmergencyOnly: args['isEmergencyOnly'] as bool? ?? false,
              ),
            );

          case '/family_doctor':
            return MaterialPageRoute(
              builder: (_) => FamilyDoctorScreen(
                patientId: args['patientId'] as String?,
                canEdit: args['canEdit'] as bool? ?? false,
                isEmergencyOnly: args['isEmergencyOnly'] as bool? ?? false,
              ),
            );

          case '/attachments':
            return MaterialPageRoute(
              builder: (_) => AttachmentsScreen(
                patientId: args['patientId'] as String?,
                canEdit: args['canEdit'] as bool? ?? false,
                isEmergencyOnly: args['isEmergencyOnly'] as bool? ?? false,
              ),
            );

          case '/patient_risk_predictions':
            return MaterialPageRoute(
              builder: (_) => const PatientRiskPredictionsScreen(),
            );

          case '/emergency_access_tokens':
            return MaterialPageRoute(
              builder: (_) => const EmergencyAccessTokenScreen(),
            );

          case '/verification_labels':
            return MaterialPageRoute(
              builder: (_) => const VerificationLabelsScreen(),
            );

          case '/patient_notifications':
            return MaterialPageRoute(
              builder: (_) => const PatientNotificationsScreen(),
            );

          case '/auth_callback':
            return MaterialPageRoute(
              builder: (_) => AuthCallbackScreen(
                callbackUri: args['uri'] as String?,
                isRecovery: args['isRecovery'] as bool? ?? false,
              ),
            );

          case '/auth-callback':
          // CHANGED: compatibility alias for older links.
            return MaterialPageRoute(
              builder: (_) => AuthCallbackScreen(
                callbackUri: args['uri'] as String?,
                isRecovery: args['isRecovery'] as bool? ?? false,
              ),
            );

          case '/password_reset':
            return MaterialPageRoute(
              builder: (_) => const PasswordResetScreen(),
            );

          case '/reset-password':
          // CHANGED: compatibility alias for older links.
            return MaterialPageRoute(
              builder: (_) => const PasswordResetScreen(),
            );

        // CHANGED: role-aware settings route resolver.
          case '/settings':
            return MaterialPageRoute(
              builder: (_) => const SettingsRouteScreen(),
            );

          case '/patient_settings':
            return MaterialPageRoute(
              builder: (_) => const PatientSettingsScreen(),
            );

          case '/caregiver_settings':
            return MaterialPageRoute(
              builder: (_) => const CaregiverSettingsScreen(),
            );

          case '/guardian_settings':
            return MaterialPageRoute(
              builder: (_) => const GuardianSettingsScreen(),
            );

          case '/clinician_settings':
            return MaterialPageRoute(
              builder: (_) => const ClinicianSettingsScreen(),
            );

          default:
            if (settings.name != null &&
                settings.name!.contains('auth-callback')) {
              return MaterialPageRoute(
                builder: (_) => AuthCallbackScreen(
                  callbackUri: args['uri'] as String?,
                  isRecovery: args['isRecovery'] as bool? ?? false,
                ),
              );
            }

            return MaterialPageRoute(
              builder: (_) => Scaffold(
                body: Center(child: Text('Route not found: ${settings.name}')),
              ),
            );
        }
      },
    );
  }
}

class SettingsRouteScreen extends StatefulWidget {
  const SettingsRouteScreen({super.key});

  @override
  State<SettingsRouteScreen> createState() => _SettingsRouteScreenState();
}

class _SettingsRouteScreenState extends State<SettingsRouteScreen> {
  late Future<Widget> _future;

  @override
  void initState() {
    super.initState();
    _future = _resolveDestination();
  }

  Future<Widget> _resolveDestination() async {
    final client = Supabase.instance.client;
    final session = client.auth.currentSession;
    final authUser = session?.user;

    if (authUser == null) return const LoginScreen();

    final userRow = await client
        .from('users')
        .select('id, role')
        .eq('auth_user_id', authUser.id)
        .maybeSingle();

    if (userRow == null) return const LoginScreen();

    // CHANGED: normalize the role before routing to the role-specific settings screen.
    final role = (userRow['role'] as String?)?.trim().toLowerCase() ?? 'owner';

    if (role == 'owner' || role == 'patient') {
      final patientProfile = await client
          .from('patient_profiles')
          .select('id')
          .eq('user_id', userRow['id'])
          .maybeSingle();

      if (patientProfile == null) {
        return const ProfileScreen();
      }

      return const PatientSettingsScreen();
    }

    if (role == 'caregiver') {
      final caregiverProfile = await client
          .from('caregiver_profiles')
          .select('id')
          .eq('user_id', userRow['id'])
          .maybeSingle();

      if (caregiverProfile == null) {
        return const CaregiverProfileScreen();
      }

      return const CaregiverSettingsScreen();
    }

    if (role == 'guardian') {
      final guardianProfile = await client
          .from('guardian_profiles')
          .select('id')
          .eq('user_id', userRow['id'])
          .maybeSingle();

      if (guardianProfile == null) {
        return const GuardianProfileScreen();
      }

      return const GuardianSettingsScreen();
    }

    if (role == 'clinician') {
      final clinicianProfile = await client
          .from('clinician_profiles')
          .select('id')
          .eq('user_id', userRow['id'])
          .maybeSingle();

      if (clinicianProfile == null) {
        return const ClinicianProfileScreen();
      }

      return const ClinicianSettingsScreen();
    }

    return const PatientSettingsScreen();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Settings route error: ${snapshot.error}')),
          );
        }

        final destination = snapshot.data ?? const PatientSettingsScreen();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => destination),
          );
        });

        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}

class AuthCallbackScreen extends StatefulWidget {
  final String? callbackUri;
  final bool isRecovery;

  const AuthCallbackScreen({
    super.key,
    this.callbackUri,
    this.isRecovery = false,
  });

  @override
  State<AuthCallbackScreen> createState() => _AuthCallbackScreenState();
}

class _AuthCallbackScreenState extends State<AuthCallbackScreen> {
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    _finish();
  }

  Future<void> _finish() async {
    if (_handled) return;
    _handled = true;

    try {
      final rawUri = widget.callbackUri;
      if (rawUri != null && rawUri.trim().isNotEmpty) {
        final uri = Uri.parse(rawUri);

        // CHANGED: always exchange the session from the callback URL first.
        await Supabase.instance.client.auth.getSessionFromUrl(uri);
      }
    } catch (e) {
      debugPrint('Auth callback exchange failed: $e');
    }

    await Future.delayed(const Duration(milliseconds: 250));

    if (!mounted) return;

    if (widget.isRecovery) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/password_reset',
            (route) => false,
      );
      return;
    }

    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      Navigator.of(context).pushNamedAndRemoveUntil('/entry', (route) => false);
    } else {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Finishing sign-in...'),
          ],
        ),
      ),
    );
  }
}