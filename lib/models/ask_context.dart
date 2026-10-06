// Sohbete eklenen bağlam. Sunucuya yalnız type+refs (kod/ID) gider; label yalnız ekranda.

import '../services/reference_names_service.dart';

class AskContext {
  /// today_headline | today_event | synastry_aspect
  final String type;
  final Map<String, dynamic> refs;
  final String label;

  const AskContext({
    required this.type,
    required this.refs,
    required this.label,
  });

  /// Bugün olay satırı / TransitDetailPage ortak üretici (aynı refs → aynı id).
  factory AskContext.todayEvent({
    required String profileId,
    required String day,
    required Map event,
    required String label,
  }) {
    final refs = <String, dynamic>{'profile_id': profileId, 'day': day};
    for (final k in const [
      'template_id',
      'transit_body_id',
      'aspect_type_id',
      'natal_body_id',
    ]) {
      if (event[k] != null) refs[k] = event[k];
    }
    return AskContext(type: 'today_event', refs: refs, label: label);
  }

    factory AskContext.todayHeadline({
    required String profileId,
    required String day,
    required Map? tag,
    required String label,
  }) {
    final refs = <String, dynamic>{'profile_id': profileId, 'day': day};
    const m = {
      'transit': 'transit_body_id',
      'aspect': 'aspect_type_id',
      'natal': 'natal_body_id',
    };
    m.forEach((k, v) {
      if (tag?[k] != null) refs[v] = tag![k];
    });
    return AskContext(type: 'today_headline', refs: refs, label: label);
  }

  factory AskContext.synastry({
    required String profileA,
    required String profileB,
    required int bodyA,
    required int bodyB,
    required int aspectTypeId,
    required String label,
  }) {
    final lo = bodyA < bodyB ? bodyA : bodyB;
    final hi = bodyA < bodyB ? bodyB : bodyA;
    return AskContext(
      type: 'synastry_aspect',
      refs: {
        'profile_a': profileA,
        'profile_b': profileB,
        'body_a': lo,
        'body_b': hi,
        'aspect_type_id': aspectTypeId,
      },
      label: label,
    );
  }

  static int? _i(dynamic v) =>
      v is num ? v.toInt() : int.tryParse('${v ?? ''}');

  /// Ekranda gösterilen etiket: refs'ten aktif dilde üretilir, olmazsa saklı label.
  String get displayLabel {
    final n = ReferenceNamesService.instance;
    String p(int? i) => i == null ? '?' : n.planet(i);
    int? a, b, asp;
    if (type == 'today_event' || type == 'today_headline') {
      a = _i(refs['transit_body_id']);
      b = _i(refs['natal_body_id']);
      asp = _i(refs['aspect_type_id']);
    } else if (type == 'synastry_aspect') {
      a = _i(refs['body_a']);
      b = _i(refs['body_b']);
      asp = _i(refs['aspect_type_id']);
    } else {
      return label;
    }
    if (a == null || b == null || asp == null) return label;
    return '${p(a)} · ${n.aspect(asp)} · ${p(b)}';
  }

  String get id {
    final keys = refs.keys.toList()..sort();
    return '$type|${keys.map((k) => '$k=${refs[k]}').join(',')}';
  }

  Map<String, dynamic> toServer() => {'type': type, 'refs': refs};
}