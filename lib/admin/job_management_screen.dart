import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'admin_job_detail_screen.dart';

class AdminJobManagementScreen extends StatefulWidget {
  const AdminJobManagementScreen({super.key});

  @override
  State<AdminJobManagementScreen> createState() => _AdminJobManagementScreenState();
}

class _AdminJobManagementScreenState extends State<AdminJobManagementScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> jobs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchJobs();
  }

  Future<void> _fetchJobs() async {
    try {
      final response = await supabase.from('jobs').select();
      if (mounted) {
        setState(() {
          jobs = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load jobs: ${e.toString()}')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _confirmAndDeleteJob(String jobId, String jobTitle) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor, // Use theme color
          title: Text('Confirm Deletion', style: Theme.of(context).textTheme.titleLarge), // Use theme text style
          content: Text('Are you sure you want to delete job "$jobTitle"? This action cannot be undone.', style: Theme.of(context).textTheme.bodyMedium), // Use theme text style
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
      _deleteJob(jobId);
    }
  }

  Future<void> _deleteJob(String jobId) async {
    try {
      await supabase.from('jobs').delete().eq('id', jobId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job deleted successfully!')));
        _fetchJobs(); // Refresh the list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete job: ${e.toString()}')));
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
                    'Job Management',
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
                      : jobs.isEmpty
                          ? FadeInUp(
                              duration: const Duration(milliseconds: 800),
                              delay: const Duration(milliseconds: 200),
                              child: Center(
                                child: Text(
                                  'No jobs found.',
                                  style: Theme.of(context).textTheme.bodyMedium, // Use theme text style
                                ),
                              ),
                            )
                          : FadeInUp(
                              duration: const Duration(milliseconds: 800),
                              delay: const Duration(milliseconds: 200),
                              child: ListView.builder(
                            itemCount: jobs.length,
                            itemBuilder: (context, index) {
                              final job = jobs[index];
                              return Card(
                                color: Theme.of(context).cardColor, // Use theme color
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: ListTile(
                                  title: Text(
                                    job['job_title'] ?? 'N/A',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), // Use theme text style
                                  ),
                                  subtitle: Text(
                                    '${job['job_category'] ?? 'N/A'} - ${job['location'] ?? 'N/A'}',
                                    style: Theme.of(context).textTheme.bodyMedium, // Use theme text style
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: FaIcon(FontAwesomeIcons.edit, color: Theme.of(context).primaryColor), // Use theme color
                                        onPressed: () {
                                          Navigator.push(context, MaterialPageRoute(builder: (context) => AdminJobDetailScreen(jobId: job['id'])));
                                        },
                                      ),
                                      IconButton(
                                        icon: FaIcon(FontAwesomeIcons.trash, color: Theme.of(context).colorScheme.error), // Use theme color
                                        onPressed: () => _confirmAndDeleteJob(job['id'], job['job_title'] ?? 'Unknown Job'),
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => AdminJobDetailScreen(jobId: job['id'])));
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