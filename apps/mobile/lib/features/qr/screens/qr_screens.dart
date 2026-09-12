import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../repositories/booking_repository.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/snip_button.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../../theme/snip_colors.dart';
import '../../../theme/snip_spacing.dart';

final bookingTicketProvider =
    FutureProvider.autoDispose.family((ref, String bookingId) {
  return ref.watch(bookingRepositoryProvider).getBooking(bookingId);
});

class BookingTicketScreen extends ConsumerWidget {
  const BookingTicketScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(bookingTicketProvider(bookingId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking ticket'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/customer/bookings'),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (booking) {
          if (booking == null) {
            return const EmptyState(title: 'Booking not found');
          }
          final date = DateFormat('EEE, MMM d · h:mm a')
              .format(booking.appointmentStart.toLocal());

          return ListView(
            padding: const EdgeInsets.all(SnipSpacing.lg),
            children: [
              Container(
                padding: const EdgeInsets.all(SnipSpacing.lg),
                decoration: BoxDecoration(
                  color: SnipColors.white,
                  borderRadius: BorderRadius.circular(SnipSpacing.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: SnipColors.dark.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    StatusChip(status: booking.status),
                    const SizedBox(height: SnipSpacing.md),
                    Text(
                      booking.serviceName ?? 'Appointment',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: SnipSpacing.xs),
                    Text(
                      booking.salonName ?? '',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: SnipColors.secondaryText,
                          ),
                    ),
                    const SizedBox(height: SnipSpacing.sm),
                    Text(date, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: SnipSpacing.lg),
                    QrImageView(
                      data: booking.qrToken,
                      size: 200,
                      backgroundColor: SnipColors.white,
                    ),
                    const SizedBox(height: SnipSpacing.md),
                    Text(
                      'Show this QR at the salon. Only your check-in token is encoded.',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: SnipSpacing.lg),
              SnipButton(
                label: 'Back to bookings',
                variant: SnipButtonVariant.outline,
                onPressed: () => context.go('/customer/bookings'),
              ),
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
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final raw = barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) return;

    setState(() {
      _handling = true;
      _message = null;
    });

    try {
      final booking =
          await ref.read(bookingRepositoryProvider).checkInWithQr(raw.trim());
      if (!mounted) return;
      setState(() {
        _message =
            'Checked in: ${booking.serviceName ?? booking.id.substring(0, 8)}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_message!)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _message = e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      await Future<void>.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _handling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR ticket')),
      body: Stack(
        children: [
          MobileScanner(onDetect: _onDetect),
          if (_handling)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator()),
            ),
          Positioned(
            left: SnipSpacing.md,
            right: SnipSpacing.md,
            bottom: SnipSpacing.xl,
            child: Container(
              padding: const EdgeInsets.all(SnipSpacing.md),
              decoration: BoxDecoration(
                color: SnipColors.white,
                borderRadius: BorderRadius.circular(SnipSpacing.radiusMd),
              ),
              child: Text(
                _message ?? 'Align the booking QR within the frame',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
