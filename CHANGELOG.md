## Unreleased

### Added

- No changes yet.

### Changed

- No changes yet.

### Fixed

- No changes yet.

## 0.2.0

### Added

- Added BSD 3-Clause license file.
- Added dartdoc comments on public API symbols to improve pub.dev
	documentation score.
- Added `.pubignore` to exclude local artifacts from published package
	contents.

### Changed

- Reworked README with a pub.dev-oriented structure, richer usage examples,
	and publishing guidance.
- Added package metadata for pub.dev (`homepage`, `repository`,
	`issue_tracker`, `topics`).

### Fixed

- Aligned text outputs and documentation language to English for package
	distribution.

## 0.1.0

- Added an MVP GEDCOM parser (INDI/FAM, name, sex, birth, death, spouse).
- Added a matching engine with a `0-100` confidence score and configurable threshold.
- Added a CLI with `-h`/`--help`, repeatable output formats, and export support.
- Added output formats: `table`, `json`, `csv`, `markdown`.
- Added a progress bar for matching.
- Added unit tests for parsing, matching, output rendering, and CLI behavior.
