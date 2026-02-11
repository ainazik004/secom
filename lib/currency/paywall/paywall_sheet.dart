import 'package:flutter/material.dart';

class PaywallSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onSubscribe;
  final VoidCallback onDonate;

  const PaywallSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onSubscribe,
    required this.onDonate,
  });

  static Future<void> show(
      BuildContext context, {
        required String title,
        required String subtitle,
        required VoidCallback onSubscribe,
        required VoidCallback onDonate,
      }) {
    return showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => PaywallSheet(
        title: title,
        subtitle: subtitle,
        onSubscribe: onSubscribe,
        onDonate: onDonate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(subtitle, style: textTheme.bodyMedium),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onSubscribe,
              child: const Text('Subscribe'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: onDonate,
              child: const Text('Donate'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
