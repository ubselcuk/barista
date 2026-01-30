import 'package:flutter/widgets.dart';

extension BuildContextExtensions on BuildContext {
  PageRoute<T> _fadeRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      settings: RouteSettings(name: page.runtimeType.toString()),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(opacity: animation, child: child),
    );
  }

  Future<T?> push<T>(Widget page) => Navigator.of(this).push<T>(_fadeRoute(page));
  Future<T?> replace<T, TO extends Object?>(Widget page, {TO? result}) => Navigator.of(this).pushReplacement<T, TO>(_fadeRoute(page), result: result);
  Future<T?> rebase<T>(Widget page) => Navigator.of(this).pushAndRemoveUntil<T>(_fadeRoute(page), (route) => false);
  void pop<T extends Object?>([T? result]) => Navigator.of(this).pop<T>(result);
}
