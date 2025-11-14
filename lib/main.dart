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

// Auth pages
import 'package:secom/pages/login_page.dart';
import 'package:secom/pages/register_page.dart';
import 'package:secom/pages/verify_email_page.dart';

// Locale provider
import 'package:secom/provider/provider.dart';

//other
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

      localeResolutionCallback: (locale, supportedLocales) {
        if (locale == null) return supportedLocales.first;
        for (final supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale.languageCode) {
            return supportedLocale;
          }
        }
        return supportedLocales.first;
      },

      // App theme
      theme: ThemeData(
        primaryColor: const Color(0xFF2C015D),
        scaffoldBackgroundColor: Colors.white,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF3D7F),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 20),
          ),
        ),
      ),

      home: const Root(),

      routes: {
        '/welcome': (_) => const WelcomePage(),
        '/login': (_) => const LoginPage(),
        '/register': (_) => const RegisterPage(),
        '/main': (_) => const MainPage(),
        '/home': (_) => HomePage(),
        '/leaderboard': (_) => const LeaderboardPage(),
        '/settings': (_) => const SettingsPage(),
      },
    );
  }
}

//
// ##############################################################
// 🔥 ROOT LOGIC WITH EMAIL VERIFICATION ENFORCEMENT
// ##############################################################
//
class Root extends StatelessWidget {
  const Root({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // waiting for Firebase Auth
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        // Not logged in → Welcome
        if (user == null) {
          return const WelcomePage();
        }

        // Logged in but NOT verified → Verification page
        if (!user.emailVerified) {
          return const VerifyEmailPage();
        }

        // Logged in AND verified → MainPage
        return const MainPage();
      },
    );
  }
}

//
// ##############################################################
// Main bottom-navigation container
// ##############################################################
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

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    return snapshot.data() ?? {};
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4FF),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _userFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }

            final data = snapshot.data ?? {};
            final int trophies = (data['trophies'] ?? 0) is int
                ? data['trophies']
                : int.tryParse('${data['trophies']}') ?? 0;
            final dynamic photoData = data['photoUrl'];
            final String? photoUrl = photoData is String ? photoData : null;
            final pages = [
              HomePage(
                embedded: true,
                userData: data,
              ),
              const LeaderboardPage(embedded: true),
              const SettingsPage(embedded: true),
            ];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                      setState(() {
                        _userFuture = _loadUserData();
                      });
                    });
                  },
                  onTapProfile: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProfilePage(),
                      ),
                    ).then((_) {
                      setState(() {
                        _userFuture = _loadUserData();
                      });
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
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Color(0x162C015D),
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          child: BottomNavigationBar(
            backgroundColor: const Color(0xFF2C015D),
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white70,
            showUnselectedLabels: true,
            selectedFontSize: 13,
            unselectedFontSize: 12,
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
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
