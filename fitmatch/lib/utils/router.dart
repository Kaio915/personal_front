import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/router_refresh_notifier.dart';
import '../screens/home_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/signup_success_screen.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/dashboard/student_dashboard.dart';
import '../screens/dashboard/trainer_dashboard.dart';
import '../screens/dashboard/admin_dashboard.dart';
import '../screens/chat/chat_screen.dart';
import '../models/user.dart';

class AppRouter {
  static String? _lastLoginRoute; // Guardar a rota de login para não perder
  
  static GoRouter createRouter(AuthProvider authProvider) {
    // Criar notifier que controla quando o router deve ser atualizado
    final routerNotifier = RouterRefreshNotifier(authProvider);
    
    return GoRouter(
      initialLocation: '/',
      refreshListenable: routerNotifier, // Usar o wrapper ao invés do authProvider direto
      redirect: (context, state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final user = authProvider.currentUser;
        final isLoading = authProvider.isLoading;
        final isAttemptingLogin = authProvider.isAttemptingLogin;
        
        final currentPath = state.uri.toString();
        
        // Salvar a rota de login se estiver nela
        if (currentPath.startsWith('/login')) {
          _lastLoginRoute = currentPath;
        }
        
        print('🔀 REDIRECT CHECK:');
        print('   Path: $currentPath');
        print('   isAuthenticated: $isAuthenticated');
        print('   isLoading: $isLoading');
        print('   isAttemptingLogin: $isAttemptingLogin');
        
        // Se ainda está carregando OU tentando fazer login, não redirecionar
        if (isLoading || isAttemptingLogin) {
          print('   ❌ Bloqueado por loading/login attempt');
          // Se estiver em home mas tem uma rota de login salva, voltar para ela
          if (currentPath == '/' && _lastLoginRoute != null) {
            print('   ↩️ Restaurando rota de login: $_lastLoginRoute');
            return _lastLoginRoute;
          }
          return null;
        }
        
        // Se não está mais tentando fazer login e está em home, limpar a rota salva
        if (currentPath == '/') {
          _lastLoginRoute = null;
        }
        
        // If not authenticated and trying to access protected routes
        if (!isAuthenticated && _isProtectedRoute(state.uri.toString())) {
          print('   ➡️ Redirecionando para /login (rota protegida)');
          return '/login';
        }
        
        // If authenticated and on login/signup pages, redirect to appropriate dashboard
        if (isAuthenticated && user != null && _isAuthRoute(state.uri.toString())) {
          final dashboard = _getDashboardRoute(user);
          print('   ➡️ Redirecionando para $dashboard (já autenticado)');
          return dashboard;
        }
        
        // If authenticated and on home page, redirect to dashboard
        if (isAuthenticated && user != null && state.uri.toString() == '/') {
          final dashboard = _getDashboardRoute(user);
          print('   ➡️ Redirecionando para $dashboard (home -> dashboard)');
          return dashboard;
        }
        
        print('   ✅ Sem redirecionamento');
        return null;
      },
      routes: [
      // Public routes
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) {
          final userType = state.uri.queryParameters['type'];
          return LoginScreen(userType: userType);
        },
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) {
          final userType = state.uri.queryParameters['type'];
          return SignupScreen(userType: userType);
        },
      ),
      GoRoute(
        path: '/signup-success',
        builder: (context, state) {
          final userType = state.uri.queryParameters['type'] ?? 'student';
          return SignupSuccessScreen(userType: userType);
        },
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) {
          final userType = state.uri.queryParameters['type'];
          return ResetPasswordScreen(userType: userType);
        },
      ),
      
      // Protected routes - Student
      GoRoute(
        path: '/dashboard/student',
        builder: (context, state) => const StudentDashboard(),
      ),
      
      // Protected routes - Trainer
      GoRoute(
        path: '/dashboard/trainer',
        builder: (context, state) => const TrainerDashboard(),
      ),
      
      // Protected routes - Admin
      GoRoute(
        path: '/dashboard/admin',
        builder: (context, state) => const AdminDashboard(),
      ),
      
      // Chat routes
      GoRoute(
        path: '/chat/:otherUserId',
        builder: (context, state) {
          final otherUserId = state.pathParameters['otherUserId']!;
          return ChatScreen(otherUserId: otherUserId);
        },
      ),
    ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Página não encontrada',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                state.error?.toString() ?? 'Erro desconhecido',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('Voltar ao Início'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static bool _isProtectedRoute(String path) {
    return path.startsWith('/dashboard') || path.startsWith('/chat');
  }

  static bool _isAuthRoute(String path) {
    return path == '/login' || path == '/signup';
  }

  static String _getDashboardRoute(User user) {
    switch (user.userType) {
      case UserType.admin:
        return '/dashboard/admin';
      case UserType.trainer:
        return '/dashboard/trainer';
      case UserType.student:
        return '/dashboard/student';
    }
  }
}

// Extension for easy navigation
extension AppRouterExtension on BuildContext {
  void goToLogin({String? userType}) {
    if (userType != null) {
      go('/login?type=$userType');
    } else {
      go('/login');
    }
  }

  void goToSignup({String? userType}) {
    if (userType != null) {
      go('/signup?type=$userType');
    } else {
      go('/signup');
    }
  }

  void goToChat(String otherUserId) {
    go('/chat/$otherUserId');
  }

  void goToDashboard() {
    final authProvider = Provider.of<AuthProvider>(this, listen: false);
    final user = authProvider.currentUser;
    if (user != null) {
      go(AppRouter._getDashboardRoute(user));
    }
  }
}
