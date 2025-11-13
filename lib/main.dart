import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

//Firebase
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// 🧩 Localization imports
import 'gen_l10n/app_localizations.dart';
import 'package:secom/l10n/l10n.dart';

// 🧭 Pages
import 'package:secom/pages/welcome_page.dart';
import 'package:secom/pages/home_page.dart';
import 'package:secom/pages/leaderboard_page.dart';
import 'package:secom/pages/settings_page.dart';

// 🧠 Locale provider
import 'package:secom/provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensures Flutter is initialized
  await Firebase.initializeApp( // Initializes Firebase
    options: DefaultFirebaseOptions.currentPlatform, // Uses Firebase options for your platform
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

      // 🌍 Localization setup
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

      // 🎨 Theme setup
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

      home: const WelcomePage(),
    );
  }
}

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

    // ✅ create pages here, so they rebuild on locale change
    final List<Widget> pages = [
      HomePage(), // HomePage uses loc internally
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
