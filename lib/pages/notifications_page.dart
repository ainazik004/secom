import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zhalbyrak/gen_l10n/app_localizations.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  Future<List<Map<String, dynamic>>> _loadNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .get();

    return snap.docs.map((d) => d.data()).toList();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    const purple = Color(0xFF2C015D);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4FF),
      body: SafeArea(
        child: Column(
          children: [
            // ---------------- TOP CLOSE BUTTON ----------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1A2C015D),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF2C015D),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ---------------- PAGE TITLE ----------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                loc.notifications,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: purple,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ---------------- NOTIFICATIONS LIST ----------------
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _loadNotifications(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final notifications = snap.data ?? [];

                  if (notifications.isEmpty) {
                    return Center(
                      child: Text(
                        loc.noNotifications,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: notifications.length,
                    itemBuilder: (context, i) {
                      final n = notifications[i];
                      final title = n['title'] ?? "Notification";
                      final message = n['message'] ?? "";
                      final ts = n['timestamp']?.toDate();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x142C015D),
                              blurRadius: 16,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: purple,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              message,
                              style: TextStyle(
                                color: Colors.black.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                            if (ts != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                "${ts.day}.${ts.month}.${ts.year}  ${ts.hour}:${ts.minute.toString().padLeft(2, '0')}",
                                style: TextStyle(
                                  color: Colors.black.withOpacity(0.4),
                                  fontSize: 12,
                                ),
                              ),
                            ]
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
