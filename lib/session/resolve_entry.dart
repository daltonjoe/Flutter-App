// lib/session/resolve_entry.dart (saf Dart, adim 5; main e bagli DEGIL)
enum SessionKind { none, anon, user }

enum EntryIntent { none, signin }

enum EntryRoute {
  loading,
  retry,
  signin,
  consent,
  language,
  name,
  notFound,
  home,
}

const Set<String> kRequiredConsents = {"privacy", "terms", "ai"};

EntryRoute resolveEntry({
  required SessionKind session,
  required int? profileCount,
  required Set<String>? consentKinds,
  required bool showSignin,
  required EntryIntent intent,
  required bool languageChosen,
}) {
  if (session == SessionKind.none) return EntryRoute.loading;
  if (showSignin) return EntryRoute.signin;
  if (profileCount == null || consentKinds == null) return EntryRoute.retry;
  final full = consentKinds.containsAll(kRequiredConsents);
  if (profileCount > 0) return full ? EntryRoute.home : EntryRoute.consent;
  final start = languageChosen ? EntryRoute.name : EntryRoute.language;
  if (session == SessionKind.anon) return start;
  if (full) return start;
  return intent == EntryIntent.signin ? EntryRoute.notFound : EntryRoute.consent;
}
