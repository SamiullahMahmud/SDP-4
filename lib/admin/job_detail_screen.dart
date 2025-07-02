import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AdminJobDetailScreen extends StatefulWidget {
  final String jobId;

  const AdminJobDetailScreen({super.key, required this.jobId});

  @override
  State<AdminJobDetailScreen> createState() => _AdminJobDetailScreenState();
}

class _AdminJobDetailScreenState extends State<AdminJobDetailScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  Map<String, dynamic>? jobData;
  bool _isLoading = true;
  bool _isEditing = false;

  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _jobDescriptionController = TextEditingController();
  final TextEditingController _jobCategoryController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _jobTypeController = TextEditingController();
  final TextEditingController _salaryController = TextEditingController();
  final TextEditingController _experienceLevelController = TextEditingController();
  final TextEditingController _requiredSkillsController = TextEditingController();
  final TextEditingController _deadlineController = TextEditingController();
  final TextEditingController _paymentMethodController = TextEditingController();
  final TextEditingController _requiredExperienceController = TextEditingController();
  final TextEditingController _jobUrgencyController = TextEditingController();
  final TextEditingController _companySizeController = TextEditingController();
  final TextEditingController _workHoursController = TextEditingController();
  final TextEditingController _contractTypeController = TextEditingController();
  final TextEditingController _genderPreferenceController = TextEditingController();
  final TextEditingController _remoteOnSiteIndicatorController = TextEditingController();
  final TextEditingController _workScheduleController = TextEditingController();
  final TextEditingController _languagesRequiredController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchJobDetails();
  }

  @override
  void dispose() {
    _jobTitleController.dispose();
    _jobDescriptionController.dispose();
    _jobCategoryController.dispose();
    _locationController.dispose();
    _jobTypeController.dispose();
    _salaryController.dispose();
    _experienceLevelController.dispose();
    _requiredSkillsController.dispose();
    _deadlineController.dispose();
    _paymentMethodController.dispose();
    _requiredExperienceController.dispose();
    _jobUrgencyController.dispose();
    _companySizeController.dispose();
    _workHoursController.dispose();
    _contractTypeController.dispose();
    _genderPreferenceController.dispose();
    _remoteOnSiteIndicatorController.dispose();
    _workScheduleController.dispose();
    _languagesRequiredController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  Future<void> _fetchJobDetails() async {
    try {
      final response = await supabase
          .from('jobs')
          .select('*')
          .eq('id', widget.jobId)
          .single();

      if (mounted) {
        setState(() {
          jobData = response;
          _jobTitleController.text = jobData?['job_title'] ?? '';
          _jobDescriptionController.text = jobData?['job_description'] ?? '';
          _jobCategoryController.text = jobData?['job_category'] ?? '';
          _locationController.text = jobData?['location'] ?? '';
          _jobTypeController.text = jobData?['job_type'] ?? '';
          _salaryController.text = jobData?['salary']?.toString() ?? '';
          _experienceLevelController.text = jobData?['experience_level'] ?? '';
          _requiredSkillsController.text = (jobData?['required_skills'] as List?)?.join(', ') ?? '';
          _deadlineController.text = jobData?['deadline'] ?? '';
          _paymentMethodController.text = jobData?['payment_method'] ?? '';
          _requiredExperienceController.text = jobData?['required_experience']?.toString() ?? '';
          _jobUrgencyController.text = jobData?['job_urgency'] ?? '';
          _companySizeController.text = jobData?['company_size'] ?? '';
          _workHoursController.text = jobData?['work_hours'] ?? '';
          _contractTypeController.text = jobData?['contract_type'] ?? '';
          _genderPreferenceController.text = jobData?['gender_preference'] ?? '';
          _remoteOnSiteIndicatorController.text = jobData?['remote_on_site_indicator'] ?? '';
          _workScheduleController.text = jobData?['work_schedule'] ?? '';
          _languagesRequiredController.text = (jobData?['languages_required'] as List?)?.join(', ') ?? '';
          _statusController.text = jobData?['status'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load job details: ${e.toString()}')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateJobDetails() async {
    try {
      await supabase
          .from('jobs')
          .update({
            'job_title': _jobTitleController.text,
            'job_description': _jobDescriptionController.text,
            'job_category': _jobCategoryController.text,
            'location': _locationController.text,
            'job_type': _jobTypeController.text,
            'salary': double.tryParse(_salaryController.text) ?? 0.0,
            'experience_level': _experienceLevelController.text,
            'required_skills': _requiredSkillsController.text.split(',').map((s) => s.trim()).toList(),
            'deadline': _deadlineController.text,
            'payment_method': _paymentMethodController.text,
            'required_experience': int.tryParse(_requiredExperienceController.text) ?? 0,
            'job_urgency': _jobUrgencyController.text,
            'company_size': _companySizeController.text,
            'work_hours': _workHoursController.text,
            'contract_type': _contractTypeController.text,
            'gender_preference': _genderPreferenceController.text,
            'remote_on_site_indicator': _remoteOnSiteIndicatorController.text,
            'work_schedule': _workScheduleController.text,
            'languages_required': _languagesRequiredController.text.split(',').map((s) => s.trim()).toList(),
            'status': _statusController.text,
          })
          .eq('id', widget.jobId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job details updated successfully!')));
        setState(() => _isEditing = false);
        _fetchJobDetails(); // Re-fetch to ensure latest data is displayed
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update job details: ${e.toString()}')));
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
                          'Job Details',
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
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _isEditing = !_isEditing;
                            });
                            if (!_isEditing) {
                              _updateJobDetails();
                            }
                          },
                          icon: FaIcon(_isEditing ? FontAwesomeIcons.save : FontAwesomeIcons.edit, color: Colors.white),
                          label: Text(_isEditing ? 'Save' : 'Edit', style: Theme.of(context).textTheme.labelLarge), // Use theme text style
                          style: Theme.of(context).elevatedButtonTheme.style?.copyWith(
                            backgroundColor: MaterialStateProperty.resolveWith((states) => _isEditing ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.secondary),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildDetailField(label: 'Job Title', controller: _jobTitleController, isEditable: _isEditing),
                      _buildDetailField(label: 'Job Description', controller: _jobDescriptionController, isEditable: _isEditing),
                      _buildDetailField(label: 'Job Category', controller: _jobCategoryController, isEditable: _isEditing),
                      _buildDetailField(label: 'Location', controller: _locationController, isEditable: _isEditing),
                      _buildDetailField(label: 'Job Type', controller: _jobTypeController, isEditable: _isEditing),
                      _buildDetailField(label: 'Salary', controller: _salaryController, isEditable: _isEditing, keyboardType: TextInputType.number),
                      _buildDetailField(label: 'Experience Level', controller: _experienceLevelController, isEditable: _isEditing),
                      _buildDetailField(label: 'Required Skills', controller: _requiredSkillsController, isEditable: _isEditing),
                      _buildDetailField(label: 'Deadline', controller: _deadlineController, isEditable: _isEditing),
                      _buildDetailField(label: 'Payment Method', controller: _paymentMethodController, isEditable: _isEditing),
                      _buildDetailField(label: 'Required Experience', controller: _requiredExperienceController, isEditable: _isEditing, keyboardType: TextInputType.number),
                      _buildDetailField(label: 'Job Urgency', controller: _jobUrgencyController, isEditable: _isEditing),
                      _buildDetailField(label: 'Company Size', controller: _companySizeController, isEditable: _isEditing),
                      _buildDetailField(label: 'Work Hours', controller: _workHoursController, isEditable: _isEditing),
                      _buildDetailField(label: 'Contract Type', controller: _contractTypeController, isEditable: _isEditing),
                      _buildDetailField(label: 'Gender Preference', controller: _genderPreferenceController, isEditable: _isEditing),
                      _buildDetailField(label: 'Remote/On-site Indicator', controller: _remoteOnSiteIndicatorController, isEditable: _isEditing),
                      _buildDetailField(label: 'Work Schedule', controller: _workScheduleController, isEditable: _isEditing),
                      _buildDetailField(label: 'Languages Required', controller: _languagesRequiredController, isEditable: _isEditing),
                      _buildDetailField(label: 'Status', controller: _statusController, isEditable: _isEditing),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}