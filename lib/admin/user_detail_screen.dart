import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AdminUserDetailScreen extends StatefulWidget {
  final String userId;

  const AdminUserDetailScreen({super.key, required this.userId});

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  Map<String, dynamic>? userData;
  bool _isLoading = true;
  bool _isEditing = false;

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileNumberController = TextEditingController();
  final TextEditingController _userTypeController = TextEditingController();
  final TextEditingController _verificationStatusController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();
  final TextEditingController _educationController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _primaryOccupationController = TextEditingController();
  final TextEditingController _skillsController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _upazilaController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _businessRegNumberController = TextEditingController();
  final TextEditingController _industrySectorController = TextEditingController();
  final TextEditingController _companySizeController = TextEditingController();
  final TextEditingController _officeLocationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _mobileNumberController.dispose();
    _userTypeController.dispose();
    _verificationStatusController.dispose();
    _roleController.dispose();
    _educationController.dispose();
    _experienceController.dispose();
    _primaryOccupationController.dispose();
    _skillsController.dispose();
    _districtController.dispose();
    _upazilaController.dispose();
    _companyNameController.dispose();
    _businessRegNumberController.dispose();
    _industrySectorController.dispose();
    _companySizeController.dispose();
    _officeLocationController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserDetails() async {
    try {
      final response = await supabase
          .from('users')
          .select('*')
          .eq('id', widget.userId)
          .single();

      if (mounted) {
        setState(() {
          userData = response;
          _fullNameController.text = userData?['full_name'] ?? '';
          _emailController.text = userData?['email'] ?? '';
          _mobileNumberController.text = userData?['mobile_number'] ?? '';
          _userTypeController.text = userData?['user_type'] ?? '';
          _verificationStatusController.text = userData?['verification_status'] ?? '';
          _roleController.text = userData?['role'] ?? '';
          _educationController.text = userData?['education'] ?? '';
          _experienceController.text = userData?['experience'] ?? '';
          _primaryOccupationController.text = userData?['primary_occupation'] ?? '';
          _skillsController.text = (userData?['skills'] as List?)?.join(', ') ?? '';
          _districtController.text = userData?['district'] ?? '';
          _upazilaController.text = userData?['upazila'] ?? '';
          _companyNameController.text = userData?['company_name'] ?? '';
          _businessRegNumberController.text = userData?['business_reg_number'] ?? '';
          _industrySectorController.text = userData?['industry_sector'] ?? '';
          _companySizeController.text = userData?['company_size'] ?? '';
          _officeLocationController.text = userData?['office_location'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load user details: ${e.toString()}')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateUserDetails() async {
    try {
      await supabase
          .from('users')
          .update({
            'full_name': _fullNameController.text,
            'email': _emailController.text,
            'mobile_number': _mobileNumberController.text,
            'user_type': _userTypeController.text,
            'verification_status': _verificationStatusController.text,
            'role': _roleController.text,
            'education': _educationController.text,
            'experience': _experienceController.text,
            'primary_occupation': _primaryOccupationController.text,
            'skills': _skillsController.text.split(',').map((s) => s.trim()).toList(),
            'district': _districtController.text,
            'upazila': _upazilaController.text,
            'company_name': _companyNameController.text,
            'business_reg_number': _businessRegNumberController.text,
            'industry_sector': _industrySectorController.text,
            'company_size': _companySizeController.text,
            'office_location': _officeLocationController.text,
          })
          .eq('id', widget.userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User details updated successfully!')));
        setState(() => _isEditing = false);
        _fetchUserDetails(); // Re-fetch to ensure latest data is displayed
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update user details: ${e.toString()}')));
      }
    }
  }

  Widget _buildDetailField({
    required String label,
    required TextEditingController controller,
    bool isEditable = false,
    bool isEmail = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        readOnly: !isEditable,
        keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
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
                          'User Details',
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
                              _updateUserDetails();
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
                      _buildDetailField(label: 'Full Name', controller: _fullNameController, isEditable: _isEditing),
                      _buildDetailField(label: 'Email', controller: _emailController, isEditable: _isEditing, isEmail: true),
                      _buildDetailField(label: 'Mobile Number', controller: _mobileNumberController, isEditable: _isEditing),
                      _buildDetailField(label: 'User Type', controller: _userTypeController, isEditable: _isEditing),
                      _buildDetailField(label: 'Verification Status', controller: _verificationStatusController, isEditable: _isEditing),
                      _buildDetailField(label: 'Role', controller: _roleController, isEditable: _isEditing),
                      _buildDetailField(label: 'Education', controller: _educationController, isEditable: _isEditing),
                      _buildDetailField(label: 'Experience', controller: _experienceController, isEditable: _isEditing),
                      _buildDetailField(label: 'Primary Occupation', controller: _primaryOccupationController, isEditable: _isEditing),
                      _buildDetailField(label: 'Skills', controller: _skillsController, isEditable: _isEditing),
                      _buildDetailField(label: 'District', controller: _districtController, isEditable: _isEditing),
                      _buildDetailField(label: 'Upazila', controller: _upazilaController, isEditable: _isEditing),
                      _buildDetailField(label: 'Company Name', controller: _companyNameController, isEditable: _isEditing),
                      _buildDetailField(label: 'Business Reg. Number', controller: _businessRegNumberController, isEditable: _isEditing),
                      _buildDetailField(label: 'Industry Sector', controller: _industrySectorController, isEditable: _isEditing),
                      _buildDetailField(label: 'Company Size', controller: _companySizeController, isEditable: _isEditing),
                      _buildDetailField(label: 'Office Location', controller: _officeLocationController, isEditable: _isEditing),
                      const SizedBox(height: 20),
                      // Add more sections for NID images, saved jobs, applied jobs, ratings, etc.
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}