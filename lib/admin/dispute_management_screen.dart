import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'admin_dispute_detail_screen.dart';

class AdminDisputeManagementScreen extends StatefulWidget {
  const AdminDisputeManagementScreen({super.key});

  @override
  State<AdminDisputeManagementScreen> createState() => _AdminDisputeManagementScreenState();
}

class _AdminDisputeManagementScreenState extends State<AdminDisputeManagementScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> disputes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDisputes();
  }

  Future<void> _fetchDisputes() async {
    try {
      final response = await supabase.from('disputes').select();
      if (mounted) {
        setState(() {
          disputes = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load disputes: ${e.toString()}')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateDisputeStatus(String disputeId, String status) async {
    try {
      await supabase.from('disputes').update({'dispute_status': status}).eq('id', disputeId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Dispute status updated to $status!')));
        _fetchDisputes(); // Refresh the list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update dispute status: ${e.toString()}')));
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
                    'Dispute Management',
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
                      : disputes.isEmpty
                          ? FadeInUp(
                              duration: const Duration(milliseconds: 800),
                              delay: const Duration(milliseconds: 200),
                              child: Center(
                                child: Text(
                                  'No disputes found.',
                                  style: Theme.of(context).textTheme.bodyMedium, // Use theme text style
                                ),
                              ),
                            )
                          : FadeInUp(
                              duration: const Duration(milliseconds: 800),
                              delay: const Duration(milliseconds: 200),
                              child: ListView.builder(
                            itemCount: disputes.length,
                            itemBuilder: (context, index) {
                              final dispute = disputes[index];
                              return Card(
                                color: Theme.of(context).cardColor, // Use theme color
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: ListTile(
                                  title: Text(
                                    'Dispute ID: ${dispute['id']}',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), // Use theme text style
                                  ),
                                  subtitle: Text(
                                    'Reason: ${dispute['dispute_reason'] ?? 'N/A'}\nStatus: ${dispute['dispute_status'] ?? 'N/A'}',
                                    style: Theme.of(context).textTheme.bodyMedium, // Use theme text style
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (String value) {
                                      _updateDisputeStatus(dispute['id'], value);
                                    },
                                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                      PopupMenuItem<String>(
                                        value: 'pending',
                                        child: Text('Mark as Pending', style: Theme.of(context).textTheme.bodyMedium), // Use theme text style
                                      ),
                                      PopupMenuItem<String>(
                                        value: 'resolved',
                                        child: Text('Mark as Resolved', style: Theme.of(context).textTheme.bodyMedium), // Use theme text style
                                      ),
                                      PopupMenuItem<String>(
                                        value: 'rejected',
                                        child: Text('Mark as Rejected', style: Theme.of(context).textTheme.bodyMedium), // Use theme text style
                                      ),
                                    ],
                                    color: Theme.of(context).cardColor, // Use theme color
                                  ),
                                  onTap: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => AdminDisputeDetailScreen(disputeId: dispute['id'])));
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