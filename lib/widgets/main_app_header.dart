import 'package:flutter/material.dart';

class MainAppHeader extends StatelessWidget {
  final VoidCallback? onTapTrophy;
  final VoidCallback onTapProfile;
  final int trophyCount;
  final String? photoUrl;

  const MainAppHeader({
    super.key,
    this.onTapTrophy,
    required this.onTapProfile,
    this.trophyCount = 0,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF2C015D);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16, // ← was 18 (reduced by 2px)
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
            Image.asset(
              'assets/secom_logo.png',
              height: 38,
            ),

            const Spacer(),

            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _AdaptiveTrophyPill(
                    count: trophyCount,
                    onTap: onTapTrophy,
                  ),

                  const SizedBox(width: 10),

                  GestureDetector(
                    onTap: onTapProfile,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: purple,
                      backgroundImage: (photoUrl != null &&
                          photoUrl!.isNotEmpty)
                          ? NetworkImage(photoUrl!)
                          : null,
                      child: (photoUrl == null || photoUrl!.isEmpty)
                          ? const Icon(Icons.person,
                          color: Colors.white, size: 18)
                          : null,
                    ),
                  ),
                ],
              ),
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
        horizontal: 10, // ← was 12 (reduced by 2px)
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E0),
        borderRadius: BorderRadius.circular(20),
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
          Icon(Icons.emoji_events, size: 16, color: Colors.amber[700]),
          const SizedBox(width: 5),

          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _shorten(count),
                maxLines: 1,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2C015D),
                  fontSize: 14,
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
      borderRadius: BorderRadius.circular(20),
      child: pill,
    );
  }
}
