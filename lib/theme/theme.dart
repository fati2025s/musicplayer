import 'package:flutter/material.dart';

final Color seed = const Color.fromRGBO(32, 63, 129, 1.0);

final ThemeData appTheme = ThemeData.from(
  colorScheme: ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.light,
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
    bodyMedium: TextStyle(fontSize: 16),
  ),
).copyWith(
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: seed),
    ),
    prefixIconColor: seed,
    suffixIconColor: seed,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: seed,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: seed.withOpacity(0.9),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    behavior: SnackBarBehavior.floating,
    contentTextStyle: const TextStyle(color: Colors.white),
  ),
);