import 'dart:async';

import 'package:app_links/app_links.dart';
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
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  StreamSubscription<AuthState>? _authSubscription;
  bool _handlingLink = false;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
    _setupDeepLinkHandling();
  }

  void _setupAuthListener() {
    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen(
              (data) async {
            debugPrint('Auth event: ${data.event}');

            switch (data.event) {
            // ── User just signed in (password login or deep-link callback) ──
              case AuthChangeEvent.signedIn:
                if (data.session != null) {
                  await _syncUserRowIfNeeded();
                  _goHome();
                }

            // ── Token refreshed in background — keep the user where they are ──
              case AuthChangeEvent.tokenRefreshed:
              // Nothing to do: user is already on the correct screen.
                break;

            // ── App started and found a saved session ──
              case AuthChangeEvent.initialSession:
                if (data.session != null) {
                  // Valid saved session: go straight to home.
                  await _syncUserRowIfNeeded();
                  _goHome();
                }
            // Null session means no saved login — stay on the welcome screen.

            // ── User signed out explicitly ──
              case AuthChangeEvent.signedOut:
                _goLogin();

              default:
                break;
            }
          },
          onError: (Object error) {
            // This catches "Refresh Token Not Found" and similar auth errors that
            // come from a stale cached session.  Treat them as a sign-out so the
            // user lands on the login screen instead of crashing.
            debugPrint('Auth stream error (treating as sign-out): $error');
            // Clear the broken session so it is not retried on next launch.
            Supabase.instance.client.auth.signOut().ignore();
            _goLogin();
          },
        );
  }

  Future<void> _setupDeepLinkHandling() async {
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      await _handleIncomingUri(initialUri);
    }

    _linkSubscription = _appLinks.uriLinkStream.listen(
          (uri) async {
        await _handleIncomingUri(uri);
      },
      onError: (_) {
        _goLogin();
      },
    );
  }

  Map<String, String> _extractParams(Uri uri) {
    final params = <String, String>{};
    params.addAll(uri.queryParameters);
    if (uri.fragment.isNotEmpty) {
      params.addAll(Uri.splitQueryString(uri.fragment));
    }
    return params;
  }

  Future<void> _handleIncomingUri(Uri uri) async {
    if (_handlingLink) return;
    _handlingLink = true;

    try {
      final isAuthCallback =
          uri.scheme == 'healthapp' && uri.host == 'auth-callback';
      if (!isAuthCallback) return;

      final params = _extractParams(uri);

      if (params.containsKey('error') || params.containsKey('error_code')) {
        debugPrint('Auth error callback: $params');
        _goLogin();
        return;
      }

      final accessToken = params['access_token'];
      final refreshToken = params['refresh_token'];
      final tokenHash = params['token_hash'];
      final type = params['type'];

      if (accessToken != null && refreshToken != null) {
        await Supabase.instance.client.auth.setSession(
          refreshToken,
          accessToken: accessToken,
        );
      } else if (tokenHash != null) {
        await Supabase.instance.client.auth.verifyOTP(
          type: OtpType.email,
          tokenHash: tokenHash,
          redirectTo: 'healthapp://auth-callback',
        );
      } else if (type == 'signup') {
        await Future<void>.delayed(const Duration(milliseconds: 400));
      }

      await _syncUserRowIfNeeded();

      if (Supabase.instance.client.auth.currentSession != null) {
        _goHome();
      } else {
        _goLogin();
      }
    } catch (e) {
      debugPrint('Callback error: $e');
      _goLogin();
    } finally {
      _handlingLink = false;
    }
  }

  Future<void> _syncUserRowIfNeeded() async {
    // The database trigger handle_new_user() creates the public.users row
    // automatically when a new auth account is created.
    // This function is kept only as a fallback for edge cases
    // (e.g. the trigger was added after the account already existed).
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    final session = client.auth.currentSession;
    if (user == null || session == null) return;

    try {
      final existing = await client
          .from('users')
          .select('id')
          .eq('auth_user_id', user.id)
          .maybeSingle();

      if (existing != null) return; // trigger already did the job

      final meta = user.userMetadata ?? {};
      final fullName = meta['full_name']?.toString().trim();
      final phone = meta['phone']?.toString().trim();

      await client.from('users').insert({
        'auth_user_id': user.id,
        'full_name': (fullName == null || fullName.isEmpty) ? 'User' : fullName,
        'email': user.email,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        'role': 'owner',
      });
    } catch (e) {
      debugPrint('_syncUserRowIfNeeded (non-fatal): $e');
    }
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
    _linkSubscription?.cancel();
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
    );
  }
}
