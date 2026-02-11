import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../currency/wallet_service.dart';

// ✅ Use EXACT same hero gradients as Home banner (identical colors + direction)
const LinearGradient zHeroGradientLight = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0xFFFF5FA2), // light hero pink
    Color(0xFF9B7CFF), // light hero purple
  ],
);

const LinearGradient zHeroGradientDark = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0xFFFF3D7F), // dark hero pink (brand pink)
    Color(0xFF2C015D), // dark hero purple (brand purple)
  ],
);

class MainAppHeader extends StatelessWidget {
  final VoidCallback? onTapTrophy;
  final VoidCallback? onTapLeaf; // ✅ NEW
  final VoidCallback onTapProfile;

  const MainAppHeader({
    super.key,
    this.onTapTrophy,
    this.onTapLeaf,
    required this.onTapProfile,
  });

  Stream<DocumentSnapshot<Map<String, dynamic>>> _userStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
  }

  int _readInt(Map<String, dynamic>? data, String key, {int fallback = 0}) {
    final v = data == null ? null : data[key];
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  String? _readString(Map<String, dynamic>? data, String key) {
    final v = data == null ? null : data[key];
    if (v is String && v.trim().isNotEmpty) return v.trim();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // ✅ ZHALBYRAKS balance comes from wallet provider (not users doc)
    final wallet = context.watch<WalletService>();
    final zhalbyraks = wallet.ready ? wallet.balance : 0;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _userStream(),
      builder: (context, snap) {
        final data = snap.data?.data();

        final trophyCount = _readInt(data, 'trophies', fallback: 0);
        final streakDays = _readInt(data, 'currentStreakDays', fallback: 0);
        final photoUrl = _readString(data, 'photoUrl');

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final s = (width / 360.0).clamp(0.80, 1.06);

              // ✅ Slightly smaller logo to give more room to pills
              final logoH = 30.0 * s; // was 34*s
              final avatarR = 19.0 * s;
              final containerVPad = 8.0 * s;
              final containerHPad = 14.0 * s;

              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: containerHPad,
                  vertical: containerVPad,
                ),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(22 * s),
                  boxShadow: [
                    BoxShadow(
                      color: cs.shadow.withOpacity(0.12),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // ✅ Make the logo area a bit tighter too
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 118 * s),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Image.asset(
                          'assets/secom_logo.png',
                          height: logoH,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    SizedBox(width: 10 * s),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: _RightClusterAdaptive(
                          scale: s,
                          streakDays: streakDays,
                          trophyCount: trophyCount,
                          leafs: zhalbyraks, // ✅ use wallet balance
                          onTapTrophy: onTapTrophy,
                          onTapLeaf: onTapLeaf,
                          onTapProfile: onTapProfile,
                          photoUrl: photoUrl,
                          avatarRadius: avatarR,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _RightClusterAdaptive extends StatelessWidget {
  final double scale;
  final int streakDays;
  final int trophyCount;
  final int leafs;

  final VoidCallback? onTapTrophy;
  final VoidCallback? onTapLeaf;
  final VoidCallback onTapProfile;

  final String? photoUrl;
  final double avatarRadius;

  const _RightClusterAdaptive({
    required this.scale,
    required this.streakDays,
    required this.trophyCount,
    required this.leafs,
    required this.onTapTrophy,
    required this.onTapLeaf,
    required this.onTapProfile,
    required this.photoUrl,
    required this.avatarRadius,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final avatarDiameter = avatarRadius * 2.0;
        final gapBeforeAvatar = 12.0 * scale;

        final pillsMaxWidth =
        (constraints.maxWidth - avatarDiameter - gapBeforeAvatar)
            .clamp(0.0, constraints.maxWidth);

        // ✅ If space is extremely tight, reduce inter-pill gaps slightly
        final bool tight = constraints.maxWidth < 210 * scale;
        final gap = (tight ? 6.0 : 8.0) * scale;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: pillsMaxWidth),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.translate(
                      offset: Offset(-4 * scale, 0),
                      child: _StreakPill(
                        streakDays: streakDays,
                        scale: scale,
                      ),
                    ),
                    SizedBox(width: gap),
                    Transform.translate(
                      offset: Offset(-4 * scale, 0),
                      child: _LeafPill(
                        count: leafs,
                        onTap: onTapLeaf,
                        scale: scale,
                      ),
                    ),
                    SizedBox(width: gap),
                    Transform.translate(
                      offset: Offset(-4 * scale, 0),
                      child: _TrophyPill(
                        count: trophyCount,
                        onTap: onTapTrophy,
                        scale: scale,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: gapBeforeAvatar),
            GestureDetector(
              onTap: onTapProfile,
              child: CircleAvatar(
                radius: avatarRadius,
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                backgroundImage:
                (photoUrl != null) ? NetworkImage(photoUrl!) : null,
                child: (photoUrl == null)
                    ? Icon(
                  Icons.person,
                  color: cs.onPrimary,
                  size: 18 * scale,
                )
                    : null,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PillNumberFormatter {
  static String shorten(num value) {
    final v = value.toDouble().abs();
    if (v < 1000) return value.toInt().toString();
    if (v < 10_000) return "${(v / 1000).toStringAsFixed(1)}k";
    if (v < 1_000_000) return "${(v / 1000).floor()}k";
    if (v < 10_000_000) return "${(v / 1_000_000).toStringAsFixed(1)}M";
    if (v < 1_000_000_000) return "${(v / 1_000_000).floor()}M";
    return "${(v / 1_000_000_000).toStringAsFixed(1)}B";
  }

  static double fontFor(int value, double base) {
    final len = value.abs().toString().length;
    if (len <= 3) return base;
    if (len == 4) return base * 0.96;
    if (len == 5) return base * 0.92;
    if (len == 6) return base * 0.88;
    if (len == 7) return base * 0.84;
    return base * 0.80;
  }
}

class _TrophyPill extends StatelessWidget {
  final int count;
  final VoidCallback? onTap;
  final double scale;

  const _TrophyPill({
    required this.count,
    this.onTap,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final text = _PillNumberFormatter.shorten(count);
    final baseFont = 14.5 * scale;
    final fontSize = _PillNumberFormatter.fontFor(count, baseFont);

    final pill = Container(
      constraints: BoxConstraints(minHeight: 30 * scale),
      padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 6 * scale),
      decoration: BoxDecoration(
        color: cs.tertiaryContainer,
        borderRadius: BorderRadius.circular(22 * scale),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.10),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.emoji_events,
            size: 17 * scale,
            color: cs.tertiary,
          ),
          SizedBox(width: 6 * scale),
          ConstrainedBox(
            constraints: BoxConstraints(minWidth: 14 * scale),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                text,
                maxLines: 1,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: cs.onTertiaryContainer,
                  fontSize: fontSize,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return pill;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22 * scale),
      child: pill,
    );
  }
}

class _LeafPill extends StatelessWidget {
  final int count;
  final VoidCallback? onTap;
  final double scale;

  const _LeafPill({
    required this.count,
    this.onTap,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;

    // ✅ Green palette (stable across light/dark)
    const leafGreen = Color(0xFF22C55E); // vivid green
    const leafGreenDark = Color(0xFF16A34A); // deeper green

    final text = _PillNumberFormatter.shorten(count);
    final baseFont = 14.5 * scale;
    final fontSize = _PillNumberFormatter.fontFor(count, baseFont);

    // ✅ Green background that still reads well in both themes
    final bg = isDark
        ? Color.alphaBlend(
      leafGreenDark.withOpacity(0.24),
      cs.surfaceContainerHigh,
    )
        : Color.alphaBlend(
      leafGreen.withOpacity(0.18),
      cs.surfaceContainerHigh,
    );

    final pill = Container(
      constraints: BoxConstraints(minHeight: 30 * scale),
      padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 6 * scale),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22 * scale),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.08),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.eco_rounded,
            size: 17 * scale,
            color: isDark ? leafGreen : leafGreenDark,
          ),
          SizedBox(width: 6 * scale),
          ConstrainedBox(
            constraints: BoxConstraints(minWidth: 14 * scale),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                text,
                maxLines: 1,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                  fontSize: fontSize,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return pill;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22 * scale),
      child: pill,
    );
  }
}

class _StreakPill extends StatelessWidget {
  final int streakDays;
  final double scale;

  const _StreakPill({
    required this.streakDays,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasStreak = streakDays > 0;

    final baseFont = 14.5 * scale;
    final fontSize = _PillNumberFormatter.fontFor(streakDays, baseFont);

    if (!hasStreak) {
      return Container(
        constraints: BoxConstraints(minHeight: 30 * scale),
        padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 6 * scale),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(22 * scale),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_fire_department_rounded,
              size: 17 * scale,
              color: cs.onSurfaceVariant.withOpacity(0.55),
            ),
            SizedBox(width: 6 * scale),
            Text(
              '0',
              style: TextStyle(
                fontSize: _PillNumberFormatter.fontFor(0, baseFont),
                fontWeight: FontWeight.w700,
                color: cs.onSurfaceVariant.withOpacity(0.75),
              ),
            ),
          ],
        ),
      );
    }

    final isDark = cs.brightness == Brightness.dark;
    final grad = isDark ? zHeroGradientDark : zHeroGradientLight;

    const fg = Colors.white;

    return Container(
      constraints: BoxConstraints(minHeight: 30 * scale),
      padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 6 * scale),
      decoration: BoxDecoration(
        gradient: grad,
        borderRadius: BorderRadius.circular(22 * scale),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.14),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            size: 17 * scale,
            color: fg,
          ),
          SizedBox(width: 6 * scale),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$streakDays',
              maxLines: 1,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
