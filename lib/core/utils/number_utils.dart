/// lib/core/utils/number_utils.dart
library;

/// Utility class for number localization.
class NumberUtils {
  /// Map of Latin digits to Arabic numerals.
  static const Map<String, String> _arabicDigits = {
    '0': '٠',
    '1': '١',
    '2': '٢',
    '3': '٣',
    '4': '٤',
    '5': '٥',
    '6': '٦',
    '7': '٧',
    '8': '٨',
    '9': '٩',
  };

  /// Converts Latin digits in a string to Arabic numerals if the current locale is Arabic.
  static String localize(String input, String languageCode) {
    if (languageCode != 'ar') return input;

    String output = input;
    _arabicDigits.forEach((latin, arabic) {
      output = output.replaceAll(latin, arabic);
    });
    
    return output;
  }
}
