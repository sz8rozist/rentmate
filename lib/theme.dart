import 'package:flutter/material.dart';

final ThemeData realEstateTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blue.shade700,
    primary: Colors.blue.shade700,
    secondary: Colors.orange.shade600,
    background: Colors.grey.shade50,
    surface: Colors.white,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onBackground: Colors.black87,
    onSurface: Colors.black87,
    brightness: Brightness.light,
  ),
  useMaterial3: true,
  textTheme: TextTheme(
    titleLarge: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
    bodyMedium: TextStyle(fontSize: 16),
  ),

  // AppBar
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.blue.shade700,
    foregroundColor: Colors.white,
    elevation: 4,
  ),

  // Floating Action Button
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: Colors.orange.shade600,
  ),

  // ElevatedButton stílus
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blue.shade700,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ),
  ),

  // OutlinedButton stílus
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: Colors.blue.shade700,
      side: BorderSide(color: Colors.blue.shade700, width: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      textStyle: TextStyle(fontSize: 16),
    ),
  ),

  // TextField stílus
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.grey.shade100,
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
    ),
    hintStyle: TextStyle(color: Colors.grey.shade500),
  ),

  iconTheme: IconThemeData(
    color: Colors.black87,
    size: 24,
  ),

  // Card stílus
  cardTheme: CardThemeData(
    color: Colors.white,
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  ),

  dropdownMenuTheme: DropdownMenuThemeData(
    menuStyle: MenuStyle(
      backgroundColor: MaterialStatePropertyAll(Colors.white),
      surfaceTintColor: MaterialStatePropertyAll(Colors.white),
      shape: MaterialStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    textStyle: TextStyle(fontSize: 16, color: Colors.black87),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade100,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
      ),
    ),
  ),

  expansionTileTheme: ExpansionTileThemeData(
    backgroundColor: Colors.grey.shade100,              // kibontott állapot háttér
    collapsedBackgroundColor: Colors.transparent,        // összecsukott háttér
    textColor: Colors.blue.shade700,                      // kibontott cím szín
    collapsedTextColor: Colors.black87,                   // összecsukott cím szín
    iconColor: Colors.blue.shade700,                      // kibontott ikon szín
    collapsedIconColor: Colors.grey.shade600,             // összecsukott ikon szín
    childrenPadding: EdgeInsets.symmetric(horizontal: 16), // opcionális, a tartalom paddingje
    tilePadding: EdgeInsets.symmetric(horizontal: 16),     // az egész tile paddingje
  ),
);

final ThemeData realEstateDarkTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blue.shade700,
    primary: Colors.blue.shade300,
    secondary: Colors.orange.shade400,
    background: Colors.grey.shade900,
    surface: Colors.grey.shade800,
    onPrimary: Colors.black,
    onSecondary: Colors.black,
    onBackground: Colors.white,
    onSurface: Colors.white,
    brightness: Brightness.dark,
  ),
  useMaterial3: true,
  textTheme: TextTheme(
    titleLarge: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
    bodyMedium: TextStyle(fontSize: 16),
  ),

  appBarTheme: AppBarTheme(
    backgroundColor: Colors.blue.shade700,
    foregroundColor: Colors.white,
    elevation: 4,
  ),

  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: Colors.orange.shade400,
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blue.shade300,
      foregroundColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ),
  ),

  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: Colors.blue.shade300,
      side: BorderSide(color: Colors.blue.shade300, width: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      textStyle: TextStyle(fontSize: 16),
    ),
  ),

  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.grey.shade700,
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade500, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.blue.shade300, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.red.shade400, width: 1),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.red.shade600, width: 2),
    ),
    hintStyle: TextStyle(color: Colors.grey.shade400),
    labelStyle: TextStyle(color: Colors.grey.shade300),
  ),

  iconTheme: IconThemeData(
    color: Colors.white,
    size: 24,
  ),

  cardTheme: CardThemeData(
    color: Colors.grey.shade800,
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  ),

  dropdownMenuTheme: DropdownMenuThemeData(
    menuStyle: MenuStyle(
      backgroundColor: MaterialStatePropertyAll(Colors.grey.shade800),
      surfaceTintColor: MaterialStatePropertyAll(Colors.grey.shade800),
      shape: MaterialStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    textStyle: TextStyle(fontSize: 16, color: Colors.white),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade700,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade500, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade500, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blue.shade300, width: 2),
      ),
    ),
  ),
  expansionTileTheme: ExpansionTileThemeData(
    backgroundColor: Colors.grey.shade800,                // kibontott háttér (sötét)
    collapsedBackgroundColor: Colors.transparent,          // összecsukott háttér (sötét)
    textColor: Colors.blue.shade300,                        // kibontott cím szín (sötét)
    collapsedTextColor: Colors.white70,                     // összecsukott cím szín (sötét)
    iconColor: Colors.blue.shade300,                        // kibontott ikon szín (sötét)
    collapsedIconColor: Colors.grey.shade500,               // összecsukott ikon szín (sötét)
    childrenPadding: EdgeInsets.symmetric(horizontal: 16),
    tilePadding: EdgeInsets.symmetric(horizontal: 16),
  ),

);
