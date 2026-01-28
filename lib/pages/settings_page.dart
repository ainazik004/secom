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

  Future<void> _showThemeDialog(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
    final themeProvider = context.read<ThemeProvider>();
    final cs = Theme.of(context).colorScheme;

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cs.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        title: _DialogHeader(
          title: loc.theme,
          subtitle: loc.chooseTheme, // ✅ add this key in l10n OR replace with loc.theme
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _FullWidthOptionTile(
              title: loc.themeSystem,
              icon: Icons.brightness_auto_rounded,
              selected: themeProvider.mode == ThemeMode.system,
              onTap: () {
                themeProvider.setMode(ThemeMode.system);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 10),
            _FullWidthOptionTile(
              title: loc.themeLight,
              icon: Icons.light_mode_rounded,
              selected: themeProvider.mode == ThemeMode.light,
              onTap: () {
                themeProvider.setMode(ThemeMode.light);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 10),
            _FullWidthOptionTile(
              title: loc.themeDark,
              icon: Icons.dark_mode_rounded,
              selected: themeProvider.mode == ThemeMode.dark,
              onTap: () {
                themeProvider.setMode(ThemeMode.dark);
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.cancel),
          ),
        ],
      ),
    );
  }

  Future<void> _showLanguageDialog(BuildContext context) async {
    final localeProvider = context.read<LocaleProvider>();
    final currentLocale = localeProvider.locale;
    final loc = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    final availableLocales = L10n.all.where((l) => l.languageCode != 'en').toList();

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cs.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        title: _DialogHeader(
          title: loc.language,
          subtitle: loc.chooseLanguage,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: availableLocales.map((locale) {
            final code = locale.languageCode;
            final languageName = L10n.getLanguageName(code);
            final isSelected = locale == currentLocale;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _FullWidthOptionTile(
                title: languageName,
                iconWidget: Text(
                  _flagForLanguage(code),
                  style: const TextStyle(fontSize: 22),
                ),
                selected: isSelected,
                onTap: () {
                  localeProvider.setLocale(locale);
                  Navigator.pop(context);
                },
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.cancel),
          ),
        ],
      ),
    );
  }

  Future<void> _showLogoutConfirm(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cs.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
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
  }

  @override
  Widget build(BuildContext context) {
    if (embedded) {
      return SafeArea(child: _buildBody(context));
    }

    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.background,
      body: SafeArea(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final currentLocale = localeProvider.locale;
    final loc = AppLocalizations.of(context)!;

    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        const SizedBox(height: 12),

        _SettingCard(
          onTap: () => _showLanguageDialog(context),
          icon: Icons.language,
          iconBackground: cs.primaryContainer,
          iconColor: cs.onPrimaryContainer,
          title: loc.language,
          subtitle:
          '${_flagForLanguage(currentLocale.languageCode)} ${L10n.getLanguageName(currentLocale.languageCode)}',
        ),

        _SettingCard(
          onTap: () => _showThemeDialog(context),
          icon: themeProvider.mode == ThemeMode.dark
              ? Icons.dark_mode_rounded
              : themeProvider.mode == ThemeMode.light
              ? Icons.light_mode_rounded
              : Icons.brightness_auto_rounded,
          iconBackground: cs.secondaryContainer,
          iconColor: cs.onSecondaryContainer,
          title: loc.theme,
          subtitle: loc.themeCurrentValue(_themeLabel(loc, themeProvider.mode)),
        ),

        _SettingCard(
          onTap: () => _showLogoutConfirm(context),
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

    final cardColor = cs.surfaceContainerHigh;
    final onCard = cs.onSurface;
    final sub = cs.onSurfaceVariant;
    final chevron = cs.outlineVariant;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(26),
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
                ),
                child: Icon(icon, color: iconColor ?? cs.onPrimaryContainer),
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
                        fontWeight: FontWeight.w700,
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
              Icon(Icons.chevron_right_rounded, color: chevron),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _DialogHeader({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

/// ✅ Full-width option tile used in BOTH dialogs (language + theme)
class _FullWidthOptionTile extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget? iconWidget;
  final bool selected;
  final VoidCallback onTap;

  const _FullWidthOptionTile({
    required this.title,
    this.icon,
    this.iconWidget,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final bg = selected
        ? Color.alphaBlend(cs.primary.withOpacity(0.12), cs.surfaceContainerHighest)
        : cs.surfaceContainerHighest;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              if (iconWidget != null) ...[
                iconWidget!,
                const SizedBox(width: 12),
              ] else if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: cs.onPrimaryContainer),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 15.5,
                  ),
                ),
              ),
              if (selected) Icon(Icons.check_circle_rounded, color: cs.primary),
            ],
          ),
        ),
      ),
    );
  }
}
