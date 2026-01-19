import 'package:flutter/material.dart';

class ErrorStateView extends StatelessWidget {
  final String title;
  final String errorText;
  final String retryText;
  final VoidCallback onRetry;

  const ErrorStateView({
    super.key,
    required this.title,
    required this.errorText,
    required this.retryText,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 42),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(errorText, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            ElevatedButton(onPressed: onRetry, child: Text(retryText)),
          ],
        ),
      ),
    );
  }
}
