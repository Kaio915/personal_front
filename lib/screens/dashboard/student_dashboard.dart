import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/user.dart';
import '../../services/trainer_service.dart';
import '../../services/rating_service.dart';
import '../../services/connection_service.dart';

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
  Timer? _pollTimer;
  Map<String, int> _lastUnreadCounts = {};
  

  @override
  void initState() {
    super.initState();
  _tabController = TabController(length: 2, vsync: this);
  _tabController.addListener(() {
    final user = context.read<AuthProvider>().currentUser;
    if (_tabController.index == 1) {
      // Load immediately and start polling while on Messages tab
      if (user != null) {
        context.read<ChatProvider>().loadConversations(user.id);
        context.read<ChatProvider>().loadUsers();
      }

      _pollTimer?.cancel();
      _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
        final u = context.read<AuthProvider>().currentUser;
        if (u != null) {
            await context.read<ChatProvider>().loadConversations(u.id);
          // Do not call loadUsers() here — loading users can overwrite
          // users fetched for conversations. Conversations loader
          // already fetches missing users as needed.
            // After loading conversations, check for unread messages and notify
            await _checkForUnreadNotifications();
        }
      });
    } else {
      // Stop polling when leaving Messages tab
      _pollTimer?.cancel();
      _pollTimer = null;
    }
  });
    
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<ChatProvider>().initialize(user.id);
        // Start provider-managed unread polling (updates badges)
        context.read<ChatProvider>().startUnreadPolling(user.id);
      }
      _loadTrainers();
    });
  }

  // Render stars based on average rating (rounded down)
  Widget _buildStars(double rating) {
    final filled = rating.floor();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        if (i < filled) {
          return const Icon(Icons.star, size: 16, color: Colors.yellow);
        }
        return const Icon(Icons.star_border, size: 16, color: Colors.grey);
      }),
    );
  }

  // Shows a dialog allowing the student to pick 1-5 stars. Returns chosen rating or null.
  Future<int?> _showRateDialog(User trainer) async {
    int selected = 0;
    return showDialog<int>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Avaliar ${trainer.name}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Escolha uma nota de 1 a 5 estrelas'),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final star = i + 1;
                      return IconButton(
                        icon: Icon(
                          star <= selected ? Icons.star : Icons.star_border,
                          color: Colors.yellow[700],
                        ),
                        onPressed: () => setState(() => selected = star),
                      );
                    }),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: selected == 0 ? null : () => Navigator.pop(context, selected),
                  child: const Text('Enviar'),
                ),
              ],
            );
          },
        );
      },
    );
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
    _tabController.removeListener(() {});
    _tabController.dispose();
    _pollTimer?.cancel();
    // Stop provider unread polling
    context.read<ChatProvider>().stopUnreadPolling();
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
          tabs: [
            const Tab(icon: Icon(Icons.search), text: 'Buscar'),
            Tab(
              icon: Consumer<ChatProvider>(
                builder: (context, chatProvider, child) {
                  final unread = chatProvider.totalUnreadCount;
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(Icons.chat),
                      if (unread > 0)
                        Positioned(
                          right: 0,
                          top: 0,
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
              text: 'Mensagens',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSearchTab(),
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

        // Filters removed per UX change (only Buscar/Mensagens remain)

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
            const SizedBox(height: 8),
            // Mostrar média de avaliações se disponível
            if (trainer.averageRating != null)
              Row(
                children: [
                  _buildStars(trainer.averageRating!),
                  const SizedBox(width: 8),
                  Text(
                    '(${trainer.ratingCount ?? 0})',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  ),
                ],
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
              const SizedBox(height: 12),
              if (trainer.averageRating != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStars(trainer.averageRating!),
                    const SizedBox(width: 8),
                    Text('(${trainer.ratingCount ?? 0} avaliações)'),
                  ],
                ),
              const SizedBox(height: 24),
              // Avaliar botão (apenas estudantes devem ver)
              if (context.read<AuthProvider>().currentUser?.userType == UserType.student)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      final rating = await _showRateDialog(trainer);
                      if (rating != null) {
                        final currentUser = context.read<AuthProvider>().currentUser;
                        if (currentUser != null) {
                          final ratingService = RatingService();
                          final studentId = int.parse(currentUser.id);
                          final trainerId = int.parse(trainer.id);
                          final success = await ratingService.rateTrainer(studentId, trainerId, rating);
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Avaliação enviada com sucesso')),
                            );
                            // Recarregar lista de trainers para atualizar média
                            _loadTrainers();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Erro ao enviar avaliação'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      }
                    },
                    icon: const Icon(Icons.star_rate),
                    label: const Text('Avaliar'),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Fechar'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                        onPressed: () {
                        Navigator.pop(context);
                        // Open chat with this trainer so the student can send a message
                        final currentUser = context.read<AuthProvider>().currentUser;
                        // Cancel polling to avoid conflicts
                        _pollTimer?.cancel();
                        if (currentUser != null) {
                          // Ensure chat provider initialized for current user
                          context.read<ChatProvider>().initialize(currentUser.id).then((_) {
                            context.push('/chat/${trainer.id}');
                          });
                        } else {
                          context.push('/chat/${trainer.id}');
                        }
                      },
                      child: const Text('Mensagem'),
                    ),
                  ),
                  const SizedBox(width: 8),
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

        return RefreshIndicator(
          onRefresh: () async {
            final user = context.read<AuthProvider>().currentUser;
            if (user != null) {
              await context.read<ChatProvider>().loadConversations(user.id);
              await context.read<ChatProvider>().loadUsers();
            }
          },
          child: ListView.builder(
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
                  subtitle: FutureBuilder(
                    future: context.read<ChatProvider>().getLastMessage(currentUser.id, userId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Text('Carregando...');
                      }
                      if (snapshot.hasError) return const Text('');
                      final last = snapshot.data;
                      if (last == null) return const Text('Toque para conversar');
                      return Text(
                        '${last.senderId == int.parse(currentUser.id) ? "Você: " : ""}${last.content}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                  ),
                  trailing: Consumer<ChatProvider>(
                    builder: (context, chatProvider, child) {
                      final unread = chatProvider.unreadCounts[userId] ?? 0;
                      if (unread > 0) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            unread > 99 ? '99+' : unread.toString(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        );
                      }
                      return const Icon(Icons.arrow_forward_ios);
                    },
                  ),
                  onTap: () {
                    // Debug: log tap and stop polling
                    print('🧭 MensagensTab: tapped conversation with userId=$userId');
                    _pollTimer?.cancel();
                    final cu = context.read<AuthProvider>().currentUser;
                    if (cu != null) {
                      // Load messages but don't await so navigation isn't blocked
                      context.read<ChatProvider>().loadMessagesBetweenUsers(cu.id, userId);
                    }
                    // Navigate in a microtask to avoid interfering with current frame
                    Future.microtask(() {
                      print('🧭 MensagensTab: navigating to /chat/$userId');
                      // Cancel polling to avoid conflicts
                      _pollTimer?.cancel();
                      context.push('/chat/$userId');
                    });
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Check unread messages per conversation and show notification when new unread appears
  Future<void> _checkForUnreadNotifications() async {
    final currentUser = context.read<AuthProvider>().currentUser;
    if (currentUser == null) return;

    final chatProvider = context.read<ChatProvider>();
    final conversations = chatProvider.getConversationsWithDetails(currentUser.id);

    for (final conv in conversations) {
      final otherId = conv['userId'] as String;
      try {
        final count = await chatProvider.getUnreadMessageCountBetweenUsers(currentUser.id, otherId);
        final hadPrev = _lastUnreadCounts.containsKey(otherId);
        final prev = _lastUnreadCounts[otherId] ?? 0;
        print('🔔 Unread check for $otherId: prev=$prev, now=$count (hadPrev=$hadPrev)');
        if (!hadPrev) {
          // Initialize without notifying
          _lastUnreadCounts[otherId] = count;
        } else if (count > prev) {
          // New messages arrived from this user — show notification with sender name
          final user = conv['user'];
          final senderName = user?.name ?? 'Usuário';
          print('🔔 Notifying new messages from $senderName ($otherId): $count > $prev');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Nova mensagem de $senderName')),
            );
          }
          _lastUnreadCounts[otherId] = count;
        }
      } catch (e) {
        // ignore errors in notification polling
      }
    }
  }
}
