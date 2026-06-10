import 'venue.dart';

class Booking {
  final String id;
  final String userId;
  final String bookingDate;
  final String startTime;
  final Venue? venue;

  Booking({
    required this.id,
    required this.userId,
    required this.bookingDate,
    required this.startTime,
    this.venue,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      bookingDate: json['booking_date'] as String,
      startTime: json['start_time'] as String,
      venue: json['venues'] != null
          ? Venue.fromJson(json['venues'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'booking_date': bookingDate,
      'start_time': startTime,
      if (venue != null) 'venues': venue!.toJson(),
    };
  }
}
