// flutter_application/lib/models/natal_chart_response.dart
//
// CHANGE: Added toChartPayload() — previously missing, caused runtime crashes
//         in ForecastResultPage and PlanetReportPage.

class NatalChartResponse {
  final String status;
  final String requestId;
  final ChartInput? input;
  final ChartLocation? location;
  final ChartSummary? summary;
  final Map<String, PlanetData>? planets;
  final List<AspectData>? aspects;
  final ChartAngles? angles;
  final String? aiReport;
  final String? errorCode;
  final String? message;
  final String? suggestion;
  final Map<String, HouseData>? houses;

  NatalChartResponse({
    required this.status,
    required this.requestId,
    this.input,
    this.houses,
    this.location,
    this.summary,
    this.planets,
    this.aspects,
    this.angles,
    this.aiReport,
    this.errorCode,
    this.message,
    this.suggestion,
  });

  bool get isSuccess => status == 'success';

  Map<String, dynamic> toChartPayload() { 
    return { 
      'planets': planets?.map((k, v) => MapEntry(k, { 
        'sign': v.sign, 'degree_in_sign': v.degreeInSign, 
        'house_number': v.houseNumber, 'retrograde': v.retrograde, 
      })) ?? {}, 
      'aspects': aspects?.map((a) => {'planet1': a.planet1, 
        'aspect': a.aspect, 'planet2': a.planet2, 
        'orb': a.orb, 'is_major': a.isMajor}).toList() ?? [], 
      'summary': {'sun_sign': summary?.sunSign ?? '', 
        'moon_sign': summary?.moonSign ?? '', 
        'ascendant_sign': summary?.ascendantSign ?? '', 
        'element_distribution': summary?.elementDistribution ?? {}, 
        'retrograde_planets': summary?.retrogradePlanets ?? []}, 
    }; 
  } 

  factory NatalChartResponse.fromJson(Map<String, dynamic> json) {
    return NatalChartResponse(
      status: json['status'] ?? 'error',
      requestId: json['request_id'] ?? '',
      input: json['input'] != null ? ChartInput.fromJson(json['input']) : null,
      location: json['location'] != null ? ChartLocation.fromJson(json['location']) : null,
      summary: json['summary'] != null ? ChartSummary.fromJson(json['summary']) : null,
      planets: json['planets'] != null
          ? (json['planets'] as Map<String, dynamic>)
              .map((k, v) => MapEntry(k, PlanetData.fromJson(v as Map<String, dynamic>)))
          : null,
      aspects: json['aspects'] != null
          ? (json['aspects'] as List).map((a) => AspectData.fromJson(a)).toList()
          : null,
      angles: json['angles'] != null ? ChartAngles.fromJson(json['angles']) : null,
      aiReport: json['ai_report'],
      errorCode: json['error_code'],
      message: json['message'],
      suggestion: json['suggestion'],
      houses: json['houses'] != null
    ? (json['houses'] as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, HouseData.fromJson(v as Map<String, dynamic>)))
    : null,
    );
  }
}

class ChartInput {
  final String birthDate;
  final String birthTimeLocal;
  final String birthTimeUtc;
  final double julianDay;

  ChartInput({
    required this.birthDate,
    required this.birthTimeLocal,
    required this.birthTimeUtc,
    required this.julianDay,
  });

  factory ChartInput.fromJson(Map<String, dynamic> json) => ChartInput(
        birthDate: json['birth_date'] ?? '',
        birthTimeLocal: json['birth_time_local'] ?? '',
        birthTimeUtc: json['birth_time_utc'] ?? '',
        julianDay: (json['julian_day'] as num?)?.toDouble() ?? 0.0,
      );
}

class ChartLocation {
  final String cityQuery;
  final String cityResolved;
  final double latitude;
  final double longitude;
  final String timezone;
  final String utcOffset;

  ChartLocation({
    required this.cityQuery,
    required this.cityResolved,
    required this.latitude,
    required this.longitude,
    required this.timezone,
    required this.utcOffset,
  });

  factory ChartLocation.fromJson(Map<String, dynamic> json) => ChartLocation(
        cityQuery: json['city_query'] ?? '',
        cityResolved: json['city_resolved'] ?? '',
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
        timezone: json['timezone'] ?? '',
        utcOffset: json['utc_offset'] ?? '',
      );
}

class ChartSummary {
  final String sunSign;
  final String moonSign;
  final String ascendantSign;
  final Map<String, int> elementDistribution;
  final List<String> retrogradePlanets;

  ChartSummary({
    required this.sunSign,
    required this.moonSign,
    required this.ascendantSign,
    required this.elementDistribution,
    required this.retrogradePlanets,
  });

  factory ChartSummary.fromJson(Map<String, dynamic> json) => ChartSummary(
        sunSign: json['sun_sign'] ?? '',
        moonSign: json['moon_sign'] ?? '',
        ascendantSign: json['ascendant_sign'] ?? '',
        elementDistribution: json['element_distribution'] != null
            ? Map<String, int>.from(json['element_distribution'])
            : {},
        retrogradePlanets: json['retrograde_planets'] != null
            ? List<String>.from(json['retrograde_planets'])
            : [],
      );
}

class PlanetData {
  final String sign;
  final int signIndex;
  final double longitude;
  final double latitude;
  final double degreeInSign;
  final int house;
  final int houseNumber;
  final bool retrograde;

  PlanetData({
    required this.sign,
    required this.signIndex,
    required this.longitude,
    required this.latitude,
    required this.degreeInSign,
    required this.house,
    required this.houseNumber,
    required this.retrograde,
  });

  factory PlanetData.fromJson(Map<String, dynamic> json) => PlanetData(
        sign: json['sign'] ?? '',
        signIndex: (json['sign_index'] as num?)?.toInt() ?? 0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
        degreeInSign: (json['degree_in_sign'] as num?)?.toDouble() ?? 0.0,
        house: (json['house'] as num?)?.toInt() ??
            (json['house_number'] as num?)?.toInt() ??
            0,
        houseNumber: (json['house'] as num?)?.toInt() ??
            (json['house_number'] as num?)?.toInt() ??
            0,
        retrograde: json['retrograde'] ?? false,
      );
}

class AspectData {
  final String planet1;
  final String aspect;
  final String planet2;
  final num angle;
  final double actualAngle;
  final double orb;
  final bool applying;
  final bool isMajor;

  AspectData({
    required this.planet1,
    required this.aspect,
    required this.planet2,
    required this.angle,
    required this.actualAngle,
    required this.orb,
    required this.applying,
    required this.isMajor,
  });

  factory AspectData.fromJson(Map<String, dynamic> json) => AspectData(
        planet1: json['planet1'] ?? '',
        aspect: json['aspect'] ?? '',
        planet2: json['planet2'] ?? '',
        angle: (json['angle'] as num?) ?? 0,
        actualAngle: (json['actual_angle'] as num?)?.toDouble() ?? 0.0,
        orb: (json['orb'] as num?)?.toDouble() ?? 0.0,
        applying: json['applying'] ?? false,
        isMajor: json['is_major'] ?? true,
      );
}

class ChartAngles {
  final String ascSign;
  final double ascDegree;
  final String mcSign;
  final double mcDegree;

  ChartAngles({
    required this.ascSign,
    required this.ascDegree,
    required this.mcSign,
    required this.mcDegree,
  });

  factory ChartAngles.fromJson(Map<String, dynamic> json) => ChartAngles(
        ascSign: json['ascendant']?['sign'] ?? '',
        ascDegree:
            (json['ascendant']?['degree_in_sign'] as num?)?.toDouble() ?? 0.0,
        mcSign: json['midheaven']?['sign'] ?? '',
        mcDegree:
            (json['midheaven']?['degree_in_sign'] as num?)?.toDouble() ?? 0.0,
      );
}

class HouseData {
  final String sign;
  final double cuspDegree;
  final int signIndex;
  final double longitude;
  final double degreeInSign;
  final int houseNumber;

  HouseData({
    required this.sign,
    required this.cuspDegree,
    required this.signIndex,
    required this.longitude,
    required this.degreeInSign,
    required this.houseNumber,
  });

  factory HouseData.fromJson(Map<String, dynamic> json) => HouseData(
        sign: json['sign'] ?? '',
        cuspDegree: (json['longitude'] as num?)?.toDouble() ?? 0.0,
        signIndex: (json['sign_index'] as num?)?.toInt() ?? 0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
        degreeInSign: (json['degree_in_sign'] as num?)?.toDouble() ?? 0.0,
        houseNumber: (json['house_number'] as num?)?.toInt() ?? 0,
      );
}
