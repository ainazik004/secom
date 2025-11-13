import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

// Localization
import 'gen_l10n/app_localizations.dart';
import 'package:secom/l10n/l10n.dart';

// Pages
import 'package:secom/pages/welcome_page.dart';
import 'package:secom/pages/home_page.dart';
import 'package:secom/pages/leaderboard_page.dart';
import 'package:secom/pages/settings_page.dart';

// Auth UI pages (you will add these pages to lib/pages/)
import 'package:secom/pages/login_page.dart';
import 'package:secom/pages/register_page.dart';

// Locale provider
import 'package:secom/provider/provider.dart';

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
        return supportedLocales.first; // fallback
      },

      // Theme setup (keeps your existing theme)
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

      // Use Root to decide initial screen based on auth state.
      home: const Root(),

      // Named routes for convenient navigation from anywhere
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

/// Root widget listens to FirebaseAuth and routes to MainPage (signed in)
/// or WelcomePage (signed out). Firebase Auth persists the user by default,
/// so this handles "remember once logged in" behavior automatically.
class Root extends StatelessWidget {
  const Root({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // still initializing connection to Firebase Auth
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If there's no user -> show Welcome flow (user will then go to Login/Register)
        if (!snapshot.hasData || snapshot.data == null) {
          return const WelcomePage();
        }

        // If user is signed in -> show MainPage (bottom navigation)
        // Optionally you could check snapshot.data!.emailVerified here and force verification.
        return const MainPage();
      },
    );
  }
}

/// Your existing MainPage with bottom navigation. Kept largely as-is.
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    // Pages rebuilt on locale change
    final List<Widget> pages = [
      HomePage(), // HomePage uses localized strings internally
      const LeaderboardPage(),
      const SettingsPage(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF2C015D),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: loc.home,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.leaderboard),
            label: loc.leaderboard,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: loc.settings,
          ),
        ],
      ),
    );
  }
}
