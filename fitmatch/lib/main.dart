import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'utils/theme.dart';
import 'utils/router.dart';
import 'providers/auth_provider.dart';
import 'providers/connection_provider.dart';
import 'providers/chat_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Global error handling to avoid the red error overlay for uncaught async
  // exceptions during development. We still log the error so it can be
  // diagnosed in the console.
  FlutterError.onError = (FlutterErrorDetails details) {
    // Forward Flutter framework errors to the current zone.
    Zone.current.handleUncaughtError(details.exception, details.stack ?? StackTrace.current);
  };

  // Catch errors that escape the Flutter framework (Dart async errors).
  runZonedGuarded(() {
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => ConnectionProvider()),
          ChangeNotifierProvider(create: (_) => ChatProvider()),
        ],
        child: const FitMatchApp(),
      ),
    );
  }, (error, stack) {
    // Log uncaught errors. You can extend this to report errors to a
    // remote logging service during development if needed.
    // Keep the log concise so it's easy to spot in the terminal/browser console.
    // NOTE: this prevents the red overlay from being shown; the underlying
    // network issue should still be investigated with browser Network tab
    // and backend logs.
    debugPrint('Unhandled error (caught by runZonedGuarded): $error');
    debugPrint('$stack');
  });
}

class FitMatchApp extends StatefulWidget {
  const FitMatchApp({super.key});

  @override
  State<FitMatchApp> createState() => _FitMatchAppState();
}

class _FitMatchAppState extends State<FitMatchApp> {
  @override
  void initState() {
    super.initState();
    // Initialize providers after the widget tree is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return MaterialApp.router(
          title: 'FitConnect',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          routerConfig: AppRouter.router,
        );
      },
    );
  }
}
