import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
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
  final supabase = ref.watch(supabaseClientProvider);
  
  // Create a real-time channel to listen to any booking changes for this specific venue.
  // When a new booking is inserted or deleted, we invalidate this provider to refresh the slots list.
  final channel = supabase
      .channel('public:bookings:venue:${arg.venueId}')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'bookings',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'venue_id',
          value: arg.venueId,
        ),
        callback: (payload) {
          debugPrint('Real-time bookings change detected for venue ${arg.venueId}: ${payload.eventType}');
          ref.invalidateSelf();
        },
      );
  
  channel.subscribe();
  
  // Clean up the channel subscription when the provider is disposed/unwatched
  ref.onDispose(() {
    supabase.removeChannel(channel);
  });

  final url = Uri.parse('$baseUrl/venues/${arg.venueId}/slots?date=${arg.date}');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final List<dynamic> body = jsonDecode(response.body);
    return body.map((dynamic item) => Slot.fromJson(item as Map<String, dynamic>)).toList();
  } else {
    throw Exception('Failed to load slots: ${response.reasonPhrase}');
  }
});

class BookingsFilter {
  final String? date;
  final String? startTime;
  final String? sportType;

  BookingsFilter({this.date, this.startTime, this.sportType});

  BookingsFilter copyWith({
    String? date,
    String? startTime,
    String? sportType,
    bool clearDate = false,
    bool clearStartTime = false,
    bool clearSportType = false,
  }) {
    return BookingsFilter(
      date: clearDate ? null : (date ?? this.date),
      startTime: clearStartTime ? null : (startTime ?? this.startTime),
      sportType: clearSportType ? null : (sportType ?? this.sportType),
    );
  }

  bool get isEmpty => date == null && startTime == null && sportType == null;
}

class BookingsFilterNotifier extends Notifier<BookingsFilter> {
  @override
  BookingsFilter build() => BookingsFilter();

  void update(BookingsFilter Function(BookingsFilter state) cb) {
    state = cb(state);
  }
}

final bookingsFilterProvider = NotifierProvider<BookingsFilterNotifier, BookingsFilter>(
  BookingsFilterNotifier.new,
);

// Fetch all unfiltered bookings for the current active user
final unfilteredUserBookingsProvider = FutureProvider<List<Booking>>((ref) async {
  final currentUser = ref.watch(currentUserProvider);
  final token = ref.watch(authSessionTokenProvider);

  if (currentUser == null || token == null) {
    return [];
  }

  // Real-time listener to automatically refresh on database changes
  final supabase = ref.watch(supabaseClientProvider);
  final channel = supabase
      .channel('public:bookings:unfiltered:${currentUser.id}')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'bookings',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: currentUser.id,
        ),
        callback: (payload) {
          ref.invalidateSelf();
        },
      );

  channel.subscribe();
  ref.onDispose(() {
    supabase.removeChannel(channel);
  });

  final uri = Uri.parse('$baseUrl/users/${currentUser.id}/bookings');
  final response = await http.get(
    uri,
    headers: {
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    final List<dynamic> body = jsonDecode(response.body);
    return body.map((dynamic item) => Booking.fromJson(item as Map<String, dynamic>)).toList();
  } else {
    throw Exception('Failed to load all bookings: ${response.reasonPhrase}');
  }
});

// Fetch bookings for the current active user (supports filters)
final userBookingsProvider = FutureProvider<List<Booking>>((ref) async {
  final currentUser = ref.watch(currentUserProvider);
  final token = ref.watch(authSessionTokenProvider);
  final filter = ref.watch(bookingsFilterProvider);

  if (currentUser == null || token == null) {
    return [];
  }

  final supabase = ref.watch(supabaseClientProvider);

  // Subscribe to real-time changes of the current user's bookings.
  final channel = supabase
      .channel('public:bookings:user:${currentUser.id}')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'bookings',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: currentUser.id,
        ),
        callback: (payload) {
          debugPrint('Real-time bookings change detected for user ${currentUser.id}: ${payload.eventType}');
          ref.invalidateSelf();
        },
      );

  channel.subscribe();

  ref.onDispose(() {
    supabase.removeChannel(channel);
  });

  // Construct query parameters based on filters
  final Map<String, String> queryParams = {};
  if (filter.date != null) queryParams['date'] = filter.date!;
  if (filter.startTime != null) queryParams['start_time'] = filter.startTime!;
  if (filter.sportType != null) queryParams['sport_type'] = filter.sportType!;

  final uri = Uri.parse('$baseUrl/users/${currentUser.id}/bookings').replace(queryParameters: queryParams);
  final response = await http.get(
    uri,
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
        ref.invalidate(unfilteredUserBookingsProvider);

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

  Future<bool> cancelBooking({
    required String bookingId,
    required String venueId,
    required String date,
    required String venueName,
    required String startTime,
  }) async {
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
        ref.invalidate(unfilteredUserBookingsProvider);

        // Helper to format 24h to 12h AM/PM
        String formatToAmPm(String time24) {
          try {
            final parts = time24.split(':');
            final hour = int.parse(parts[0]);
            final minute = parts[1];
            final period = hour >= 12 ? 'PM' : 'AM';
            var hour12 = hour % 12;
            if (hour12 == 0) hour12 = 12;
            return '$hour12:$minute $period';
          } catch (e) {
            return time24;
          }
        }

        // Trigger local notification immediately on cancellation
        try {
          ref.read(fcmManagerProvider).showLocalNotification(
            title: 'Booking Cancelled ❌',
            body: 'Your booking at $venueName on $date at ${formatToAmPm(startTime.substring(0, 5))} has been cancelled.',
          );
        } catch (e) {
          debugPrint('Local Notification Error: $e');
        }

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
