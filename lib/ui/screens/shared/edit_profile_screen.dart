import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/models/user_model.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();

  // Agent/Landlord specific
  final TextEditingController _businessNameController = TextEditingController();

  // Tenant specific validation options
  final List<String> _employmentOptions = [
    'Self-Employed',
    'Employed',
    'Student',
    'Not-Employed',
  ];
  final List<String> _genderOptions = ['Male', 'Female'];
  final List<String> _maritalStatusOptions = ['Married', 'Single', 'Divorced'];

  String? _avatarUrl;
  String? _selectedEmployment;
  String? _selectedGender;
  String? _selectedMaritalStatus;
  String? _role;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final UserModel? user = await _authService.getUserProfile();
      if (mounted && user != null) {
        setState(() {
          _nameController.text = user.fullName ?? '';
          _phoneController.text = user.phone ?? '';
          _bioController.text = user.bio ?? '';
          _stateController.text = user.state ?? '';
          _cityController.text = user.city ?? '';
          _businessNameController.text = user.businessName ?? '';

          _avatarUrl = user.avatarUrl;
          _role = user.role;

          if (_employmentOptions.contains(user.employmentStatus)) {
            _selectedEmployment = user.employmentStatus;
          }
          if (_genderOptions.contains(user.gender)) {
            _selectedGender = user.gender;
          }
          if (_maritalStatusOptions.contains(user.maritalStatus)) {
            _selectedMaritalStatus = user.maritalStatus;
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load profile: $e')));
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
    );

    if (image == null) return;

    setState(() => _isUploadingImage = true);

    try {
      final userId = _authService.currentUserId;
      if (userId == null) throw Exception('User not logged in');

      final fileExt = image.path.split('.').last;
      final fileName =
          '${userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = fileName;

      final bytes = await image.readAsBytes();
      await Supabase.instance.client.storage
          .from('avatars')
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );

      final imageUrl = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(filePath);

      // Update DB immediately with new avatar
      await Supabase.instance.client
          .from('users')
          .update({'avatar_url': imageUrl})
          .eq('id', userId);

      if (mounted) {
        setState(() {
          _avatarUrl = imageUrl;
          _isUploadingImage = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingImage = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final userId = _authService.currentUserId;
      if (userId == null) throw Exception('No user logged in');

      final Map<String, dynamic> updates = {
        'full_name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'bio': _bioController.text.trim(),
        'state': _stateController.text.trim(),
        'city': _cityController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (_role == 'agent' || _role == 'landlord') {
        updates['business_name'] = _businessNameController.text.trim();
      } else {
        updates['employment_status'] = _selectedEmployment;
        updates['gender'] = _selectedGender;
        updates['marital_status'] = _selectedMaritalStatus;
      }

      await Supabase.instance.client
          .from('users')
          .update(updates)
          .eq('id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile Updated Successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save profile: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _businessNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If role is missing, default to tenant or check logic? Assumed loaded.
    final bool isAgent = _role == 'agent' || _role == 'landlord';

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildAvatarSection(),
                    const SizedBox(height: 32),

                    _buildTextField(
                      _nameController,
                      'Full Name',
                      Icons.person_outline,
                    ),
                    const SizedBox(height: 16),

                    if (isAgent) ...[
                      _buildTextField(
                        _businessNameController,
                        'Business Name',
                        Icons.business,
                      ),
                      const SizedBox(height: 16),
                    ],

                    _buildTextField(
                      _phoneController,
                      'Phone Number',
                      Icons.phone_outlined,
                      inputType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),

                    if (!isAgent) ..._buildTenantSpecificFields(),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            _stateController,
                            'State',
                            Icons.map,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            _cityController,
                            'City',
                            Icons.location_city,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      _bioController,
                      isAgent ? 'About' : 'Bio',
                      Icons.info_outline,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 32),

                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
    );
  }

  List<Widget> _buildTenantSpecificFields() {
    return [
      _buildDropdown(
        value: _selectedEmployment,
        items: _employmentOptions,
        label: 'Employment Status',
        icon: Icons.work_outline,
        onChanged: (val) => setState(() => _selectedEmployment = val),
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: _buildDropdown(
              value: _selectedGender,
              items: _genderOptions,
              label: 'Gender',
              icon: Icons.person,
              onChanged: (val) => setState(() => _selectedGender = val),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildDropdown(
              value: _selectedMaritalStatus,
              items: _maritalStatusOptions,
              label: 'Marital Status',
              icon: Icons.favorite_border,
              onChanged: (val) => setState(() => _selectedMaritalStatus = val),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
    ];
  }

  Widget _buildAvatarSection() {
    return Center(
      child: Stack(
        children: [
          _isUploadingImage
              ? const CircleAvatar(
                  radius: 50,
                  child: CircularProgressIndicator(),
                )
              : CircleAvatar(
                  radius: 50,
                  backgroundColor: Theme.of(
                    context,
                  ).primaryColor.withValues(alpha: 0.1),
                  backgroundImage: _avatarUrl != null
                      ? NetworkImage(_avatarUrl!)
                      : null,
                  child: _avatarUrl == null
                      ? Icon(
                          Icons.person,
                          size: 50,
                          color: Theme.of(context).primaryColor,
                        )
                      : null,
                ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickAndUploadImage,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? inputType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        alignLabelWithHint: maxLines > 1,
      ),
      validator: (v) => v?.isEmpty ?? true ? '$label is required' : null,
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required String label,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      // 'value' is deprecated in strict form usage if state is managed externally,
      // but we use it here because we setState() on change.
      // However, to satisfy strict lints we switch to value which drives valid state.
      // If the lint demands initialValue, we use that, but be aware 'value' is usually needed for reset.
      // Given the specific error "Use initialValue instead", we swap it.
      // Reverting to value as initialValue doesn't update on setState re-renders for controlled inputs.
      // If 'value' is deprecated, it's likely a misinterpretation of a specific lint or a bleeding-edge change.
      // But typically, value is correct for controlled.
      // Let's try to silence it if we can't fix it logically without breaking functionality.
      // The lint says "Use initialValue instead. This will set the initial value for the form field."
      // BUT we need it to update when _selected... changes.
      // I will keep 'value' for now but if I MUST change it, I would need a Key.
      // Wait, let's look at the method again.
      // If I change to initialValue, I MUST add a Key(value) to ensure it rebuilds.
      key: ValueKey(value),
      initialValue: value,
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      validator: (v) => v == null ? 'Select $label' : null,
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSaving
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Save Changes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
