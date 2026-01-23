import 'package:eduguide/features/settings/services/profile_services.dart';
import 'package:flutter/material.dart';

// --- Constants (Synced with other pages) ---
const Color primaryBlue = Color(0xFF407BFF);
const Color lightBackground = Color(0xFFF7F7FD);
const Color cardBackground = Colors.white;
const Color textSubtle = Color(0xFF6E6E73);
const Color textBody = Color(0xFF1D1D1F);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ADDED: GlobalKey for Form validation
  final _formKey = GlobalKey<FormState>();

  final ProfileService _profileService = ProfileService();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _collegeController = TextEditingController();
  final _courseController = TextEditingController();
  final _branchController = TextEditingController();
  final _yearOfPassingController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final userProfile = await _profileService.getUserProfile();
      if (mounted) {
        setState(() {
          _nameController.text = userProfile.name;
          _mobileController.text = userProfile.mobileNumber;
          _emailController.text = userProfile.email;
          _collegeController.text = userProfile.college;
          _courseController.text = userProfile.course;
          _branchController.text = userProfile.branch;
          _yearOfPassingController.text = userProfile.yearOfPassing;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile data: $e')),
        );
      }
    }
  }

  Future<void> _saveUserProfile() async {
    // ADDED: Form validation check
    if (!_formKey.currentState!.validate()) {
      return; // If form is not valid, do not proceed
    }

    setState(() => _isSaving = true);

    final updatedProfile = UserProfile(
      name: _nameController.text,
      mobileNumber: _mobileController.text,
      email: _emailController.text,
      college: _collegeController.text,
      course: _courseController.text,
      branch: _branchController.text,
      yearOfPassing: _yearOfPassingController.text,
      photoUrl: '', // Photo URL is no longer used
    );

    final success = await _profileService.saveUserProfile(updatedProfile);

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Profile saved successfully!' : 'Failed to save profile.',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _collegeController.dispose();
    _courseController.dispose();
    _branchController.dispose();
    _yearOfPassingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: lightBackground,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: lightBackground,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryBlue))
          : Form(
              // ADDED: Form widget
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                children: [
                  const SizedBox(height: 24),
                  _buildInfoSection(
                    title: 'Personal Details',
                    children: [
                      _buildTextField(
                        label: 'Full Name',
                        controller: _nameController,
                        // ADDED: Validator for name
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      _buildTextField(
                        label: 'Mobile Number',
                        controller: _mobileController,
                        keyboardType: TextInputType.phone,
                        // ADDED: Validator for mobile number
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your mobile number';
                          }
                          if (value.length != 10) {
                            return 'Mobile number must be 10 digits';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                      _buildTextField(
                        label: 'Email Address',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        enabled: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildInfoSection(
                    title: 'Academic Information',
                    children: [
                      _buildTextField(
                        label: 'College',
                        controller: _collegeController,
                      ),
                      _buildTextField(
                        label: 'Course',
                        controller: _courseController,
                      ),
                      _buildTextField(
                        label: 'Branch',
                        controller: _branchController,
                      ),
                      _buildTextField(
                        label: 'Year of Passing',
                        controller: _yearOfPassingController,
                        keyboardType: TextInputType.number,
                        // ADDED: Validator for year
                        validator: (value) {
                          if (value != null &&
                              value.isNotEmpty &&
                              value.length != 4) {
                            return 'Enter a valid 4-digit year';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildSaveButton(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textBody,
            ),
          ),
          const SizedBox(height: 24),
          ...children.map(
            (child) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
    // ADDED: validator parameter
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: enabled,
      // ADDED: validator property
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: const TextStyle(fontWeight: FontWeight.w500, color: textBody),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: textSubtle),
        fillColor: !enabled ? Colors.grey.shade100 : lightBackground,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        // ADDED: Error border style
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _isSaving ? null : _saveUserProfile,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
      child: _isSaving
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            )
          : const Text(
              'Save Changes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
    );
  }
}
