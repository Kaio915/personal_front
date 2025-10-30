import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'utils/theme.dart';
import 'utils/router.dart';
import 'providers/auth_provider.dart';
import 'providers/connection_provider.dart';
import 'providers/chat_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
