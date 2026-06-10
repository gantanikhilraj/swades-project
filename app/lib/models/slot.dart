class Slot {
  final String startTime;
  final String status;
  final String? bookingId;
  final String? userId;

  Slot({
    required this.startTime,
    required this.status,
    this.bookingId,
    this.userId,
  });

  bool get isBooked => status == 'booked';
  bool get isAvailable => status == 'available';

  factory Slot.fromJson(Map<String, dynamic> json) {
    return Slot(
      startTime: json['start_time'] as String,
      status: json['status'] as String,
      bookingId: json['booking_id'] as String?,
      userId: json['user_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start_time': startTime,
      'status': status,
      'booking_id': bookingId,
      'user_id': userId,
    };
  }
}
