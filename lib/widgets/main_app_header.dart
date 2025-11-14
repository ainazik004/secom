import 'package:flutter/material.dart';

class MainAppHeader extends StatelessWidget {
  final VoidCallback onTapNotifications;
  final VoidCallback? onTapTrophy;
  final VoidCallback onTapProfile;
  final int trophyCount;
  final String? photoUrl;

  const MainAppHeader({
    super.key,
    required this.onTapNotifications,
    this.onTapTrophy,
    required this.onTapProfile,
    this.trophyCount = 0,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF2C015D);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x182C015D),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            // LOGO (unchanged)
            Image.asset(
              'assets/secom_logo.png',
              height: 44,
            ),

            const Spacer(),

            // RIGHT SIDE
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🔔 Notifications (slightly smaller)
                _HeaderIconButton(
                  icon: Icons.notifications_outlined,
                  onTap: onTapNotifications,
                  size: 22,
                ),

                const SizedBox(width: 12),

                // 🏆 Trophy Pill (slightly smaller)
                _TrophyPill(
                  count: trophyCount,
                  onTap: onTapTrophy,
                ),

                const SizedBox(width: 12),

                // 👤 Profile (reduced from 22 → 20)
                GestureDetector(
                  onTap: onTapProfile,
                  child: CircleAvatar(
                    radius: 20, // was 22
                    backgroundColor: purple,
                    backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty)
                        ? NetworkImage(photoUrl!)
                        : null,
                    child: (photoUrl == null || photoUrl!.isEmpty)
                        ? const Icon(Icons.person, color: Colors.white, size: 20)
                        : null,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    this.size = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF4ECFF),
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: const Color(0x332C015D),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10), // reduced from 12
          child: Icon(
            icon,
            size: size, // reduced from 26 → 22
            color: const Color(0xFF2C015D),
          ),
        ),
      ),
    );
  }
}

class _TrophyPill extends StatelessWidget {
  final int count;
  final VoidCallback? onTap;

  const _TrophyPill({
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), // smaller
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E0),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events, size: 18, color: Colors.amber[700]), // smaller
          const SizedBox(width: 6),
          Text(
            _shorten(count),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF2C015D),
              fontSize: 15, // smaller
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
