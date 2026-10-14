import "package:flutter/material.dart";
import "../i18n/app_localizations.dart";

class LegalAgreementsPage extends StatelessWidget {
  const LegalAgreementsPage({super.key});

  void _open(BuildContext context, String titleKey, String bodyKey) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LegalTextPage(titleKey: titleKey, bodyKey: bodyKey),
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
              onTap: () => _open(context, "settings.privacy.policy", "legal.privacy.body"),
            ),
            ListTile(
              title: Text(t(context, "settings.privacy.terms")),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _open(context, "settings.privacy.terms", "legal.terms.body"),
            ),
          ],
        ),
      ),
    );
  }
}

class LegalTextPage extends StatelessWidget {
  const LegalTextPage({super.key, required this.titleKey, required this.bodyKey});
  final String titleKey;
  final String bodyKey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t(context, titleKey))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: SelectableText(t(context, bodyKey)),
        ),
      ),
    );
  }
}
