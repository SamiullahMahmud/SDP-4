import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'admin_user_detail_screen.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final response = await supabase.from('users').select();
      if (mounted) {
        setState(() {
          users = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load users: ${e.toString()}')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _confirmAndDeleteUser(String userId, String userName) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor, // Use theme color
          title: Text('Confirm Deletion', style: Theme.of(context).textTheme.titleLarge), // Use theme text style
          content: Text('Are you sure you want to delete user "$userName"? This action cannot be undone.', style: Theme.of(context).textTheme.bodyMedium), // Use theme text style
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel', style: TextStyle(color: Theme.of(context).primaryColor)), // Use theme color
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)), // Use theme color
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      _deleteUser(userId);
    }
  }

  Future<void> _deleteUser(String userId) async {
    try {
      await supabase.from('users').delete().eq('id', userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User deleted successfully!')));
        _fetchUsers(); // Refresh the list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete user: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Theme.of(context).scaffoldBackgroundColor, Theme.of(context).colorScheme.surface], // Use theme colors
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeInDown(
                  duration: const Duration(milliseconds: 800),
                  child: Text(
                    'User Management',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      shadows: [
                        Shadow(
                          blurRadius: 10,
                          color: Theme.of(context).primaryColor.withAlpha(77),
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : users.isEmpty
                          ? FadeInUp(
                              duration: const Duration(milliseconds: 800),
                              delay: const Duration(milliseconds: 200),
                              child: Center(
                                child: Text(
                                  'No users found.',
                                  style: Theme.of(context).textTheme.bodyMedium, // Use theme text style
                                ),
                              ),
                            )
                          : FadeInUp(
                              duration: const Duration(milliseconds: 800),
                              delay: const Duration(milliseconds: 200),
                              child: ListView.builder(
                            itemCount: users.length,
                            itemBuilder: (context, index) {
                              final user = users[index];
                              return Card(
                                color: Theme.of(context).cardColor, // Use theme color
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Theme.of(context).primaryColor, // Use theme color
                                    child: Text(user['full_name'] != null && user['full_name'].isNotEmpty ? user['full_name'][0] : 'U', style: const TextStyle(color: Colors.white)),
                                  ),
                                  title: Text(
                                    user['full_name'] ?? 'N/A',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), // Use theme text style
                                  ),
                                  subtitle: Text(
                                    '${user['email'] ?? 'N/A'} - ${user['user_type'] ?? 'N/A'}',
                                    style: Theme.of(context).textTheme.bodyMedium, // Use theme text style
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: FaIcon(FontAwesomeIcons.edit, color: Theme.of(context).primaryColor), // Use theme color
                                        onPressed: () {
                                          Navigator.push(context, MaterialPageRoute(builder: (context) => AdminUserDetailScreen(userId: user['id'])));
                                        },
                                      ),
                                      IconButton(
                                        icon: FaIcon(FontAwesomeIcons.trash, color: Theme.of(context).colorScheme.error), // Use theme color
                                        onPressed: () => _confirmAndDeleteUser(user['id'], user['full_name'] ?? 'Unknown User'),
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => AdminUserDetailScreen(userId: user['id'])));
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}