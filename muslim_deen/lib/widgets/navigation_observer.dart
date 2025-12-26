import 'package:flutter/material.dart';
import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/logger_service.dart';

class AppNavigationObserver extends NavigatorObserver {
  final LoggerService _logger = locator<LoggerService>();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _logger.logNavigation(
      'didPush',
      routeName: route.settings.name ?? 'unknown',
      params: route.settings.arguments as Map<String, dynamic>?,
      details: 'from ${previousRoute?.settings.name ?? 'unknown'}',
    );
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _logger.logNavigation(
      'didPop',
      routeName: previousRoute?.settings.name ?? 'unknown',
      params: previousRoute?.settings.arguments as Map<String, dynamic>?,
      details: 'popped ${route.settings.name ?? 'unknown'}',
    );
    super.didPop(route, previousRoute);
  }
}
