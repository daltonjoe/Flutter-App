// lib/session/resolve_entry.dart (saf Dart, adim 5; main e bagli DEGIL)
enum SessionKind { none, anon, user }

enum EntryIntent { none, signin }

enum EntryRoute {
  loading,
  retry,
  signin,
  onboarding,
  notFound,
  home,
}

const Set<String> kRequiredConsents = {"privacy", "terms"};

EntryRoute resolveEntry({
  required SessionKind session,
  required int? profileCount,
  required Set<String>? consentKinds,
  required bool showSignin,
  required EntryIntent intent,
}) {
  if (session == SessionKind.none) return EntryRoute.loading;
  if (showSignin) return EntryRoute.signin;
  if (profileCount == null || consentKinds == null) return EntryRoute.retry;
  if (profileCount > 0) return EntryRoute.home;
  if (session == SessionKind.anon) return EntryRoute.onboarding;
  return intent == EntryIntent.signin ? EntryRoute.notFound : EntryRoute.onboarding;
}
