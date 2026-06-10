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

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Confirm Booking',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Do you want to book ${widget.venue.name} at ${slot.startTime} on ${DateFormat('EEE, MMM d').format(_selectedDate)}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00FF87),
              foregroundColor: const Color(0xFF0F172A),
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
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF00FF87)),
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
              backgroundColor: const Color(0xFF1E293B),
              icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 48),
              title: const Text(
                'Slot Already Taken',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              content: Text(
                result.message,
                style: const TextStyle(color: Colors.white70),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00FF87),
                    foregroundColor: const Color(0xFF0F172A),
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

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: CustomScrollView(
        slivers: [
          // Premium collapsing header with image
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: const Color(0xFF1E293B),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.venue.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
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
                      return Container(color: Colors.white10);
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
                      const Icon(Icons.location_on, color: Colors.white70, size: 20),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.venue.location,
                          style: const TextStyle(fontSize: 14, color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.sports, color: Color(0xFF00FF87), size: 20),
                      const SizedBox(width: 6),
                      Text(
                        widget.venue.sportType,
                        style: const TextStyle(fontSize: 14, color: Color(0xFF00FF87), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white12, height: 32),
                  // Date Picker
                  const Text(
                    'Select Date',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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
                                color: isSelected ? const Color(0xFF00FF87) : const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF00FF87) : Colors.white12,
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
                                      color: isSelected ? const Color(0xFF0F172A) : Colors.white54,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    DateFormat('d').format(date),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? const Color(0xFF0F172A) : Colors.white,
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
                  const Divider(color: Colors.white12, height: 32),
                  const Text(
                    'Select Hourly Slot',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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
                return const SliverFillRemaining(
                  child: Center(
                    child: Text('No slots configured', style: TextStyle(color: Colors.white54)),
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

                      Color cardColor;
                      Color borderColor;
                      Color textColor;
                      Widget suffixWidget = const SizedBox();

                      if (isBookedByMe) {
                        cardColor = const Color(0xFF3B82F6).withOpacity(0.15); // blue
                        borderColor = const Color(0xFF3B82F6);
                        textColor = const Color(0xFF3B82F6);
                        suffixWidget = const Icon(Icons.check_circle, size: 12, color: Color(0xFF3B82F6));
                      } else if (slot.isBooked) {
                        cardColor = Colors.white.withOpacity(0.03);
                        borderColor = Colors.white.withOpacity(0.08);
                        textColor = Colors.white24;
                        suffixWidget = const Icon(Icons.lock, size: 10, color: Colors.white24);
                      } else {
                        // Available
                        cardColor = const Color(0xFF00FF87).withOpacity(0.05);
                        borderColor = const Color(0xFF00FF87).withOpacity(0.4);
                        textColor = const Color(0xFF00FF87);
                      }

                      return InkWell(
                        onTap: slot.isBooked ? null : () => _handleBooking(slot),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor, width: 1.5),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                slot.startTime,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
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
                                      color: textColor.withOpacity(0.8),
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
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF00FF87)),
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
                      const Text(
                        'Failed to load slots',
                        style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(error.toString(), style: const TextStyle(fontSize: 11, color: Colors.white30)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => ref.refresh(slotsProvider(SlotArg(venueId: widget.venue.id, date: dateStr))),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B)),
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
