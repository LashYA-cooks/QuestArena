// WHAT THIS FILE DOES:
// Centralizes all text styles using Google Fonts to maintain the "Gaming" aesthetic.
//
// KEY CONCEPTS IN THIS FILE:
// • Typography Hierarchy: Different font weights and sizes for different levels of information.
// • Syne vs Inter: Using a bold, heavy font for scores/headers and a readable sans-serif for body text.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // Display Styles (Scores, Level Up, Game Titles)
  static TextStyle display = GoogleFonts.syne(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );

  static TextStyle headline = GoogleFonts.syne(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  // Body Styles (Main content, Chat, Questions)
  static TextStyle bodyLg = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static TextStyle bodyMd = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  // Label Styles (Captions, Stats, Dates)
  static TextStyle label = GoogleFonts.spaceMono(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.2,
    color: AppColors.textSecondary,
  );
}
