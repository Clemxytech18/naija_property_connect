import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/user_mode_provider.dart';
import '../../data/services/auth_service.dart';
import '../../data/models/user_model.dart';
import 'agent/property_analytics_screen.dart';
import 'agent/appointment_calendar_screen.dart';
import 'shared/notifications_screen.dart';
import 'shared/edit_profile_screen.dart';
import 'shared/placeholder_screen.dart';
import 'tenant/tenant_appointments_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final AuthService _authService = AuthService();
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = await _authService.getUserProfile();
    if (mounted) {
      setState(() {
        _user = user;
      });
    }
  }

  Future<void> _signOut() async {
    await _authService.signOut();
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _handleModeSwitch(UserModeProvider userMode) async {
    final isAgent = userMode.isAgentMode;

    // If getting back to tenant mode, simply toggle
    if (isAgent) {
      userMode.toggleMode();
      return;
    }

    // If switching to agent mode, check if user is already an agent/landlord
    if (_user?.role == 'agent' || _user?.role == 'landlord') {
      userMode.toggleMode();
      return;
    }

    // If not, show optional upgrade dialog
    await _showBecomeAgentDialog(userMode);
  }

  Future<void> _showBecomeAgentDialog(UserModeProvider userMode) async {
    final businessNameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Become an Agent/Landlord'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'To switch to agent mode, you need to register as an agent. Please provide your business details.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: businessNameController,
                decoration: const InputDecoration(
                  labelText: 'Business User/Company Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Business name is required';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  Navigator.pop(context); // Close dialog
                  _showSnack('Upgrading account...');

                  await _authService.upgradeToAgent(
                    businessNameController.text.trim(),
                  );

                  // Reload profile to get new role
                  await _loadProfile();

                  // Switch mode
                  userMode.setAgentMode(true);

                  _showSnack('Welcome to Agent Mode!');
                } catch (e) {
                  _showSnack('Error uplifting account: $e');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Become An Agent'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserModeProvider>(
      builder: (context, userMode, _) {
        final isAgent = userMode.isAgentMode;

        return Scaffold(
          backgroundColor: Colors.grey[50], // Light background
          appBar: AppBar(
            title: const Text('Settings'),
            backgroundColor: Colors.white,
            elevation: 0,
            foregroundColor: Colors.black,
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            children: [
              // User Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.1),
                      backgroundImage: (_user?.avatarUrl?.isNotEmpty ?? false)
                          ? NetworkImage(_user!.avatarUrl!)
                          : null,
                      child: (_user?.avatarUrl?.isNotEmpty ?? false)
                          ? null
                          : Text(
                              (_user?.fullName?.isNotEmpty ?? false)
                                  ? _user!.fullName![0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _user?.fullName ?? _user?.email ?? 'Loading...',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (_user?.fullName != null)
                            Text(
                              (_user?.email ??
                                      _authService.currentUser?.email) ??
                                  '',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isAgent
                                  ? Colors.blue[50]
                                  : Colors.green[50],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isAgent ? 'AGENT MODE' : 'TENANT MODE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isAgent ? Colors.blue : Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Mode Switcher (For Testing/Demo)
              _buildSectionHeader('App Mode'),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: SwitchListTile(
                  title: Text(
                    isAgent ? 'Switch to Tenant View' : 'Switch to Agent View',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  secondary: Icon(
                    Icons.swap_horiz,
                    color: Theme.of(context).primaryColor,
                  ),
                  value: isAgent,
                  onChanged: (_) => _handleModeSwitch(userMode),
                ),
              ),
              const SizedBox(height: 24),

              // Sections
              if (isAgent) ..._buildAgentSections(),
              if (!isAgent) ..._buildTenantSections(),

              // Sign Out
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: _signOut,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.red[50],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Version 1.0.0',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildAgentSections() {
    return [
      _buildSectionHeader('Account'),
      _buildMenuContainer([
        _buildMenuItem(
          Icons.person_outline,
          'Edit Profile',
          'Update your personal information',
          () => _navTo(const EditProfileScreen()),
        ),
        _buildMenuItem(
          Icons.verified_user_outlined,
          'Verification',
          'Manage your verification status',
          () => _navTo(const PlaceholderScreen(title: 'Verification')),
        ),
        _buildMenuItem(
          Icons.lock_outline,
          'Privacy & Security',
          'Control your privacy settings',
          () => _navTo(const PlaceholderScreen(title: 'Privacy & Security')),
        ),
      ]),
      const SizedBox(height: 24),
      _buildSectionHeader('Business Tools'),
      _buildMenuContainer([
        _buildMenuItem(
          Icons.calendar_month_outlined,
          'Calendar',
          'View appointments',
          () => _navTo(const AppointmentCalendarScreen()),
        ),
        _buildMenuItem(
          Icons.credit_card,
          'Billing & Payments',
          'Manage your subscription',
          () => _navTo(const PlaceholderScreen(title: 'Billing & Payments')),
        ),
        _buildMenuItem(
          Icons.analytics_outlined,
          'Analytics',
          'Performance insights',
          () => _navTo(const PropertyAnalyticsScreen()),
        ),
        _buildMenuItem(
          Icons.access_time,
          'Availability Settings',
          'Set your viewing hours',
          () => _navTo(const PlaceholderScreen(title: 'Availability Settings')),
        ),
      ]),
      const SizedBox(height: 24),
      _buildSectionHeader('Support'),
      _buildMenuContainer([
        _buildMenuItem(
          Icons.help_outline,
          'Help Center',
          null,
          () => _navTo(const PlaceholderScreen(title: 'Help Center')),
        ),
        _buildMenuItem(
          Icons.headset_mic_outlined,
          'Contact Support',
          null,
          () => _navTo(const PlaceholderScreen(title: 'Contact Support')),
        ),
        _buildMenuItem(
          Icons.description_outlined,
          'Terms & Privacy',
          null,
          () => _navTo(const PlaceholderScreen(title: 'Terms & Privacy')),
        ),
      ]),
    ];
  }

  List<Widget> _buildTenantSections() {
    return [
      _buildSectionHeader('Account Settings'),
      _buildMenuContainer([
        _buildMenuItem(
          Icons.person_outline,
          'Edit Profile',
          'Update your personal information',
          () => _navTo(const EditProfileScreen()),
        ),
        _buildMenuItem(
          Icons.calendar_month_outlined,
          'My Appointments',
          'View your scheduled viewings',
          () => _navTo(const TenantAppointmentsScreen()),
        ),
        _buildMenuItem(
          Icons.verified_user_outlined,
          'Verification',
          'Get verified for faster renting',
          () => _navTo(const PlaceholderScreen(title: 'Verification')),
        ),
        _buildMenuItem(
          Icons.lock_outline,
          'Privacy',
          'Control your data',
          () => _navTo(const PlaceholderScreen(title: 'Privacy')),
        ),
        _buildMenuItem(
          Icons.notifications_outlined,
          'Notifications',
          'Manage alerts',
          () => _navTo(const NotificationsScreen()),
        ),
      ]),
      const SizedBox(height: 24),
      _buildSectionHeader('Help'),
      _buildMenuContainer([
        _buildMenuItem(
          Icons.help_outline,
          'Help Center',
          null,
          () => _navTo(const PlaceholderScreen(title: 'Help Center')),
        ),
        _buildMenuItem(
          Icons.headset_mic_outlined,
          'Contact Support',
          null,
          () => _navTo(const PlaceholderScreen(title: 'Contact Support')),
        ),
      ]),
    ];
  }

  void _navTo(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey[600],
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildMenuContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    String? subtitle,
    VoidCallback? onTap,
  ) {
    return InkWell(
      onTap: onTap ?? () => _showSnack('Opening $title...'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }
}
