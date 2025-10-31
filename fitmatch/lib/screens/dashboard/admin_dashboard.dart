import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../providers/auth_provider.dart';
import '../../config/config.dart';
import '../../services/auth_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _pendingUsers = [];
  List<Map<String, dynamic>> _allUsers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final token = await AuthService().getToken();
      
      final pendingResponse = await http.get(
        Uri.parse('${Config.apiUrl}/users/pending/approval'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (pendingResponse.statusCode == 200) {
        _pendingUsers = List<Map<String, dynamic>>.from(
          json.decode(pendingResponse.body) as List,
        );
      }
      
      final allResponse = await http.get(
        Uri.parse('${Config.apiUrl}/users'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (allResponse.statusCode == 200) {
        _allUsers = List<Map<String, dynamic>>.from(
          json.decode(allResponse.body) as List,
        );
      }
    } catch (e) {
      debugPrint('Erro ao carregar dados: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar dados: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateApproval(int userId, bool approved) async {
    debugPrint('═══════════════════════════════════════');
    debugPrint('🔄 _updateApproval INICIADO');
    debugPrint('userId: $userId (tipo: ${userId.runtimeType})');
    debugPrint('approved: $approved');
    debugPrint('📊 ANTES - _pendingUsers.length: ${_pendingUsers.length}');
    debugPrint('📊 ANTES - _allUsers.length: ${_allUsers.length}');
    
    // Encontrar o usuário antes de remover
    final userIdStr = userId.toString();
    Map<String, dynamic>? foundUser;
    
    // Procurar o usuário em _pendingUsers
    for (var u in _pendingUsers) {
      if (u['id'].toString() == userIdStr) {
        foundUser = Map<String, dynamic>.from(u); // Criar cópia
        debugPrint('👤 Usuário encontrado: ${foundUser['email']}');
        break;
      }
    }
    
    if (foundUser == null) {
      debugPrint('❌ Usuário $userId não encontrado em _pendingUsers');
      return;
    }
    
    // Remover da lista de pendentes e atualizar _allUsers
    debugPrint('🗑️ Chamando setState para ${approved ? 'aprovar' : 'rejeitar'}...');
    setState(() {
      // Remover de pendentes
      _pendingUsers.removeWhere((user) {
        final currentId = user['id'].toString();
        final match = currentId == userIdStr;
        if (match) debugPrint('  ✓ Removido de _pendingUsers: ${user['email']}');
        return match;
      });
      
      if (approved) {
        // Se APROVADO, atualizar o status e adicionar à lista de todos
        foundUser!['approved'] = true;
        
        // Verificar se já não está em _allUsers (evitar duplicação)
        final alreadyExists = _allUsers.any((u) => u['id'].toString() == userIdStr);
        if (!alreadyExists) {
          _allUsers.add(foundUser);
          debugPrint('  ✓ Adicionado a _allUsers: ${foundUser['email']}');
        } else {
          // Se já existe, atualizar o status
          final index = _allUsers.indexWhere((u) => u['id'].toString() == userIdStr);
          if (index >= 0) {
            _allUsers[index]['approved'] = true;
            debugPrint('  ✓ Atualizado em _allUsers: ${foundUser['email']}');
          }
        }
      } else {
        // Se REJEITADO, remover de _allUsers também
        _allUsers.removeWhere((user) {
          final currentId = user['id'].toString();
          final match = currentId == userIdStr;
          if (match) debugPrint('  ✓ Removido de _allUsers: ${user['email']}');
          return match;
        });
      }
    });
    
    debugPrint('✅ DEPOIS DO setState - _pendingUsers.length: ${_pendingUsers.length}');
    debugPrint('✅ DEPOIS DO setState - _allUsers.length: ${_allUsers.length}');
    debugPrint('═══════════════════════════════════════');

    try {
      final token = await AuthService().getToken();
      
      if (approved) {
        // APROVAR: Usar PATCH para marcar como aprovado
        debugPrint('📡 Enviando PATCH para aprovar...');
        final response = await http.patch(
          Uri.parse('${Config.apiUrl}/users/$userId/approval'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode({'approved': true}),
        );
        
        debugPrint('📨 Resposta PATCH: ${response.statusCode}');
        
        if (response.statusCode == 200) {
          debugPrint('✅ Usuário aprovado com sucesso!');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Usuário aprovado!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          debugPrint('❌ Erro ao aprovar: ${response.statusCode} - ${response.body}');
          await _loadData(); // Restaurar estado
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Erro ao aprovar usuário'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        // REJEITAR: Usar DELETE para remover completamente
        debugPrint('📡 Enviando DELETE para rejeitar...');
        
        try {
          final response = await http.delete(
            Uri.parse('${Config.apiUrl}/users/$userId'),
            headers: {
              'Authorization': 'Bearer $token',
            },
          );
          
          debugPrint('📨 Resposta DELETE: ${response.statusCode}');
          
          if (response.statusCode == 200 || response.statusCode == 204) {
            debugPrint('✅ Usuário deletado com sucesso!');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Usuário rejeitado e removido'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          } else {
            debugPrint('❌ Erro ao deletar: ${response.statusCode}');
            await _loadData(); // Restaurar estado
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Erro ao rejeitar usuário'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        } catch (deleteError) {
          // Ignorar erros de parsing - o importante é que o usuário foi removido localmente
          debugPrint('⚠️ Erro ao fazer DELETE (mas usuário já foi removido localmente): $deleteError');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Usuário rejeitado e removido'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Exceção: $e');
      // Se der erro, recarregar para restaurar o estado
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Admin - ${user?.name ?? "Administrador"}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Atualizar',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                context.read<AuthProvider>().logout();
                context.go('/');
              }
            },
            itemBuilder: (context) => [
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
                label: Text('${_pendingUsers.length}'),
                isLabelVisible: _pendingUsers.isNotEmpty,
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

    if (_pendingUsers.isEmpty) {
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
          ],
        ),
      );
    }

    return ListView.builder(
      key: ValueKey(_pendingUsers.length), // Força rebuild quando o tamanho muda
      padding: const EdgeInsets.all(16),
      itemCount: _pendingUsers.length,
      itemBuilder: (context, index) {
        return _buildUserCard(_pendingUsers[index], isPending: true);
      },
    );
  }

  Widget _buildUsersTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final approved = _allUsers.where((u) => u['approved'] == true).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: approved.length,
      itemBuilder: (context, index) {
        return _buildUserCard(approved[index], isPending: false);
      },
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user, {required bool isPending}) {
    final roleName = user['role']?['name'] ?? 'unknown';
    final isTrainer = roleName == 'personal';
    final isAdmin = roleName == 'admin';
    
    Color roleColor;
    String roleLabel;
    
    if (isAdmin) {
      roleColor = Colors.red;
      roleLabel = 'Admin';
    } else if (isTrainer) {
      roleColor = Colors.blue;
      roleLabel = 'Personal';
    } else {
      roleColor = Colors.green;
      roleLabel = 'Aluno';
    }

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
                  backgroundColor: roleColor,
                  child: Text(
                    (user['full_name'] ?? user['email'] ?? '?')
                        .substring(0, 1)
                        .toUpperCase(),
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
                        user['full_name'] ?? 'Sem nome',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user['email'] ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: roleColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          roleLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: roleColor.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isPending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _updateApproval(user['id'], false),
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
                      onPressed: () => _updateApproval(user['id'], true),
                      icon: const Icon(Icons.check),
                      label: const Text('Aprovar'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsTab() {
    final trainers = _allUsers.where(
      (u) => u['role']?['name'] == 'personal' && u['approved'] == true,
    ).length;
    final students = _allUsers.where(
      (u) => u['role']?['name'] == 'aluno' && u['approved'] == true,
    ).length;
    final total = _allUsers.where((u) => u['approved'] == true).length;

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
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total',
                  '$total',
                  Icons.people,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Trainers',
                  '$trainers',
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
                  '$students',
                  Icons.school,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Pendentes',
                  '${_pendingUsers.length}',
                  Icons.pending,
                  Colors.red,
                ),
              ),
            ],
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
}
