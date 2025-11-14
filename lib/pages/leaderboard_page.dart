import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
              // Section title (header bar is provided by MainPage)
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
                // if you add a dedicated key later, replace this
                // with loc.leaderboardSubtitle
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

                    if (docs.isEmpty) {
                      return Center(
                        child: Text(
                          // if you add key later, use loc.noUsersYet
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

                        // trophies can be null / string / int → normalize safely
                        final dynamic rawTrophies = data['trophies'];
                        final int trophies = rawTrophies is int
                            ? rawTrophies
                            : int.tryParse('${rawTrophies ?? 0}') ?? 0;

                        final String? photoUrl =
                        data['photoUrl'] is String ? data['photoUrl'] : null;

                        return _LeaderboardTile(
                          index: index,
                          name: name,
                          trophies: trophies,
                          photoUrl: photoUrl,
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

  const _LeaderboardTile({
    required this.index,
    required this.name,
    required this.trophies,
    required this.photoUrl,
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
          // Rank badge
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

          // Avatar + name
          CircleAvatar(
            radius: 20,
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

          // Name
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C015D),
              ),
            ),
          ),

          // Trophies
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
    );
  }
}
