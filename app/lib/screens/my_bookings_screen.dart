import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/booking_provider.dart';
import 'fact_loader.dart';


class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(userBookingsProvider);
    final filter = ref.watch(bookingsFilterProvider);
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final textMutedColor = isDark ? Colors.white70 : const Color(0xFF475569);
    final textLightMutedColor = isDark ? Colors.white38 : const Color(0xFF94A3B8);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final dividerColor = isDark ? Colors.white12 : Colors.black12;
    final accentColor = isDark ? const Color(0xFF00FF87) : Theme.of(context).primaryColor;

    return Column(
      children: [
        // Horizontal Filter Options Bar
        _buildFilterBar(context, ref, filter, accentColor, cardColor, textColor, textMutedColor),
        Expanded(
          child: bookingsAsync.when(
            data: (bookings) {
              if (bookings.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          filter.isEmpty ? Icons.calendar_today_outlined : Icons.filter_alt_off_rounded,
                          size: 64,
                          color: textColor.withOpacity(0.2),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          filter.isEmpty ? 'No bookings found' : 'No matching bookings',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textMutedColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          filter.isEmpty
                              ? 'Book slots from the explore tab to see them listed here.'
                              : 'No bookings match your active filters. Try resetting the filters.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: textLightMutedColor,
                          ),
                        ),
                        if (!filter.isEmpty) ...[
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () {
                              ref.read(bookingsFilterProvider.notifier).update((_) => BookingsFilter());
                            },
                            icon: const Icon(Icons.clear_all),
                            label: const Text('Reset Filters'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
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

                    final String startTime24 = booking.startTime.substring(0, 5);
                    int startHour = int.parse(startTime24.split(':')[0]);
                    int endHour = startHour + 1;

                    String formatHourAmPm(int hour) {
                      final period = hour >= 12 ? 'PM' : 'AM';
                      var hour12 = hour % 12;
                      if (hour12 == 0) hour12 = 12;
                      return '$hour12:00 $period';
                    }

                    final timeSlotStr = '${formatHourAmPm(startHour)} - ${formatHourAmPm(endHour)}';

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
                                onPressed: () => _confirmCancellation(
                                  context: context,
                                  ref: ref,
                                  bookingId: booking.id,
                                  venueId: venue?.id ?? '',
                                  bookingDate: booking.bookingDate,
                                  venueName: venue?.name ?? 'your sports court',
                                  startTime: booking.startTime,
                                ),
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
            loading: () => const FactLoader(title: 'Loading Bookings... ⚡'),
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
          ),
        ),
      ],
    );
  }

  // Horizontal Filter bar widget
  Widget _buildFilterBar(
    BuildContext context,
    WidgetRef ref,
    BookingsFilter filter,
    Color accentColor,
    Color cardColor,
    Color textColor,
    Color textMutedColor,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white12 : Colors.black12,
            width: 1.0,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Date Filter Chip
            _buildFilterChip(
              context: context,
              label: filter.date != null
                  ? DateFormat('MMM d, yyyy').format(DateTime.parse(filter.date!))
                  : 'Date',
              isSelected: filter.date != null,
              icon: Icons.calendar_today,
              onTap: () async {
                final unfilteredBookings = ref.read(unfilteredUserBookingsProvider).value ?? [];
                final bookedDates = unfilteredBookings.map((b) => b.bookingDate).toSet();

                // If user has booked dates, set initialDate to the first one, otherwise DateTime.now()
                final initial = bookedDates.isNotEmpty 
                    ? DateTime.parse(bookedDates.first) 
                    : DateTime.now();

                final picked = await showDatePicker(
                  context: context,
                  initialDate: initial,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  selectableDayPredicate: bookedDates.isEmpty
                      ? null
                      : (DateTime day) {
                          final formatted = DateFormat('yyyy-MM-dd').format(day);
                          return bookedDates.contains(formatted);
                        },
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.dark(
                          primary: accentColor,
                          onPrimary: isDark ? Colors.black : Colors.white,
                          surface: cardColor,
                          onSurface: textColor,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  final formatted = DateFormat('yyyy-MM-dd').format(picked);
                  ref.read(bookingsFilterProvider.notifier).update(
                        (state) => state.copyWith(date: formatted),
                      );
                }
              },
              onClear: () {
                ref.read(bookingsFilterProvider.notifier).update(
                      (state) => state.copyWith(clearDate: true),
                    );
              },
              accentColor: accentColor,
              cardColor: cardColor,
              textColor: textColor,
              textMutedColor: textMutedColor,
            ),
            const SizedBox(width: 8),
            // Time Filter Chip
            _buildFilterChip(
              context: context,
              label: filter.startTime != null
                  ? _formatToAmPm(filter.startTime!)
                  : 'Time',
              isSelected: filter.startTime != null,
              icon: Icons.access_time,
              onTap: () => _selectTimeFilter(context, ref, filter, accentColor, cardColor, textColor),
              onClear: () {
                ref.read(bookingsFilterProvider.notifier).update(
                      (state) => state.copyWith(clearStartTime: true),
                    );
              },
              accentColor: accentColor,
              cardColor: cardColor,
              textColor: textColor,
              textMutedColor: textMutedColor,
            ),
            const SizedBox(width: 8),
            // Sport Filter Chip
            _buildFilterChip(
              context: context,
              label: filter.sportType != null ? filter.sportType! : 'Sport',
              isSelected: filter.sportType != null,
              icon: Icons.sports_tennis,
              onTap: () => _selectSportFilter(context, ref, filter, accentColor, cardColor, textColor),
              onClear: () {
                ref.read(bookingsFilterProvider.notifier).update(
                      (state) => state.copyWith(clearSportType: true),
                    );
              },
              accentColor: accentColor,
              cardColor: cardColor,
              textColor: textColor,
              textMutedColor: textMutedColor,
            ),
            // Reset Button
            if (!filter.isEmpty) ...[
              const SizedBox(width: 12),
              TextButton.icon(
                onPressed: () {
                  ref.read(bookingsFilterProvider.notifier).update((_) => BookingsFilter());
                },
                icon: const Icon(Icons.clear_all, size: 16, color: Colors.redAccent),
                label: const Text(
                  'Reset',
                  style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Helper Widget for custom Filter Chip
  Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required IconData icon,
    required VoidCallback onTap,
    required VoidCallback onClear,
    required Color accentColor,
    required Color cardColor,
    required Color textColor,
    required Color textMutedColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withOpacity(0.15)
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          border: Border.all(
            color: isSelected
                ? accentColor
                : (isDark ? Colors.white12 : Colors.black12),
            width: 1.2,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? accentColor : textMutedColor,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? accentColor : textColor,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onClear,
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: accentColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Time Filter Selection Modal
  void _selectTimeFilter(
    BuildContext context,
    WidgetRef ref,
    BookingsFilter filter,
    Color accentColor,
    Color cardColor,
    Color textColor,
  ) {
    final List<String> rawSlots = [
      '06:00', '07:00', '08:00', '09:00', '10:00', '11:00', '12:00', '13:00',
      '14:00', '15:00', '16:00', '17:00', '18:00', '19:00', '20:00', '21:00'
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 350,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Start Time',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2.2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: rawSlots.length,
                  itemBuilder: (context, index) {
                    final slot = rawSlots[index];
                    final formatted = _formatToAmPm(slot);
                    final isSelected = filter.startTime == slot;

                    return InkWell(
                      onTap: () {
                        ref.read(bookingsFilterProvider.notifier).update(
                              (state) => state.copyWith(startTime: slot),
                            );
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? accentColor.withOpacity(0.15) : Colors.transparent,
                          border: Border.all(
                            color: isSelected ? accentColor : Colors.white12,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            formatted,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? accentColor : textColor,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Sport Filter Selection Modal
  void _selectSportFilter(
    BuildContext context,
    WidgetRef ref,
    BookingsFilter filter,
    Color accentColor,
    Color cardColor,
    Color textColor,
  ) {
    final List<String> sports = ['Badminton', 'Tennis', 'Basketball', 'Football'];

    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Sport Type',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sports.length,
                itemBuilder: (context, index) {
                  final sport = sports[index];
                  final isSelected = filter.sportType == sport;

                  return ListTile(
                    title: Text(
                      sport,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? accentColor : textColor,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_circle, color: accentColor)
                        : null,
                    onTap: () {
                      ref.read(bookingsFilterProvider.notifier).update(
                            (state) => state.copyWith(sportType: sport),
                          );
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Time formatter helper
  String _formatToAmPm(String time24) {
    try {
      final parts = time24.split(':');
      final hour = int.parse(parts[0]);
      final minute = parts.length > 1 ? parts[1] : '00';
      final period = hour >= 12 ? 'PM' : 'AM';
      var hour12 = hour % 12;
      if (hour12 == 0) hour12 = 12;
      return '$hour12:$minute $period';
    } catch (e) {
      return time24;
    }
  }

  void _confirmCancellation({
    required BuildContext context,
    required WidgetRef ref,
    required String bookingId,
    required String venueId,
    required String bookingDate,
    required String venueName,
    required String startTime,
  }) async {
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

      final success = await ref.read(bookingActionsProvider.notifier).cancelBooking(
        bookingId: bookingId,
        venueId: venueId,
        date: bookingDate,
        venueName: venueName,
        startTime: startTime,
      );

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
