import 'package:flutter/material.dart';

class MainAppHeader extends StatelessWidget {
  final VoidCallback? onTapTrophy;
  final VoidCallback onTapProfile;
  final int trophyCount;
  final int streakDays; // New: streak from Firestore
  final String? photoUrl;

  const MainAppHeader({
    super.key,
    this.onTapTrophy,
    required this.onTapProfile,
    this.trophyCount = 0,
    required this.streakDays,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF2C015D);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
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
            // Left: logo
            Image.asset(
              'assets/secom_logo.png',
              height: 38,
            ),

            const Spacer(),

            // Right side: streak, trophies, avatar
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Move slightly left so avatar has space
                Transform.translate(
                  offset: const Offset(-6, 0),
                  child: _StreakPill(streakDays: streakDays),
                ),

                const SizedBox(width: 10),

                Transform.translate(
                  offset: const Offset(-6, 0),
                  child: _AdaptiveTrophyPill(
                    count: trophyCount,
                    onTap: onTapTrophy,
                  ),
                ),

                const SizedBox(width: 14),

                // Avatar – now clearly visible
                GestureDetector(
                  onTap: onTapProfile,
                  child: CircleAvatar(
                    radius: 21, // slightly bigger
                    backgroundColor: purple,
                    backgroundImage: (photoUrl != null &&
                        photoUrl!.isNotEmpty)
                        ? NetworkImage(photoUrl!)
                        : null,
                    child: (photoUrl == null || photoUrl!.isEmpty)
                        ? const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 20,
                    )
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AdaptiveTrophyPill extends StatelessWidget {
  final int count;
  final VoidCallback? onTap;

  const _AdaptiveTrophyPill({
    required this.count,
    this.onTap,
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
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E0),
        borderRadius: BorderRadius.circular(22),
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
          Icon(Icons.emoji_events, size: 18, color: Colors.amber[700]),
          const SizedBox(width: 6),
          Text(
            _shorten(count),
            maxLines: 1,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF2C015D),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return pill;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: pill,
    );
  }
}

// ─────────────────────────────────────────
// Colored streak pill (no "d")
// ─────────────────────────────────────────
class _StreakPill extends StatelessWidget {
  final int streakDays;

  const _StreakPill({required this.streakDays});

  @override
  Widget build(BuildContext context) {
    final hasStreak = streakDays > 0;

    if (!hasStreak) {
      // Grey, when no streak yet
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F7),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.local_fire_department_rounded,
              size: 18,
              color: Color(0xFFB0B0B5),
            ),
            SizedBox(width: 6),
            Text(
              '0',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF7E7E86),
              ),
            ),
          ],
        ),
      );
    }

    // Colored gradient streak pill
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFF7FB2),
            Color(0xFF7F4BFF),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(22),
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
          const Icon(
            Icons.local_fire_department_rounded,
            size: 18,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            '$streakDays', // no "d"
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
