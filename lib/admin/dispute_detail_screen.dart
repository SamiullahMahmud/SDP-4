import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AdminDisputeDetailScreen extends StatefulWidget {
  final String disputeId;

  const AdminDisputeDetailScreen({super.key, required this.disputeId});

  @override
  State<AdminDisputeDetailScreen> createState() => _AdminDisputeDetailScreenState();
}

class _AdminDisputeDetailScreenState extends State<AdminDisputeDetailScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  Map<String, dynamic>? disputeData;
  bool _isLoading = true;

  final TextEditingController _disputeReasonController = TextEditingController();
  final TextEditingController _disputeStatusController = TextEditingController();
  final TextEditingController _jobIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchDisputeDetails();
  }

  @override
  void dispose() {
    _disputeReasonController.dispose();
    _disputeStatusController.dispose();
    _jobIdController.dispose();
    super.dispose();
  }

  Future<void> _fetchDisputeDetails() async {
    try {
      final response = await supabase
          .from('disputes')
          .select('*, jobs(job_title), users!job_applications_worker_id_fkey(full_name), users!job_applications_employer_id_fkey(full_name)')
          .eq('id', widget.disputeId)
          .single();

      if (mounted) {
        setState(() {
          disputeData = response;
          _disputeReasonController.text = disputeData?['dispute_reason'] ?? '';
          _disputeStatusController.text = disputeData?['dispute_status'] ?? '';
          _jobIdController.text = disputeData?['job_id'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load dispute details: ${e.toString()}')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateDisputeStatus(String status) async {
    try {
      await supabase
          .from('disputes')
          .update({'dispute_status': status})
          .eq('id', widget.disputeId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Dispute status updated to $status!')));
        _fetchDisputeDetails(); // Re-fetch to ensure latest data is displayed
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update dispute status: ${e.toString()}')));
      }
    }
  }

  Widget _buildDetailField({
    required String label,
    required TextEditingController controller,
    bool isEditable = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        readOnly: !isEditable,
        keyboardType: keyboardType,
        style: Theme.of(context).textTheme.bodyLarge, // Use theme text style
        decoration: InputDecoration(
          labelText: label,
        ),
      ),
    );
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
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadeInDown(
                        duration: const Duration(milliseconds: 800),
                        child: Text(
                          'Dispute Details',
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
                      const SizedBox(height: 20),
                      _buildDetailField(label: 'Dispute Reason', controller: _disputeReasonController),
                      _buildDetailField(label: 'Current Status', controller: _disputeStatusController),
                      _buildDetailField(label: 'Job ID', controller: _jobIdController),
                      if (disputeData?['jobs'] != null)
                        _buildDetailField(label: 'Job Title', controller: TextEditingController(text: disputeData!['jobs']['job_title'])),
                      if (disputeData?['users!job_applications_worker_id_fkey'] != null)
                        _buildDetailField(label: 'Worker Name', controller: TextEditingController(text: disputeData!['users!job_applications_worker_id_fkey']['full_name'])),
                      if (disputeData?['users!job_applications_employer_id_fkey'] != null)
                        _buildDetailField(label: 'Employer Name', controller: TextEditingController(text: disputeData!['users!job_applications_employer_id_fkey']['full_name'])),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _updateDisputeStatus('resolved'),
                            icon: const FaIcon(FontAwesomeIcons.checkCircle, color: Colors.white),
                            label: const Text('Resolve'),
                            style: Theme.of(context).elevatedButtonTheme.style?.copyWith(
                              backgroundColor: MaterialStateProperty.resolveWith((states) => Theme.of(context).primaryColor), // Use theme color
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _updateDisputeStatus('rejected'),
                            icon: const FaIcon(FontAwesomeIcons.timesCircle, color: Colors.white),
                            label: const Text('Reject'),
                            style: Theme.of(context).elevatedButtonTheme.style?.copyWith(
                              backgroundColor: MaterialStateProperty.resolveWith((states) => Theme.of(context).colorScheme.error), // Use theme color
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}