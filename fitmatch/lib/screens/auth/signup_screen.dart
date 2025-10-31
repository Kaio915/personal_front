import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';
import '../../utils/router.dart';

class SignupScreen extends StatefulWidget {
  final String? userType;

  const SignupScreen({super.key, this.userType});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();

  // Common fields
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Trainer fields
  final _specialtyController = TextEditingController();
  final _crefController = TextEditingController();
  final _experienceController = TextEditingController();
  final _bioController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _cityController = TextEditingController();

  // Student fields
  final _goalsController = TextEditingController();
  String _selectedFitnessLevel = 'Iniciante';

  UserType _selectedUserType = UserType.student;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    if (widget.userType != null) {
      _selectedUserType = UserType.fromString(widget.userType!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _specialtyController.dispose();
    _crefController.dispose();
    _experienceController.dispose();
    _bioController.dispose();
    _hourlyRateController.dispose();
    _cityController.dispose();
    _goalsController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    final userData = <String, dynamic>{
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'userType': _selectedUserType.value,
    };

    if (_selectedUserType == UserType.trainer) {
      userData.addAll({
        'specialty': _specialtyController.text.trim(),
        'cref': _crefController.text.trim(),
        'experience': _experienceController.text.trim(),
        'bio': _bioController.text.trim(),
        'hourlyRate': _hourlyRateController.text.trim(),
        'city': _cityController.text.trim(),
      });
    } else if (_selectedUserType == UserType.student) {
      userData.addAll({
        'goals': _goalsController.text.trim(),
        'fitnessLevel': _selectedFitnessLevel,
      });
    }

    print('🔄 Enviando cadastro para o backend...');
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signup(
      userData,
      _passwordController.text,
    );

    print('📊 Resultado do cadastro: success = $success');
    
    if (!mounted) return;

    if (success) {
      // Redirecionar direto para a tela de login específica
      final userTypeParam = _selectedUserType == UserType.student ? 'student' : 'trainer';
      
      print('✅ Cadastro bem-sucedido! Mostrando diálogo de confirmação');
      
      // Mostrar diálogo de sucesso que requer confirmação
      showDialog(
        context: context,
        barrierDismissible: false, // Usuário precisa clicar em OK
        builder: (context) => AlertDialog(
          icon: Icon(
            Icons.check_circle_outline,
            size: 64,
            color: Colors.green.shade600,
          ),
          title: const Text(
            'Cadastro Realizado!',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _selectedUserType == UserType.student 
                  ? 'Seu cadastro como Aluno foi enviado para análise.'
                  : 'Seu cadastro como Personal Trainer foi enviado para análise.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Aguarde a aprovação do administrador para fazer login.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Fecha o diálogo
                  print('🔄 Redirecionando para login tipo: $userTypeParam');
                  context.goToLogin(userType: userTypeParam);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('OK, Entendi'),
              ),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Erro ao fazer cadastro'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _nextPage() {
    // Validar o formulário antes de avançar
    if (!_formKey.currentState!.validate()) {
      print('❌ Validação falhou - não pode avançar');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, corrija os erros antes de continuar'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    print('✅ Validação OK - avançando para próxima página');
    if (_currentPage < 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _handleSignup();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.go('/'),
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'Voltar',
                  ),
                  const Spacer(),
                  Text(
                    'Cadastro',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48), // Balance the back button
                ],
              ),
            ),

            // Progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: LinearProgressIndicator(
                value: (_currentPage + 1) / 2,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),

            // Form content
            Expanded(
              child: Form(
                key: _formKey,
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(), // Impede arrastar entre páginas
                  onPageChanged: (page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  children: [_buildBasicInfoPage(), _buildSpecificInfoPage()],
                ),
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousPage,
                        child: const Text('Anterior'),
                      ),
                    ),
                  if (_currentPage > 0) const SizedBox(width: 16),
                  Expanded(
                    child: Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        return ElevatedButton(
                          onPressed: authProvider.isLoading ? null : _nextPage,
                          child: authProvider.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  _currentPage < 1 ? 'Próximo' : 'Cadastrar',
                                ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Informações Básicas',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Preencha suas informações pessoais',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 32),

          // User type selection
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Eu sou um:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedUserType = UserType.student;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _selectedUserType == UserType.student
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey.shade300,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Icon(
                                  _selectedUserType == UserType.student
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                                  color: _selectedUserType == UserType.student
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Aluno',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                      Text(
                                        'Busco personal trainer',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedUserType = UserType.trainer;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _selectedUserType == UserType.trainer
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey.shade300,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Icon(
                                  _selectedUserType == UserType.trainer
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                                  color: _selectedUserType == UserType.trainer
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Personal Trainer',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                      Text(
                                        'Ofereço serviços',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Name field
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nome Completo',
              hintText: 'Digite seu nome completo',
              prefixIcon: Icon(Icons.person_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Nome é obrigatório';
              }
              if (value.trim().length < 2) {
                return 'Nome deve ter pelo menos 2 caracteres';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

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
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value.trim())) {
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
              hintText: 'Mínimo 8 caracteres',
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
              if (value.length < 8) {
                return 'Senha deve ter no mínimo 8 caracteres';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Confirm password field
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration: InputDecoration(
              labelText: 'Confirmar Senha',
              hintText: 'Digite a senha novamente',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
            ),
            validator: (value) {
              print('🔍 Validando confirmar senha: "$value"');
              print('🔍 Senha original: "${_passwordController.text}"');
              
              if (value == null || value.isEmpty) {
                print('❌ Confirmação vazia');
                return 'Confirmação de senha é obrigatória';
              }
              if (value.length < 8) {
                print('❌ Confirmação menor que 8 caracteres');
                return 'Confirmação deve ter no mínimo 8 caracteres';
              }
              if (value != _passwordController.text) {
                print('❌ Senhas diferentes!');
                return 'As senhas não coincidem';
              }
              print('✅ Senhas coincidem');
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSpecificInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _selectedUserType == UserType.trainer
                ? 'Informações Profissionais'
                : 'Seus Objetivos',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedUserType == UserType.trainer
                ? 'Conte-nos sobre sua experiência e qualificações'
                : 'Ajude-nos a encontrar o personal trainer ideal para você',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 32),

          if (_selectedUserType == UserType.trainer) ..._buildTrainerFields(),
          if (_selectedUserType == UserType.student) ..._buildStudentFields(),

          const SizedBox(height: 32),

          // Terms and conditions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              'Ao se cadastrar, você concorda com nossos Termos de Uso e Política de Privacidade. '
              '${_selectedUserType == UserType.trainer ? 'Seu cadastro passará por análise antes da aprovação.' : ''}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTrainerFields() {
    return [
      // Specialty
      TextFormField(
        controller: _specialtyController,
        decoration: const InputDecoration(
          labelText: 'Especialidade',
          hintText: 'Ex: Musculação, Funcional, Pilates',
          prefixIcon: Icon(Icons.fitness_center),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Especialidade é obrigatória';
          }
          return null;
        },
      ),

      const SizedBox(height: 16),

      // CREF
      TextFormField(
        controller: _crefController,
        decoration: const InputDecoration(
          labelText: 'CREF',
          hintText: 'Número do registro CREF',
          prefixIcon: Icon(Icons.badge_outlined),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'CREF é obrigatório';
          }
          return null;
        },
      ),

      const SizedBox(height: 16),

      // Experience
      TextFormField(
        controller: _experienceController,
        decoration: const InputDecoration(
          labelText: 'Experiência',
          hintText: 'Ex: 5 anos',
          prefixIcon: Icon(Icons.work_outline),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Experiência é obrigatória';
          }
          return null;
        },
      ),

      const SizedBox(height: 16),

      // City
      TextFormField(
        controller: _cityController,
        decoration: const InputDecoration(
          labelText: 'Cidade',
          hintText: 'Ex: São Paulo, SP',
          prefixIcon: Icon(Icons.location_on_outlined),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Cidade é obrigatória';
          }
          return null;
        },
      ),

      const SizedBox(height: 16),

      // Hourly rate
      TextFormField(
        controller: _hourlyRateController,
        decoration: const InputDecoration(
          labelText: 'Valor por Hora',
          hintText: 'Ex: R\$ 80,00',
          prefixIcon: Icon(Icons.monetization_on_outlined),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Valor por hora é obrigatório';
          }
          return null;
        },
      ),

      const SizedBox(height: 16),

      // Bio
      TextFormField(
        controller: _bioController,
        maxLines: 4,
        decoration: const InputDecoration(
          labelText: 'Biografia',
          hintText: 'Conte um pouco sobre você e sua metodologia de trabalho',
          prefixIcon: Icon(Icons.description_outlined),
          alignLabelWithHint: true,
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Biografia é obrigatória';
          }
          return null;
        },
      ),
    ];
  }

  List<Widget> _buildStudentFields() {
    return [
      // Goals
      TextFormField(
        controller: _goalsController,
        maxLines: 3,
        decoration: const InputDecoration(
          labelText: 'Objetivos',
          hintText:
              'Ex: Perder peso, ganhar massa muscular, melhorar condicionamento',
          prefixIcon: Icon(Icons.flag_outlined),
          alignLabelWithHint: true,
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Objetivos são obrigatórios';
          }
          return null;
        },
      ),

      const SizedBox(height: 16),

      // Fitness level
      DropdownButtonFormField<String>(
        initialValue: _selectedFitnessLevel,
        decoration: const InputDecoration(
          labelText: 'Nível de Condicionamento',
          prefixIcon: Icon(Icons.trending_up),
        ),
        items: ['Iniciante', 'Intermediário', 'Avançado']
            .map((level) => DropdownMenuItem(value: level, child: Text(level)))
            .toList(),
        onChanged: (value) {
          setState(() {
            _selectedFitnessLevel = value!;
          });
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Nível de condicionamento é obrigatório';
          }
          return null;
        },
      ),
    ];
  }
}
