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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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

                    GestureDetector(
                      onTap: onTapProfile,
                      child: CircleAvatar(
                        radius: 21,
                        backgroundColor: purple,
                        backgroundImage:
                        (photoUrl != null) ? NetworkImage(photoUrl) : null,
                        child: (photoUrl == null)
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
      },
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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

class _StreakPill extends StatelessWidget {
  final int streakDays;

  const _StreakPill({required this.streakDays});

  @override
  Widget build(BuildContext context) {
    final hasStreak = streakDays > 0;

    if (!hasStreak) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
            '$streakDays',
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
