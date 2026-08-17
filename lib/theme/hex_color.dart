import 'package:flutter/material.dart';

Color hexColor(String value, [Color fallback = const Color(0xFF000000)]) {
  var hex = value.trim().replaceAll('#', '');
  if (hex.length == 3) {
    hex = hex.split('').map((c) => '$c$c').join();
  }
  if (hex.length == 6) hex = 'FF$hex';
  if (hex.length != 8) return fallback;
  return Color(int.tryParse(hex, radix: 16) ?? fallback.toARGB32());
}

String colorToHex(Color color) {
  final value = color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase();
  return '#${value.substring(2)}';
}
