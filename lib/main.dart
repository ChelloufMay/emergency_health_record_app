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
import 'screens/caregiver_screen.dart';
import 'screens/conditions_screen.dart';
import 'screens/clinician_profile_screen.dart';
import 'screens/emergency_access_token_screen.dart';
import 'screens/emergency_screen.dart';
import 'screens/family_doctor_screen.dart';
import 'screens/family_history_screen.dart';
import 'screens/guardian_profile_screen.dart';
import 'screens/home_screen.dart';
import 'screens/hospitalizations_screen.dart';
import 'screens/lifestyle_screen.dart';
import 'screens/login_screen.dart';
import 'screens/medical_summary_screen.dart';
import 'screens/medications_screen.dart';
import 'screens/patient_notifications_screen.dart';
import 'screens/patient_risk_predictions_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/qr_screen.dart';
import 'screens/register_screen.dart';
import 'screens/reproductive_health_screen.dart';
import 'screens/role_router_screen.dart';
import 'screens/settings_screen.dart';
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
        nav.pushNamedAndRemoveUntil(
          '/auth-callback',
          (route) => false,
          arguments: {'uri': uri.toString()},
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
              builder: (_) =>
                  EmergencyScreen(payload: args['payload'] as String?),
            );
          case '/qr':
            return MaterialPageRoute(builder: (_) => const QrScreen());

          case '/caregivers':
            return MaterialPageRoute(builder: (_) => const CaregiverScreen());
          case '/caregiver_choice':
            return MaterialPageRoute(
              builder: (_) => const CaregiverChoiceScreen(),
            );
          case '/access_dashboard':
            return MaterialPageRoute(
              builder: (_) => const AccessDashboardScreen(),
            );
          case '/caregiver_dashboard':
            return MaterialPageRoute(
              builder: (_) => const CaregiverDashboardScreen(),
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

          case '/auth-callback':
            return MaterialPageRoute(
              builder: (_) =>
                  AuthCallbackScreen(callbackUri: args['uri'] as String?),
            );
          case '/settings':
            return MaterialPageRoute(builder: (_) => const SettingsScreen());

          default:
            if (settings.name != null &&
                settings.name!.contains('auth-callback')) {
              return MaterialPageRoute(
                builder: (_) =>
                    AuthCallbackScreen(callbackUri: args['uri'] as String?),
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

class AuthCallbackScreen extends StatefulWidget {
  final String? callbackUri;

  const AuthCallbackScreen({super.key, this.callbackUri});

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
        await Supabase.instance.client.auth.getSessionFromUrl(uri);
      }
    } catch (e) {
      debugPrint('Auth callback exchange failed: $e');
    }

    await Future.delayed(const Duration(milliseconds: 250));

    if (!mounted) return;

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
