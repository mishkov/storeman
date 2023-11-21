import 'dart:math';

import 'package:flutter/material.dart';

class ColorGenerator {
  static final List<Color> _colorPalette = [
    Colors.blue,
    Colors.green,
    Colors.red,
    Colors.yellow,
    Colors.orange,
    Colors.purple,
    Colors.amber,
    Colors.brown,
  ];

  static Color next() {
    final Random random = Random();
    final int previousIndex = random.nextInt(_colorPalette.length);
    final int nextIndex = (previousIndex + 1) % _colorPalette.length;
    return _colorPalette[nextIndex];
  }
}
