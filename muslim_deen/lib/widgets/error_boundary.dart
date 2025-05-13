import 'package:flutter/material.dart';

/// A widget that catches and displays errors that occur in its child widget tree
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(BuildContext context, dynamic error)? errorBuilder;

  const ErrorBoundary({super.key, required this.child, this.errorBuilder});

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  dynamic _error;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // In a real implementation, you'd listen to global errors
    // This is simplified for analysis

    // If there's an error and we have a custom error builder, use it
    if (_error != null && widget.errorBuilder != null) {
      return widget.errorBuilder!(context, _error!);
    }

    // If there's an error but no custom builder, show a default error UI
    if (_error != null) {
      return Material(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 16),
                Text(
                  _error?.message ?? 'An unknown error occurred',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                if (_error?.details != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _error!.details!,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _error = null;
                    });
                  },
                  child: const Text('Dismiss'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // If no error, just render the child widget
    return widget.child;
  }
}
