import 'notification_repository.dart';

/// Final text shown in the push / inbox.
class RenderedNotification {
  final String title;
  final String body;
  final String? question;
  final String target;
  const RenderedNotification({
    required this.title,
    required this.body,
    required this.question,
    required this.target,
  });
}

/// Pure template filling (TEKNIK 3). No network, no UI.
class NotificationTemplate {
  static const int maxTitle = 120;
  static const int maxBody = 400;

  static String ordinalEn(int n) {
    final m100 = n % 100;
    if (m100 >= 11 && m100 <= 13) return '${n}th';
    switch (n % 10) {
      case 1:
        return '${n}st';
      case 2:
        return '${n}nd';
      case 3:
        return '${n}rd';
      default:
        return '${n}th';
    }
  }

  static String housePrefix(String locale, int house) {
    if (locale.toLowerCase().startsWith('tr')) return 'Senin $house. evinde: ';
    return 'In your ${ordinalEn(house)} house: ';
  }

  static String? _pick(String? v) {
    if (v == null) return null;
    final t = v.trim();
    return t.isEmpty ? null : t;
  }

  static String _clean(String s) => s.replaceAll(RegExp(r' {2,}'), ' ').trim();

  static String _fill(String tpl,
      {String? houseText, String? time, String? question}) {
    final s = tpl
        .replaceAll('{house}', houseText ?? '')
        .replaceAll('{time}', time ?? '')
        .replaceAll('{q}', question ?? '');
    return _clean(s);
  }

  static String _cut(String s, int max) =>
      s.length <= max ? s : '${s.substring(0, max - 1)}\u2026';

  static RenderedNotification render({
    required CosmicNotification row,
    required String locale,
    String? firstName,
    int? house,
    String? houseLine,
    bool hard = false,
    String topic = 'self',
    DateTime Function(DateTime utc)? toLocal,
  }) {
    // 1 title
    final name = _pick(firstName);
    var title = row.title;
    if (name != null && row.titleNamed != null) {
      title = row.titleNamed!.replaceAll('{name}', name);
    }
    title = _cut(title, maxTitle);

    // 2 body template
    final useHard = row.slot == 'evening' && hard && _pick(row.bodyHard) != null;
    final tpl = useHard ? row.bodyHard! : row.body;

    // 3 house
    final line = _pick(houseLine);
    String? houseText;
    if (house != null && house >= 1 && house <= 12 && line != null) {
      houseText = housePrefix(locale, house) + line;
    }

    // 4 time
    String? time;
    if (row.eventAt != null) {
      final l = (toLocal ?? (DateTime d) => d.toLocal())(row.eventAt!);
      time = '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
    }

    // 5 question
    String? question;
    if (topic == 'love') {
      question = _pick(row.qLove) ?? _pick(row.qSelf);
    } else if (topic == 'work') {
      question = _pick(row.qWork) ?? _pick(row.qSelf);
    } else {
      question = _pick(row.qSelf);
    }

    // 6 length guard: drop the house sentence first
    var body = _fill(tpl, houseText: houseText, time: time, question: question);
    if (body.length > maxBody && houseText != null) {
      body = _fill(tpl, houseText: null, time: time, question: question);
    }
    body = _cut(body, maxBody);

    return RenderedNotification(
      title: title,
      body: body,
      question: question,
      target: row.target,
    );
  }
}
