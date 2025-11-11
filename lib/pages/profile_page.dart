import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        backgroundColor: const Color(0xFF2C015D),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Это страница профиля'),
      ),
    );
  }
}