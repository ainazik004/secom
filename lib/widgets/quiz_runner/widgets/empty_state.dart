import 'package:flutter/material.dart';

class EmptyStateView extends StatelessWidget {
  final String title;
  final String subtitle;
  final String backText;
  final VoidCallback onBack;

  const EmptyStateView({
    super.key,
    required this.title,
    required this.subtitle,
    required this.backText,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined, size: 42),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            ElevatedButton(onPressed: onBack, child: Text(backText)),
          ],
        ),
      ),
    );
  }
}
