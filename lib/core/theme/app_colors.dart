import 'package:flutter/material.dart';

import '../../models/mind_orb.dart';

abstract final class AppColors {
  static const spaceBlack = Color(0xFF0B0C10);
  static const deepCharcoal = Color(0xFF1F2833);
  static const starlightWhite = Color(0xFFC5C6C7);
  static const joy = Color(0xFFFFD700);
  static const sadness = Color(0xFF4A90E2);
  static const anger = Color(0xFFE74C3C);
  static const calm = Color(0xFF2ECC71);
  static const anxiety = Color(0xFF9B59B6);

  static Color of(EmotionType emotion) => switch (emotion) {
    EmotionType.joy => joy,
    EmotionType.sadness => sadness,
    EmotionType.anger => anger,
    EmotionType.calm => calm,
    EmotionType.anxiety => anxiety,
  };
}

extension EmotionPresentation on EmotionType {
  String get label => switch (this) {
    EmotionType.joy => '快樂',
    EmotionType.sadness => '悲傷',
    EmotionType.anger => '憤怒',
    EmotionType.calm => '平靜',
    EmotionType.anxiety => '焦慮',
  };

  String get body => switch (this) {
    EmotionType.joy => '恆星',
    EmotionType.sadness => '彗星',
    EmotionType.anger => '超新星',
    EmotionType.calm => '行星',
    EmotionType.anxiety => '星雲',
  };

  String get texture => switch (this) {
    EmotionType.joy => '高亮柔光',
    EmotionType.sadness => '環狀流光',
    EmotionType.anger => '脈衝閃爍',
    EmotionType.calm => '穩定光暈',
    EmotionType.anxiety => '霧狀星雲',
  };

  Color get color => AppColors.of(this);

  Color get onColor =>
      this == EmotionType.joy ? AppColors.spaceBlack : Colors.white;
}
