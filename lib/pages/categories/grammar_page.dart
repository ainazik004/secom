import 'package:flutter/material.dart';

class GrammarPage extends StatelessWidget {
  const GrammarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Практическая грамматика русского языка'),
        backgroundColor: const Color(0xFF2C015D),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Содержимое раздела Практическая грамматика'),
      ),
    );
  }
}
