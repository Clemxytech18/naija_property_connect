import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/user_mode_provider.dart';
import '../screens/home_screen.dart';
import '../screens/chat_list_screen.dart';
import '../screens/tenant/search_screen.dart';
import '../screens/tenant/wishlist_screen.dart';
import '../screens/landlord/properties_screen.dart';
// Keeping for backward compatibility if needed
import '../screens/agent/agent_dashboard_screen.dart';
import '../screens/agent/agent_appointments_screen.dart';
import '../screens/account_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final userMode = Provider.of<UserModeProvider>(context);
    final isAgent = userMode.isAgentMode;

    final screens = isAgent
        ? [
            const AgentDashboardScreen(),
            const LandlordPropertiesScreen(),
            const AgentAppointmentsScreen(),
            const ChatListScreen(),
            const AccountScreen(),
          ]
        : [
            const HomeScreen(), // Explore
            const TenantSearchScreen(), // Find
            const TenantWishlistScreen(), // Saved
            const ChatListScreen(), // Messages
            const AccountScreen(), // Profile
          ];

    final navItems = isAgent
        ? const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.business_outlined),
              activeIcon: Icon(Icons.business),
              label: 'Properties',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today),
              label: 'Appointments',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ]
        : const [
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore),
              label: 'Explore',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_outline),
              activeIcon: Icon(Icons.favorite),
              label: 'Saved',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ];

    // Reset index if switching modes to avoid out of bounds
    if (_currentIndex >= screens.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: navItems,
        backgroundColor: Colors.white,
        elevation: 8,
      ),
    );
  }
}
