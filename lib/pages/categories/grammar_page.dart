import 'package:flutter/material.dart';
import 'package:secom/gen_l10n/app_localizations.dart';

class GrammarPage extends StatelessWidget {
  const GrammarPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    const purple = Color(0xFF2C015D);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4FF),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TOP BAR
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Row(
                children: [
                  const _CloseButton(),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.grammar,
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                            color: purple,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Practice key grammar skills.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: const [
                  _TopicCard(
                    icon: Icons.spellcheck_rounded,
                    accentColor: Color(0xFF2C015D),
                    title: 'Tenses',
                    subtitle: 'Present, past, future usage',
                  ),
                  _TopicCard(
                    icon: Icons.text_fields_rounded,
                    accentColor: Color(0xFF7F4BFF),
                    title: 'Sentence structure',
                    subtitle: 'Clauses, phrases, word order',
                  ),
                  _TopicCard(
                    icon: Icons.rule_folder_rounded,
                    accentColor: Color(0xFFFF8AB6),
                    title: 'Agreement & articles',
                    subtitle: 'Subject-verb agreement, a/an/the',
                  ),
                  _TopicCard(
                    icon: Icons.checklist_rtl_rounded,
                    accentColor: Color(0xFFFFB74D),
                    title: 'Mixed practice',
                    subtitle: 'Combine all grammar topics',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: const Color(0x22000000),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => Navigator.of(context).pop(),
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(
            Icons.close_rounded,
            size: 20,
            color: Color(0xFF2C015D),
          ),
        ),
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  final IconData icon;
  final Color accentColor;
  final String title;
  final String subtitle;

  const _TopicCard({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x132C015D),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Coming soon'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(milliseconds: 900),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  icon,
                  color: accentColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2C015D),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.3,
                        color: Colors.black.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.withOpacity(0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
