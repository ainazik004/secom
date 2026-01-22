import 'package:flutter/material.dart';

PreferredSizeWidget customAppBar(BuildContext context, String title) {
  final cs = Theme.of(context).colorScheme;
  final tt = Theme.of(context).textTheme;

  return AppBar(
    centerTitle: true,

    backgroundColor: cs.primary,
    foregroundColor: cs.onPrimary,
    elevation: 0,

    title: Text(
      title,
      style: tt.titleMedium?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: cs.onPrimary,
      ),
    ),

    leading: IconButton(
      icon: Icon(Icons.arrow_back, color: cs.onPrimary),
      onPressed: () => Navigator.pop(context),
    ),
  );
}
