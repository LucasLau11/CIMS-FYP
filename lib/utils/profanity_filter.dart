final Set<String> _profaneWords = {
  'fuck', 'fucking', 'fucker', 'shit', 'shitty', 'bitch', 'bastard',
  'asshole', 'dick', 'piss', 'cunt', 'crap', 'damn', 'douchebag',
  'slut', 'whore', 'bollocks', 'wanker', 'twat', 'motherfucker',
};

String censorProfanity(String text) {
  return text.replaceAllMapped(RegExp(r'\b[a-zA-Z]+\b'), (match) {
    final word = match.group(0)!;
    if (_profaneWords.contains(word.toLowerCase())) {
      return '*' * word.length;
    }
    return word;
  });
}
