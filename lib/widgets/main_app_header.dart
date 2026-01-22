import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
  final VoidCallback onTapProfile;

  const MainAppHeader({
    super.key,
    this.onTapTrophy,
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
              final s = (width / 360.0).clamp(0.82, 1.0);

              final logoH = 34.0 * s;
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
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 140 * s),
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
                          onTapTrophy: onTapTrophy,
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
  final VoidCallback? onTapTrophy;
  final VoidCallback onTapProfile;
  final String? photoUrl;
  final double avatarRadius;

  const _RightClusterAdaptive({
    required this.scale,
    required this.streakDays,
    required this.trophyCount,
    required this.onTapTrophy,
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
                      offset: Offset(-5 * scale, 0),
                      child: _StreakPill(
                        streakDays: streakDays,
                        scale: scale,
                      ),
                    ),
                    SizedBox(width: 8 * scale),
                    Transform.translate(
                      offset: Offset(-5 * scale, 0),
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
                backgroundImage: (photoUrl != null) ? NetworkImage(photoUrl!) : null,
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

class _TrophyPill extends StatelessWidget {
  final int count;
  final VoidCallback? onTap;
  final double scale;

  const _TrophyPill({
    required this.count,
    this.onTap,
    required this.scale,
  });

  String _shorten(int value) {
    if (value < 1000) return value.toString();
    if (value < 10000) return "${(value / 1000).toStringAsFixed(1)}k";
    if (value < 1000000) return "${(value / 1000).floor()}k";
    if (value < 10000000) return "${(value / 1000000).toStringAsFixed(1)}M";
    return "${(value / 1000000).floor()}M";
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _shorten(count),
              maxLines: 1,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: cs.onTertiaryContainer,
                fontSize: 14.5 * scale,
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
                fontSize: 14.5 * scale,
                fontWeight: FontWeight.w700,
                color: cs.onSurfaceVariant.withOpacity(0.75),
              ),
            ),
          ],
        ),
      );
    }

    // ✅ FIX: no flipping, no cs.secondary/cs.primary guesswork.
    // Use the SAME gradients as the Home hero banner.
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;
    final grad = isDark ? zHeroGradientDark : zHeroGradientLight;

    // On these hero gradients, white is always the correct readable foreground
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
                fontSize: 14.5 * scale,
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
