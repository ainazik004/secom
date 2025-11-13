import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';
import 'package:secom/gen_l10n/app_localizations.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: customAppBar(context, loc.notifications),
      body: Center(
        child: Text(
          loc.noNotifications,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
