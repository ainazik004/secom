import 'package:flutter/material.dart';

class MathematicsPage extends StatelessWidget {
  const MathematicsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Математика'),
        backgroundColor: const Color(0xFF2C015D),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Содержимое раздела Математика'),
      ),
    );
  }
}
