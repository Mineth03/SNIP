import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../repositories/booking_repository.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/snip_avatar.dart';
import '../../../shared/widgets/snip_button.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../../theme/snip_colors.dart';
import '../../../theme/snip_spacing.dart';

final bookingTicketProvider =
    FutureProvider.autoDispose.family((ref, String bookingId) {
  return ref.watch(bookingRepositoryProvider).getBooking(bookingId);
});

class BookingTicketScreen extends ConsumerStatefulWidget {
  const BookingTicketScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  ConsumerState<BookingTicketScreen> createState() =>
      _BookingTicketScreenState();
}

class _BookingTicketScreenState extends ConsumerState<BookingTicketScreen> {
  int _tab = 0; // 0 = Upcoming, 1 = Past

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(bookingTicketProvider(widget.bookingId));

    return Scaffold(
      backgroundColor: SnipColors.background,
      appBar: AppBar(
        backgroundColor: SnipColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.go('/customer/bookings'),
        ),
        title: const Text(
          'My Booking',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: SnipColors.dark,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: SnipColors.primary),
        ),
        error: (e, _) => Center(child: Text('$e')),
        data: (booking) {
          if (booking == null) {
            return const EmptyState(title: 'Booking not found');
          }

          final dateStr = DateFormat('EEEE, MMM d · h:mm a')
              .format(booking.appointmentStart.toLocal());
          final timeStr = DateFormat('h:mm a')
              .format(booking.appointmentStart.toLocal());
          final dayStr = DateFormat('MMM d')
              .format(booking.appointmentStart.toLocal());
          final isToday = booking.appointmentStart.day == DateTime.now().day;
          final headerDate = '${isToday ? "Today" : dayStr}, $timeStr';

          final ticketCode =
              'SNIP${booking.qrToken.replaceAll("-", "").substring(0, 6).toUpperCase()}';

          return ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: SnipSpacing.md,
              vertical: SnipSpacing.sm,
            ),
            children: [
              // Segmented toggle: Upcoming / Past
              Container(
                decoration: BoxDecoration(
                  color: SnipColors.white,
                  borderRadius: BorderRadius.circular(SnipSpacing.radiusPill),
                  border: Border.all(color: SnipColors.border),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _tab = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _tab == 0
                                ? SnipColors.primary
                                : Colors.transparent,
                            borderRadius:
                                BorderRadius.circular(SnipSpacing.radiusPill),
                          ),
                          child: Center(
                            child: Text(
                              'Upcoming',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _tab == 0
                                    ? SnipColors.white
                                    : SnipColors.secondaryText,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _tab = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _tab == 1
                                ? SnipColors.primary
                                : Colors.transparent,
                            borderRadius:
                                BorderRadius.circular(SnipSpacing.radiusPill),
                          ),
                          child: Center(
                            child: Text(
                              'Past',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _tab == 1
                                    ? SnipColors.white
                                    : SnipColors.secondaryText,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: SnipSpacing.md),

              // Main Ticket Card
              Container(
                decoration: BoxDecoration(
                  color: SnipColors.white,
                  borderRadius: BorderRadius.circular(SnipSpacing.radiusLg),
                  border: Border.all(color: SnipColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: SnipColors.dark.withValues(alpha: 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header row: Date & status
                    Padding(
                      padding: const EdgeInsets.all(SnipSpacing.md),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                size: 16,
                                color: SnipColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                headerDate,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: SnipColors.dark,
                                ),
                              ),
                            ],
                          ),
                          StatusChip(status: booking.status),
                        ],
                      ),
                    ),

                    const Divider(),

                    // Salon info row
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SnipSpacing.md,
                        vertical: SnipSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: SnipColors.primaryMuted,
                              borderRadius:
                                  BorderRadius.circular(SnipSpacing.radiusSm),
                            ),
                            child: const Icon(
                              Icons.storefront_rounded,
                              color: SnipColors.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  booking.salonName ?? 'The Modern Cut',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: SnipColors.dark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Colombo 05',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: SnipColors.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Service & Stylist info row
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SnipSpacing.md,
                        vertical: SnipSpacing.xs,
                      ),
                      child: Row(
                        children: [
                          SnipAvatar(
                            name: booking.barberName ?? 'Kamal',
                            size: 44,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${booking.serviceName ?? "Men's Haircut"} with ${booking.barberName ?? "Kamal"}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: SnipColors.dark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  dateStr,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: SnipColors.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'LKR ${booking.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: SnipColors.dark,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: SnipSpacing.sm),
                    const Divider(),
                    const SizedBox(height: SnipSpacing.md),

                    // QR Code
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: SnipColors.white,
                          borderRadius:
                              BorderRadius.circular(SnipSpacing.radiusMd),
                          border: Border.all(color: SnipColors.border),
                        ),
                        child: QrImageView(
                          data: booking.qrToken,
                          size: 170,
                          backgroundColor: SnipColors.white,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: SnipColors.dark,
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: SnipColors.dark,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: SnipSpacing.sm),

                    // Ticket code
                    Text(
                      ticketCode,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.0,
                        color: SnipColors.dark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Show this QR code at the salon for check-in',
                      style: TextStyle(
                        fontSize: 12,
                        color: SnipColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: SnipSpacing.lg),
                  ],
                ),
              ),

              const SizedBox(height: SnipSpacing.lg),

              // Action buttons: Add to Calendar & Reschedule
              SnipButton(
                label: 'Add to Calendar',
                icon: Icons.calendar_month_rounded,
                variant: SnipButtonVariant.secondary,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Added to calendar')),
                  );
                },
              ),
              const SizedBox(height: SnipSpacing.sm),
              SnipButton(
                label: 'Reschedule',
                icon: Icons.refresh_rounded,
                variant: SnipButtonVariant.outline,
                onPressed: () {
                  context.go('/customer/bookings');
                },
              ),
              const SizedBox(height: SnipSpacing.lg),
            ],
          );
        },
      ),
    );
  }
}

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  bool _handling = false;
  String? _message;

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handling) return;
    final barcode = capture.barcodes.firstOrNull?.rawValue;
    if (barcode == null) return;

    setState(() {
      _handling = true;
      _message = 'Validating check-in...';
    });

    try {
      final booking =
          await ref.read(bookingRepositoryProvider).checkInWithQr(barcode);
      if (!mounted) return;
      setState(() {
        _message =
            'Check-in successful!\nBooking ${booking.id.substring(0, 8)} confirmed.';
      });
      await Future<void>.delayed(const Duration(seconds: 2));
      if (mounted) context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _message = 'Error: $e';
      });
      await Future<void>.delayed(const Duration(seconds: 3));
      if (mounted) setState(() => _handling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR ticket'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(onDetect: _onDetect),
          if (_message != null)
            Positioned(
              left: SnipSpacing.md,
              right: SnipSpacing.md,
              bottom: SnipSpacing.xl,
              child: Container(
                padding: const EdgeInsets.all(SnipSpacing.md),
                decoration: BoxDecoration(
                  color: SnipColors.dark.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(SnipSpacing.radiusMd),
                ),
                child: Text(
                  _message!,
                  style: const TextStyle(color: SnipColors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
