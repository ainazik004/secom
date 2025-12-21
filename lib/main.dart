import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';

// Localization
import 'gen_l10n/app_localizations.dart';
import 'package:secom/l10n/l10n.dart';

// Pages
import 'pages/welcome_page.dart';
import 'pages/home_page.dart';
import 'pages/leaderboard_page.dart';
import 'pages/settings_page.dart';
import 'pages/statistics_page.dart';
import 'pages/profile_page.dart';
import 'pages/verify_email_page.dart';

// Provider
import 'provider/provider.dart';

// Header
import 'widgets/main_app_header.dart';

// Shimmer
import 'package:shimmer/shimmer.dart';

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
  late Future<Map<String, dynamic>> _userFuture;

  final List<Widget?> _pages = List<Widget?>.filled(4, null, growable: false);

  @override
  void initState() {
    super.initState();
    _userFuture = _loadUser();
  }

  Future<Map<String, dynamic>> _loadUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};

    final snap =
    await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    return snap.data() ?? {};
  }

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

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4FF),

      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _userFuture,
          builder: (context, s) {
            if (s.connectionState == ConnectionState.waiting) {
              return const _MainShimmer();
            }

            if (s.hasError) {
              return Center(
                child: Text(
                  'Error: ${s.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              );
            }

            final data = s.data ?? {};

            // ── TROPHIES ───────────────────────────────────────
            final dynamic t = data['trophies'];
            final int trophies = t is int ? t : int.tryParse('$t') ?? 0;

            // ── STREAK (NEW) ───────────────────────────────────
            final dynamic cs = data['currentStreakDays'];
            final int currentStreakDays =
            cs is int ? cs : int.tryParse('$cs') ?? 0;

            // ── AVATAR URL ─────────────────────────────────────
            final photoUrl =
            data['photoUrl'] is String ? data['photoUrl'] as String : null;

            _pages[_index] ??= _buildPage(_index);

            return Column(
              children: [
                //
                // ───────── HEADER WITH STREAK ─────────
                //
                MainAppHeader(
                  trophyCount: trophies,
                  streakDays: currentStreakDays, // <<< NEW
                  photoUrl: photoUrl,
                  onTapProfile: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProfilePage(),
                      ),
                    ).then((_) {
                      setState(() => _userFuture = _loadUser());
                    });
                  },
                  onTapTrophy: () {
                    setState(() => _index = 1); // leaderboard
                  },
                ),

                Expanded(
                  child: IndexedStack(
                    index: _index,
                    children: List.generate(_pages.length, (i) {
                      final page = _pages[i];
                      if (page != null) return page;

                      if (i == 0) {
                        return const HomePage();
                      }
                      return const SizedBox.shrink();
                    }),
                  ),
                ),
              ],
            );
          },
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
//         CUSTOM BOTTOM NAV BAR
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
    const purple = Color(0xFF2C015D);
    const selectedColor = Color(0xFFFF3D7F);
    const background = Color(0xFFF6F4FF);

    return Container(
      height: 86,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: const BoxDecoration(
        color: background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(26),
          topRight: Radius.circular(26),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 20,
            offset: Offset(0, -6),
          ),
        ],
      ),

      child: Row(
        children: List.generate(labels.length, (i) {
          final selected = i == index;

          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => onTap(i),

              child: Padding(
                padding: const EdgeInsets.only(bottom: 6),

                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ---- ICON ----
                    AnimatedScale(
                      scale: selected ? 1.20 : 1.0,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutBack,
                      child: Icon(
                        icons[i],
                        size: 28,
                        color: selected ? selectedColor : purple,
                      ),
                    ),

                    const SizedBox(height: 2),

                    // ---- LABEL ----
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
                            selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected
                                ? selectedColor
                                : purple.withOpacity(0.85),
                          ),
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
//           FULL-PAGE SHIMMER (FIXED)
// ─────────────────────────────────────────
//

class _MainShimmer extends StatelessWidget {
  const _MainShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        //
        // ───────── FIXED SHORT HEADER SHIMMER ─────────
        //
        Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),

            // EXACT height matching new header:
            height: 58,

            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),

        //
        // ───────── BODY SHIMMER ─────────
        //
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //
                    // Hero card placeholder
                    //
                    Container(
                      height: 150,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),

                    //
                    // Category grid shimmer (4 items)
                    //
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
                            color: Colors.white,
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
