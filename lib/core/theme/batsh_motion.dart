import 'package:flutter/animation.dart';

/// Premium motion tokens — curated for Apple/Houzz-level tactile feel.
/// Ease-out-quart for entrances, spring for interactions.
class BatshMotion {
  const BatshMotion._();

  // ── Durations ─────────────────────────────────────────────────────────
  static const Duration instant = Duration(milliseconds: 0);
  static const Duration micro = Duration(milliseconds: 80);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration slower = Duration(milliseconds: 600);
  static const Duration pageTransition = Duration(milliseconds: 350);
  static const Duration pageTransitionFast = Duration(milliseconds: 250);
  static const Duration staggerBase = Duration(milliseconds: 60);

  // ── Curves — premium feel ─────────────────────────────────────────────
  /// Smooth ease-out for entrances (quart for premium deceleration)
  static const Curve easeOut = Cubic(0.25, 0.46, 0.45, 0.94);

  /// Fast ease-in for exits
  static const Curve easeIn = Cubic(0.55, 0.06, 0.68, 0.19);

  /// Gentle ease-in-out for transitions
  static const Curve easeInOut = Cubic(0.76, 0, 0.24, 1);

  /// Subtle spring for tap feedback
  static const Curve springTap = Cubic(0.34, 1.56, 0.64, 1);

  /// Elastic out for celebratory moments
  static const Curve springCelebrate = Curves.elasticOut;

  /// Premium deceleration for hero transitions
  static const Curve heroEase = Cubic(0.16, 1, 0.3, 1);

  // ── Stagger helpers ───────────────────────────────────────────────────
  static Duration stagger(int index) =>
      Duration(milliseconds: staggerBase.inMilliseconds * index);
  static Duration staggerClamped(int index, {int max = 6}) =>
      stagger(index.clamp(0, max));

  // ── Reduced motion ────────────────────────────────────────────────────
  static const Duration reduced = Duration(milliseconds: 1);
  static const Curve reducedCurve = Curves.linear;

  static Duration durationFor(bool reduceMotion, Duration normal) =>
      reduceMotion ? reduced : normal;

  static Curve curveFor(bool reduceMotion, Curve normal) =>
      reduceMotion ? reducedCurve : normal;
}
