import 'package:flutter_application/screens/onboarding/onboarding_first_question_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('son satirin ilk cumlesi', () {
    expect(
      onboardingHook('Ilk balon.\nMart sonunda Jupiter evine giriyor. Detaylar sonra.'),
      'Mart sonunda Jupiter evine giriyor.',
    );
  });

  test('cumle sonu yoksa 160 karakterle kesilir', () {
    final h = onboardingHook('a' * 200)!;
    expect(h.length, 158);
    expect(h.endsWith('…'), true);
  });

  test('kisa son satir oldugu gibi', () {
    expect(onboardingHook('Merhaba\nKisa satir'), 'Kisa satir');
  });

  test('bos cevap null', () {
    expect(onboardingHook('  \n '), null);
  });
}
