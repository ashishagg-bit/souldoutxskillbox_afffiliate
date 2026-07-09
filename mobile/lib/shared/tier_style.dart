import 'package:flutter/material.dart';
import '../core/models/types.dart';

class TierStyle {
  final Color background;
  final Color text;
  final Color solid;

  const TierStyle({required this.background, required this.text, required this.solid});
}

const Map<Tier, TierStyle> tierStyles = {
  Tier.bronze: TierStyle(
    background: Color(0xFFFFF7ED),
    text: Color(0xFFC2410C),
    solid: Color(0xFFC2410C),
  ),
  Tier.silver: TierStyle(
    background: Color(0xFFFFF1F2),
    text: Color(0xFF9F1239),
    solid: Color(0xFF881337),
  ),
  Tier.gold: TierStyle(
    background: Color(0xFFFFFBEB),
    text: Color(0xFFB45309),
    solid: Color(0xFFD97706),
  ),
  Tier.platinum: TierStyle(
    background: Color(0xFFF1F5F9),
    text: Color(0xFF334155),
    solid: Color(0xFF1E293B),
  ),
};
