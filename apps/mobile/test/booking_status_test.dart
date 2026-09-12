import 'package:flutter_test/flutter_test.dart';
import 'package:snip_mobile/models/booking.dart';

bool isValidBookingTransition(BookingStatus from, BookingStatus to) {
  if (from == to) return true;
  const allowed = <BookingStatus, Set<BookingStatus>>{
    BookingStatus.pending: {
      BookingStatus.confirmed,
      BookingStatus.cancelled,
    },
    BookingStatus.confirmed: {
      BookingStatus.checkedIn,
      BookingStatus.cancelled,
      BookingStatus.noShow,
    },
    BookingStatus.checkedIn: {
      BookingStatus.inProgress,
      BookingStatus.cancelled,
      BookingStatus.noShow,
    },
    BookingStatus.inProgress: {
      BookingStatus.completed,
      BookingStatus.cancelled,
    },
  };
  return allowed[from]?.contains(to) ?? false;
}

void main() {
  test('allows confirmed to checked_in', () {
    expect(
      isValidBookingTransition(BookingStatus.confirmed, BookingStatus.checkedIn),
      isTrue,
    );
  });

  test('blocks completed to confirmed', () {
    expect(
      isValidBookingTransition(BookingStatus.completed, BookingStatus.confirmed),
      isFalse,
    );
  });
}
