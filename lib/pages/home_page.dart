// ---------------- HOME PAGE ----------------

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zhalbyrak/gen_l10n/app_localizations.dart';

// ✅ Mock test start page (adjust import path to where you placed it)
import 'package:zhalbyrak/mock_test/pages/mock_test_start_page.dart';

import 'categories/mathematics_page.dart';
import 'categories/analogy_page.dart';
import 'categories/reading_page.dart';
import 'categories/grammar_page.dart';

// ✅ Restored "before" style hero gradients (light) + higher-contrast (dark)
const LinearGradient zHeroGradientLight = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0xFFFF5FA2), // pink (soft)
    Color(0xFF9B7CFF), // soft purple
  ],
);

const LinearGradient zHeroGradientDark = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0xFFFF3D7F), // brand pink
    Color(0xFF2C015D), // brand purple
  ],
);

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load(); // fire-and-forget
  }

  Future<void> _load({bool forceMinDelay = true}) async {
    setState(() => _loading = true);

    // ✅ Guarantee shimmer is visible even if Firestore returns instantly
    final minDelay = forceMinDelay
        ? Future<void>.delayed(const Duration(milliseconds: 700))
        : Future<void>.value();

    final fetch = _loadUserData();
    final results = await Future.wait([minDelay, fetch]);

    final data = results[1] as Map<String, dynamic>;
    if (!mounted) return;

    setState(() {
      _data = data;
      _loading = false;
    });
  }

  Future<Map<String, dynamic>> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};

    final snap =
    await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

    return snap.data() ?? {};
  }

  Future<void> _onRefresh() async {
    await _load(forceMinDelay: false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: _loading
            ? _HomeShimmer(onRefresh: _onRefresh)
            : _HomeContent(
          data: _data ?? <String, dynamic>{},
          onRefresh: _onRefresh,
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  final Map<String, dynamic> data;
  final Future<void> Function() onRefresh;

  const _HomeContent({
    required this.data,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Use app locale as Firestore language key (ru/ky/en etc.)
    final appLang = Localizations.localeOf(context).languageCode;

    final fullName =
        (data['fullName'] ?? data['displayName'] ?? '') as String? ?? '';
    final greeting =
    fullName.isNotEmpty ? "${loc.hello}, $fullName!" : loc.hello;

    final categories = [
      _CategoryData(
        title: loc.math,
        subtitle: loc.over500questions,
        icon: Icons.calculate_rounded,
        accentColor: cs.secondary,
        page: const MathematicsPage(),
      ),
      _CategoryData(
        title: loc.analogy,
        subtitle: loc.sharpenReasoning,
        icon: Icons.compare_arrows_rounded,
        accentColor: cs.tertiary,
        page: const AnalogyPage(),
      ),
      _CategoryData(
        title: loc.reading,
        subtitle: loc.over400passages,
        icon: Icons.menu_book_rounded,
        accentColor: cs.primary,
        page: const ReadingPage(),
      ),
      _CategoryData(
        title: loc.grammar,
        subtitle: loc.over2000questions,
        icon: Icons.spellcheck_rounded,
        accentColor: cs.primary,
        page: const GrammarPage(),
      ),
    ];

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HERO BANNER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Container(
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  gradient: isDark ? zHeroGradientDark : zHeroGradientLight,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: cs.shadow.withOpacity(isDark ? 0.28 : 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.welcomeToSecom,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      loc.prepSmart,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.82),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Greeting
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(isDark ? 0.14 : 0.16),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.waving_hand_rounded,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              greeting,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ✅ ORT MOCK TEST BUTTON (full width, before categories)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _OrtMockTestCard(
                title: loc.ortMockTestTitle,
                subtitle: loc.ortMockTestSubtitle,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MockTestStartPage(lang: appLang),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // TITLE
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                loc.homeCategories,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // CATEGORY GRID
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = (constraints.maxWidth - 16) / 2;

                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: categories
                        .map(
                          (c) => SizedBox(
                        width: width,
                        child: _CategoryCard(data: c),
                      ),
                    )
                        .toList(),
                  );
                },
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _OrtMockTestCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OrtMockTestCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;

    final bg = cs.surfaceContainerHighest;
    final sh = cs.shadow.withOpacity(isDark ? 0.28 : 0.16);

    // Light purple branded tint (subtle)
    final tinted = Color.alphaBlend(
      const Color(0xFF9B7CFF).withOpacity(isDark ? 0.14 : 0.10),
      bg,
    );

    return SizedBox(
      height: 128,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: sh,
              blurRadius: 30,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            splashFactory: NoSplash.splashFactory,
            onTap: onTap,
            child: Ink(
              decoration: BoxDecoration(
                color: tinted,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.primary.withOpacity(isDark ? 0.18 : 0.12),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        Icons.assignment_rounded,
                        size: 28,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant.withOpacity(0.78),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final _CategoryData data;

  const _CategoryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;

    final bg = cs.surfaceContainerHighest;
    final sh = cs.shadow.withOpacity(isDark ? 0.28 : 0.16);

    return SizedBox(
      height: 170,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: sh,
              blurRadius: 30,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            splashFactory: NoSplash.splashFactory,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => data.page),
            ),
            child: Ink(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: data.accentColor.withOpacity(isDark ? 0.18 : 0.14),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(data.icon, size: 28, color: data.accentColor),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      data.title,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        data.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant.withOpacity(0.75),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final Widget page;

  _CategoryData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.page,
  });
}

//
// ─────────────────────────────────────────────
//                SHIMMER PLACEHOLDERS
// ─────────────────────────────────────────────

class _HomeShimmer extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _HomeShimmer({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // ✅ High contrast shimmer colors derived from theme (always distinct)
    final base = Color.alphaBlend(
      cs.onSurface.withOpacity(cs.brightness == Brightness.dark ? 0.10 : 0.06),
      cs.surfaceContainerHighest,
    );
    final highlight = Color.alphaBlend(
      Colors.white.withOpacity(cs.brightness == Brightness.dark ? 0.22 : 0.38),
      cs.surfaceContainerHighest,
    );

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: _ZShimmer(
                baseColor: base,
                highlightColor: highlight,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ✅ Shimmer for ORT mock test card (full width)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _ZShimmer(
                baseColor: base,
                highlightColor: highlight,
                child: Container(
                  height: 128,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                children: List.generate(
                  4,
                      (_) => _CategoryShimmerCard(
                    base: base,
                    highlight: highlight,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _CategoryShimmerCard extends StatelessWidget {
  final Color base;
  final Color highlight;

  const _CategoryShimmerCard({
    required this.base,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.of(context).size.width - 56) / 2;

    return _ZShimmer(
      baseColor: base,
      highlightColor: highlight,
      child: Container(
        width: width,
        height: 170,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }
}

/// Custom shimmer that always animates (no external package)
class _ZShimmer extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;

  const _ZShimmer({
    required this.child,
    required this.baseColor,
    required this.highlightColor,
  });

  @override
  State<_ZShimmer> createState() => _ZShimmerState();
}

class _ZShimmerState extends State<_ZShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value; // 0..1

        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) {
            // Move highlight from left to right
            final dx = rect.width * (t * 2 - 1); // -W .. +W

            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: const [0.35, 0.50, 0.65],
              transform: _SlideGradientTransform(dx),
            ).createShader(rect);
          },
          child: widget.child,
        );
      },
    );
  }
}

class _SlideGradientTransform extends GradientTransform {
  final double dx;
  const _SlideGradientTransform(this.dx);

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(dx, 0.0, 0.0);
  }
}