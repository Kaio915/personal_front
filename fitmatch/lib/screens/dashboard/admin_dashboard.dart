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
  String _statsFilter = 'none';
  String _approvalsFilter = 'none';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
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
        debugPrint('📋 Pending users loaded: ${_pendingUsers.length}');
        if (_pendingUsers.isNotEmpty) {
          debugPrint('📋 Sample user data: ${_pendingUsers.first}');
        }
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
    final userIdStr = userId.toString();
    Map<String, dynamic>? foundUser;
    
    for (var u in _pendingUsers) {
      if (u['id'].toString() == userIdStr) {
        foundUser = Map<String, dynamic>.from(u);
        break;
      }
    }
    
    if (foundUser == null) {
      return;
    }
    
    setState(() {
      _pendingUsers.removeWhere((user) => user['id'].toString() == userIdStr);
      
      if (approved) {
        foundUser!['approved'] = true;
        final alreadyExists = _allUsers.any((u) => u['id'].toString() == userIdStr);
        if (!alreadyExists) {
          _allUsers.add(foundUser);
        } else {
          final index = _allUsers.indexWhere((u) => u['id'].toString() == userIdStr);
          if (index >= 0) {
            _allUsers[index]['approved'] = true;
          }
        }
      } else {
        _allUsers.removeWhere((user) => user['id'].toString() == userIdStr);
      }
    });
    
    try {
      final token = await AuthService().getToken();
      
      if (approved) {
        final response = await http.patch(
          Uri.parse('${Config.apiUrl}/users/$userId/approval'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode({'approved': true}),
        );
        
        if (response.statusCode == 200 && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usuário aprovado com sucesso'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        final response = await http.delete(
          Uri.parse('${Config.apiUrl}/users/$userId'),
          headers: {'Authorization': 'Bearer $token'},
        );
        
        if (response.statusCode == 200 && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usuário rejeitado'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
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

  Future<void> _confirmDeleteUser(Map<String, dynamic> user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.red.shade700, size: 28),
            const SizedBox(width: 12),
            const Text('Confirmar Exclusão'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tem certeza que deseja excluir este usuário?',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['full_name'] ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user['email'] ?? 'N/A',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Esta ação não pode ser desfeita.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _deleteUser(user['id'] as int);
    }
  }

  Future<void> _deleteUser(int userId) async {
    setState(() {
      _allUsers.removeWhere((u) => u['id'] == userId);
      _pendingUsers.removeWhere((u) => u['id'] == userId);
    });

    try {
      final token = await AuthService().getToken();
      final response = await http.delete(
        Uri.parse('${Config.apiUrl}/users/$userId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuário excluído com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
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
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // Header moderno
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, size: 24),
                      onPressed: () => context.go('/'),
                      tooltip: 'Voltar',
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.admin_panel_settings,
                        color: Colors.blue.shade700,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Painel Administrativo',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          user?.name ?? 'Administrador',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 24),
                      onPressed: _loadData,
                      tooltip: 'Atualizar',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () async {
                        await context.read<AuthProvider>().logout();
                        if (!context.mounted) return;
                        context.go('/');
                      },
                      icon: const Icon(Icons.logout, size: 20),
                      label: const Text('Sair'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Tabs modernos
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.blue.shade700,
                unselectedLabelColor: Colors.grey.shade600,
                indicatorColor: Colors.blue.shade700,
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.normal,
                ),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Aprovações'),
                        if (_pendingUsers.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.shade500,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_pendingUsers.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Tab(text: 'Estatísticas'),
                ],
              ),
            ),
            
            // Conteúdo
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildApprovalsTab(),
                  _buildStatsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalsTab() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
            ),
            const SizedBox(height: 16),
            Text(
              'Carregando dados...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    final pendingStudents = _pendingUsers.where(
      (u) => u['role']?['name'] == 'aluno',
    ).toList();
    
    final pendingTrainers = _pendingUsers.where(
      (u) => u['role']?['name'] == 'personal',
    ).toList();

    // Se um filtro estiver ativo, mostrar a lista filtrada
    if (_approvalsFilter != 'none') {
      List<Map<String, dynamic>> filteredUsers;
      String title;
      IconData icon;
      Color color;
      
      if (_approvalsFilter == 'students') {
        filteredUsers = pendingStudents;
        title = 'Alunos Pendentes';
        icon = Icons.school;
        color = Colors.blue.shade700;
      } else {
        filteredUsers = pendingTrainers;
        title = 'Personal Trainers Pendentes';
        icon = Icons.fitness_center;
        color = Colors.orange.shade700;
      }
      
      // Filtrar por busca
      if (_searchQuery.isNotEmpty) {
        filteredUsers = filteredUsers.where((user) {
          final name = (user['full_name'] ?? '').toLowerCase();
          final email = (user['email'] ?? '').toLowerCase();
          final query = _searchQuery.toLowerCase();
          return name.contains(query) || email.contains(query);
        }).toList();
      }
      
      return Column(
        children: [
          // Cabeçalho com busca
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, size: 22),
                      onPressed: () {
                        setState(() {
                          _approvalsFilter = 'none';
                          _searchQuery = '';
                          _searchController.clear();
                        });
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            '${filteredUsers.length} solicitaç${filteredUsers.length == 1 ? 'ão' : 'ões'}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nome ou email...',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade600, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: color, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ],
            ),
          ),
          
          // Lista de usuários
          Expanded(
            child: filteredUsers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _searchQuery.isNotEmpty
                                ? Icons.search_off
                                : Icons.check_circle_outline,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Nenhum resultado encontrado'
                              : 'Nenhuma solicitação pendente',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Tente buscar com outros termos'
                              : 'Todas as solicitações foram processadas',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      return _buildUserCard(user, isPending: true);
                    },
                  ),
          ),
        ],
      );
    }

    // Vista inicial com cards de categoria
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Solicitações de cadastro aguardando aprovação',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 768) {
                // Desktop - 2 colunas
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildApprovalCategoryCard(
                        'Personal Trainers Pendentes',
                        pendingTrainers.length,
                        Icons.fitness_center,
                        Colors.orange.shade700,
                        onTap: () {
                          setState(() {
                            _approvalsFilter = 'trainers';
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _buildApprovalCategoryCard(
                        'Alunos Pendentes',
                        pendingStudents.length,
                        Icons.school,
                        Colors.blue.shade700,
                        onTap: () {
                          setState(() {
                            _approvalsFilter = 'students';
                          });
                        },
                      ),
                    ),
                  ],
                );
              } else {
                // Mobile - 1 coluna
                return Column(
                  children: [
                    _buildApprovalCategoryCard(
                      'Personal Trainers Pendentes',
                      pendingTrainers.length,
                      Icons.fitness_center,
                      Colors.orange.shade700,
                      onTap: () {
                        setState(() {
                          _approvalsFilter = 'trainers';
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildApprovalCategoryCard(
                      'Alunos Pendentes',
                      pendingStudents.length,
                      Icons.school,
                      Colors.blue.shade700,
                      onTap: () {
                        setState(() {
                          _approvalsFilter = 'students';
                        });
                      },
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalCategoryCard(
    String title,
    int count,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: count > 0 ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: count > 0 ? color.withOpacity(0.3) : Colors.grey.shade300,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: count > 0 ? color.withOpacity(0.08) : Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: count > 0 ? color.withOpacity(0.1) : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 48,
                  color: count > 0 ? color : Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: count > 0 ? color : Colors.grey.shade400,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: count > 0 ? Colors.black87 : Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                count == 1 ? 'solicitação' : 'solicitações',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),
              if (count > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Ver detalhes',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: color,
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Nenhuma pendência',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user, {bool isPending = false}) {
    final roleName = user['role']?['name'] ?? 'N/A';
    final isStudent = roleName == 'aluno';
    final color = isStudent ? Colors.blue.shade700 : Colors.orange.shade700;
    final roleLabel = isStudent ? 'Aluno' : 'Personal Trainer';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200, width: 1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isStudent ? Icons.school : Icons.fitness_center,
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user['full_name'] ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user['email'] ?? 'N/A',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      roleLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: isStudent ? [
                    // Campos para Alunos
                    _buildInfoRow('Objetivos', user['goals'] ?? 'N/A'),
                    const SizedBox(height: 12),
                    _buildInfoRow('Nível', user['fitnessLevel'] ?? user['fitness_level'] ?? 'N/A'),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      'Data de Cadastro',
                      user['created_at'] != null
                          ? _formatDate(user['created_at'])
                          : (user['registration_date'] != null
                              ? _formatDate(user['registration_date'])
                              : 'N/A'),
                    ),
                  ] : [
                    // Campos para Personal Trainers
                    _buildInfoRow('Especialidade', user['specialty'] ?? 'N/A'),
                    const SizedBox(height: 12),
                    _buildInfoRow('CREF', user['cref'] ?? 'N/A'),
                    const SizedBox(height: 12),
                    _buildInfoRow('Experiência', user['experience'] ?? 'N/A'),
                    const SizedBox(height: 12),
                    _buildInfoRow('Cidade', user['city'] ?? 'N/A'),
                    const SizedBox(height: 12),
                    _buildInfoRow('Valor/Hora', user['hourlyRate'] ?? user['hourly_rate'] ?? 'N/A'),
                    const SizedBox(height: 12),
                    _buildInfoRow('Bio', user['bio'] ?? 'N/A'),
                  ],
                ),
              ),
              if (isPending) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _updateApproval(user['id'] as int, false),
                        icon: const Icon(Icons.close, size: 20),
                        label: const Text('Rejeitar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          side: BorderSide(color: Colors.red.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _updateApproval(user['id'] as int, true),
                        icon: const Icon(Icons.check, size: 20),
                        label: const Text('Aprovar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmDeleteUser(user),
                    icon: const Icon(Icons.delete_outline, size: 20),
                    label: const Text('Excluir Usuário'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(String date) {
    try {
      final parsedDate = DateTime.parse(date);
      return '${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year}';
    } catch (e) {
      return date;
    }
  }

  Widget _buildStatsTab() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
            ),
            const SizedBox(height: 16),
            Text(
              'Carregando dados...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    final totalUsers = _allUsers.length;
    final trainersCount = _allUsers.where((u) => u['role']?['name'] == 'personal').length;
    final studentsCount = _allUsers.where((u) => u['role']?['name'] == 'aluno').length;

    if (_statsFilter != 'none') {
      List<Map<String, dynamic>> filteredUsers;
      String title;
      IconData icon;
      Color color;

      switch (_statsFilter) {
        case 'total':
          filteredUsers = _allUsers;
          title = 'Todos os Usuários';
          icon = Icons.people;
          color = Colors.purple.shade700;
          break;
        case 'trainers':
          filteredUsers = _allUsers.where((u) => u['role']?['name'] == 'personal').toList();
          title = 'Personal Trainers';
          icon = Icons.fitness_center;
          color = Colors.orange.shade700;
          break;
        case 'students':
          filteredUsers = _allUsers.where((u) => u['role']?['name'] == 'aluno').toList();
          title = 'Alunos';
          icon = Icons.school;
          color = Colors.blue.shade700;
          break;
        default:
          filteredUsers = [];
          title = '';
          icon = Icons.error;
          color = Colors.grey;
      }

      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, size: 22),
                  onPressed: () {
                    setState(() {
                      _statsFilter = 'none';
                    });
                  },
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '${filteredUsers.length} ${filteredUsers.length == 1 ? 'usuário' : 'usuários'}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredUsers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Nenhum usuário encontrado',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      return _buildUserCard(user, isPending: _statsFilter == 'pending');
                    },
                  ),
          ),
        ],
      );
    }

    // Vista inicial com estatísticas
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Visão geral do sistema',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(
                'Total de Usuários',
                totalUsers,
                Icons.people,
                Colors.purple.shade700,
                onTap: () {
                  setState(() {
                    _statsFilter = 'total';
                  });
                },
              ),
              _buildStatCard(
                'Personal Trainers',
                trainersCount,
                Icons.fitness_center,
                Colors.orange.shade700,
                onTap: () {
                  setState(() {
                    _statsFilter = 'trainers';
                  });
                },
              ),
              _buildStatCard(
                'Alunos',
                studentsCount,
                Icons.school,
                Colors.blue.shade700,
                onTap: () {
                  setState(() {
                    _statsFilter = 'students';
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    int count,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
