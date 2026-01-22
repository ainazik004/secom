import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';


// Localization
import 'gen_l10n/app_localizations.dart';

// Pages
import 'pages/welcome_page.dart';
import 'pages/home_page.dart';
import 'pages/leaderboard_page.dart';
import 'pages/settings_page.dart';
import 'pages/statistics_page.dart';
import 'pages/profile_page.dart';
import 'pages/verify_email_page.dart';

// Providers
import 'provider/provider.dart';
import 'provider/theme_provider.dart';

// Header
import 'widgets/main_app_header.dart';

// Shimmer
import 'package:shimmer/shimmer.dart';

// Theme schemes
import 'theme/z_color_schemes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ App Check (debug in dev, real provider in release)
  await FirebaseAppCheck.instance.activate(
    androidProvider: kReleaseMode
        ? AndroidProvider.playIntegrity
        : AndroidProvider.debug,
    appleProvider: kReleaseMode
        ? AppleProvider.deviceCheck
        : AppleProvider.debug,
  );

  final themeProvider = ThemeProvider();
  await themeProvider.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider.value(value: themeProvider),
      ],
      child: const SecomApp(),
    ),
  );
}

class SecomApp extends StatelessWidget {
  const SecomApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ZHALBYRAK',

      locale: localeProvider.locale,
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

      themeMode: themeProvider.mode,

      theme: ThemeData(
        useMaterial3: true,
        colorScheme: zLightScheme,
      ),

      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: zDarkScheme,
      ),

      home: const Root(),
    );
  }
}

//
// ─────────────────────────────────────────
//                   ROOT
// ─────────────────────────────────────────
//

class Root extends StatelessWidget {
  const Root({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, s) {
        if (s.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.background,
            body: SafeArea(child: _MainShimmer()),
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
// ─────────────────────────────────────────
//               MAIN PAGE
// ─────────────────────────────────────────
//

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _index = 0;

  final List<Widget?> _pages = List<Widget?>.filled(4, null, growable: false);

  Widget _buildPage(int i) {
    switch (i) {
      case 0:
        return const HomePage();
      case 1:
        return const LeaderboardPage();
      case 2:
        return const StatisticsPage();
      case 3:
      default:
        return const SettingsPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    _pages[_index] ??= _buildPage(_index);

    return Scaffold(
      backgroundColor: cs.background,
      body: SafeArea(
        child: Column(
          children: [
            MainAppHeader(
              onTapProfile: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                );
              },
              onTapTrophy: () {
                setState(() => _index = 1);
              },
            ),

            Expanded(
              child: IndexedStack(
                index: _index,
                children: List.generate(_pages.length, (i) {
                  final page = _pages[i];
                  if (page != null) return page;

                  return _MainShimmer();
                }),
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: _BottomNavBar(
        index: _index,
        onTap: (i) {
          setState(() {
            _index = i;
            _pages[i] ??= _buildPage(i);
          });
        },
        labels: [
          loc.home,
          loc.leaderboard,
          loc.statistics,
          loc.settings,
        ],
        icons: const [
          Icons.home_rounded,
          Icons.leaderboard_rounded,
          Icons.show_chart_rounded,
          Icons.settings_rounded,
        ],
      ),
    );
  }
}

//
// ─────────────────────────────────────────
//         CUSTOM BOTTOM NAV BAR (THEMED)
// ─────────────────────────────────────────
//

class _BottomNavBar extends StatelessWidget {
  final int index;
  final List<String> labels;
  final List<IconData> icons;
  final ValueChanged<int> onTap;

  const _BottomNavBar({
    required this.index,
    required this.labels,
    required this.icons,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final isDark = cs.brightness == Brightness.dark;

    final bg = isDark
    // darker than surface in dark mode
        ? Color.alphaBlend(
      Colors.black.withOpacity(0.30),
      cs.surface,
    )
    // darker than surface in light mode
        : Color.alphaBlend(
      Colors.black.withOpacity(0.08),
      cs.surface,
    );


    final selected = cs.secondary;

    // ✅ Themed purple/blue for unselected items (instead of grey)
    final unselected = Color.alphaBlend(
      cs.primary.withOpacity(0.75),
      cs.onSurface,
    ).withOpacity(0.95);

    return Container(
      height: 86,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.zero,
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.16),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final isSelected = i == index;

          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => onTap(i),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedScale(
                      scale: isSelected ? 1.20 : 1.0,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutBack,
                      child: Icon(
                        icons[i],
                        size: 28,
                        color: isSelected ? selected : unselected,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FittedBox(
                        child: Text(
                          labels[i],
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.fade,
                          style: TextStyle(
                            fontSize: 12.8,
                            fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? selected : unselected.withOpacity(0.85),
                          )
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

//
// ─────────────────────────────────────────
//           FULL-PAGE SHIMMER (THEMED)
// ─────────────────────────────────────────
//

class _MainShimmer extends StatelessWidget {
  const _MainShimmer();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Keep shimmer subtle in both themes:
    final base = cs.surfaceContainerHigh;
    final highlight = cs.surfaceContainerHighest;

    return Column(
      children: [
        // Header shimmer
        Shimmer.fromColors(
          baseColor: base,
          highlightColor: highlight,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            height: 58,
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),

        // Body shimmer
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Shimmer.fromColors(
                baseColor: base,
                highlightColor: highlight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 150,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),

                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: List.generate(4, (_) {
                        final width =
                            (MediaQuery.of(context).size.width - 56) / 2;

                        return Container(
                          width: width,
                          height: 170,
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(24),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
