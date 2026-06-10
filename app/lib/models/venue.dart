class Venue {
  final String id;
  final String name;
  final String sportType;
  final String location;
  final String imageUrl;

  Venue({
    required this.id,
    required this.name,
    required this.sportType,
    required this.location,
    required this.imageUrl,
  });

  factory Venue.fromJson(Map<String, dynamic> json) {
    return Venue(
      id: json['id'] as String,
      name: json['name'] as String,
      sportType: json['sport_type'] as String,
      location: json['location'] as String,
      imageUrl: json['image_url'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sport_type': sportType,
      'location': location,
      'image_url': imageUrl,
    };
  }
}
