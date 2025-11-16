import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:secom/gen_l10n/app_localizations.dart';
import 'package:visibility_detector/visibility_detector.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  late Future<List<DocumentSnapshot<Map<String, dynamic>>>> _leaderboardFuture;

  bool _userTileVisible = false;

  @override
  void initState() {
    super.initState();
    _leaderboardFuture = _loadLeaderboard();
  }

  /// -----------------------------------------------------
  /// LOAD TOP 50 USERS + CURRENT USER (IF NOT IN TOP 50)
  /// -----------------------------------------------------
  Future<List<DocumentSnapshot<Map<String, dynamic>>>> _loadLeaderboard() async {
    final db = FirebaseFirestore.instance;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return [];

    final top50snap = await db
        .collection('users')
        .orderBy('trophies', descending: true)
        .limit(50)
        .get();

    final top50 = top50snap.docs;

    // Get current user doc
    final me = await db.collection('users').doc(user.uid).get();

    final isInTop50 = top50.any((d) => d.id == user.uid);

    if (isInTop50) {
      return top50;
    } else {
      return [...top50, me];
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4FF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.leaderboard,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2C015D),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Top learners ranked by trophies",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black.withOpacity(0.55),
                ),
              ),

              const SizedBox(height: 16),

              Expanded(
                child: FutureBuilder<
                    List<DocumentSnapshot<Map<String, dynamic>>>>(
                  future: _leaderboardFuture,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (!snap.hasData || snap.data!.isEmpty) {
                      return Center(
                        child: Text(
                          "No users yet",
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.6),
                            fontSize: 14,
                          ),
                        ),
                      );
                    }

                    final docs = snap.data!;
                    final userId = FirebaseAuth.instance.currentUser!.uid;

                    return Stack(
                      children: [
                        // ---------------------- LIST ----------------------
                        ListView.separated(
                          itemCount: docs.length,
                          separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            final data = doc.data()!;
                            final String name =
                            (data['fullName'] ?? '—') as String;

                            final rawTrophies = data['trophies'];
                            final int trophies = rawTrophies is int
                                ? rawTrophies
                                : int.tryParse('$rawTrophies') ?? 0;

                            final String? photoUrl =
                            data['photoUrl'] as String?;

                            final bool isMe = doc.id == userId;

                            if (isMe) {
                              return VisibilityDetector(
                                key: Key("user-tile-$userId"),
                                onVisibilityChanged: (info) {
                                  final visible = info.visibleFraction > 0.45;
                                  if (_userTileVisible != visible) {
                                    setState(
                                            () => _userTileVisible = visible);
                                  }
                                },
                                child: _LeaderboardTile(
                                  index: index,
                                  name: name,
                                  trophies: trophies,
                                  photoUrl: photoUrl,
                                  isMe: true,
                                ),
                              );
                            }

                            return _LeaderboardTile(
                              index: index,
                              name: name,
                              trophies: trophies,
                              photoUrl: photoUrl,
                              isMe: false,
                            );
                          },
                        ),

                        // ---------------------- FLOATING TILE ----------------------
                        if (!_userTileVisible)
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 4,
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: -50, end: 0),
                              duration:
                              const Duration(milliseconds: 450),
                              curve: Curves.easeOutBack,
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(0, value),
                                  child: child,
                                );
                              },
                              child: _FloatingMyTile(
                                docs: docs,
                                userId: userId,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ------------------------------------------------------------
/// FLOATING USER TILE
/// ------------------------------------------------------------
class _FloatingMyTile extends StatelessWidget {
  final List<DocumentSnapshot<Map<String, dynamic>>> docs;
  final String userId;

  const _FloatingMyTile({
    super.key,
    required this.docs,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final doc = docs.firstWhere((d) => d.id == userId);
    final data = doc.data()!;

    final name = data['fullName'] ?? "—";
    final raw = data['trophies'];
    final trophies = raw is int ? raw : int.tryParse('$raw') ?? 0;
    final photoUrl = data['photoUrl'];

    return _LeaderboardTile(
      index: docs.indexOf(doc),
      name: name,
      trophies: trophies,
      photoUrl: photoUrl,
      isMe: true,
    );
  }
}

/// ------------------------------------------------------------
/// LEADERBOARD TILE
/// ------------------------------------------------------------
class _LeaderboardTile extends StatelessWidget {
  final int index;
  final String name;
  final int trophies;
  final String? photoUrl;
  final bool isMe;

  const _LeaderboardTile({
    super.key,
    required this.index,
    required this.name,
    required this.trophies,
    required this.photoUrl,
    required this.isMe,
  });

  Color _rankColor(int rank) {
    switch (rank) {
      case 0:
        return const Color(0xFFFFD700); // gold
      case 1:
        return const Color(0xFFC0C0C0); // silver
      case 2:
        return const Color(0xFFCD7F32); // bronze
      default:
        return const Color(0xFF2C015D);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rank = index + 1;
    final rankColor = _rankColor(index);

    final tileColor =
    isMe ? const Color(0xFFEDD9FF) : Colors.white;
    final borderColor =
    isMe ? const Color(0xFF9A4DFF) : Colors.transparent;

    return AnimatedScale(
      scale: isMe ? 1.03 : 1.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: isMe ? 2 : 0),
          boxShadow: const [
            BoxShadow(
              color: Color(0x142C015D),
              blurRadius: 14,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // Rank number circle
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: rankColor.withOpacity(0.1),
              ),
              alignment: Alignment.center,
              child: Text(
                "$rank",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: rankColor,
                ),
              ),
            ),

            const SizedBox(width: 10),

            // Profile Image
            CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFF2C015D),
              backgroundImage: (photoUrl != null &&
                  photoUrl!.isNotEmpty)
                  ? NetworkImage(photoUrl!)
                  : null,
              child: (photoUrl == null || photoUrl!.isEmpty)
                  ? Text(
                name.isNotEmpty ? name[0].toUpperCase() : "?",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              )
                  : null,
            ),

            const SizedBox(width: 12),

            // Name + YOU
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2C015D),
                      ),
                    ),
                  ),

                  if (isMe)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9A4DFF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        "YOU",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Trophy Count
            Row(
              children: [
                const Icon(
                  Icons.emoji_events_rounded,
                  size: 20,
                  color: Color(0xFFFFC107),
                ),
                const SizedBox(width: 4),
                Text(
                  "$trophies",
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xFF2C015D),
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
