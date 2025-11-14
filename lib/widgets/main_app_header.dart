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
              Image.asset(
                'assets/secom_logo.png',
                height: 40,
              ),
              const Spacer(),
              _HeaderIconButton(
                icon: Icons.notifications_outlined,
                onTap: onTapNotifications,
              ),
              const SizedBox(width: 12),
              _TrophyPill(
                count: trophyCount,
                onTap: onTapTrophy,
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onTapProfile,
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: purple,
                  backgroundImage:
                  photoUrl != null && photoUrl!.isNotEmpty ? NetworkImage(photoUrl!) : null,
                  child: photoUrl == null || photoUrl!.isEmpty
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),
              ),
            ],
          ),
        ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF4ECFF),
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: const Color(0x332C015D),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            icon,
            size: 20,
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

  @override
  Widget build(BuildContext context) {
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            Icons.emoji_events,
            size: 18,
            color: Colors.amber[700],
          ),
          const SizedBox(width: 6),
          Text(
            count.toString(),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C015D),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return pill;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: pill,
    );
  }
}