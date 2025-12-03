import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
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
  Timer? _notifyPollTimer;
  Map<int, int> _lastUnreadCounts = {};

  @override
  void initState() {
    super.initState();
  _tabController = TabController(length: 2, vsync: this);
    
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
        // Start provider-managed unread polling
        context.read<ChatProvider>().startUnreadPolling(user.id);
        _loadConnections();
        // Start a lightweight polling to check unread messages and notify
        _notifyPollTimer = Timer.periodic(const Duration(seconds: 6), (_) async {
          await _checkForUnreadNotificationsTrainer();
        });
      }
    });
  }

  Future<void> _checkForUnreadNotificationsTrainer() async {
    final currentUser = context.read<AuthProvider>().currentUser;
    if (currentUser == null) return;

    final chatProvider = context.read<ChatProvider>();
    final trainerId = currentUser.id;

    for (var conn in _acceptedConnections) {
      final otherId = conn.studentId.toString();
      try {
        final count = await chatProvider.getUnreadMessageCountBetweenUsers(trainerId, otherId);
        final hadPrev = _lastUnreadCounts.containsKey(conn.studentId);
        final prev = _lastUnreadCounts[conn.studentId] ?? 0;
        print('🔔 Trainer unread check for ${conn.studentId}: prev=$prev, now=$count (hadPrev=$hadPrev)');
        if (!hadPrev) {
          _lastUnreadCounts[conn.studentId] = count;
        } else if (count > prev) {
          final name = _studentInfo[conn.studentId]?['name'] ?? 'Aluno';
          print('🔔 Trainer notifying new messages from $name (${conn.studentId}): $count > $prev');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Nova mensagem de $name')),
            );
          }
          _lastUnreadCounts[conn.studentId] = count;
        }
      } catch (e) {
        // ignore
      }
    }
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
                'goals': student.goals ?? '',
                'fitnessLevel': student.fitnessLevel ?? '',
                'bio': student.bio ?? '',
                'city': student.city ?? '',
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
    _notifyPollTimer?.cancel();
    // Stop provider unread polling
    context.read<ChatProvider>().stopUnreadPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text('Olá, ${user?.name ?? 'Personal'}'),
          actions: [
            Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                final total = chatProvider.totalUnreadCount;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      onPressed: () => _showNotificationsSheet(),
                    ),
                    if (total > 0)
                      Positioned(
                        right: 10,
                        top: 10,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Center(
                            child: Text(
                              total > 99 ? '99+' : total.toString(),
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'logout') {
                  await context.read<AuthProvider>().logout();
                  if (mounted) context.go('/');
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
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
              // Tab(icon: Icon(Icons.chat), text: 'Mensagens'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildRequestsTab(),
            _buildStudentsTab(),
            // _buildMessagesTab(),
          ],
        ),
      ),
    );
  }

  void _showNotificationsSheet() {
    final chatProvider = context.read<ChatProvider>();
    final currentUser = context.read<AuthProvider>().currentUser;
    if (currentUser == null) return;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        // Build a list of unread conversations
        final unreadMap = chatProvider.unreadCounts;
        final unreadEntries = unreadMap.entries.where((e) => e.value > 0).toList();

        if (unreadEntries.isEmpty) {
          return SizedBox(
            height: 200,
            child: Center(
              child: Text('Sem novas mensagens'),
            ),
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: const [
                    Icon(Icons.notifications),
                    SizedBox(width: 8),
                    Text('Notificações', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: unreadEntries.length,
                  itemBuilder: (context, index) {
                    final otherId = unreadEntries[index].key;
                    final count = unreadEntries[index].value;
                    final userObj = chatProvider.getUserById(otherId);
                    final name = userObj?.name ?? _studentInfo[int.tryParse(otherId) ?? 0]?['name'] ?? 'Usuário';

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                        child: Text(name.substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.white)),
                      ),
                      title: Text(name),
                      subtitle: FutureBuilder(
                        future: chatProvider.getLastMessage(currentUser.id, otherId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) return const Text('Carregando...');
                          final last = snapshot.data;
                          if (last == null) return const Text('Nova mensagem');
                          return Text('${last.senderId == int.parse(currentUser.id) ? "Você: " : ""}${last.content}', maxLines: 1, overflow: TextOverflow.ellipsis);
                        },
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
                        child: Text(count > 99 ? '99+' : count.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      onTap: () {
                        // Close sheet and navigate to chat
                        Navigator.pop(context);
                        _notifyPollTimer?.cancel();
                        Future.microtask(() => context.push('/chat/$otherId'));
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
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
                      const SizedBox(height: 6),
                      // Exibir informações adicionais do aluno quando disponíveis
                      if ((studentInfo?['goals'] ?? '').isNotEmpty)
                        Text(
                          'Objetivo: ${studentInfo?['goals']}',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if ((studentInfo?['fitnessLevel'] ?? '').isNotEmpty)
                        Text(
                          'Nível: ${studentInfo?['fitnessLevel']}',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
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
            Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                final unread = chatProvider.unreadCounts[connection.studentId.toString()] ?? 0;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chat_outlined),
                      onPressed: () {
                        print('🧭 TrainerDashboard: chat button pressed for student ${connection.studentId}');
                        // Cancel notify polling to avoid conflicts
                        _notifyPollTimer?.cancel();
                        Future.microtask(() => context.push('/chat/${connection.studentId}'));
                      },
                      tooltip: 'Conversar',
                    ),
                    if (unread > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                          child: Center(
                            child: Text(
                              unread > 99 ? '99+' : unread.toString(),
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
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
          print('🧭 TrainerDashboard: tapped student ${connection.studentId}');
          // Cancel polling to avoid conflicts
          _notifyPollTimer?.cancel();
          Future.microtask(() => context.push('/chat/${connection.studentId}'));
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

  
}
