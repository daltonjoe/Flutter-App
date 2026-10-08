import 'package:flutter/foundation.dart';

/// Ask composer'a yazılacak (gönderilmeyen) taslak soru. AskPage okuyunca null'lar.
final ValueNotifier<String?> askDraft = ValueNotifier<String?>(null);