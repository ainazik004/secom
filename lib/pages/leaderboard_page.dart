import 'package:flutter/material.dart';
import 'package:secom/gen_l10n/app_localizations.dart';

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final purple = const Color(0xFF2C015D);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.leaderboard),
        backgroundColor: purple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),

          // Section Title (localized)
          Text(
            loc.leaderboard,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: ListView.builder(
              itemCount: 10, // placeholder data
              itemBuilder: (context, index) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: purple,
                    child: Text(
                      "${index + 1}",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text("User ${index + 1}"),
                  subtitle: Text("Score: ${(10 - index) * 100}"),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
