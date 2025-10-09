import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/connection_provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/connection.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> with TickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConnectionProvider>().loadConnections();
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<ChatProvider>().initialize(user.id);
      }
    });
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
    // Mock trainers data - in a real app this would come from a service
    final trainers = [
      {
        'name': 'João Silva',
        'specialty': 'Musculação',
        'experience': '5 anos',
        'rating': 4.8,
        'hourlyRate': 'R\$ 80,00',
        'city': 'São Paulo, SP',
        'bio': 'Personal trainer especializado em hipertrofia e condicionamento físico.',
      },
      {
        'name': 'Maria Santos',
        'specialty': 'Funcional',
        'experience': '3 anos',
        'rating': 4.9,
        'hourlyRate': 'R\$ 75,00',
        'city': 'Rio de Janeiro, RJ',
        'bio': 'Focada em treinamento funcional e reabilitação.',
      },
      {
        'name': 'Carlos Oliveira',
        'specialty': 'Pilates',
        'experience': '7 anos',
        'rating': 4.7,
        'hourlyRate': 'R\$ 90,00',
        'city': 'Belo Horizonte, MG',
        'bio': 'Instrutor de Pilates com formação em fisioterapia.',
      },
    ];

    final filteredTrainers = trainers.where((trainer) {
      if (_searchQuery.isEmpty) return true;
      return (trainer['name'] as String).toLowerCase().contains(_searchQuery.toLowerCase()) ||
             (trainer['specialty'] as String).toLowerCase().contains(_searchQuery.toLowerCase()) ||
             (trainer['city'] as String).toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    if (filteredTrainers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhum personal trainer encontrado',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredTrainers.length,
      itemBuilder: (context, index) {
        final trainer = filteredTrainers[index];
        return _buildTrainerCard(trainer);
      },
    );
  }

  Widget _buildTrainerCard(Map<String, dynamic> trainer) {
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
                    trainer['name']!.substring(0, 1).toUpperCase(),
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
                        trainer['name']!,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        trainer['specialty']!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.amber.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            trainer['rating']!.toString(),
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.work_outline,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            trainer['experience']!,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      trainer['hourlyRate']!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text('/hora', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  trainer['city']!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              trainer['bio']!,
              style: const TextStyle(fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _showTrainerProfile(trainer);
                    },
                    child: const Text('Ver Perfil'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _sendConnectionRequest(trainer);
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

  Widget _buildConnectionsTab() {
    return Consumer<ConnectionProvider>(
      builder: (context, connectionProvider, child) {
        if (connectionProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final connections = connectionProvider.connections
            .where((conn) => conn.status == ConnectionStatus.accepted)
            .toList();

        if (connections.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Você ainda não tem conexões',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Busque por personal trainers e faça conexões!',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: connections.length,
          itemBuilder: (context, index) {
            final connection = connections[index];
            return _buildConnectionCard(connection);
          },
        );
      },
    );
  }

  Widget _buildConnectionCard(Connection connection) {
    // In a real app, we would get trainer details from the connection or user service
    // For now, we'll use trainerId as a placeholder
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            'T', // Using 'T' for trainer
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        title: Text('Personal Trainer ${connection.trainerId.substring(0, 8)}'),
        subtitle: const Text('Personal Trainer'),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'chat':
                context.go('/chat/${connection.trainerId}');
                break;
              case 'rate':
                _showRatingDialog(connection);
                break;
              case 'disconnect':
                _disconnectTrainer(connection);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'chat',
              child: ListTile(
                leading: Icon(Icons.chat_outlined),
                title: Text('Conversar'),
              ),
            ),
            const PopupMenuItem(
              value: 'rate',
              child: ListTile(
                leading: Icon(Icons.star_outline),
                title: Text('Avaliar'),
              ),
            ),
            const PopupMenuItem(
              value: 'disconnect',
              child: ListTile(
                leading: Icon(Icons.link_off),
                title: Text('Desconectar'),
              ),
            ),
          ],
        ),
        onTap: () {
          context.go('/chat/${connection.trainerId}');
        },
      ),
    );
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

  void _showTrainerProfile(Map<String, dynamic> trainer) {
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
                  trainer['name']!.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                trainer['name']!,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                trainer['specialty']!,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Icon(Icons.star, color: Colors.amber.shade600),
                      Text(trainer['rating']!.toString()),
                      const Text('Avaliação', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  Column(
                    children: [
                      const Icon(Icons.work_outline),
                      Text(trainer['experience']!),
                      const Text('Experiência', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  Column(
                    children: [
                      const Icon(Icons.monetization_on_outlined),
                      Text(trainer['hourlyRate']!),
                      const Text('Por hora', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                trainer['bio']!,
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
                        _sendConnectionRequest(trainer);
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

  void _sendConnectionRequest(Map<String, dynamic> trainer) {
    // In a real app, this would create a connection request
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Solicitação enviada para ${trainer['name']}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showRatingDialog(Connection connection) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Avaliar Personal Trainer'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Como foi sua experiência?'),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star_border, size: 32),
                Icon(Icons.star_border, size: 32),
                Icon(Icons.star_border, size: 32),
                Icon(Icons.star_border, size: 32),
                Icon(Icons.star_border, size: 32),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Avaliação enviada!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  void _disconnectTrainer(Connection connection) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desconectar'),
        content: const Text('Tem certeza que deseja se desconectar deste personal trainer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // In a real app, this would call a proper disconnect method
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Desconectado com sucesso'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('Desconectar'),
          ),
        ],
      ),
    );
  }
}
