import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/slot.dart';
import '../models/booking.dart';
import 'api_config.dart';
import 'auth_provider.dart';
import 'fcm_provider.dart';

// Slot identifier argument class
class SlotArg {
  final String venueId;
  final String date;

  SlotArg({required this.venueId, required this.date});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SlotArg &&
          runtimeType == other.runtimeType &&
          venueId == other.venueId &&
          date == other.date;

  @override
  int get hashCode => venueId.hashCode ^ date.hashCode;
}

// Fetch slots for a venue and date
final slotsProvider = FutureProvider.family<List<Slot>, SlotArg>((ref, arg) async {
  final url = Uri.parse('$baseUrl/venues/${arg.venueId}/slots?date=${arg.date}');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final List<dynamic> body = jsonDecode(response.body);
    return body.map((dynamic item) => Slot.fromJson(item as Map<String, dynamic>)).toList();
  } else {
    throw Exception('Failed to load slots: ${response.reasonPhrase}');
  }
});

// Fetch bookings for the current active user
final userBookingsProvider = FutureProvider<List<Booking>>((ref) async {
  final currentUser = ref.watch(currentUserProvider);
  final token = ref.watch(authSessionTokenProvider);

  if (currentUser == null || token == null) {
    return [];
  }

  final url = Uri.parse('$baseUrl/users/${currentUser.id}/bookings');
  final response = await http.get(
    url,
    headers: {
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    final List<dynamic> body = jsonDecode(response.body);
    return body.map((dynamic item) => Booking.fromJson(item as Map<String, dynamic>)).toList();
  } else {
    throw Exception('Failed to load your bookings: ${response.reasonPhrase}');
  }
});

// Concurrency response type for bookings
class BookingResult {
  final bool success;
  final String message;

  BookingResult({required this.success, required this.message});
}

// Booking actions manager
class BookingNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<BookingResult> bookSlot({
    required String venueId,
    required String date,
    required String startTime,
    required String venueName,
  }) async {
    state = const AsyncValue.loading();
    final token = ref.read(authSessionTokenProvider);
    final url = Uri.parse('$baseUrl/bookings');

    if (token == null) {
      state = const AsyncValue.data(null);
      return BookingResult(success: false, message: 'You must be logged in to book slots');
    }

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'venue_id': venueId,
          'date': date,
          'start_time': startTime,
        }),
      );

      state = const AsyncValue.data(null);

      if (response.statusCode == 201) {
        // Invalidate current slots and user bookings to trigger automatic UI refresh
        ref.invalidate(slotsProvider(SlotArg(venueId: venueId, date: date)));
        ref.invalidate(userBookingsProvider);

        // Trigger local notification immediately as confirmation
        try {
          ref.read(fcmManagerProvider).showLocalNotification(
            title: 'Booking Confirmed! ⚡',
            body: 'Your booking is confirmed at $venueName for $date at ${startTime.substring(0, 5)}.',
          );
        } catch (e) {
          debugPrint('Local Notification Error: $e');
        }

        return BookingResult(success: true, message: 'Slot booked successfully!');
      } else if (response.statusCode == 409) {
        // Concurrency conflict (double booking)
        ref.invalidate(slotsProvider(SlotArg(venueId: venueId, date: date)));
        return BookingResult(
          success: false,
          message: 'This slot was just booked by another user. Refreshing slots...',
        );
      } else {
        final Map<String, dynamic> body = jsonDecode(response.body);
        return BookingResult(
          success: false,
          message: body['error'] ?? 'Booking failed. Please try again.',
        );
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return BookingResult(
        success: false,
        message: 'Network error. Please check your connection.',
      );
    }
  }

  Future<bool> cancelBooking(String bookingId, String venueId, String date) async {
    state = const AsyncValue.loading();
    final token = ref.read(authSessionTokenProvider);
    final url = Uri.parse('$baseUrl/bookings/$bookingId');

    if (token == null) {
      state = const AsyncValue.data(null);
      return false;
    }

    try {
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      state = const AsyncValue.data(null);

      if (response.statusCode == 200) {
        // Invalidate slots and user bookings to refresh UI
        ref.invalidate(slotsProvider(SlotArg(venueId: venueId, date: date)));
        ref.invalidate(userBookingsProvider);
        return true;
      }
      return false;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }
}

final bookingActionsProvider = NotifierProvider<BookingNotifier, AsyncValue<void>>(BookingNotifier.new);
