const Map<String, String> _accentMap = {
  'à': 'a',
  'á': 'a',
  'â': 'a',
  'ä': 'a',
  'ã': 'a',
  'å': 'a',
  'ç': 'c',
  'è': 'e',
  'é': 'e',
  'ê': 'e',
  'ë': 'e',
  'ì': 'i',
  'í': 'i',
  'î': 'i',
  'ï': 'i',
  'ñ': 'n',
  'ò': 'o',
  'ó': 'o',
  'ô': 'o',
  'ö': 'o',
  'õ': 'o',
  'ù': 'u',
  'ú': 'u',
  'û': 'u',
  'ü': 'u',
  'ý': 'y',
  'ÿ': 'y',
  'œ': 'oe',
  'æ': 'ae',
};

String normalizeText(String value) {
  final lower = value.toLowerCase().trim();
  final withoutAccents = lower
      .split('')
      .map((char) => _accentMap[char] ?? char)
      .join();
  final cleaned = withoutAccents.replaceAll(RegExp(r'[^a-z0-9 ]'), ' ');
  return cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
}

String normalizeName(String givenName, String surname) {
  return normalizeText(
    [givenName, surname].where((part) => part.trim().isNotEmpty).join(' '),
  );
}
