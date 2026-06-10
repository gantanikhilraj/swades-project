import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/booking_provider.dart';

class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(userBookingsProvider);
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final textMutedColor = isDark ? Colors.white70 : const Color(0xFF475569);
    final textLightMutedColor = isDark ? Colors.white38 : const Color(0xFF94A3B8);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final dividerColor = isDark ? Colors.white12 : Colors.black12;
    final accentColor = isDark ? const Color(0xFF00FF87) : Theme.of(context).primaryColor;

    return bookingsAsync.when(
      data: (bookings) {
        if (bookings.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 64,
                    color: textColor.withOpacity(0.2),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No bookings found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textMutedColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Book slots from the explore tab to see them listed here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: textLightMutedColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.refresh(userBookingsProvider.future),
          color: accentColor,
          backgroundColor: cardColor,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              final venue = booking.venue;

              // Parse date and time for better display
              DateTime? parsedDate;
              try {
                parsedDate = DateTime.parse(booking.bookingDate);
              } catch (_) {}

              final formattedDate = parsedDate != null
                  ? DateFormat('EEEE, MMM d, yyyy').format(parsedDate)
                  : booking.bookingDate;

              final String startTimeStr = booking.startTime.substring(0, 5); // '09:00:00' -> '09:00'
              // Calculate end time (start time + 1 hour)
              int startHour = int.parse(startTimeStr.substring(0, 2));
              int endHour = startHour + 1;
              final String endTimeStr = '${endHour.toString().padLeft(2, '0')}:00';
              final timeSlotStr = '$startTimeStr - $endTimeStr';

              return Card(
                color: cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: isDark ? BorderSide.none : BorderSide(color: dividerColor, width: 1),
                ),
                margin: const EdgeInsets.only(bottom: 14),
                elevation: isDark ? 4 : 1,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Venue top details
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  venue?.name ?? 'Unknown Venue',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: accentColor.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        venue?.sportType ?? 'Sport',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: accentColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        venue?.location ?? '',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: textMutedColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (venue?.imageUrl != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                venue!.imageUrl,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const SizedBox(),
                              ),
                            ),
                        ],
                      ),
                      Divider(color: dividerColor, height: 24),
                      // Date & Time details
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: textMutedColor),
                          const SizedBox(width: 8),
                          Text(
                            formattedDate,
                            style: TextStyle(fontSize: 13, color: textMutedColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 16, color: textMutedColor),
                          const SizedBox(width: 8),
                          Text(
                            timeSlotStr,
                            style: TextStyle(fontSize: 13, color: textMutedColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Cancel Button
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: () => _confirmCancellation(context, ref, booking.id, venue?.id ?? '', booking.bookingDate),
                          icon: const Icon(Icons.cancel, size: 14),
                          label: const Text('Cancel Booking'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.redAccent, width: 1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => Center(
        child: CircularProgressIndicator(
          color: accentColor,
        ),
      ),
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(
                'Failed to load bookings',
                style: TextStyle(color: textMutedColor, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(error.toString(), style: TextStyle(fontSize: 11, color: textLightMutedColor)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(userBookingsProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cardColor,
                  foregroundColor: textColor,
                  elevation: isDark ? 2 : 0,
                  side: isDark ? BorderSide.none : BorderSide(color: dividerColor),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmCancellation(
    BuildContext context,
    WidgetRef ref,
    String bookingId,
    String venueId,
    String bookingDate,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final textMutedColor = isDark ? Colors.white70 : const Color(0xFF475569);
    final textLightMutedColor = isDark ? Colors.white38 : const Color(0xFF94A3B8);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Cancel Booking',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to cancel this booking? This action cannot be undone.',
          style: TextStyle(color: textMutedColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Keep Booking', style: TextStyle(color: textLightMutedColor)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF00FF87)),
        ),
      );

      final success = await ref.read(bookingActionsProvider.notifier).cancelBooking(bookingId, venueId, bookingDate);

      if (context.mounted) {
        Navigator.pop(context); // Dismiss loading spinner
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Booking cancelled successfully' : 'Failed to cancel booking'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }
}
