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
import 'screens/caregiver_profile_screen.dart';
import 'screens/caregiver_screen.dart';
import 'screens/conditions_screen.dart';
import 'screens/emergency_screen.dart';
import 'screens/family_doctor_screen.dart';
import 'screens/family_history_screen.dart';
import 'screens/guardian_profile_screen.dart';
import 'screens/home_screen.dart';
import 'screens/hospitalizations_screen.dart';
import 'screens/clinician_profile_screen.dart';
import 'screens/lifestyle_screen.dart';
import 'screens/login_screen.dart';
import 'screens/medical_summary_screen.dart';
import 'screens/medications_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/qr_screen.dart';
import 'screens/register_screen.dart';
import 'screens/reproductive_health_screen.dart';
import 'screens/role_router_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/surgeries_screen.dart';
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
  StreamSubscription<AuthState>? _authSubscription;
  StreamSubscription<Uri>? _linkSubscription;
  final AppLinks _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
    _setupDeepLinks();
  }

  void _setupAuthListener() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
          (data) async {
        debugPrint('Auth event: ${data.event}');
        switch (data.event) {
          case AuthChangeEvent.signedIn:
            if (data.session != null) {
              _goEntry();
            }
            break;
          case AuthChangeEvent.initialSession:
            if (data.session != null) {
              _goEntry();
            }
            break;
          case AuthChangeEvent.signedOut:
            _goLogin();
            break;
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

  void _setupDeepLinks() {
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      final nav = navigatorKey.currentState;
      if (nav == null) return;

      if (uri.scheme == 'healthapp' && uri.host == 'emergency') {
        final payload = EmergencyPayloadService.extractPayloadFromUri(uri);
        if (payload != null && payload.isNotEmpty) {
          nav.pushNamed('/emergency', arguments: {'payload': payload});
        } else {
          nav.pushNamed('/emergency');
        }
      }
    });
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
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/entry': (context) => const RoleRouterScreen(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/medical_summary': (context) => const MedicalSummaryScreen(),
        '/emergency': (context) => const EmergencyScreen(),
        '/qr': (context) => const QrScreen(),
        '/caregivers': (context) => const CaregiverScreen(),
        '/caregiver_choice': (context) => const CaregiverChoiceScreen(),
        '/access_dashboard': (context) => const AccessDashboardScreen(),
        '/caregiver_profile': (context) => const CaregiverProfileScreen(),
        '/guardian_profile': (context) => const GuardianProfileScreen(),
        '/clinician_profile': (context) => const ClinicianProfileScreen(),
        '/audit_log': (context) => const AuditLogScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/allergies': (context) => const AllergiesScreen(),
        '/medications': (context) => const MedicationsScreen(),
        '/conditions': (context) => const ConditionsScreen(),
        '/surgeries': (context) => const SurgeriesScreen(),
        '/hospitalizations': (context) => const HospitalizationsScreen(),
        '/vaccinations': (context) => const VaccinationsScreen(),
        '/lifestyle': (context) => const LifestyleScreen(),
        '/family_history': (context) => const FamilyHistoryScreen(),
        '/reproductive_health': (context) => const ReproductiveHealthScreen(),
        '/family_doctor': (context) => const FamilyDoctorScreen(),
        '/attachments': (context) => const AttachmentsScreen(),
      },
    );
  }
}

class AuthCallbackScreen extends StatefulWidget {
  const AuthCallbackScreen({super.key});

  @override
  State<AuthCallbackScreen> createState() => _AuthCallbackScreenState();
}

class _AuthCallbackScreenState extends State<AuthCallbackScreen> {
  @override
  void initState() {
    super.initState();
    _finish();
  }

  Future<void> _finish() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final session = Supabase.instance.client.auth.currentSession;
    if (!mounted) return;

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