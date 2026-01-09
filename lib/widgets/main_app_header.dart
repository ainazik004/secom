import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
    const purple = Color(0xFF2C015D);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _userStream(),
      builder: (context, snap) {
        final data = snap.data?.data();

        final trophyCount = _readInt(data, 'trophies', fallback: 0);
        final streakDays = _readInt(data, 'currentStreakDays', fallback: 0);
        final photoUrl = _readString(data, 'photoUrl');

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6), // ↓ less tall
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Base design tuned for ~360px wide phones.
              // Scale gently down on smaller widths, and do not scale up.
              final width = constraints.maxWidth;
              final s = (width / 360.0).clamp(0.82, 1.0);

              final logoH = 34.0 * s; // was 38
              final avatarR = 19.0 * s; // was 21
              final containerVPad = 8.0 * s; // was 10
              final containerHPad = 14.0 * s; // was 16

              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: containerHPad,
                  vertical: containerVPad,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22 * s), // slightly smaller
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x182C015D),
                      blurRadius: 15,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Logo: constrained + scaleDown so it never forces overflow
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

                    // Right side takes remaining width and scales as needed
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
                          purple: purple,
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
  final Color purple;
  final double avatarRadius;

  const _RightClusterAdaptive({
    required this.scale,
    required this.streakDays,
    required this.trophyCount,
    required this.onTapTrophy,
    required this.onTapProfile,
    required this.photoUrl,
    required this.purple,
    required this.avatarRadius,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final avatarDiameter = avatarRadius * 2.0;
        final gapBeforeAvatar = 12.0 * scale; // was 14

        // Available width for pills row
        final pillsMaxWidth =
        (constraints.maxWidth - avatarDiameter - gapBeforeAvatar)
            .clamp(0.0, constraints.maxWidth);

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pills area: scales down as a whole if needed (no overflow)
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

            // Avatar: also scales down
            GestureDetector(
              onTap: onTapProfile,
              child: CircleAvatar(
                radius: avatarRadius,
                backgroundColor: purple,
                backgroundImage: (photoUrl != null) ? NetworkImage(photoUrl!) : null,
                child: (photoUrl == null)
                    ? Icon(
                  Icons.person,
                  color: Colors.white,
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
    final pill = Container(
      constraints: BoxConstraints(minHeight: 30 * scale),
      padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 6 * scale),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E0),
        borderRadius: BorderRadius.circular(22 * scale),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events, size: 17 * scale, color: Colors.amber[700]),
          SizedBox(width: 6 * scale),
          // Scale down the number if needed
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _shorten(count),
              maxLines: 1,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2C015D),
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
    final hasStreak = streakDays > 0;

    if (!hasStreak) {
      return Container(
        constraints: BoxConstraints(minHeight: 30 * scale),
        padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 6 * scale),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F7),
          borderRadius: BorderRadius.circular(22 * scale),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_fire_department_rounded,
              size: 17 * scale,
              color: const Color(0xFFB0B0B5),
            ),
            SizedBox(width: 6 * scale),
            Text(
              '0',
              style: TextStyle(
                fontSize: 14.5 * scale,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF7E7E86),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      constraints: BoxConstraints(minHeight: 30 * scale),
      padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 6 * scale),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF7FB2), Color(0xFF7F4BFF)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(22 * scale),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            size: 17 * scale,
            color: Colors.white,
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
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
