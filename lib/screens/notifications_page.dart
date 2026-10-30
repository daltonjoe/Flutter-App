import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/app_typography.dart';
import '../i18n/app_localizations.dart';
import '../presentation/widgets/components/cosmic_background.dart';
import '../services/notification_inbox_grouping.dart';
import '../services/notification_repository.dart';

/// Bell with unread badge for the Today AppBar (N5).
class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final r = await NotificationRepository.inbox();
      if (!mounted) return;
      setState(() => _unread = r.where((e) => !e.isRead).length);
    } catch (e) {
      debugPrint('NotificationBell load failed: $e');
    }
  }

  Future<void> _open() async {
    await Navigator.of(context).pushNamed('/notifications');
    if (mounted) unawaited(_load());
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: t(context, 'notif.inbox.title'),
      child: SizedBox(
        width: 40,
        height: 40,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _open,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.notifications_none,
                  size: 22, color: AppColors.gold),
              if (_unread > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: AppColors.themeIdentity,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<InboxItem> _items = const [];
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final r = await NotificationRepository.inbox();
      if (!mounted) return;
      setState(() {
        _items = r;
        _loading = false;
        _error = false;
      });
    } catch (e) {
      debugPrint('NotificationsPage load failed: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  Future<void> _markAll() async {
    try {
      await NotificationRepository.markRead();
    } catch (e) {
      debugPrint('markRead all failed: $e');
    }
    await _load();
  }

  Future<void> _markOne(InboxItem it) async {
    if (it.isRead) return;
    try {
      await NotificationRepository.markRead(
        day: DateTime.parse(it.day),
        slot: it.slot,
      );
    } catch (e) {
      debugPrint('markRead failed: $e');
    }
    await _load();
  }

  void _copy(InboxItem it) {
    Clipboard.setData(ClipboardData(text: '${it.title}\n${it.body}'));
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t(context, 'notif.inbox.copied'))),
    );
  }

  String _groupLabel(InboxGroup g) {
    if (g.kind == 'today') return t(context, 'notif.inbox.today');
    if (g.kind == 'yesterday') return t(context, 'notif.inbox.yesterday');
    return inboxDateLabel(g.dayKey);
  }

  Widget _row(InboxItem it) {
    final label = t(context, 'notif.target.${it.target}');
    return InkWell(
      onTap: () => unawaited(_markOne(it)),
      onLongPress: () => _copy(it),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenH,
          vertical: 12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(Icons.notifications_none,
                  size: 20, color: AppColors.gold),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    it.title,
                    style: AppTextStyles.bodyLg()
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(it.body, style: AppTextStyles.bodyMd()),
                  const SizedBox(height: 6),
                  Text(
                    '\u2192 $label',
                    style: AppTextStyles.bodySm(color: AppColors.gold),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (!it.isRead)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: AppColors.themeIdentity,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error) {
      return Center(
        child: TextButton(
          onPressed: () {
            setState(() => _loading = true);
            unawaited(_load());
          },
          child: Text(t(context, 'notif.inbox.error')),
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Text(t(context, 'notif.inbox.empty'),
            style: AppTextStyles.bodyMd()),
      );
    }
    final groups = groupInbox(_items, DateTime.now());
    final hasUnread = _items.any((e) => !e.isRead);
    final children = <Widget>[];
    if (hasUnread) {
      children.add(Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(right: AppSpacing.screenH - 8),
          child: TextButton(
            onPressed: () => unawaited(_markAll()),
            child: Text(t(context, 'notif.inbox.mark_all'),
                style: AppTextStyles.bodySm(color: AppColors.gold)),
          ),
        ),
      ));
    }
    for (final g in groups) {
      children.add(Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenH, 16, AppSpacing.screenH, 4),
        child: Text(_groupLabel(g), style: AppTextStyles.overline()),
      ));
      for (final it in g.items) {
        children.add(_row(it));
      }
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(children: children),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CosmicBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(t(context, 'notif.inbox.title'),
              style: AppTextStyles.h1()),
        ),
        body: SafeArea(top: false, child: _body()),
      ),
    );
  }
}
