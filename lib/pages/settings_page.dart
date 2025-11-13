import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:secom/provider/provider.dart';
import 'package:secom/l10n/l10n.dart';
import 'package:secom/gen_l10n/app_localizations.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

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
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(loc.language),
            subtitle: Text(loc.chooseLanguage),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(loc.settings),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: L10n.all.map((locale) {
                      final languageName = L10n.getLanguageName(locale.languageCode);
                      final isSelected = locale == currentLocale;

                      return ListTile(
                        title: Text(languageName),
                        trailing: isSelected ? const Icon(Icons.check, color: Colors.pink) : null,
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
        ],
      ),
    );
  }
}
