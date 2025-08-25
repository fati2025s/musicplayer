import 'package:flutter/material.dart';

final Color seed = const Color.fromRGBO(32, 63, 129, 1.0);

final ThemeData lightTheme = ThemeData.from(
  colorScheme: ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.light,
  ),
);


final ThemeData darkTheme = ThemeData.from(
  colorScheme: ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.dark,
  ),
);
