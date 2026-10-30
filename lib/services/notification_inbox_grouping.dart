import 'notification_repository.dart';

/// Pure grouping of inbox rows (N5). kind: today | yesterday | date.
class InboxGroup {
  final String kind;
  final String dayKey; // yyyy-MM-dd
  final List<InboxItem> items;
  const InboxGroup(this.kind, this.dayKey, this.items);
}

String inboxDayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// dd.MM.yyyy from a yyyy-MM-dd key.
String inboxDateLabel(String dayKey) {
  final p = dayKey.split('-');
  if (p.length != 3) return dayKey;
  return '${p[2]}.${p[1]}.${p[0]}';
}

List<InboxGroup> groupInbox(List<InboxItem> items, DateTime now) {
  final todayKey = inboxDayKey(now);
  final yKey = inboxDayKey(DateTime(now.year, now.month, now.day - 1));
  final sorted = List<InboxItem>.of(items)
    ..sort((a, b) {
      final c = b.day.compareTo(a.day);
      if (c != 0) return c;
      if (a.scheduledAt != null && b.scheduledAt != null) {
        return b.scheduledAt!.compareTo(a.scheduledAt!);
      }
      return a.slot.compareTo(b.slot); // evening before morning
    });
  final out = <InboxGroup>[];
  for (final it in sorted) {
    if (out.isEmpty || out.last.dayKey != it.day) {
      final kind = it.day == todayKey
          ? 'today'
          : (it.day == yKey ? 'yesterday' : 'date');
      out.add(InboxGroup(kind, it.day, <InboxItem>[]));
    }
    out.last.items.add(it);
  }
  return out;
}
