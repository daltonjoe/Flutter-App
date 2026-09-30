import 'package:flutter/material.dart';

enum ContentTheme {
  love(1, 'love', Color(0xFFE85D75)),
  career(2, 'career', Color(0xFF4A90D9)),
  identity(3, 'identity', Color(0xFF9B59B6)),
  health(4, 'health', Color(0xFF4CAF50));

  final int id;
  final String code;
  final Color color;
  const ContentTheme(this.id, this.code, this.color);

  static ContentTheme fromId(int id) =>
      ContentTheme.values.firstWhere((t) => t.id == id);
}

class PlacementContent {
  final String id;
  final int planetId;
  final int signId;
  final int houseId;
  final int themeId;
  final String locale;
  final String title;
  final String shortDescription;
  final String content;
  final List<String> keywords;
  final List<String> strengths;
  final List<String> challenges;

  PlacementContent({
    required this.id,
    required this.planetId,
    required this.signId,
    required this.houseId,
    required this.themeId,
    required this.locale,
    required this.title,
    required this.shortDescription,
    required this.content,
    required this.keywords,
    required this.strengths,
    required this.challenges,
  });

  ContentTheme get theme => ContentTheme.fromId(themeId);

  factory PlacementContent.fromMap(Map<String, dynamic> map) {
    return PlacementContent(
      id: map['id'] as String,
      planetId: map['planet_id'] as int,
      signId: map['sign_id'] as int,
      houseId: map['house_id'] as int,
      themeId: map['theme_id'] as int,
      locale: map['locale'] as String,
      title: map['title'] as String? ?? '',
      shortDescription: map['short_description'] as String? ?? '',
      content: map['content'] as String? ?? '',
      keywords: (map['keywords'] as List?)?.map((e) => e.toString()).toList() ?? [],
      strengths: (map['strengths'] as List?)?.map((e) => e.toString()).toList() ?? [],
      challenges: (map['challenges'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

class PlacementSignThemeContent {
  final String id;
  final String placementType; // 'sun' | 'moon' | 'ascendant'
  final int signId;
  final int themeId;
  final String locale;
  final String title;
  final String shortDescription;
  final String content;
  final List<String> keywords;
  final List<String> strengths;
  final List<String> challenges;

  PlacementSignThemeContent({
    required this.id,
    required this.placementType,
    required this.signId,
    required this.themeId,
    required this.locale,
    required this.title,
    required this.shortDescription,
    required this.content,
    required this.keywords,
    required this.strengths,
    required this.challenges,
  });

  ContentTheme get theme => ContentTheme.fromId(themeId);

  factory PlacementSignThemeContent.fromMap(Map<String, dynamic> map) {
    return PlacementSignThemeContent(
      id: map['id'] as String,
      placementType: map['placement_type'] as String,
      signId: map['sign_id'] as int,
      themeId: map['theme_id'] as int,
      locale: map['locale'] as String,
      title: map['title'] as String? ?? '',
      shortDescription: map['short_description'] as String? ?? '',
      content: map['content'] as String? ?? '',
      keywords: (map['keywords'] as List?)?.map((e) => e.toString()).toList() ?? [],
      strengths: (map['strengths'] as List?)?.map((e) => e.toString()).toList() ?? [],
      challenges: (map['challenges'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}