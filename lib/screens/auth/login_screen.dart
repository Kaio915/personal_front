import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';

class LoginScreen extends StatefulWidget {
  final String? userType;

  const LoginScreen({super.key, this.userType});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoggingIn = false; // Flag local para controlar loading

  @override
  void initState() {
    super.initState();
    print('🔍 LoginScreen iniciada com userType: ${widget.userType}');
    
    // Limpar os campos quando a tela for carregada
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _emailController.clear();
      _passwordController.clear();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoggingIn) return; // Previne múltiplas tentativas

    setState(() {
      _isLoggingIn = true;
    });

    // Capturar o ScaffoldMessenger antes do await para evitar problemas com contexto desmontado
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      final success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
        userType: widget.userType, // Passa o tipo de usuário para validação
      );

      if (!mounted) return;

      if (success) {
        context.goToDashboard();
      } else {
        // Mostra erro mas NÃO volta para tela anterior
        // Limpa o campo de senha para segurança
        _passwordController.clear();
        
        setState(() {
          _isLoggingIn = false;
        });
        
        // Reseta a flag de tentativa de login para permitir navegação novamente
        authProvider.resetLoginAttempt();
        
        // Usa o ScaffoldMessenger capturado antes do await
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    authProvider.errorMessage ?? 'Email ou senha incorretos',
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _passwordController.clear();
        setState(() {
          _isLoggingIn = false;
        });
        
        // Reseta a flag de tentativa de login
        authProvider.resetLoginAttempt();
      }
      
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Erro ao fazer login: $e',
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Back button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () {
                        print('🔙 BOTÃO VOLTAR clicado - navegando para /');
                        // Resetar a flag de login antes de navegar
                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                        authProvider.resetLoginAttempt();
                        context.go('/');
                      },
                      icon: const Icon(Icons.arrow_back),
                      tooltip: 'Voltar',
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Logo and title
                  Icon(
                    widget.userType == 'student' 
                        ? Icons.school
                        : widget.userType == 'trainer'
                            ? Icons.fitness_center
                            : Icons.fitness_center,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  
                  // Badge de tipo de usuário
                  if (widget.userType != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: widget.userType == 'student' 
                            ? Colors.blue.shade100 
                            : Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.userType == 'student' ? '🎓 ALUNO' : '💪 PERSONAL TRAINER',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: widget.userType == 'student' 
                              ? Colors.blue.shade900 
                              : Colors.orange.shade900,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  
                  Text(
                    widget.userType == 'student' 
                        ? 'Login como Aluno'
                        : widget.userType == 'trainer'
                            ? 'Login como Personal Trainer'
                            : 'Entrar',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Acesse sua conta FitConnect',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Login form
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Email field
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                hintText: 'seu@email.com',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Email é obrigatório';
                                }
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                    .hasMatch(value.trim())) {
                                  return 'Email inválido';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // Password field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Senha',
                                hintText: 'Sua senha',
                                prefixIcon: const Icon(Icons.lock_outlined),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Senha é obrigatória';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 24),

                            // Login button
                            ElevatedButton(
                              onPressed: _isLoggingIn ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: _isLoggingIn
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text('Entrar'),
                            ),

                            const SizedBox(height: 12),

                            // Forgot password link
                            TextButton(
                              onPressed: () => context.go('/reset-password?type=${widget.userType ?? 'student'}'),
                              child: Text(
                                'Esqueceu sua senha?',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontSize: 14,
                                ),
                              ),
                            ),

                            const SizedBox(height: 4),

                            // Error message
                            Consumer<AuthProvider>(
                              builder: (context, authProvider, child) {
                                if (authProvider.errorMessage != null) {
                                  return Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.red.shade200),
                                    ),
                                    child: Text(
                                      authProvider.errorMessage!,
                                      style: TextStyle(
                                        color: Colors.red.shade700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Sign up link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Não tem uma conta? ',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () => context.goToSignup(userType: widget.userType),
                        child: const Text('Cadastre-se'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Extension to add navigation methods
extension on BuildContext {
  void goToDashboard() {
    final authProvider = Provider.of<AuthProvider>(this, listen: false);
    final user = authProvider.currentUser;
    if (user != null) {
      switch (user.userType) {
        case UserType.admin:
          go('/dashboard/admin');
          break;
        case UserType.trainer:
          go('/dashboard/trainer');
          break;
        case UserType.student:
          go('/dashboard/student');
          break;
      }
    }
  }

  void goToSignup({String? userType}) {
    if (userType != null) {
      go('/signup?type=$userType');
    } else {
      go('/signup');
    }
  }
}
