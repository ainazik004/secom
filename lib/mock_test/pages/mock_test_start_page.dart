import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../mock_attempt_store.dart';
import '../mock_test_controller.dart';
import 'mock_test_runner_page.dart';

class MockTestStartPage extends StatefulWidget {
  final String lang; // from settings/provider
  const MockTestStartPage({super.key, required this.lang});

  @override
  State<MockTestStartPage> createState() => _MockTestStartPageState();
}

class _MockTestStartPageState extends State<MockTestStartPage> {
  late final MockTestController controller;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    controller = MockTestController(
      db: FirebaseFirestore.instance,
      store: MockAttemptStore(),
    );

    () async {
      await controller.restore();
      if (!mounted) return;
      setState(() => loading = false);
    }();
  }

  Future<void> _startAndOpenRunner({required bool startNew}) async {
    try {
      if (startNew) {
        await controller.startNew(lang: widget.lang);
      } else {
        // Continue: ensure section started if needed
        await controller.startCurrentSectionIfNeeded();
      }

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MockTestRunnerPage(controller: controller),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Setup required'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final attempt = controller.attempt;

    return Scaffold(
      appBar: AppBar(title: const Text('ORT Mock Test')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Sections: math → analogy → sentence completion → reading → grammar'),
            const SizedBox(height: 16),

            if (attempt != null && !attempt.isFinished) ...[
              ElevatedButton(
                onPressed: () => _startAndOpenRunner(startNew: false),
                child: const Text('Continue current mock'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () async {
                  await controller.clearAttempt();
                  if (!mounted) return;
                  setState(() {});
                },
                child: const Text('Discard current mock'),
              ),
            ] else ...[
              ElevatedButton(
                onPressed: () => _startAndOpenRunner(startNew: true),
                child: const Text('Start new mock'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
