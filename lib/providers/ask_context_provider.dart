import 'package:flutter/foundation.dart';

import '../models/ask_context.dart';

/// MainShell'de Ask sekmesinin shellTab indeksi.
const int kAskTab = 4;

/// feature_flags.tab_ai (MainShell yükler). Kapalıyken "Sohbete ekle" girişleri gizlenir.
final ValueNotifier<bool> askEnabled = ValueNotifier<bool>(false);

/// K32: aktif Ask modu ('natal' | 'forecast').
final ValueNotifier<String> askMode = ValueNotifier<String>('natal');

class AskContextProvider extends ChangeNotifier {
  static const int maxItems = 5;
  final List<AskContext> _items = [];

  List<AskContext> get items => List.unmodifiable(_items);

  /// Yalnız verilen modun kartları (sunucuya bunlar gider).
  List<AskContext> itemsFor(String mode) =>
      _items.where((e) => e.mode == mode).toList();

  /// false: üst sınır (mod başına) doldu. Aynı bağlam zaten varsa true.
  /// Eklenen kartın moduna geçer (addToAsk dahil).
  bool add(AskContext c) {
    if (_items.any((e) => e.id == c.id)) {
      askMode.value = c.mode;
      return true;
    }
    if (itemsFor(c.mode).length >= maxItems) return false;
    _items.add(c);
    askMode.value = c.mode;
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