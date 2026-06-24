/// Converts Iraq location strings (Arabic/Kurdish script) to Latin display text.
abstract final class IraqRomanization {
  static String toLatin(String input) {
    final buffer = StringBuffer();
    final chars = input.replaceAll(RegExp(r'\s+'), '').split('');
    for (final ch in chars) {
      buffer.write(_map[ch] ?? ch);
    }
    final words = _splitWords(buffer.toString());
    if (words.isEmpty) return input;
    return words.map(_titleWord).join(' ');
  }

  static String toArabic(String input) =>
      input.replaceAll(RegExp(r'\s{2,}'), ' ').trim();

  static List<String> _splitWords(String compact) {
    if (compact.isEmpty) return const [];

    final words = <String>[];
    final current = StringBuffer();
    for (var i = 0; i < compact.length; i++) {
      final ch = compact[i];
      final isUpper = ch == ch.toUpperCase() && ch != ch.toLowerCase();
      if (isUpper && current.isNotEmpty) {
        words.add(current.toString());
        current.clear();
      }
      current.write(ch);
    }
    if (current.isNotEmpty) words.add(current.toString());
    return words;
  }

  static String _titleWord(String word) {
    if (word.isEmpty) return word;
    if (word.length == 1) return word.toUpperCase();
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }

  static const _map = <String, String>{
    'ا': 'a', 'أ': 'a', 'إ': 'i', 'آ': 'a', 'ئ': "'", 'ء': "'",
    'ب': 'b', 'پ': 'p', 'ت': 't', 'ث': 'th', 'ج': 'j', 'چ': 'ch',
    'ح': 'h', 'خ': 'kh', 'د': 'd', 'ذ': 'dh', 'ر': 'r', 'ز': 'z',
    'ژ': 'zh', 'س': 's', 'ش': 'sh', 'ص': 's', 'ض': 'd', 'ط': 't',
    'ظ': 'z', 'ع': "'", 'غ': 'gh', 'ف': 'f', 'ق': 'q', 'ك': 'k',
    'ک': 'k', 'گ': 'g', 'ل': 'l', 'م': 'm', 'ن': 'n', 'ه': 'h',
    'ة': 'a', 'ھ': 'h', 'و': 'w', 'ؤ': 'w', 'ۇ': 'u', 'ۆ': 'o',
    'ی': 'y', 'ي': 'y', 'ى': 'a', 'ە': 'a', 'ێ': 'e',
    'ڕ': 'r', 'ڤ': 'v', 'ڎ': 'dh', 'ڵ': 'l',
    '(' : ' (', ')': ') ',
    '-': '-', '/': '/',
  };
}
