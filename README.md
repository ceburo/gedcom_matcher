# gedcom_matcher

[![pub package](https://img.shields.io/pub/v/gedcom_matcher.svg)](https://pub.dev/packages/gedcom_matcher)
[![Dart SDK](https://img.shields.io/badge/dart-%5E3.10.4-blue.svg)](https://dart.dev)

`gedcom_matcher` is a Dart CLI for comparing two GEDCOM files (`.ged`) and
finding likely person matches with a confidence score.

## Features

- Compare two GEDCOM datasets.
- Compute a confidence score from `0` to `100`.
- Configure a minimum confidence threshold (`--min-confidence`).
- Use repeatable output formats (`table`, `json`, `csv`, `markdown`).
- Export results with `--output`, with format inferred from file extension.
- Show a progress bar in interactive terminals.

## Installation

```bash
fvm dart pub get
```

## Quick Start

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

## CLI Usage

```bash
fvm dart run bin/gedcom_matcher.dart [options] file_a.ged file_b.ged
```

Show help:

```bash
fvm dart run bin/gedcom_matcher.dart --help
```

Example with repeatable formats and export:

```bash
fvm dart run bin/gedcom_matcher.dart \
	--format table \
	--format json \
	--min-confidence 70 \
	--output results.csv \
	data/a.ged data/b.ged
```

## Main Options

- `-h, --help`: Display help.
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
- `--no-color`: Disable ANSI colors.

Example for large files:

```bash
fvm dart run bin/gedcom_matcher.dart \
	--min-confidence 70 \
	--max-candidates 200 \
	--output results.json \
	file_a.ged file_b.ged
```

## MVP Matching Criteria

- Normalized given name + surname.
- Birth date.
- Birth place.
- Death date.
- Sex.
- Spouse first name + last name (lightly weighted).

## GEDCOM Parsing

Parsing relies on the `gedcom_parser` package to support common GEDCOM
structures while keeping the implementation focused and simple.

## Development Checks

```bash
fvm dart format lib test example
fvm dart analyze
fvm dart test
```
