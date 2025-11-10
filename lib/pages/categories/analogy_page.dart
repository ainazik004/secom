import 'package:flutter/material.dart';

class AnalogyPage extends StatelessWidget {
  const AnalogyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Аналогия и дополнение'),
        backgroundColor: const Color(0xFF2C015D),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Содержимое раздела Аналогия и дополнение'),
      ),
    );
  }
}
