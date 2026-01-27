// lib/widgets/quiz_runner/widgets/comparison_value_card.dart
import 'package:flutter/material.dart';

/// Renders comparison values (left/right) with stacked fractions and nested fractions.
/// Supports:
/// - Simple fractions: 3/5, -3/5, x/5, -x/7
/// - Nested: a/(b/c)
/// - Multiple fractions inside an expression via RichText + WidgetSpan
class ComparisonSideCard extends StatelessWidget {
  final String value;
  final ColorScheme cs;

  const ComparisonSideCard({
    super.key,
    required this.value,
    required this.cs,
  });

  // a/(b/c)
  static final _nestedFractionRegex = RegExp(
    r'(-?[a-zA-Z]|\-?\d+)\s*/\s*\(\s*(-?[a-zA-Z]|\-?\d+)\s*/\s*(-?[a-zA-Z]|\-?\d+)\s*\)',
  );

  // a/b, x/7, -3/5 (also inside expression)
  static final _simpleFractionRegex = RegExp(
    r'(-?[a-zA-Z]|\-?\d+)\s*/\s*(-?[a-zA-Z]|\-?\d+)',
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: cs.outlineVariant.withOpacity(0.55),
          width: 1.3,
        ),
      ),
      child: Center(
        child: _buildInlineExpression(value),
      ),
    );
  }

  Widget _buildInlineExpression(String text) {
    final t = text.trim();
    if (t.isEmpty) {
      return Text(
        '—',
        style: _textStyle(),
        textAlign: TextAlign.center,
      );
    }

    // 1) Nested fraction exact match: a/(b/c)
    final nested = _nestedFractionRegex.firstMatch(t);
    if (nested != null && nested.start == 0 && nested.end == t.length) {
      return NestedFraction(
        outerNum: nested.group(1)!,
        innerNum: nested.group(2)!,
        innerDen: nested.group(3)!,
        cs: cs,
      );
    }

    // 2) Inline expression with multiple simple fractions
    final spans = <InlineSpan>[];
    int lastIndex = 0;

    for (final match in _simpleFractionRegex.allMatches(t)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: t.substring(lastIndex, match.start),
          style: _textStyle(),
        ));
      }

      final frac = match.group(0)!;
      final parts = frac.split('/');
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: InlineFraction(
              numerator: parts[0].trim(),
              denominator: parts[1].trim(),
              cs: cs,
            ),
          ),
        ),
      );

      lastIndex = match.end;
    }

    if (lastIndex < t.length) {
      spans.add(TextSpan(
        text: t.substring(lastIndex),
        style: _textStyle(),
      ));
    }

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(children: spans),
    );
  }

  TextStyle _textStyle() {
    return TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w900,
      color: cs.onSurface,
      height: 1.2,
    );
  }
}

class FractionView extends StatelessWidget {
  final String numerator;
  final String denominator;
  final ColorScheme cs;

  const FractionView({
    super.key,
    required this.numerator,
    required this.denominator,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          numerator,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            height: 1.0,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 40,
          height: 2,
          decoration: BoxDecoration(
            color: cs.onSurface.withOpacity(0.75),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          denominator,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            height: 1.0,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }
}

class InlineFraction extends StatelessWidget {
  final String numerator;
  final String denominator;
  final ColorScheme cs;

  const InlineFraction({
    super.key,
    required this.numerator,
    required this.denominator,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          numerator,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            height: 1.0,
            color: cs.onSurface,
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          height: 1.6,
          width: 26,
          color: cs.onSurface.withOpacity(0.75),
        ),
        Text(
          denominator,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            height: 1.0,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }
}

class NestedFraction extends StatelessWidget {
  final String outerNum;
  final String innerNum;
  final String innerDen;
  final ColorScheme cs;

  const NestedFraction({
    super.key,
    required this.outerNum,
    required this.innerNum,
    required this.innerDen,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          outerNum,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: cs.onSurface,
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          height: 2,
          width: 40,
          color: cs.onSurface.withOpacity(0.75),
        ),
        InlineFraction(
          numerator: innerNum,
          denominator: innerDen,
          cs: cs,
        ),
      ],
    );
  }
}
