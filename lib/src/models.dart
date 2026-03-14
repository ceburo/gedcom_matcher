class PersonRecord {
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

  final String id;
  final String givenName;
  final String surname;
  final String? sex;
  final String? birthDate;
  final String? birthPlace;
  final String? deathDate;
  final String? deathPlace;
  final String? spouseName;

  String get fullName =>
      [givenName, surname].where((part) => part.isNotEmpty).join(' ').trim();
}

class MatchWeights {
  const MatchWeights({
    this.name = 45,
    this.birthDate = 15,
    this.birthPlace = 10,
    this.deathDate = 10,
    this.sex = 10,
    this.spouse = 10,
  });

  final int name;
  final int birthDate;
  final int birthPlace;
  final int deathDate;
  final int sex;
  final int spouse;
}

class MatchOptions {
  const MatchOptions({
    this.minConfidence = 70,
    this.weights = const MatchWeights(),
    this.maxCandidatesPerPerson = 300,
  });

  final double minConfidence;
  final MatchWeights weights;
  final int maxCandidatesPerPerson;
}

class MatchResult {
  const MatchResult({
    required this.left,
    required this.right,
    required this.confidence,
  });

  final PersonRecord left;
  final PersonRecord right;
  final double confidence;

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

class MatchCandidate {
  const MatchCandidate({
    required this.left,
    required this.right,
    required this.confidence,
  });

  final PersonRecord left;
  final PersonRecord right;
  final double confidence;
}
