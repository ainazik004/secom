import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:zhalbyrak/provider/provider.dart';
import 'package:zhalbyrak/l10n/l10n.dart';
import 'package:zhalbyrak/gen_l10n/app_localizations.dart';
import 'package:zhalbyrak/pages/login_page.dart';

class SettingsPage extends StatelessWidget {
  final bool embedded;

  const SettingsPage({super.key, this.embedded = false});

  Future<void> _logout(BuildContext context) async {
    final navigator = Navigator.of(context);
    final loc = AppLocalizations.of(context)!;

    try {
      await FirebaseAuth.instance.signOut();
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${loc.logoutFailed}: ${e.toString()}')),
      );
    }
  }

  // Emoji flags for supported languages (RU, KY).
  // You can extend this map later if you add more languages.
  String _flagForLanguage(String languageCode) {
    switch (languageCode) {
      case 'ru':
        return '🇷🇺';
      case 'ky':
        return '🇰🇬';
      default:
        return '🏳️';
    }
  }

  @override
  Widget build(BuildContext context) {
    // If embedded inside MainPage → return body only
    if (embedded) {
      return SafeArea(child: _buildBody(context));
    }

    // Stand-alone version → NO header
    return Scaffold(
      backgroundColor: const Color(0xFFF6F4FF),
      body: SafeArea(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    final provider = Provider.of<LocaleProvider>(context);
    final currentLocale = provider.locale;
    final loc = AppLocalizations.of(context)!;

    // Only show RU + KY in settings
    final availableLocales =
    L10n.all.where((l) => l.languageCode != 'en').toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        const SizedBox(height: 12),

        // ---------- Language ----------
        _SettingCard(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(loc.language),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: availableLocales.map((locale) {
                    final code = locale.languageCode;
                    final languageName = L10n.getLanguageName(code);
                    final isSelected = locale == currentLocale;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Text(
                        _flagForLanguage(code),
                        style: const TextStyle(fontSize: 22),
                      ),
                      title: Text(languageName),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: Color(0xFFFF3D7F))
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
          icon: Icons.language,
          iconBackground: const Color(0xFFF4ECFF),
          title: loc.language,
          subtitle: loc.chooseLanguage,
        ),

        // ---------- Logout ----------
        _SettingCard(
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text(loc.confirmation),
                content: Text(loc.logoutQuestion),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(loc.cancel),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      await _logout(context);
                    },
                    child: Text(loc.logout),
                  ),
                ],
              ),
            );
          },
          icon: Icons.logout,
          iconBackground: const Color(0xFFFFEBEE),
          iconColor: Colors.redAccent,
          title: loc.logout,
          titleColor: Colors.redAccent,
        ),

        const SizedBox(height: 30),
      ],
    );
  }
}

class _SettingCard extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final Color iconBackground;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final Color? titleColor;

  const _SettingCard({
    required this.onTap,
    required this.icon,
    required this.iconBackground,
    this.iconColor,
    required this.title,
    this.subtitle,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x112C015D),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? const Color(0xFF2C015D),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: titleColor ?? const Color(0xFF2C015D),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: Colors.black.withOpacity(0.55),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFB39DDB),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
