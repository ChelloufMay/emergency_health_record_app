import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'screens/allergies_screen.dart';
import 'screens/attachments_screen.dart';
import 'screens/audit_log_screen.dart';
import 'screens/caregiver_choice_screen.dart';
import 'screens/caregiver_dashboard_screen.dart';
import 'screens/caregiver_profile_screen.dart';
import 'screens/caregiver_screen.dart';
import 'screens/conditions_screen.dart';
import 'screens/emergency_screen.dart';
import 'screens/family_doctor_screen.dart';
import 'screens/family_history_screen.dart';
import 'screens/home_screen.dart';
import 'screens/hospitalizations_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    // The app now routes authenticated users through /entry first.
    // That screen decides whether the user is an owner or a caregiver.
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

          case AuthChangeEvent.tokenRefreshed:
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
        '/auth-callback': (context) => const AuthCallbackScreen(),

        // Entry point after login.
        '/entry': (context) => const RoleRouterScreen(),

        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/medical_summary': (context) => const MedicalSummaryScreen(),
        '/emergency': (context) => const EmergencyScreen(),
        '/qr': (context) => const QrScreen(),
        '/caregivers': (context) => const CaregiverScreen(),
        '/caregiver_choice': (context) => const CaregiverChoiceScreen(),
        '/caregiver_dashboard': (context) => const CaregiverDashboardScreen(),
        '/caregiver_profile': (context) => const CaregiverProfileScreen(),
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
      onGenerateRoute: (settings) {
        if (settings.name == '/auth-callback') {
          return MaterialPageRoute(
            builder: (_) => const AuthCallbackScreen(),
            settings: settings,
          );
        }
        return null;
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
    _finishAuthFlow();
  }

  Future<void> _finishAuthFlow() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

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