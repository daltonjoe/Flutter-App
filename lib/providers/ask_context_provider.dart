import 'package:flutter/foundation.dart';

import '../models/ask_context.dart';

/// MainShell'de Ask sekmesinin shellTab indeksi.
const int kAskTab = 4;

/// feature_flags.tab_ai (MainShell yükler). Kapalıyken "Sohbete ekle" girişleri gizlenir.
final ValueNotifier<bool> askEnabled = ValueNotifier<bool>(false);

class AskContextProvider extends ChangeNotifier {
  static const int maxItems = 5;
  final List<AskContext> _items = [];

  List<AskContext> get items => List.unmodifiable(_items);

  /// false: üst sınır doldu. Aynı bağlam zaten varsa true.
  bool add(AskContext c) {
    if (_items.any((e) => e.id == c.id)) return true;
    if (_items.length >= maxItems) return false;
    _items.add(c);
    notifyListeners();
    return true;
  }

  void remove(String id) {
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  void clear() {
    if (_items.isEmpty) return;
    _items.clear();
    notifyListeners();
  }
}

final AskContextProvider askContext = AskContextProvider();