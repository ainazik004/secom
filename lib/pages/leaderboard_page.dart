import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:secom/gen_l10n/app_localizations.dart';

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> _usersStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .orderBy('trophies', descending: true)
        .limit(100)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    const purple = Color(0xFF2C015D);

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
                  color: purple,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Top learners ranked by trophies',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black.withOpacity(0.55),
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _usersStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    final docs = snapshot.data?.docs ?? [];
                    final currentUser = FirebaseAuth.instance.currentUser;

                    if (docs.isEmpty) {
                      return Center(
                        child: Text(
                          'No users yet',
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.6),
                            fontSize: 14,
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data();

                        final String name =
                            (data['fullName'] ?? '—') as String? ?? '—';

                        final dynamic rawTrophies = data['trophies'];
                        final int trophies = rawTrophies is int
                            ? rawTrophies
                            : int.tryParse('${rawTrophies ?? 0}') ?? 0;

                        final String? photoUrl =
                        data['photoUrl'] is String ? data['photoUrl'] : null;

                        final bool isMe = currentUser?.uid == doc.id;

                        return _LeaderboardTile(
                          index: index,
                          name: name,
                          trophies: trophies,
                          photoUrl: photoUrl,
                          isMe: isMe,
                        );
                      },
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

class _LeaderboardTile extends StatelessWidget {
  final int index;
  final String name;
  final int trophies;
  final String? photoUrl;
  final bool isMe;

  const _LeaderboardTile({
    required this.index,
    required this.name,
    required this.trophies,
    required this.photoUrl,
    required this.isMe,
  });

  Color _rankColor(int rank) {
    switch (rank) {
      case 0:
        return const Color(0xFFFFD700);
      case 1:
        return const Color(0xFFC0C0C0);
      case 2:
        return const Color(0xFFCD7F32);
      default:
        return const Color(0xFF2C015D);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rank = index + 1;
    final rankColor = _rankColor(index);

    final tileColor = isMe
        ? const Color(0xFFEDD9FF) // soft purple highlight
        : Colors.white;

    final borderColor = isMe ? const Color(0xFF9A4DFF) : Colors.transparent;

    return AnimatedScale(
      scale: isMe ? 1.03 : 1.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6), // ★ NEW
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
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: rankColor.withOpacity(0.1),
              ),
              alignment: Alignment.center,
              child: Text(
                '$rank',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: rankColor,
                ),
              ),
            ),
            const SizedBox(width: 10),

            CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFF2C015D),
              backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty)
                  ? NetworkImage(photoUrl!)
                  : null,
              child: (photoUrl == null || photoUrl!.isEmpty)
                  ? Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              )
                  : null,
            ),
            const SizedBox(width: 12),

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
                      padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.emoji_events_rounded,
                  size: 20,
                  color: Color(0xFFFFC107),
                ),
                const SizedBox(width: 4),
                Text(
                  trophies.toString(),
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