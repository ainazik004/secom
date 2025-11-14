import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Localization
import 'gen_l10n/app_localizations.dart';
import 'package:secom/l10n/l10n.dart';

// Pages
import 'package:secom/pages/welcome_page.dart';
import 'package:secom/pages/home_page.dart';
import 'package:secom/pages/leaderboard_page.dart';
import 'package:secom/pages/settings_page.dart';
import 'package:secom/pages/statistics_page.dart';

// Auth pages
import 'package:secom/pages/login_page.dart';
import 'package:secom/pages/register_page.dart';
import 'package:secom/pages/verify_email_page.dart';

// Locale provider
import 'package:secom/provider/provider.dart';

// Other
import 'package:secom/pages/notifications_page.dart';
import 'package:secom/pages/profile_page.dart';
import 'package:secom/widgets/main_app_header.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => LocaleProvider(),
      child: const SecomApp(),
    ),
  );
}

class SecomApp extends StatelessWidget {
  const SecomApp({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LocaleProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SECOM',

      // Localization setup
      locale: provider.locale,
      supportedLocales: const [
        Locale('en'),
        Locale('ru'),
        Locale('ky'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      localeResolutionCallback: (locale, supported) {
        if (locale == null) return supported.first;
        for (final s in supported) {
          if (s.languageCode == locale.languageCode) return s;
        }
        return supported.first;
      },

      theme: ThemeData(
        primaryColor: const Color(0xFF2C015D),
        scaffoldBackgroundColor: Colors.white,
      ),

      home: const Root(),

      routes: {
        '/welcome': (_) => const WelcomePage(),
        '/login': (_) => const LoginPage(),
        '/register': (_) => const RegisterPage(),
        '/main': (_) => const MainPage(),
        '/home': (_) => const HomePage(),
        '/leaderboard': (_) => const LeaderboardPage(),
        '/settings': (_) => const SettingsPage(),
      },
    );
  }
}

//
// ######################## ROOT ########################
//
class Root extends StatelessWidget {
  const Root({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, s) {
        if (s.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = s.data;

        if (user == null) return const WelcomePage();
        if (!user.emailVerified) return const VerifyEmailPage();

        return const MainPage();
      },
    );
  }
}

//
// ######################## MAIN PAGE ########################
//
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  late Future<Map<String, dynamic>> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = _loadUserData();
  }

  Future<Map<String, dynamic>> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    return snap.data() ?? {};
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4FF),

      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _userFuture,
          builder: (context, s) {
            if (s.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = s.data ?? {};

            // Trophies safe parsing
            final dynamic t = data['trophies'];
            final int trophies = t is int ? t : int.tryParse("$t") ?? 0;

            final photoUrl =
            data['photoUrl'] is String ? data['photoUrl'] : null;

            final pages = [
              const HomePage(),
              const LeaderboardPage(),
              const StatisticsPage(),
              const SettingsPage(),
            ];

            return Column(
              children: [
                // TOP HEADER
                MainAppHeader(
                  trophyCount: trophies,
                  photoUrl: photoUrl,
                  onTapNotifications: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationsPage(),
                      ),
                    ).then((_) {
                      setState(() => _userFuture = _loadUserData());
                    });
                  },
                  onTapProfile: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProfilePage(),
                      ),
                    ).then((_) {
                      setState(() => _userFuture = _loadUserData());
                    });
                  },
                ),

                Expanded(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: pages,
                  ),
                ),
              ],
            );
          },
        ),
      ),

      // BOTTOM NAVIGATION
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        child: Container(
          padding: const EdgeInsets.only(top: 8, bottom: 12), // makes it taller safely
          color: const Color(0xFF2C015D),
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white70,
            iconSize: 30,
            selectedFontSize: 13,
            unselectedFontSize: 12,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.home_rounded),
                label: loc.home,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.leaderboard_rounded),
                label: loc.leaderboard,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.show_chart_rounded),
                label: loc.statistics,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.settings_rounded),
                label: loc.settings,
              ),
            ],
          ),
        ),
      ),
    );
  }
}