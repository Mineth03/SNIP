import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snip_mobile/theme/snip_colors.dart';

void main() {
  test('SNIP brand primary color matches kit', () {
    expect(SnipColors.primary, const Color(0xFF1488A6));
    expect(SnipColors.dark, const Color(0xFF0F172A));
  });
}
