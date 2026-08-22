class Clinic {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double distanceKm;
  final int waitTimeMinutes;
  final bool isLiveQueueActive;
  final double rating;
  final int reviewCount;

  const Clinic({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
    required this.waitTimeMinutes,
    required this.isLiveQueueActive,
    required this.rating,
    required this.reviewCount,
  });
}
