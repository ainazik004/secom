import 'package:flutter/material.dart';
import 'package:secom/gen_l10n/app_localizations.dart';

class LeaderboardPage extends StatelessWidget {
  final bool embedded;

  const LeaderboardPage({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final body = _buildBody(context);

    if (embedded) {
      return body;
    }

    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4FF),
      appBar: AppBar(
        title: Text(loc.leaderboard),
        backgroundColor: const Color(0xFF2C015D),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(child: body),
    );
  }

  Widget _buildBody(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final purple = const Color(0xFF2C015D);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.leaderboard,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: purple,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.separated(
              itemCount: 10,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final rank = index + 1;
                final score = (10 - index) * 100;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x112C015D),
                        blurRadius: 18,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: purple,
                        child: Text(
                          '$rank',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'User $rank',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Score: $score',
                              style: TextStyle(
                                color: Colors.black.withOpacity(0.6),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: purple.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFFFC857),
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              score.toString(),
                              style: TextStyle(
                                color: purple,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
