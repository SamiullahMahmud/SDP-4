import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AdminNidReviewScreen extends StatefulWidget {
  const AdminNidReviewScreen({super.key});

  @override
  State<AdminNidReviewScreen> createState() => _AdminNidReviewScreenState();
}

class _AdminNidReviewScreenState extends State<AdminNidReviewScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> pendingNidVerifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPendingNidVerifications();
  }

  Future<void> _fetchPendingNidVerifications() async {
    try {
      final response = await supabase
          .from('nid_verifications')
          .select('*, users(full_name, email)')
          .eq('verification_status', 'pending');

      if (mounted) {
        setState(() {
          pendingNidVerifications = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load NID verifications: ${e.toString()}')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateVerificationStatus(String verificationId, String status) async {
    try {
      await supabase
          .from('nid_verifications')
          .update({'verification_status': status})
          .eq('id', verificationId);

      // Also update user's verification status in the users table
      final verification = pendingNidVerifications.firstWhere((element) => element['id'] == verificationId);
      final userId = verification['user_id'];
      await supabase.from('users').update({'verification_status': status}).eq('id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('NID verification ${status}!')));
        _fetchPendingNidVerifications(); // Refresh the list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update verification status: ${e.toString()}')));
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
                    'NID Verification Review',
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
                      : pendingNidVerifications.isEmpty
                          ? FadeInUp(
                              duration: const Duration(milliseconds: 800),
                              delay: const Duration(milliseconds: 200),
                              child: Center(
                                child: Text(
                                  'No pending NID verifications.',
                                  style: Theme.of(context).textTheme.bodyMedium, // Use theme text style
                                ),
                              ),
                            )
                          : FadeInUp(
                              duration: const Duration(milliseconds: 800),
                              delay: const Duration(milliseconds: 200),
                              child: ListView.builder(
                                itemCount: pendingNidVerifications.length,
                                itemBuilder: (context, index) {
                                  final verification = pendingNidVerifications[index];
                                  final user = verification['users'];
                                  return Card(
                                    color: Theme.of(context).cardColor, // Use theme color
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                    margin: const EdgeInsets.symmetric(vertical: 8),
                                    child: ExpansionTile(
                                      leading: FaIcon(FontAwesomeIcons.idCard, color: Theme.of(context).primaryColor), // Use theme color
                                      title: Text(
                                        user?['full_name'] ?? 'N/A',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), // Use theme text style
                                      ),
                                      subtitle: Text(user?['email'] ?? 'N/A', style: Theme.of(context).textTheme.bodyMedium), // Use theme text style
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('NID Number: ${verification['nid_number'] ?? 'N/A'}', style: Theme.of(context).textTheme.bodyLarge), // Use theme text style
                                              const SizedBox(height: 10),
                                              Text('Front Image:', style: Theme.of(context).textTheme.bodyLarge), // Use theme text style
                                              CachedNetworkImage(
                                                imageUrl: verification['front_image_url'] ?? '',
                                                placeholder: (context, url) => const CircularProgressIndicator(),
                                                errorWidget: (context, url, error) => Icon(Icons.error, color: Theme.of(context).colorScheme.error), // Use theme color
                                                width: double.infinity,
                                                height: 200,
                                                fit: BoxFit.cover,
                                              ),
                                              const SizedBox(height: 10),
                                              Text('Back Image:', style: Theme.of(context).textTheme.bodyLarge), // Use theme text style
                                              CachedNetworkImage(
                                                imageUrl: verification['back_image_url'] ?? '',
                                                placeholder: (context, url) => const CircularProgressIndicator(),
                                                errorWidget: (context, url, error) => Icon(Icons.error, color: Theme.of(context).colorScheme.error), // Use theme color
                                                width: double.infinity,
                                                height: 200,
                                                fit: BoxFit.cover,
                                              ),
                                              const SizedBox(height: 20),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                children: [
                                                  ElevatedButton.icon(
                                                    onPressed: () => _updateVerificationStatus(verification['id'], 'approved'),
                                                    icon: const Icon(Icons.check, color: Colors.white),
                                                    label: const Text('Approve'),
                                                    style: Theme.of(context).elevatedButtonTheme.style?.copyWith(
                                                      backgroundColor: MaterialStateProperty.resolveWith((states) => Colors.green), // Use theme color
                                                    ),
                                                  ),
                                                  ElevatedButton.icon(
                                                    onPressed: () => _updateVerificationStatus(verification['id'], 'rejected'),
                                                    icon: const Icon(Icons.close, color: Colors.white),
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
                                      ],
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