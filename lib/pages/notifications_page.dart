import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(context, 'Уведомления'),
      body: const Center(
        child: Text(
          'Пока уведомлений нет',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
