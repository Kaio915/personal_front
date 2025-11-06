import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/user.dart';
import '../../services/trainer_service.dart';
import '../../services/connection_service.dart';
import '../../services/auth_service.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> with TickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  final TrainerService _trainerService = TrainerService();
  final ConnectionService _connectionService = ConnectionService();
  List<User> _trainers = [];
  bool _isLoadingTrainers = false;
  List<ConnectionModel> _acceptedConnections = [];
  bool _isLoadingConnections = false;
  Map<int, Map<String, String>> _trainerInfo = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<ChatProvider>().initialize(user.id);
        _loadConnections();
      }
      _loadTrainers();
    });
  }

  Future<void> _loadConnections() async {
    final currentUser = context.read<AuthProvider>().currentUser;
    if (currentUser == null) return;

    setState(() {
      _isLoadingConnections = true;
    });

    try {
      final studentId = int.parse(currentUser.id);
      
      // Carregar todas as conexões aceitas
      final all = await _connectionService.getStudentConnections(studentId);
      final accepted = all.where((c) => c.status == ConnectionStatusEnum.accepted).toList();
      
      // Carregar informações dos trainers
      final authService = AuthService();
      for (var conn in accepted) {
        if (!_trainerInfo.containsKey(conn.trainerId)) {
          try {
            final trainer = await authService.getUserById(conn.trainerId);
            if (trainer != null) {
              _trainerInfo[conn.trainerId] = {
                'name': trainer.name,
                'email': trainer.email,
              };
            }
          } catch (e) {
            print('Erro ao carregar info do trainer ${conn.trainerId}: $e');
          }
        }
      }
      
      setState(() {
        _acceptedConnections = accepted;
        _isLoadingConnections = false;
      });
    } catch (e) {
      print('Erro ao carregar conexões: $e');
      setState(() {
        _isLoadingConnections = false;
      });
    }
  }

  Future<void> _loadTrainers() async {
    setState(() {
      _isLoadingTrainers = true;
    });

    try {
      final trainers = await _trainerService.getApprovedTrainers();
      setState(() {
        _trainers = trainers;
        _isLoadingTrainers = false;
      });
    } catch (e) {
      print('Erro ao carregar trainers: $e');
      setState(() {
        _isLoadingTrainers = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Olá, ${user?.name ?? 'Aluno'}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Show notifications
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'profile':
                  // TODO: Navigate to profile
                  break;
                case 'settings':
                  // TODO: Navigate to settings
                  break;
                case 'logout':
                  await context.read<AuthProvider>().logout();
                  if (mounted) {
                    context.go('/');
                  }
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
            Tab(icon: Icon(Icons.search), text: 'Buscar'),
            Tab(icon: Icon(Icons.people), text: 'Conexões'),
            Tab(icon: Icon(Icons.chat), text: 'Mensagens'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSearchTab(),
          _buildConnectionsTab(),
          _buildMessagesTab(),
        ],
      ),
    );
  }

  Widget _buildSearchTab() {
    return Column(
      children: [
        // Search bar
        Container(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar personal trainers...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),

        // Filters
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              FilterChip(
                label: const Text('Musculação'),
                selected: false,
                onSelected: (selected) {},
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Funcional'),
                selected: false,
                onSelected: (selected) {},
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Pilates'),
                selected: false,
                onSelected: (selected) {},
              ),
            ],
          ),
        ),

        // Trainers list
        Expanded(
          child: _buildTrainersList(),
        ),
      ],
    );
  }

  Widget _buildTrainersList() {
    if (_isLoadingTrainers) {
      return const Center(child: CircularProgressIndicator());
    }

    // Filtrar trainers por query de busca
    final filteredTrainers = _trainers.where((trainer) {
      if (_searchQuery.isEmpty) return true;
      return trainer.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             trainer.email.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    if (filteredTrainers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _trainers.isEmpty
                  ? 'Nenhum personal trainer cadastrado ainda'
                  : 'Nenhum personal trainer encontrado',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            if (_trainers.isEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Aguarde enquanto personal trainers se cadastram no sistema',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredTrainers.length,
      itemBuilder: (context, index) {
        final trainer = filteredTrainers[index];
        return _buildTrainerCardFromUser(trainer);
      },
    );
  }

  Widget _buildTrainerCardFromUser(User trainer) {
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
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    trainer.name.substring(0, 1).toUpperCase(),
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
                        trainer.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Personal Trainer',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.verified,
                            size: 16,
                            color: Colors.green.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Aprovado',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              trainer.email,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _showTrainerProfileFromUser(trainer);
                    },
                    child: const Text('Ver Perfil'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _sendConnectionRequestToUser(trainer);
                    },
                    child: const Text('Conectar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showTrainerProfileFromUser(User trainer) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  trainer.name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                trainer.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Personal Trainer',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                trainer.email,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Fechar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _sendConnectionRequestToUser(trainer);
                      },
                      child: const Text('Conectar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _sendConnectionRequestToUser(User trainer) async {
    final currentUser = context.read<AuthProvider>().currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro: usuário não autenticado'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final studentId = int.parse(currentUser.id);
      final trainerId = int.parse(trainer.id);
      
      print('📤 Enviando solicitação: Student $studentId -> Trainer $trainerId');
      
      final success = await _connectionService.createConnection(
        studentId,
        trainerId,
      );

      if (!mounted) return;
      Navigator.pop(context); // Fechar loading

      if (success) {
        print('✅ Solicitação enviada com sucesso!');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Solicitação enviada para ${trainer.name}'),
            backgroundColor: Colors.green,
          ),
        );
        // Recarregar conexões
        await _loadConnections();
      } else {
        print('⚠️ Falha ao enviar solicitação');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao enviar solicitação. Você já pode ter uma solicitação pendente.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Fechar loading
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao enviar solicitação: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildConnectionsTab() {
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
              'Você ainda não tem conexões',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Busque por personal trainers e faça conexões!',
              style: TextStyle(color: Colors.grey),
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
        return _buildConnectionCardFromModel(connection);
      },
    );
  }

  Widget _buildConnectionCardFromModel(ConnectionModel connection) {
    final trainerInfo = _trainerInfo[connection.trainerId];
    final trainerName = trainerInfo?['name'] ?? 'Personal #${connection.trainerId}';
    final trainerEmail = trainerInfo?['email'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            trainerName.substring(0, 1).toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        title: Text(trainerName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (trainerEmail.isNotEmpty)
              Text(trainerEmail),
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
                context.go('/chat/${connection.trainerId}');
              },
              tooltip: 'Conversar',
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'disconnect':
                    _disconnectTrainerFromModel(connection);
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
          context.go('/chat/${connection.trainerId}');
        },
      ),
    );
  }

  Future<void> _disconnectTrainerFromModel(ConnectionModel connection) async {
    // Confirmar desconexão
    final trainerInfo = _trainerInfo[connection.trainerId];
    final trainerName = trainerInfo?['name'] ?? 'este personal trainer';
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desconectar'),
        content: Text('Tem certeza que deseja desconectar de $trainerName?'),
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
            content: Text('Desconectado de $trainerName'),
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
                  'Conecte-se com personal trainers e comece a conversar!',
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
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    user?.name?.substring(0, 1).toUpperCase() ?? 'T',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                title: Text(user?.name ?? 'Personal Trainer'),
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
