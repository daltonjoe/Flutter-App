import '../providers/ask_context_provider.dart';

/// Pure helpers for notification taps (N6).
/// Payload format: "yyyy-MM-dd|slot" (see scheduler).
({String day, String slot})? parseTapPayload(String? p) {
  if (p == null) return null;
  final parts = p.split('|');
  if (parts.length != 2) return null;
  final day = parts[0];
  final slot = parts[1];
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(day)) return null;
  if (slot != 'morning' && slot != 'evening') return null;
  return (day: day, slot: slot);
}

/// shellTab index for a notification target.
/// forecast opens Today for now (ForecastSelectionPage needs chartData).
int tabForTarget(String target) {
  switch (target) {
    case 'ask':
      return kAskTab;
    case 'match':
      return 3;
    default:
      return 0;
  }
}
