/// A normalized representation of a person extracted from a GEDCOM file.
class PersonRecord {
  /// Creates a person record.
  const PersonRecord({
    required this.id,
    required this.givenName,
    required this.surname,
    this.sex,
    this.birthDate,
    this.birthPlace,
    this.deathDate,
    this.deathPlace,
    this.spouseName,
  });

  /// Stable person identifier (usually GEDCOM ID like `I1`).
  final String id;

  /// Person given name.
  final String givenName;

  /// Person surname.
  final String surname;

  /// Person sex when available (`M`, `F`, ...).
  final String? sex;

  /// Raw birth date as parsed from GEDCOM.
  final String? birthDate;

  /// Raw birth place as parsed from GEDCOM.
  final String? birthPlace;

  /// Raw death date as parsed from GEDCOM.
  final String? deathDate;

  /// Raw death place as parsed from GEDCOM.
  final String? deathPlace;

  /// Concatenated spouse full names when known.
  final String? spouseName;

  /// Returns the display full name built from given name and surname.
  String get fullName =>
      [givenName, surname].where((part) => part.isNotEmpty).join(' ').trim();
}

/// Weights used to compute match confidence.
class MatchWeights {
  /// Creates a weight configuration.
  const MatchWeights({
    this.name = 45,
    this.birthDate = 15,
    this.birthPlace = 10,
    this.deathDate = 10,
    this.sex = 10,
    this.spouse = 10,
  });

  /// Weight for normalized full-name similarity.
  final int name;

  /// Weight for birth-date similarity.
  final int birthDate;

  /// Weight for birth-place similarity.
  final int birthPlace;

  /// Weight for death-date similarity.
  final int deathDate;

  /// Weight for sex equality.
  final int sex;

  /// Weight for spouse-name similarity.
  final int spouse;
}

/// Runtime options used by the matching engine.
class MatchOptions {
  /// Creates matching options.
  const MatchOptions({
    this.minConfidence = 70,
    this.weights = const MatchWeights(),
    this.maxCandidatesPerPerson = 300,
  });

  /// Minimum confidence required for a match to be kept.
  final double minConfidence;

  /// Criterion weights used by the confidence scorer.
  final MatchWeights weights;

  /// Maximum right-side candidates evaluated per left-side person.
  final int maxCandidatesPerPerson;
}

/// Final best-match output between one left person and one right person.
class MatchResult {
  /// Creates a match result.
  const MatchResult({
    required this.left,
    required this.right,
    required this.confidence,
  });

  /// Person coming from the left GEDCOM dataset.
  final PersonRecord left;

  /// Person coming from the right GEDCOM dataset.
  final PersonRecord right;

  /// Match confidence score in range `[0, 100]`.
  final double confidence;

  /// Converts the result to a JSON-serializable map.
  Map<String, Object?> toJson() => {
    'confidence': confidence,
    'left': {
      'id': left.id,
      'full_name': left.fullName,
      'birth_date': left.birthDate,
      'birth_place': left.birthPlace,
      'death_date': left.deathDate,
      'sex': left.sex,
      'spouse_name': left.spouseName,
    },
    'right': {
      'id': right.id,
      'full_name': right.fullName,
      'birth_date': right.birthDate,
      'birth_place': right.birthPlace,
      'death_date': right.deathDate,
      'sex': right.sex,
      'spouse_name': right.spouseName,
    },
  };
}

/// Candidate pairing used by some consumers for intermediate processing.
class MatchCandidate {
  /// Creates a candidate match pairing.
  const MatchCandidate({
    required this.left,
    required this.right,
    required this.confidence,
  });

  /// Candidate person from the left dataset.
  final PersonRecord left;

  /// Candidate person from the right dataset.
  final PersonRecord right;

  /// Candidate confidence score.
  final double confidence;
}
