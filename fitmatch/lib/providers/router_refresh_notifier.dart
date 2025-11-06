import 'package:flutter/foundation.dart';
import 'auth_provider.dart';

/// Wrapper que controla quando o GoRouter deve ser notificado
/// Isso evita redirects indesejados durante operações de login
class RouterRefreshNotifier extends ChangeNotifier {
  final AuthProvider authProvider;
  bool _shouldNotifyRouter = true;

  RouterRefreshNotifier(this.authProvider) {
    authProvider.addListener(_onAuthProviderChange);
  }

  void _onAuthProviderChange() {
    // Só notifica o router se:
    // 1. Não estiver tentando fazer login
    // 2. O estado de autenticação mudou (login bem-sucedido ou logout)
    if (_shouldNotifyRouter && !authProvider.isAttemptingLogin) {
      print('📡 RouterRefreshNotifier - Notificando GoRouter');
      notifyListeners();
    } else {
      print('🚫 RouterRefreshNotifier - Bloqueando notificação do GoRouter');
    }
  }

  bool get isAuthenticated => authProvider.isAuthenticated;
  bool get isLoading => authProvider.isLoading;

  void pauseRouterNotifications() {
    _shouldNotifyRouter = false;
    print('⏸️ RouterRefreshNotifier - Pausando notificações');
  }

  void resumeRouterNotifications() {
    _shouldNotifyRouter = true;
    print('▶️ RouterRefreshNotifier - Resumindo notificações');
  }

  @override
  void dispose() {
    authProvider.removeListener(_onAuthProviderChange);
    super.dispose();
  }
}
