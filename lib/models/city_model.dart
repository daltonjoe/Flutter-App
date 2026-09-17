import 'dart:convert';
import 'package:flutter/services.dart';

class CityModel {
  final String city;
  final String country;
  final String display;
  final double latitude;
  final double longitude;
  final String timezone;

  CityModel({
    required this.city,
    required this.country,
    required this.display,
    required this.latitude,
    required this.longitude,
    required this.timezone,
  });

  factory CityModel.fromJson(Map<String, dynamic> json) => CityModel(
    city: json['city'],
    country: json['country'],
    display: json['display'],
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    timezone: json['timezone'],
  );

  // Python API'ye gönderilecek format
  Map<String, dynamic> toApiMap() => {
    'city': display,
    'latitude': latitude,
    'longitude': longitude,
    'timezone': timezone,
  };

  static Future<List<CityModel>> loadAll() async {
    final String raw =
        await rootBundle.loadString('assets/data/cities.json');
    final List<dynamic> list = jsonDecode(raw);
    return list.map((e) => CityModel.fromJson(e)).toList();
  }
}