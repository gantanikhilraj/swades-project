import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/venue.dart';
import '../models/slot.dart';
import '../providers/booking_provider.dart';
import '../providers/auth_provider.dart';

class VenueDetailsScreen extends ConsumerStatefulWidget {
  final Venue venue;

  const VenueDetailsScreen({super.key, required this.venue});

  @override
  ConsumerState<VenueDetailsScreen> createState() => _VenueDetailsScreenState();
}

class _VenueDetailsScreenState extends ConsumerState<VenueDetailsScreen> {
  late DateTime _selectedDate;
  final List<DateTime> _dates = [];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    // Generate next 7 days for booking
    for (int i = 0; i < 7; i++) {
      _dates.add(DateTime.now().add(Duration(days: i)));
    }
  }

  String _formatDate(DateTime dt) {
    return DateFormat('yyyy-MM-dd').format(dt);
  }

  void _handleBooking(Slot slot) async {
    final dateStr = _formatDate(_selectedDate);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final textMutedColor = isDark ? Colors.white70 : const Color(0xFF475569);
    final textLightMutedColor = isDark ? Colors.white38 : const Color(0xFF94A3B8);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final accentColor = isDark ? const Color(0xFF00FF87) : Theme.of(context).primaryColor;

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Confirm Booking',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Do you want to book ${widget.venue.name} at ${slot.startTime} on ${DateFormat('EEE, MMM d').format(_selectedDate)}?',
          style: TextStyle(color: textMutedColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: textLightMutedColor)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
            ),
            child: const Text('Book Now'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Show loading indicator overlay
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(color: accentColor),
        ),
      );

      final result = await ref.read(bookingActionsProvider.notifier).bookSlot(
            venueId: widget.venue.id,
            date: dateStr,
            startTime: slot.startTime,
          );

      // Dismiss loading dialog
      if (mounted) Navigator.pop(context);

      // Show result message
      if (mounted) {
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Display a prominent dialog for double-booking collision
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 48),
              title: Text(
                'Slot Already Taken',
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
              ),
              content: Text(
                result.message,
                style: TextStyle(color: textMutedColor),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                  ),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = _formatDate(_selectedDate);
    final slotsAsync = ref.watch(slotsProvider(SlotArg(venueId: widget.venue.id, date: dateStr)));
    final currentUser = ref.watch(currentUserProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final textMutedColor = isDark ? Colors.white70 : const Color(0xFF475569);
    final textLightMutedColor = isDark ? Colors.white38 : const Color(0xFF94A3B8);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final dividerColor = isDark ? Colors.white12 : Colors.black12;
    final accentColor = isDark ? const Color(0xFF00FF87) : Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Premium collapsing header with image
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.venue.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(1, 1))],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.venue.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(color: cardColor);
                    },
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black87],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location details
                  Row(
                    children: [
                      Icon(Icons.location_on, color: textMutedColor, size: 20),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.venue.location,
                          style: TextStyle(fontSize: 14, color: textMutedColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.sports, color: accentColor, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        widget.venue.sportType,
                        style: TextStyle(fontSize: 14, color: accentColor, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Divider(color: dividerColor, height: 32),
                  // Date Picker
                  Text(
                    'Select Date',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _dates.length,
                      itemBuilder: (context, index) {
                        final date = _dates[index];
                        final isSelected = DateUtils.isSameDay(date, _selectedDate);
                        return Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedDate = date;
                              });
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: 65,
                              decoration: BoxDecoration(
                                color: isSelected ? accentColor : cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? accentColor : dividerColor,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    DateFormat('EEE').format(date).toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                                          : textMutedColor,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    DateFormat('d').format(date),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                                          : textColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Divider(color: dividerColor, height: 32),
                  Text(
                    'Select Hourly Slot',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          // Hourly grid layout
          slotsAsync.when(
            data: (slots) {
              if (slots.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Text('No slots configured', style: TextStyle(color: textMutedColor)),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.8,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final slot = slots[index];
                      final isBookedByMe = slot.isBooked && currentUser != null && slot.userId == currentUser.id;

                      Color gridCardColor;
                      Color gridBorderColor;
                      Color gridTextColor;
                      Widget suffixWidget = const SizedBox();

                      if (isBookedByMe) {
                        gridCardColor = const Color(0xFF3B82F6).withOpacity(0.15); // blue
                        gridBorderColor = const Color(0xFF3B82F6);
                        gridTextColor = const Color(0xFF3B82F6);
                        suffixWidget = const Icon(Icons.check_circle, size: 12, color: Color(0xFF3B82F6));
                      } else if (slot.isBooked) {
                        gridCardColor = isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03);
                        gridBorderColor = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);
                        gridTextColor = isDark ? Colors.white24 : Colors.black26;
                        suffixWidget = Icon(Icons.lock, size: 10, color: isDark ? Colors.white24 : Colors.black26);
                      } else {
                        // Available
                        gridCardColor = accentColor.withOpacity(0.05);
                        gridBorderColor = accentColor.withOpacity(0.4);
                        gridTextColor = accentColor;
                      }

                      return InkWell(
                        onTap: slot.isBooked ? null : () => _handleBooking(slot),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: gridCardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: gridBorderColor, width: 1.5),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                slot.startTime,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: gridTextColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    isBookedByMe
                                        ? 'Mine'
                                        : slot.isBooked
                                            ? 'Taken'
                                            : 'Book',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: gridTextColor.withOpacity(0.8),
                                    ),
                                  ),
                                  if (isBookedByMe || slot.isBooked) ...[
                                    const SizedBox(width: 4),
                                    suffixWidget
                                  ]
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: slots.length,
                  ),
                ),
              );
            },
            loading: () => SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: accentColor),
              ),
            ),
            error: (error, stackTrace) => SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                      const SizedBox(height: 12),
                      Text(
                        'Failed to load slots',
                        style: TextStyle(color: textMutedColor, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(error.toString(), style: TextStyle(fontSize: 11, color: textLightMutedColor)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => ref.refresh(slotsProvider(SlotArg(venueId: widget.venue.id, date: dateStr))),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cardColor,
                          foregroundColor: textColor,
                          elevation: isDark ? 2 : 0,
                          side: isDark ? BorderSide.none : BorderSide(color: dividerColor),
                        ),
                        child: const Text('Retry'),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 40),
          ),
        ],
      ),
    );
  }
}
