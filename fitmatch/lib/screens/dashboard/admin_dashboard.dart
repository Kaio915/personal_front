import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../models/pending_registration.dart';
import '../../models/user.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with TickerProviderStateMixin {
  late TabController _tabController;
  List<PendingRegistration> _pendingRegistrations = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPendingRegistrations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPendingRegistrations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Mock pending registrations - in a real app this would come from a service
      await Future.delayed(const Duration(milliseconds: 500));
      
      _pendingRegistrations = [
        PendingRegistration(
          id: '1',
          name: 'João Silva',
          email: 'joao.silva@email.com',
          userType: UserType.trainer,
          password: 'temp123',
          registrationDate: DateTime.now().subtract(const Duration(days: 2)),
          specialty: 'Musculação',
          cref: '123456-G/SP',
          experience: '5 anos',
          bio: 'Personal trainer especializado em hipertrofia e condicionamento físico.',
          hourlyRate: 'R\$ 80,00',
          city: 'São Paulo, SP',
        ),
        PendingRegistration(
          id: '2',
          name: 'Maria Santos',
          email: 'maria.santos@email.com',
          userType: UserType.trainer,
          password: 'temp456',
          registrationDate: DateTime.now().subtract(const Duration(days: 1)),
          specialty: 'Funcional',
          cref: '789012-G/RJ',
          experience: '3 anos',
          bio: 'Focada em treinamento funcional e reabilitação.',
          hourlyRate: 'R\$ 75,00',
          city: 'Rio de Janeiro, RJ',
        ),
        PendingRegistration(
          id: '3',
          name: 'Ana Costa',
          email: 'ana.costa@email.com',
          userType: UserType.student,
          password: 'temp789',
          registrationDate: DateTime.now().subtract(const Duration(hours: 6)),
          goals: 'Perder peso e melhorar condicionamento físico',
          fitnessLevel: 'Iniciante',
        ),
      ];
    } catch (e) {
      debugPrint('Erro ao carregar registros pendentes: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin - ${user?.name ?? 'Administrador'}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPendingRegistrations,
            tooltip: 'Atualizar',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'settings':
                  // TODO: Navigate to settings
                  break;
                case 'logout':
                  context.read<AuthProvider>().logout();
                  context.go('/');
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings_outlined),
                  title: Text('Configurações'),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Sair'),
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: Badge(
                label: Text('${_pendingRegistrations.length}'),
                isLabelVisible: _pendingRegistrations.isNotEmpty,
                child: const Icon(Icons.pending_actions),
              ),
              text: 'Aprovações',
            ),
            const Tab(icon: Icon(Icons.people), text: 'Usuários'),
            const Tab(icon: Icon(Icons.analytics), text: 'Estatísticas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildApprovalsTab(),
          _buildUsersTab(),
          _buildStatsTab(),
        ],
      ),
    );
  }

  Widget _buildApprovalsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pendingRegistrations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text(
              'Nenhuma aprovação pendente',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Todos os registros foram processados!',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingRegistrations.length,
      itemBuilder: (context, index) {
        final registration = _pendingRegistrations[index];
        return _buildRegistrationCard(registration);
      },
    );
  }

  Widget _buildRegistrationCard(PendingRegistration registration) {
    final isTrainer = registration.userType == UserType.trainer;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: isTrainer 
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.secondary,
                  child: Text(
                    registration.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        registration.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        registration.email,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isTrainer ? Colors.blue.shade100 : Colors.green.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isTrainer ? 'Personal Trainer' : 'Aluno',
                              style: TextStyle(
                                fontSize: 12,
                                color: isTrainer ? Colors.blue.shade800 : Colors.green.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(registration.registrationDate),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Registration details
            if (isTrainer) ...[
              _buildDetailRow('Especialidade', registration.specialty ?? 'N/A'),
              _buildDetailRow('CREF', registration.cref ?? 'N/A'),
              _buildDetailRow('Experiência', registration.experience ?? 'N/A'),
              _buildDetailRow('Cidade', registration.city ?? 'N/A'),
              _buildDetailRow('Valor/Hora', registration.hourlyRate ?? 'N/A'),
              const SizedBox(height: 8),
              Text(
                'Biografia:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                registration.bio ?? 'N/A',
                style: const TextStyle(fontSize: 14),
              ),
            ] else ...[
              _buildDetailRow('Objetivos', registration.goals ?? 'N/A'),
              _buildDetailRow('Nível', registration.fitnessLevel ?? 'N/A'),
            ],
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectRegistration(registration),
                    icon: const Icon(Icons.close),
                    label: const Text('Rejeitar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approveRegistration(registration),
                    icon: const Icon(Icons.check),
                    label: const Text('Aprovar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Em Desenvolvimento',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Gerenciamento de usuários será implementado em breve.',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estatísticas do Sistema',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Stats cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Usuários Totais',
                  '156',
                  Icons.people,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Personal Trainers',
                  '24',
                  Icons.fitness_center,
                  Colors.green,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Alunos',
                  '132',
                  Icons.school,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Conexões Ativas',
                  '89',
                  Icons.link,
                  Colors.purple,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Atividade Recente',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const ListTile(
                    leading: Icon(Icons.person_add, color: Colors.green),
                    title: Text('Novo cadastro de personal trainer'),
                    subtitle: Text('Maria Santos - há 2 horas'),
                  ),
                  const Divider(),
                  const ListTile(
                    leading: Icon(Icons.link, color: Colors.blue),
                    title: Text('Nova conexão estabelecida'),
                    subtitle: Text('João Silva ↔ Ana Costa - há 4 horas'),
                  ),
                  const Divider(),
                  const ListTile(
                    leading: Icon(Icons.person_add, color: Colors.green),
                    title: Text('Novo cadastro de aluno'),
                    subtitle: Text('Pedro Santos - há 6 horas'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _approveRegistration(PendingRegistration registration) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aprovar Cadastro'),
        content: Text('Aprovar o cadastro de ${registration.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _pendingRegistrations.removeWhere((reg) => reg.id == registration.id);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Cadastro de ${registration.name} aprovado!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Aprovar'),
          ),
        ],
      ),
    );
  }

  void _rejectRegistration(PendingRegistration registration) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejeitar Cadastro'),
        content: Text('Rejeitar o cadastro de ${registration.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _pendingRegistrations.removeWhere((reg) => reg.id == registration.id);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Cadastro de ${registration.name} rejeitado'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Rejeitar'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} min atrás';
      }
      return '${difference.inHours}h atrás';
    } else if (difference.inDays == 1) {
      return 'ontem';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} dias atrás';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
