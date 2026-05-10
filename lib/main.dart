import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'screens/allergies_screen.dart';
import 'screens/attachments_screen.dart';
import 'screens/audit_log_screen.dart';
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
    // The database now creates public.users automatically through the trigger.
    // The app no longer needs to manually insert a users row here.
    // Only use auth state changes to route the user to the correct screen.
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
          (data) async {
        debugPrint('Auth event: ${data.event}');

        switch (data.event) {
          case AuthChangeEvent.signedIn:
          // After sign-in or email confirmation, go straight to the app.
            if (data.session != null) {
              _goHome();
            }
            break;

          case AuthChangeEvent.initialSession:
          // When the app starts and there is already a session, go home.
            if (data.session != null) {
              _goHome();
            }
            break;

          case AuthChangeEvent.signedOut:
          // Clear route stack so the user cannot go back into protected pages.
            _goLogin();
            break;

          case AuthChangeEvent.tokenRefreshed:
          // No navigation needed.
            break;

          default:
            break;
        }
      },
      onError: (Object error) {
        // If the auth stream fails, fall back to a safe signed-out state.
        debugPrint('Auth stream error (treating as sign-out): $error');
        Supabase.instance.client.auth.signOut().ignore();
        _goLogin();
      },
    );
  }

  void _goHome() {
    final nav = navigatorKey.currentState;
    if (nav == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _goHome());
      return;
    }

    nav.pushNamedAndRemoveUntil('/home', (route) => false);
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
      // Keep "/" as the public landing page.
      // The auth callback route is added separately so the email link can
      // return into the app instead of landing on a blank page.
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/auth-callback': (context) => const AuthCallbackScreen(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/medical_summary': (context) => const MedicalSummaryScreen(),
        '/emergency': (context) => const EmergencyScreen(),
        '/qr': (context) => const QrScreen(),
        '/caregivers': (context) => const CaregiverScreen(),
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
      // This fallback helps if the app is opened directly from the email link.
      // The route name must match the path part of your callback URI.
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
    // The email confirmation link is handled by Supabase/Auth and the OS.
    // Once the app opens, we simply wait for the auth session to exist and
    // then route the user into the app.
    await Future<void>.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    } else {
      // If the session is not available yet, send the user back to login.
      // This is safer than leaving them on a blank callback page.
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        // Keep this screen minimal: it is only a bridge between the email link
        // and the authenticated part of the app.
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
