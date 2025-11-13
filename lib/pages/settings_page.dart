import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:secom/provider/provider.dart';
import 'package:secom/l10n/l10n.dart';
import 'package:secom/gen_l10n/app_localizations.dart';
import 'package:secom/pages/login_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _logout(BuildContext context) async {
    final navigator = Navigator.of(context);
    try {
      await FirebaseAuth.instance.signOut();
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LocaleProvider>(context);
    final currentLocale = provider.locale;
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.settings),
        backgroundColor: const Color(0xFF2C015D),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          // 🌍 Language Settings
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(loc.language),
            subtitle: Text(loc.chooseLanguage),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) =>
                    AlertDialog(
                      title: Text(loc.language),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: L10n.all.map((locale) {
                          final languageName = L10n.getLanguageName(
                              locale.languageCode);
                          final isSelected = locale == currentLocale;

                          return ListTile(
                            title: Text(languageName),
                            trailing: isSelected
                                ? const Icon(Icons.check, color: Colors.pink)
                                : null,
                            onTap: () {
                              provider.setLocale(locale);
                              Navigator.pop(context);
                            },
                          );
                        }).toList(),
                      ),
                    ),
              );
            },
          ),

          const Divider(),

          // 🚪 Logout Button
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: Text(
              'Выйти из аккаунта',
              style: const TextStyle(
                  color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
            onTap: () {
              showDialog(
                context: context,
                builder: (_) =>
                    AlertDialog(
                      title: const Text('Подтверждение'),
                      content: const Text(
                          'Вы действительно хотите выйти из аккаунта?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Отмена'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                          ),
                          onPressed: () async {
                            Navigator.pop(context); // close dialog
                            await _logout(context);
                          },
                          child: const Text('Выйти'),
                        ),
                      ],
                    ),
              );
            },
          ),
        ],
      ),
    );
  }
}
