import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:zhalbyrak/provider/provider.dart'; // LocaleProvider
import 'package:zhalbyrak/provider/theme_provider.dart'; // ThemeProvider
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

  String _themeLabel(AppLocalizations loc, ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return loc.themeSystem;
      case ThemeMode.light:
        return loc.themeLight;
      case ThemeMode.dark:
        return loc.themeDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (embedded) {
      // embedded pages inherit parent scaffold background
      return SafeArea(child: _buildBody(context));
    }

    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      // ✅ background must be cs.background (not cs.surface)
      backgroundColor: cs.background,
      body: SafeArea(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final currentLocale = localeProvider.locale;
    final loc = AppLocalizations.of(context)!;

    final isDarkNow = themeProvider.mode == ThemeMode.system
        ? (MediaQuery.of(context).platformBrightness == Brightness.dark)
        : (themeProvider.mode == ThemeMode.dark);

    final cs = Theme.of(context).colorScheme;

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
                // ✅ dialog surfaces should be surfaceContainerHigh on top of scrim
                backgroundColor: cs.surfaceContainerHigh,
                surfaceTintColor: Colors.transparent,
                titleTextStyle: TextStyle(
                  color: cs.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
                contentTextStyle: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 14,
                ),
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
                      title: Text(
                        languageName,
                        style: TextStyle(color: cs.onSurface),
                      ),
                      trailing:
                      isSelected ? Icon(Icons.check, color: cs.primary) : null,
                      onTap: () {
                        localeProvider.setLocale(locale);
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
              ),
            );
          },
          icon: Icons.language,
          iconBackground: cs.primaryContainer,
          iconColor: cs.onPrimaryContainer,
          title: loc.language,
          subtitle: loc.chooseLanguage,
        ),

        // ---------- Theme ----------
        _SettingCard(
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                backgroundColor: cs.surfaceContainerHigh,
                surfaceTintColor: Colors.transparent,
                titleTextStyle: TextStyle(
                  color: cs.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RadioListTile<ThemeMode>(
                      contentPadding: EdgeInsets.zero,
                      title: Text(loc.themeSystem, style: TextStyle(color: cs.onSurface)),
                      value: ThemeMode.system,
                      groupValue: themeProvider.mode,
                      onChanged: (v) {
                        if (v == null) return;
                        context.read<ThemeProvider>().setMode(v);
                        Navigator.pop(context);
                      },
                    ),
                    RadioListTile<ThemeMode>(
                      contentPadding: EdgeInsets.zero,
                      title: Text(loc.themeLight, style: TextStyle(color: cs.onSurface)),
                      value: ThemeMode.light,
                      groupValue: themeProvider.mode,
                      onChanged: (v) {
                        if (v == null) return;
                        context.read<ThemeProvider>().setMode(v);
                        Navigator.pop(context);
                      },
                    ),
                    RadioListTile<ThemeMode>(
                      contentPadding: EdgeInsets.zero,
                      title: Text(loc.themeDark, style: TextStyle(color: cs.onSurface)),
                      value: ThemeMode.dark,
                      groupValue: themeProvider.mode,
                      onChanged: (v) {
                        if (v == null) return;
                        context.read<ThemeProvider>().setMode(v);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
          icon: isDarkNow ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
          iconBackground: cs.secondaryContainer,
          iconColor: cs.onSecondaryContainer,
          title: loc.theme,
          subtitle: loc.themeCurrentValue(_themeLabel(loc, themeProvider.mode)),
        ),

        // ---------- Logout ----------
        _SettingCard(
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                backgroundColor: cs.surfaceContainerHigh,
                surfaceTintColor: Colors.transparent,
                titleTextStyle: TextStyle(
                  color: cs.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
                contentTextStyle: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 14,
                ),
                title: Text(loc.confirmation),
                content: Text(loc.logoutQuestion),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(loc.cancel),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.error,
                      foregroundColor: cs.onError,
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
          iconBackground: cs.errorContainer,
          iconColor: cs.error,
          title: loc.logout,
          titleColor: cs.error,
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
    final cs = Theme.of(context).colorScheme;

    // hierarchy:
    // page background = cs.background
    // card = cs.surfaceContainerHigh
    final cardColor = cs.surfaceContainerHigh;
    final onCard = cs.onSurface;
    final sub = cs.onSurfaceVariant;
    final chevron = cs.outlineVariant;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(26),
        // ❌ removed outline
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
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
                  // ❌ removed icon outline
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? cs.onPrimaryContainer,
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
                        color: titleColor ?? onCard,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: sub.withOpacity(0.85),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: chevron,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
