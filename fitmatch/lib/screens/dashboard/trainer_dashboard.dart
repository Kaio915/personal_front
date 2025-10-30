import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../services/connection_service.dart';
import '../../services/auth_service.dart';

class TrainerDashboard extends StatefulWidget {
  const TrainerDashboard({super.key});

  @override
  State<TrainerDashboard> createState() => _TrainerDashboardState();
}

class _TrainerDashboardState extends State<TrainerDashboard> with TickerProviderStateMixin {
  late TabController _tabController;
  final ConnectionService _connectionService = ConnectionService();
  List<ConnectionModel> _pendingConnections = [];
  List<ConnectionModel> _acceptedConnections = [];
  bool _isLoadingConnections = false;
  Map<int, Map<String, String>> _studentInfo = {}; // Cache student info

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Adicionar listener para recarregar quando mudar de aba
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        // Recarregar conexões quando acessar a aba de Solicitações ou Alunos
        if (_tabController.index == 0 || _tabController.index == 1) {
          _loadConnections();
        }
      }
    });
    
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<ChatProvider>().initialize(user.id);
        _loadConnections();
      }
    });
  }

  Future<void> _loadConnections() async {
    final currentUser = context.read<AuthProvider>().currentUser;
    if (currentUser == null) return;

    setState(() {
      _isLoadingConnections = true;
    });

    try {
      final trainerId = int.parse(currentUser.id);
      print('🔄 Carregando conexões do trainer ID: $trainerId');
      
      // Carregar solicitações pendentes
      final pending = await _connectionService.getTrainerPendingConnections(trainerId);
      print('✅ Conexões pendentes carregadas: ${pending.length}');
      for (var conn in pending) {
        print('  - Conexão #${conn.id}: Student ${conn.studentId} -> Trainer ${conn.trainerId} (${conn.status.name})');
      }
      
      // Carregar todas as conexões aceitas
      final all = await _connectionService.getTrainerConnections(trainerId);
      final accepted = all.where((c) => c.status == ConnectionStatusEnum.accepted).toList();
      print('✅ Conexões aceitas carregadas: ${accepted.length}');
      
      // Carregar informações dos alunos
      final authService = AuthService();
      for (var conn in [...pending, ...accepted]) {
        if (!_studentInfo.containsKey(conn.studentId)) {
          try {
            final student = await authService.getUserById(conn.studentId);
            if (student != null) {
              _studentInfo[conn.studentId] = {
                'name': student.name,
                'email': student.email,
              };
              print('👤 Info do aluno ${conn.studentId} carregada: ${student.name}');
            }
          } catch (e) {
            print('❌ Erro ao carregar info do aluno ${conn.studentId}: $e');
          }
        }
      }
      
      setState(() {
        _pendingConnections = pending;
        _acceptedConnections = accepted;
        _isLoadingConnections = false;
      });
      
      print('✅ Carregamento concluído! Pendentes: ${_pendingConnections.length}, Aceitas: ${_acceptedConnections.length}');
    } catch (e) {
      print('❌ Erro ao carregar conexões: $e');
      setState(() {
        _isLoadingConnections = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Olá, ${user?.name ?? 'Personal'}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Show notifications
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  // TODO: Navigate to profile
                  break;
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
                value: 'profile',
                child: ListTile(
                  leading: Icon(Icons.person_outline),
                  title: Text('Perfil'),
                ),
              ),
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
          tabs: const [
            Tab(icon: Icon(Icons.pending_actions), text: 'Solicitações'),
            Tab(icon: Icon(Icons.people), text: 'Alunos'),
            Tab(icon: Icon(Icons.chat), text: 'Mensagens'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRequestsTab(),
          _buildStudentsTab(),
          _buildMessagesTab(),
        ],
      ),
    );
  }

  Widget _buildRequestsTab() {
    if (_isLoadingConnections) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pendingConnections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.pending_actions_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Nenhuma solicitação pendente',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Quando alunos solicitarem conexão, elas aparecerão aqui.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadConnections,
              icon: const Icon(Icons.refresh),
              label: const Text('Atualizar'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingConnections.length,
      itemBuilder: (context, index) {
        final connection = _pendingConnections[index];
        return _buildRequestCardFromModel(connection);
      },
    );
  }

  Widget _buildRequestCardFromModel(ConnectionModel connection) {
    final studentInfo = _studentInfo[connection.studentId];
    final studentName = studentInfo?['name'] ?? 'Aluno #${connection.studentId}';
    final studentEmail = studentInfo?['email'] ?? '';

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
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  child: Text(
                    studentName.substring(0, 1).toUpperCase(),
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
                        studentName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (studentEmail.isNotEmpty)
                        Text(
                          studentEmail,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      Text(
                        'Solicitação pendente',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectConnection(connection),
                    icon: const Icon(Icons.close),
                    label: const Text('Rejeitar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _acceptConnection(connection),
                    icon: const Icon(Icons.check),
                    label: const Text('Aceitar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _acceptConnection(ConnectionModel connection) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final success = await _connectionService.updateConnectionStatus(
        connection.id,
        ConnectionStatusEnum.accepted,
      );

      if (!mounted) return;
      Navigator.pop(context); // Fechar loading

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Conexão com ${_studentInfo[connection.studentId]?['name'] ?? 'aluno'} aceita!'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadConnections(); // Recarregar lista
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao aceitar conexão'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectConnection(ConnectionModel connection) async {
    // Confirmar rejeição
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejeitar solicitação'),
        content: Text('Tem certeza que deseja rejeitar a solicitação de ${_studentInfo[connection.studentId]?['name'] ?? 'este aluno'}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Rejeitar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final success = await _connectionService.updateConnectionStatus(
        connection.id,
        ConnectionStatusEnum.rejected,
      );

      if (!mounted) return;
      Navigator.pop(context); // Fechar loading

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solicitação rejeitada'),
            backgroundColor: Colors.orange,
          ),
        );
        await _loadConnections(); // Recarregar lista
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao rejeitar conexão'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildStudentsTab() {
    if (_isLoadingConnections) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_acceptedConnections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Nenhum aluno conectado',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Aceite solicitações de conexão para ver seus alunos aqui.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadConnections,
              icon: const Icon(Icons.refresh),
              label: const Text('Atualizar'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _acceptedConnections.length,
      itemBuilder: (context, index) {
        final connection = _acceptedConnections[index];
        return _buildStudentCardFromModel(connection);
      },
    );
  }

  Widget _buildStudentCardFromModel(ConnectionModel connection) {
    final studentInfo = _studentInfo[connection.studentId];
    final studentName = studentInfo?['name'] ?? 'Aluno #${connection.studentId}';
    final studentEmail = studentInfo?['email'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.secondary,
          child: Text(
            studentName.substring(0, 1).toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        title: Text(studentName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (studentEmail.isNotEmpty)
              Text(studentEmail),
            const SizedBox(height: 4),
            Text(
              'Conectado',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chat_outlined),
              onPressed: () {
                context.go('/chat/${connection.studentId}');
              },
              tooltip: 'Conversar',
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'disconnect':
                    _disconnectStudent(connection);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'disconnect',
                  child: ListTile(
                    leading: Icon(Icons.link_off, color: Colors.red),
                    title: Text('Desconectar'),
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () {
          context.go('/chat/${connection.studentId}');
        },
      ),
    );
  }

  Future<void> _disconnectStudent(ConnectionModel connection) async {
    // Confirmar desconexão
    final studentInfo = _studentInfo[connection.studentId];
    final studentName = studentInfo?['name'] ?? 'este aluno';
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desconectar aluno'),
        content: Text('Tem certeza que deseja desconectar $studentName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Desconectar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final success = await _connectionService.deleteConnection(connection.id);

      if (!mounted) return;
      Navigator.pop(context); // Fechar loading

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Desconectado de $studentName'),
            backgroundColor: Colors.orange,
          ),
        );
        await _loadConnections(); // Recarregar lista
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao desconectar'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildMessagesTab() {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        if (chatProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final currentUser = context.read<AuthProvider>().currentUser;
        if (currentUser == null) {
          return const Center(child: Text('Usuário não encontrado'));
        }

        // Get conversations with details
        final conversationsWithDetails = chatProvider.getConversationsWithDetails(currentUser.id);

        if (conversationsWithDetails.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Nenhuma conversa ainda',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Aceite conexões com alunos e comece a conversar!',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: conversationsWithDetails.length,
          itemBuilder: (context, index) {
            final conversation = conversationsWithDetails[index];
            final user = conversation['user'];
            final userId = conversation['userId'];
            
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  child: Text(
                    user?.name?.substring(0, 1).toUpperCase() ?? 'A',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                title: Text(user?.name ?? 'Aluno'),
                subtitle: const Text('Toque para conversar'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  context.go('/chat/$userId');
                },
              ),
            );
          },
        );
      },
    );
  }
}
