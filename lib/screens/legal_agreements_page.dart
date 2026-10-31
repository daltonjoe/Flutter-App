import "package:flutter/material.dart";
import "package:flutter/services.dart" show rootBundle;
import "../i18n/app_localizations.dart";

class LegalAgreementsPage extends StatelessWidget {
  const LegalAgreementsPage({super.key});

  void _open(BuildContext context, String titleKey, String doc) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LegalTextPage(titleKey: titleKey, doc: doc),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t(context, "settings.legal.row"))),
      body: SafeArea(
        child: ListView(
          children: [
            ListTile(
              title: Text(t(context, "settings.privacy.policy")),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _open(context, "settings.privacy.policy", "privacy"),
            ),
            ListTile(
              title: Text(t(context, "settings.privacy.terms")),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _open(context, "settings.privacy.terms", "terms"),
            ),
            ListTile(
              title: Text(t(context, "ai_consent.title")),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _open(context, "ai_consent.title", "consent"),
            ),
          ],
        ),
      ),
    );
  }
}

class LegalTextPage extends StatelessWidget {
  const LegalTextPage({super.key, required this.titleKey, required this.doc});
  final String titleKey;

  /// `assets/legal/<doc>_<tr|en>.txt`; Türkçe dışındaki diller İngilizce metni gösterir.
  final String doc;

  @override
  Widget build(BuildContext context) {
    final lang =
        Localizations.localeOf(context).languageCode == "tr" ? "tr" : "en";
    return Scaffold(
      appBar: AppBar(title: Text(t(context, titleKey))),
      body: SafeArea(
        child: FutureBuilder<String>(
          future: rootBundle.loadString("assets/legal/${doc}_$lang.txt"),
          builder: (context, snap) => SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: SelectableText(snap.data ?? ""),
          ),
        ),
      ),
    );
  }
}
