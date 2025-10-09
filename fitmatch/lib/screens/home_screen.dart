import 'package:flutter/material.dart';
import '../utils/router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.fitness_center,
                            size: 32,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'FitConnect',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {
                          context.goToLogin();
                        },
                        child: const Text('Entrar'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Hero Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).colorScheme.surface,
                    Colors.grey.shade50,
                  ],
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Text(
                    'Conecte-se com os Melhores Personal Trainers',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'A plataforma que une profissionais de educação física qualificados com alunos em busca de resultados reais',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          context.goToLogin(userType: 'student');
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                        child: const Text('Login como Aluno'),
                      ),
                      OutlinedButton(
                        onPressed: () {
                          context.goToLogin(userType: 'trainer');
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                        child: const Text('Login como Personal Trainer'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),

            // Features Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 768) {
                        // Desktop layout
                        return Row(
                          children: [
                            Expanded(
                              child: _buildFeatureCard(
                                context,
                                Icons.search,
                                'Busca Inteligente',
                                'Encontre personal trainers por especialidade, localização e disponibilidade',
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: _buildFeatureCard(
                                context,
                                Icons.people,
                                'Conexão Direta',
                                'Conecte-se diretamente com profissionais qualificados e certificados',
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: _buildFeatureCard(
                                context,
                                Icons.trending_up,
                                'Acompanhamento',
                                'Gerencie suas conexões e acompanhe seu progresso em um só lugar',
                              ),
                            ),
                          ],
                        );
                      } else {
                        // Mobile layout
                        return Column(
                          children: [
                            _buildFeatureCard(
                              context,
                              Icons.search,
                              'Busca Inteligente',
                              'Encontre personal trainers por especialidade, localização e disponibilidade',
                            ),
                            const SizedBox(height: 24),
                            _buildFeatureCard(
                              context,
                              Icons.people,
                              'Conexão Direta',
                              'Conecte-se diretamente com profissionais qualificados e certificados',
                            ),
                            const SizedBox(height: 24),
                            _buildFeatureCard(
                              context,
                              Icons.trending_up,
                              'Acompanhamento',
                              'Gerencie suas conexões e acompanhe seu progresso em um só lugar',
                            ),
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),

            // CTA Section
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(32.0),
              padding: const EdgeInsets.all(32.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    'Pronto para começar?',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Cadastre-se agora e dê o primeiro passo para alcançar seus objetivos',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onPrimary.withValues(alpha: 0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      context.goToSignup();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    child: const Text('Criar Conta Gratuita'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
