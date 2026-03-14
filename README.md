[![Pub Version](https://img.shields.io/pub/v/gedcom_matcher?color=blue)](https://pub.dev/packages/gedcom_matcher)
[![Pub Likes](https://img.shields.io/pub/likes/gedcom_matcher?color=red)](https://pub.dev/packages/gedcom_matcher)
[![Pub Points](https://img.shields.io/pub/points/gedcom_matcher?label=pub%20points&logo=dart)](https://pub.dev/packages/gedcom_matcher)

# GEDCOM Matcher

A standalone Dart package and CLI to compare two GEDCOM files and detect likely
person matches with a confidence score.

## Features

- **Confidence-based Matching**: Match people across two GEDCOM datasets with a
	score from `0` to `100`.
- **Configurable Heuristics**: Tune matching weights for name, birth date,
	birth place, death date, sex, and spouse.
- **Threshold Filtering**: Keep only matches above a minimum confidence level
	(`--min-confidence`).
- **Multiple Output Formats**: Render output as `table`, `json`, `csv`, or
	`markdown`.
- **Export Support**: Write results to a file via `--output`, with format
	inferred from extension.
- **Progress Feedback**: Show a progress bar in interactive terminals.
- **Library + CLI**: Use it as a command-line tool or directly from Dart code.

## Usage

### CLI

```bash
fvm dart run bin/gedcom_matcher.dart [options] file_a.ged file_b.ged
```

Show help:

```bash
fvm dart run bin/gedcom_matcher.dart --help
```

Quick example:

```bash
fvm dart run bin/gedcom_matcher.dart \
	--format table \
	--min-confidence 70 \
	data/a.ged data/b.ged
```

Export JSON:

```bash
fvm dart run bin/gedcom_matcher.dart \
	--format json \
	--output matches.json \
	data/a.ged data/b.ged
```

Multiple formats in one run:

```bash
fvm dart run bin/gedcom_matcher.dart \
	--format table \
	--format markdown \
	--min-confidence 70 \
	data/a.ged data/b.ged
```

### Dart API

```dart
import 'package:gedcom_matcher/gedcom_matcher.dart';

void main() {
	const parser = GedcomParser();
	const matcher = GedcomMatcher();
	const formatter = MatchOutputFormatter();

	const leftGedcom = '''
0 @I1@ INDI
1 NAME John /Martin/
1 SEX M
1 BIRT
2 DATE 12 JAN 1900
2 PLAC Lyon
0 TRLR
''';

	const rightGedcom = '''
0 @I9@ INDI
1 NAME Johan /Martin/
1 SEX M
1 BIRT
2 DATE 12 JAN 1900
2 PLAC Lyon
0 TRLR
''';

	final leftPeople = parser.parse(leftGedcom);
	final rightPeople = parser.parse(rightGedcom);

	final results = matcher.match(
		leftPeople: leftPeople,
		rightPeople: rightPeople,
		options: const MatchOptions(minConfidence: 70),
	);

	final output = formatter.format(results, OutputFormat.table, useColor: false);
	print(output);
}
```

## Installation

Add `gedcom_matcher` to your `pubspec.yaml`:

```yaml
dependencies:
	gedcom_matcher: ^0.1.0
```

Then install dependencies:

```bash
fvm dart pub get
```

## Main CLI Options

- `-h, --help`: Show help.
- `-f, --format`: Output format (repeatable).
- `-o, --output`: Output file path.
- `--min-confidence`: Minimum threshold between `0` and `100`.
- `--weight-name`
- `--weight-birth-date`
- `--weight-birth-place`
- `--weight-death-date`
- `--weight-sex`
- `--weight-spouse`
- `--max-candidates`: Limit comparisons per person to improve performance.
- `--no-color`: Disable ANSI color output.

## Matching Criteria

Current matching logic uses a weighted combination of:

- Given name + surname (normalized)
- Birth date
- Birth place
- Death date
- Sex
- Spouse name (lightly weighted)

GEDCOM parsing relies on `gedcom_parser` to support common GEDCOM structures.

## Development

Run formatting, static analysis, and tests:

```bash
fvm dart format lib test example
fvm dart analyze
fvm dart test
```

## Publishing

Before publishing a new version:

1. Update `version` in `pubspec.yaml`.
2. Add release notes in `CHANGELOG.md`.
3. Run development checks.
4. Run a dry run:

```bash
fvm dart pub publish --dry-run
```

5. Publish:

```bash
fvm dart pub publish
```

## Contributing

Contributions are welcome.

1. Fork the repository.
2. Create a feature branch.
3. Add or update tests for your changes.
4. Run the development checks.
5. Open a pull request.
