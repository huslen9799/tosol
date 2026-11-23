/// Байрны ойр байрлах нийтийн газрын мэдээлэл (backend: /properties/{id}/nearby/).
class NearbyPlace {
  final String name;
  final int distance;
  final double latitude, longitude;
  final String category;
  const NearbyPlace({
    required this.name,
    required this.distance,
    required this.latitude,
    required this.longitude,
    required this.category,
  });

  factory NearbyPlace.fromJson(String category, Map<String, dynamic> d) =>
      NearbyPlace(
        name: d['name'] as String? ?? '',
        distance: (d['distance'] as num?)?.toInt() ?? 0,
        latitude: (d['latitude'] as num).toDouble(),
        longitude: (d['longitude'] as num).toDouble(),
        category: category,
      );

  String get distanceLabel =>
      distance >= 1000 ? '${(distance / 1000).toStringAsFixed(1)} км' : '$distance м';
}

class NearbyCategory {
  final String key, label;
  final List<NearbyPlace> places;
  const NearbyCategory({
    required this.key,
    required this.label,
    required this.places,
  });

  factory NearbyCategory.fromJson(Map<String, dynamic> d) => NearbyCategory(
    key: d['key'] as String? ?? '',
    label: d['label'] as String? ?? '',
    places: (d['places'] as List? ?? [])
        .map((e) => NearbyPlace.fromJson(d['key'] as String? ?? '', e as Map<String, dynamic>))
        .toList(),
  );

  NearbyPlace? get nearest => places.isEmpty ? null : places.first;
}

class NearbyResult {
  final bool available;
  final String? reason;
  final List<NearbyCategory> categories;
  const NearbyResult({
    required this.available,
    required this.categories,
    this.reason,
  });

  factory NearbyResult.fromJson(Map<String, dynamic> d) => NearbyResult(
    available: d['available'] == true,
    reason: d['reason'] as String?,
    categories: (d['categories'] as List? ?? [])
        .map((e) => NearbyCategory.fromJson(e as Map<String, dynamic>))
        .where((c) => c.places.isNotEmpty)
        .toList(),
  );

  bool get isEmpty => categories.isEmpty;
}