import 'package:flutter/material.dart';
import 'package:zhalbyrak/gen_l10n/app_localizations.dart';
import 'package:zhalbyrak/pages/categories/topic_quiz_page.dart';

class AnalogyPage extends StatelessWidget {
  const AnalogyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TOP BAR
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Row(
                children: [
                  const _CloseButton(),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.analogy,
                          style: tt.titleLarge?.copyWith(
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          loc.analogyIntroSubtitle,
                          style: tt.bodySmall?.copyWith(
                            fontSize: 13,
                            color: cs.onSurface.withOpacity(0.60),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
                  _InfoCard(
                    title: loc.testAboutTitle,
                    locBody: loc.analogyTestAboutBody,
                  ),
                  const SizedBox(height: 14),

                  _BulletsCard(
                    title: loc.testYouWillGetTitle,
                    bullets: [
                      loc.testYouWillGetBullet1,
                      loc.testYouWillGetBullet2,
                      loc.testYouWillGetBullet3,
                    ],
                  ),
                  const SizedBox(height: 18),

                  _PrimaryButton(
                    text: loc.startTest,
                    icon: Icons.play_arrow_rounded,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TopicQuizPage(
                            title: loc.analogy,
                            section: 'analogy',
                            limit: 20,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surfaceContainerHighest,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: cs.shadow.withOpacity(0.18),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => Navigator.of(context).pop(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            Icons.close_rounded,
            size: 20,
            color: cs.onSurface,
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String locBody;

  const _InfoCard({required this.title, required this.locBody});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final card = cs.surfaceContainerHighest;
    final shadow = cs.shadow.withOpacity(0.10);
    final accent = cs.primary;

    return Container(
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: shadow,
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.info_outline_rounded,
                    color: accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: tt.titleSmall?.copyWith(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              locBody,
              style: tt.bodyMedium?.copyWith(
                fontSize: 13.5,
                height: 1.45,
                color: cs.onSurface.withOpacity(0.72),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BulletsCard extends StatelessWidget {
  final String title;
  final List<String> bullets;

  const _BulletsCard({required this.title, required this.bullets});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final card = cs.surfaceContainerHighest;
    final shadow = cs.shadow.withOpacity(0.10);
    final accent = cs.secondary;

    return Container(
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: shadow,
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.checklist_rounded,
                    color: accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: tt.titleSmall?.copyWith(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...bullets.map((b) => _BulletRow(text: b)),
          ],
        ),
      ),
    );
  }
}

class _BulletRow extends StatelessWidget {
  final String text;

  const _BulletRow({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: cs.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: tt.bodyMedium?.copyWith(
                fontSize: 13.5,
                height: 1.4,
                color: cs.onSurface.withOpacity(0.72),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.text,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final btnColor = isDark
        ? Color.alphaBlend(Colors.black.withOpacity(0.18), cs.primary)
        : cs.primary;

    final shadowOpacity = isDark ? 0.12 : 0.22;
    final elevation = isDark ? 2.0 : 6.0;

    return SizedBox(
      height: 54,
      child: Material(
        color: btnColor,
        borderRadius: BorderRadius.circular(18),
        elevation: elevation,
        shadowColor: cs.shadow.withOpacity(shadowOpacity),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: cs.onPrimary),
                const SizedBox(width: 10),
                Text(
                  text,
                  style: tt.titleSmall?.copyWith(
                    color: cs.onPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 15.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
