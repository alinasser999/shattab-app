import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/batsh_motion.dart';

/// Standard push: subtle fade + slide-up.
/// Used for most screen-to-screen navigation within tabs.
Page<T> fadeSlidePage<T>(Widget child, GoRouterState state) =>
    CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: BatshMotion.pageTransition,
      reverseTransitionDuration: BatshMotion.fast,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: BatshMotion.easeOut,
          reverseCurve: BatshMotion.easeIn,
        );
        // Reduced motion strips the movement, not the transition. Opacity is
        // not what triggers vestibular symptoms; translation and zoom are, so
        // the fade stays and the travel goes. Returning the child bare would
        // also drop the only cue that the screen changed.
        if (MediaQuery.disableAnimationsOf(context)) {
          return FadeTransition(opacity: curved, child: child);
        }
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.02),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );

/// Modal-style entrance from bottom.
/// Use for full-screen forms, editors, and modals.
Page<T> slideUpPage<T>(Widget child, GoRouterState state) =>
    CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: BatshMotion.slower,
      reverseTransitionDuration: BatshMotion.fast,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: BatshMotion.easeOut,
          reverseCurve: BatshMotion.easeIn,
        );
        // Reduced motion strips the movement, not the transition. Opacity is
        // not what triggers vestibular symptoms; translation and zoom are, so
        // the fade stays and the travel goes. Returning the child bare would
        // also drop the only cue that the screen changed.
        if (MediaQuery.disableAnimationsOf(context)) {
          return FadeTransition(opacity: curved, child: child);
        }
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 0.08),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
    );

/// Minimal zoom-in page transition.
/// Use for rich media (portfolio detail, project detail, photos).
Page<T> zoomInPage<T>(Widget child, GoRouterState state) =>
    CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: BatshMotion.normal,
      reverseTransitionDuration: BatshMotion.fast,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: BatshMotion.easeOut,
          reverseCurve: BatshMotion.easeIn,
        );
        // Reduced motion strips the movement, not the transition. Opacity is
        // not what triggers vestibular symptoms; translation and zoom are, so
        // the fade stays and the travel goes. Returning the child bare would
        // also drop the only cue that the screen changed.
        if (MediaQuery.disableAnimationsOf(context)) {
          return FadeTransition(opacity: curved, child: child);
        }
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
