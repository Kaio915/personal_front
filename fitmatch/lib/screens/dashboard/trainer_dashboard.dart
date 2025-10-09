import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/connection_provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/connection.dart';

class TrainerDashboard extends StatefulWidget {
  const TrainerDashboard({super.key});

  @override
  State<TrainerDashboard> createState() => _TrainerDashboardState();
}

class _TrainerDashboardState extends State<TrainerDashboard> with TickerProviderStateMixin {
  late TabController _tabController;

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
    return Consumer<ConnectionProvider>(
      builder: (context, connectionProvider, child) {
        if (connectionProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final pendingConnections = connectionProvider.connections
            .where((conn) => conn.status == ConnectionStatus.pending)
            .toList();

        if (pendingConnections.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pending_actions_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Nenhuma solicitação pendente',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Quando alunos solicitarem conexão, elas aparecerão aqui.',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pendingConnections.length,
          itemBuilder: (context, index) {
            final connection = pendingConnections[index];
            return _buildRequestCard(connection);
          },
        );
      },
    );
  }

  Widget _buildRequestCard(Connection connection) {
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
                    connection.studentName.substring(0, 1).toUpperCase(),
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
                        connection.studentName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        connection.studentEmail,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        'Solicitação enviada em ${_formatDate(connection.createdAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
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
                  child: OutlinedButton(
                    onPressed: () => _rejectConnection(connection),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text('Recusar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _acceptConnection(connection),
                    child: const Text('Aceitar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentsTab() {
    return Consumer<ConnectionProvider>(
      builder: (context, connectionProvider, child) {
        if (connectionProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final acceptedConnections = connectionProvider.connections
            .where((conn) => conn.status == ConnectionStatus.accepted)
            .toList();

        if (acceptedConnections.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Nenhum aluno conectado',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Aceite solicitações de conexão para ver seus alunos aqui.',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: acceptedConnections.length,
          itemBuilder: (context, index) {
            final connection = acceptedConnections[index];
            return _buildStudentCard(connection);
          },
        );
      },
    );
  }

  Widget _buildStudentCard(Connection connection) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.secondary,
          child: Text(
            connection.studentName.substring(0, 1).toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        title: Text(connection.studentName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(connection.studentEmail),
            const SizedBox(height: 4),
            Text(
              'Conectado desde ${_formatDate(connection.respondedAt ?? connection.createdAt)}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'chat':
                context.go('/chat/${connection.studentId}');
                break;
              case 'view_rating':
                _showStudentRating(connection);
                break;
              case 'disconnect':
                _disconnectStudent(connection);
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
              value: 'view_rating',
              child: ListTile(
                leading: Icon(Icons.star_outline),
                title: Text('Ver Avaliação'),
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
          context.go('/chat/${connection.studentId}');
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

  void _acceptConnection(Connection connection) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aceitar Conexão'),
        content: Text('Aceitar solicitação de ${connection.studentName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // In a real app, this would update the connection status
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Conexão com ${connection.studentName} aceita!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Aceitar'),
          ),
        ],
      ),
    );
  }

  void _rejectConnection(Connection connection) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recusar Conexão'),
        content: Text('Recusar solicitação de ${connection.studentName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // In a real app, this would update the connection status
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Conexão com ${connection.studentName} recusada'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Recusar'),
          ),
        ],
      ),
    );
  }

  void _showStudentRating(Connection connection) {
    final rating = connection.rating ?? 0;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Avaliação de ${connection.studentName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (rating > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    color: Colors.amber.shade600,
                    size: 32,
                  );
                }),
              ),
              const SizedBox(height: 8),
              Text(
                '$rating/5 estrelas',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ] else ...[
              const Icon(Icons.star_border, size: 48, color: Colors.grey),
              const SizedBox(height: 8),
              const Text('Ainda não avaliado'),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _disconnectStudent(Connection connection) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desconectar Aluno'),
        content: Text('Tem certeza que deseja se desconectar de ${connection.studentName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // In a real app, this would remove the connection
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Desconectado de ${connection.studentName}'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Desconectar'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'hoje';
    } else if (difference.inDays == 1) {
      return 'ontem';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} dias atrás';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks semana${weeks > 1 ? 's' : ''} atrás';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
