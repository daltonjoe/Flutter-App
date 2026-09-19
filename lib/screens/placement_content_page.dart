import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/natal_chart_response.dart';
import '../services/placement_content_service.dart';
import '../providers/language_provider.dart'; // yolu düzelt
import '../theme/app_theme.dart';
import '../i18n/app_localizations.dart';

class PlacementContentPage extends StatefulWidget {
  final NatalChartResponse chartData;
  const PlacementContentPage({super.key, required this.chartData});

  @override
  State<PlacementContentPage> createState() => _PlacementContentPageState();
}

class _PlacementContentPageState extends State<PlacementContentPage> {
  static const _tabs = [
    ('sun', 'chart.sun'),
    ('moon', 'chart.moon'),
    ('ascendant', 'chart.ascendant'),
  ];

  bool _loading = true;
  bool _error = false;
  Map<String, List<PlacementContent>> _data = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = widget.chartData.summary;
    final locale = context.read<LanguageProvider>().locale.languageCode;
    try {
      final r = await PlacementContentService.fetch(
        placements: {
          'sun': s?.sunSign ?? '',
          'moon': s?.moonSign ?? '',
          'ascendant': s?.ascendantSign ?? '',
        },
        locale: locale,
      );
      if (!mounted) return;
      setState(() {
        _data = r;
        _loading = false;
        _error = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        backgroundColor: AppTheme.bgDeep,
        appBar: AppBar(
          backgroundColor: AppTheme.bgDeep,
          iconTheme: const IconThemeData(color: AppTheme.textPrimary),
          title: Text(t(context, 'placement.title'),
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          bottom: TabBar(
            indicatorColor: AppTheme.violet,
            labelColor: AppTheme.violet,
            unselectedLabelColor: AppTheme.textMuted,
            tabs: [for (final tab in _tabs) Tab(text: t(context, tab.$2))],
          ),
        ),
        body: _body(),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(t(context, 'placement.error'),
              style: const TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              setState(() {
                _loading = true;
                _error = false;
              });
              _load();
            },
            child: Text(t(context, 'placement.retry')),
          ),
        ]),
      );
    }
    return TabBarView(
      children: [for (final tab in _tabs) _list(_data[tab.$1] ?? [])],
    );
  }

  Widget _list(List<PlacementContent> items) {
    if (items.isEmpty) {
      return Center(
        child: Text(t(context, 'placement.empty'),
            style: const TextStyle(color: AppTheme.textSecondary)),
      );
    }
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _themeCard(items[i]),
        ),
      ),
    );
  }

  Widget _themeCard(PlacementContent c) {
    return Container(
      decoration: cosmicCard(),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: c.themeOrder == 1,
          iconColor: AppTheme.violet,
          collapsedIconColor: AppTheme.textMuted,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          title: Text(
            t(context, 'placement.theme.${c.themeCode}'),
            style: const TextStyle(
                color: AppTheme.violet,
                fontSize: 12,
                fontWeight: FontWeight.w700),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(c.title,
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
          ),
          children: [
            if (c.shortDescription != null)
              Text(c.shortDescription!,
                  style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      fontStyle: FontStyle.italic)),
            if (c.content != null) ...[
              const SizedBox(height: 10),
              Text(c.content!,
                  style: const TextStyle(
                      color: AppTheme.textPrimary, fontSize: 14, height: 1.5)),
            ],
            if (c.keywords.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final k in c.keywords)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0x268B5CF6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(k,
                        style: const TextStyle(
                            color: AppTheme.violet, fontSize: 11)),
                  ),
              ]),
            ],
            _bullets('placement.strengths', c.strengths),
            _bullets('placement.challenges', c.challenges),
          ],
        ),
      ),
    );
  }

  Widget _bullets(String titleKey, List<String> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(t(context, titleKey),
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        for (final s in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('• ', style: TextStyle(color: AppTheme.violet)),
              Expanded(
                child: Text(s,
                    style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        height: 1.4)),
              ),
            ]),
          ),
      ]),
    );
  }
}