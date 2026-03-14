import 'dart:convert';

import 'models.dart';

enum OutputFormat {
  table,
  json,
  csv,
  markdown;

  static OutputFormat parse(String value) {
    return switch (value.toLowerCase().trim()) {
      'table' => OutputFormat.table,
      'json' => OutputFormat.json,
      'csv' => OutputFormat.csv,
      'markdown' || 'md' => OutputFormat.markdown,
      _ => throw ArgumentError('Unsupported format: $value'),
    };
  }
}

class MatchOutputFormatter {
  const MatchOutputFormatter();

  String format(
    List<MatchResult> results,
    OutputFormat format, {
    bool useColor = true,
    MatchSummary? summary,
  }) {
    final effectiveSummary =
        summary ??
        MatchSummary.fromResults(
          results: results,
          comparedPeople: results.length,
        );

    return switch (format) {
      OutputFormat.table => _toTable(
        results,
        summary: effectiveSummary,
        useColor: useColor,
      ),
      OutputFormat.json => _toJson(results, summary: effectiveSummary),
      OutputFormat.csv => _toCsv(results, summary: effectiveSummary),
      OutputFormat.markdown => _toMarkdown(results, summary: effectiveSummary),
    };
  }

  String _toJson(List<MatchResult> results, {required MatchSummary summary}) {
    return const JsonEncoder.withIndent('  ').convert({
      'matches': results.map((item) => item.toJson()).toList(),
      'summary': summary.toJson(),
    });
  }

  String _toCsv(List<MatchResult> results, {required MatchSummary summary}) {
    final rows = <String>[
      'confidence,left_id,left_name,right_id,right_name,left_birth,right_birth,left_spouse,right_spouse',
    ];

    for (final result in results) {
      rows.add(
        [
          result.confidence.toStringAsFixed(2),
          result.left.id,
          _escape(result.left.fullName),
          result.right.id,
          _escape(result.right.fullName),
          _escape(result.left.birthDate ?? ''),
          _escape(result.right.birthDate ?? ''),
          _escape(result.left.spouseName ?? ''),
          _escape(result.right.spouseName ?? ''),
        ].join(','),
      );
    }

    rows.add('');
    rows.add('summary_key,summary_value');
    rows.add('compared_people,${summary.comparedPeople}');
    rows.add(
      'average_confidence,${summary.averageConfidence.toStringAsFixed(2)}',
    );
    rows.add('confidence_100_count,${summary.fullConfidenceCount}');

    return rows.join('\n');
  }

  String _toMarkdown(
    List<MatchResult> results, {
    required MatchSummary summary,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('| Confidence | Person A | Person B | Birth A | Birth B |');
    buffer.writeln('|---:|---|---|---|---|');
    for (final result in results) {
      buffer.writeln(
        '| ${result.confidence.toStringAsFixed(2)} | ${_pipeSafe(result.left.fullName)} | ${_pipeSafe(result.right.fullName)} | ${_pipeSafe(result.left.birthDate ?? '')} | ${_pipeSafe(result.right.birthDate ?? '')} |',
      );
    }

    buffer.writeln();
    buffer.writeln('## Summary');
    buffer.writeln('- Compared people: ${summary.comparedPeople}');
    buffer.writeln(
      '- Average confidence: ${summary.averageConfidence.toStringAsFixed(2)}%',
    );
    buffer.writeln('- People at 100%: ${summary.fullConfidenceCount}');

    return buffer.toString().trimRight();
  }

  String _toTable(
    List<MatchResult> results, {
    required MatchSummary summary,
    required bool useColor,
  }) {
    final title = useColor
        ? '\x1B[36mGEDCOM Matcher - Matches\x1B[0m'
        : 'GEDCOM Matcher - Matches';
    final header =
        '+-----------+--------------------------+--------------------------+--------------+\n'
        '| Confidence| Person A                 | Person B                 | Birth        |\n'
        '+-----------+--------------------------+--------------------------+--------------+';
    final rows = results
        .map((result) {
          final confidence = result.confidence.toStringAsFixed(2).padLeft(9);
          final left = _truncate(result.left.fullName, 24).padRight(24);
          final right = _truncate(result.right.fullName, 24).padRight(24);
          final birth = _truncate(
            result.left.birthDate ?? '-',
            12,
          ).padRight(12);
          return '| $confidence | $left | $right | $birth |';
        })
        .join('\n');

    final footer =
        '+-----------+--------------------------+--------------------------+--------------+';
    final summaryBlock =
        'Summary:\n'
        '- Compared people: ${summary.comparedPeople}\n'
        '- Average confidence: ${summary.averageConfidence.toStringAsFixed(2)}%\n'
        '- People at 100%: ${summary.fullConfidenceCount}';

    if (results.isEmpty) {
      return '$title\nNo matches found.\n$summaryBlock';
    }
    return '$title\n$header\n$rows\n$footer\n$summaryBlock';
  }

  String _escape(String value) {
    final quote = String.fromCharCode(34);
    final escaped = value.replaceAll(quote, '$quote$quote');
    if (escaped.contains(',') ||
        escaped.contains(quote) ||
        escaped.contains('\n')) {
      return '$quote$escaped$quote';
    }
    return escaped;
  }

  String _pipeSafe(String value) => value.replaceAll('|', '\\|');

  String _truncate(String value, int width) {
    final text = value.trim();
    if (text.length <= width) {
      return text;
    }
    if (width <= 3) {
      return text.substring(0, width);
    }
    return '${text.substring(0, width - 3)}...';
  }
}

class MatchSummary {
  const MatchSummary({
    required this.comparedPeople,
    required this.averageConfidence,
    required this.fullConfidenceCount,
  });

  final int comparedPeople;
  final double averageConfidence;
  final int fullConfidenceCount;

  static MatchSummary fromResults({
    required List<MatchResult> results,
    required int comparedPeople,
  }) {
    if (results.isEmpty) {
      return MatchSummary(
        comparedPeople: comparedPeople,
        averageConfidence: 0,
        fullConfidenceCount: 0,
      );
    }

    final totalConfidence = results
        .map((result) => result.confidence)
        .reduce((a, b) => a + b);
    final averageConfidence = totalConfidence / results.length;
    final fullConfidenceCount = results
        .where((result) => result.confidence >= 100)
        .length;

    return MatchSummary(
      comparedPeople: comparedPeople,
      averageConfidence: averageConfidence,
      fullConfidenceCount: fullConfidenceCount,
    );
  }

  Map<String, Object> toJson() => {
    'compared_people': comparedPeople,
    'average_confidence': double.parse(averageConfidence.toStringAsFixed(2)),
    'confidence_100_count': fullConfidenceCount,
  };
}
