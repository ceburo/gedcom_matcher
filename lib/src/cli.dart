import 'dart:io';

import 'package:args/args.dart';

import 'gedcom_parser.dart';
import 'matcher.dart';
import 'models.dart';
import 'output.dart';

const String _usage =
    'Usage: gedcom_matcher [options] <file_a.ged> <file_b.ged>';

/// Runs the command-line interface.
///
/// Returns a process-compatible exit code.
Future<int> runCli(List<String> arguments) async {
  final parser = ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help')
    ..addMultiOption(
      'format',
      abbr: 'f',
      defaultsTo: const ['table'],
      allowed: const ['table', 'json', 'csv', 'markdown'],
      help: 'Output formats (repeatable)',
    )
    ..addOption('output', abbr: 'o', help: 'Export file path')
    ..addOption(
      'min-confidence',
      defaultsTo: '70',
      help: 'Minimum confidence threshold between 0 and 100',
    )
    ..addOption('weight-name', defaultsTo: '45')
    ..addOption('weight-birth-date', defaultsTo: '15')
    ..addOption('weight-birth-place', defaultsTo: '10')
    ..addOption('weight-death-date', defaultsTo: '10')
    ..addOption('weight-sex', defaultsTo: '10')
    ..addOption('weight-spouse', defaultsTo: '10')
    ..addOption(
      'max-candidates',
      defaultsTo: '300',
      help: 'Maximum candidates compared per person (0 = unlimited)',
    )
    ..addFlag('no-color', negatable: false, help: 'Disable ANSI color');

  ArgResults parsed;
  try {
    parsed = parser.parse(arguments);
  } catch (error) {
    stderr.writeln('Error: $error');
    stderr.writeln(_usage);
    return 64;
  }

  if (parsed.flag('help')) {
    stdout.writeln(_usage);
    stdout.writeln(parser.usage);
    return 0;
  }

  if (parsed.rest.length != 2) {
    stderr.writeln('Error: 2 GEDCOM file paths are required.');
    stderr.writeln(_usage);
    return 64;
  }

  final minConfidence = double.tryParse(parsed.option('min-confidence') ?? '');
  if (minConfidence == null || minConfidence < 0 || minConfidence > 100) {
    stderr.writeln('Error: --min-confidence must be between 0 and 100.');
    return 64;
  }

  final leftPath = parsed.rest[0];
  final rightPath = parsed.rest[1];
  final leftFile = File(leftPath);
  final rightFile = File(rightPath);

  if (!leftFile.existsSync() || !rightFile.existsSync()) {
    stderr.writeln('Error: GEDCOM file not found.');
    return 66;
  }

  final weights = MatchWeights(
    name: _intOption(parsed, 'weight-name'),
    birthDate: _intOption(parsed, 'weight-birth-date'),
    birthPlace: _intOption(parsed, 'weight-birth-place'),
    deathDate: _intOption(parsed, 'weight-death-date'),
    sex: _intOption(parsed, 'weight-sex'),
    spouse: _intOption(parsed, 'weight-spouse'),
  );

  final options = MatchOptions(
    minConfidence: minConfidence,
    weights: weights,
    maxCandidatesPerPerson: _intOption(parsed, 'max-candidates'),
  );

  final parserGed = const GedcomParser();
  final leftContent = await leftFile.readAsString();
  final rightContent = await rightFile.readAsString();
  final leftPeople = parserGed.parse(leftContent);
  final rightPeople = parserGed.parse(rightContent);

  final matcher = const GedcomMatcher();
  final hasTerminal = stdout.hasTerminal;
  final results = matcher.match(
    leftPeople: leftPeople,
    rightPeople: rightPeople,
    options: options,
    onProgress: (current, total) {
      if (!hasTerminal || total == 0) {
        return;
      }
      _printProgress(current: current, total: total);
      if (current == total) {
        stdout.writeln();
      }
    },
  );

  final formatter = const MatchOutputFormatter();
  final summary = MatchSummary.fromResults(
    results: results,
    comparedPeople: leftPeople.length,
  );
  final formats = parsed.multiOption('format').map(OutputFormat.parse).toList();
  final useColor = !parsed.flag('no-color') && hasTerminal;

  for (final format in formats) {
    stdout.writeln(
      formatter.format(results, format, useColor: useColor, summary: summary),
    );
  }

  final outputPath = parsed.option('output');
  if (outputPath != null && outputPath.trim().isNotEmpty) {
    final outputFormat = _formatFromPath(outputPath);
    final payload = formatter.format(
      results,
      outputFormat,
      useColor: false,
      summary: summary,
    );
    await File(outputPath).writeAsString(payload);
    stdout.writeln('Export written: $outputPath');
  }

  return 0;
}

void _printProgress({required int current, required int total}) {
  final ratio = total == 0 ? 1.0 : current / total;
  const width = 28;
  final filled = (ratio * width).round();
  final bar = '[${'=' * filled}${'.' * (width - filled)}]';
  final percent = (ratio * 100).toStringAsFixed(0).padLeft(3);
  stdout.write('\rComparing $bar $percent% ($current/$total)');
}

OutputFormat _formatFromPath(String path) {
  final lower = path.toLowerCase();
  if (lower.endsWith('.json')) {
    return OutputFormat.json;
  }
  if (lower.endsWith('.csv')) {
    return OutputFormat.csv;
  }
  if (lower.endsWith('.md') || lower.endsWith('.markdown')) {
    return OutputFormat.markdown;
  }
  if (lower.endsWith('.txt')) {
    return OutputFormat.table;
  }
  throw ArgumentError('Unsupported output extension: $path');
}

int _intOption(ArgResults parsed, String name) {
  final value = int.tryParse(parsed.option(name) ?? '');
  if (value == null || value < 0) {
    throw ArgumentError('--$name must be a non-negative integer.');
  }
  return value;
}
