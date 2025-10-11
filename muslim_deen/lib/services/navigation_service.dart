import 'package:flutter/material.dart';
import 'package:muslim_deen/services/logger_service.dart';

/// Centralized navigation service for consistent routing throughout the app
class NavigationService {
  static NavigationService? _instance;
  final LoggerService _logger = LoggerService();

  factory NavigationService() {
    _instance ??= NavigationService._internal();
    return _instance!;
  }

  NavigationService._internal();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<T?> navigateTo<T>(Widget page, {String? routeName}) async {
    final context = navigatorKey.currentContext;
    if (context == null) {
      _logger.error('Navigation failed: No context available');
      return null;
    }

    _logger.logNavigation(
      'Push',
      routeName: routeName ?? page.runtimeType.toString(),
    );

    try {
      return await Navigator.push<T>(
        context,
        MaterialPageRoute(builder: (_) => page),
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Navigation error',
        error: e,
        stackTrace: stackTrace,
        data: {'route': routeName ?? page.runtimeType.toString()},
      );
      return null;
    }
  }

  void goBack<T>([T? result]) {
    final context = navigatorKey.currentContext;
    if (context == null || !Navigator.canPop(context)) {
      _logger.warning('Cannot go back: No context or cannot pop');
      return;
    }

    _logger.logNavigation('Pop');
    Navigator.pop(context, result);
  }

  Future<T?> navigateAndReplace<T>(Widget page, {String? routeName}) async {
    final context = navigatorKey.currentContext;
    if (context == null) {
      _logger.error('Navigation failed: No context available');
      return null;
    }

    _logger.logNavigation(
      'Replace',
      routeName: routeName ?? page.runtimeType.toString(),
    );

    try {
      return await Navigator.pushReplacement<T, void>(
        context,
        MaterialPageRoute(builder: (_) => page),
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Navigation error',
        error: e,
        stackTrace: stackTrace,
        data: {'route': routeName ?? page.runtimeType.toString()},
      );
      return null;
    }
  }

  Future<T?> navigateAndRemoveUntil<T>(
    Widget page, {
    String? routeName,
    bool Function(Route<dynamic>)? predicate,
  }) async {
    final context = navigatorKey.currentContext;
    if (context == null) {
      _logger.error('Navigation failed: No context available');
      return null;
    }

    _logger.logNavigation(
      'PushAndRemoveUntil',
      routeName: routeName ?? page.runtimeType.toString(),
    );

    try {
      return await Navigator.pushAndRemoveUntil<T>(
        context,
        MaterialPageRoute(builder: (_) => page),
        predicate ?? (route) => false,
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Navigation error',
        error: e,
        stackTrace: stackTrace,
        data: {'route': routeName ?? page.runtimeType.toString()},
      );
      return null;
    }
  }

  void popUntil(bool Function(Route<dynamic>) predicate) {
    final context = navigatorKey.currentContext;
    if (context == null) {
      _logger.warning('Cannot pop until: No context available');
      return;
    }

    _logger.logNavigation('PopUntil');
    Navigator.popUntil(context, predicate);
  }

  bool canPop() {
    final context = navigatorKey.currentContext;
    if (context == null) return false;
    return Navigator.canPop(context);
  }
}
