import 'package:flutter/material.dart';

class MainAppHeader extends StatelessWidget {
  final VoidCallback onTapNotifications;
  final VoidCallback onTapTrophy;
  final VoidCallback onTapProfile;

  const MainAppHeader({
    super.key,
    required this.onTapNotifications,
    required this.onTapTrophy,
    required this.onTapProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset(
            'assets/secom_logo.png',
            height: 42,
          ),
          Row(
            children: [
              _HeaderIconButton(
                icon: Icons.notifications_outlined,
                onTap: onTapNotifications,
              ),
              const SizedBox(width: 12),
              _HeaderIconButton(
                icon: Icons.emoji_events_outlined,
                onTap: onTapTrophy,
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onTapProfile,
                child: const CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xFF2C015D),
                  child: Icon(
                    Icons.person,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
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
      color: Colors.white,
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
            size: 22,
            color: const Color(0xFF2C015D),
          ),
        ),
      ),
    );
  }
}