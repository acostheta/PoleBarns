import 'package:flutter/material.dart';

class AppStyles {
  // Primary Orange Color
  static const Color primaryOrange = Color(0xFFD97706);

  // Label and Text Colors
  static const Color labelColor = Color(0xFF374151);
  static const Color subLabelColor = Color(0xFF6B7280);
  static const Color titleColor = Color(0xFF111827);

  // Form Field Decoration
  static InputDecoration inputDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
      fillColor: const Color(0xFFF9FAFB),
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryOrange, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
    );
  }

  // Button Style
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryOrange,
    foregroundColor: Colors.white,
    elevation: 0,
    padding: const EdgeInsets.symmetric(vertical: 18),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.5,
    ),
  );

  // Dialog Title Style
  static const TextStyle dialogTitleStyle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: titleColor,
  );

  // Form Label Style
  static const TextStyle labelStyle = TextStyle(
    fontWeight: FontWeight.w500,
    fontSize: 14,
    color: labelColor,
  );
}
