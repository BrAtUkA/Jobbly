import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project/providers/providers.dart';
import 'package:project/models/models.dart';
import 'package:project/screens/company/company_dashboard_screen.dart';
import 'package:project/screens/company/company_jobs_tab.dart';
import 'package:project/screens/company/company_applications_tab.dart';
import 'package:project/screens/company/company_profile_tab.dart';

class CompanyMainScreen extends StatefulWidget {
  const CompanyMainScreen({super.key});

  @override
  State<CompanyMainScreen> createState() => _CompanyMainScreenState();
}

class _CompanyMainScreenState extends State<CompanyMainScreen> {
  int _currentIndex = 0;
  int _previousIndex = 0;

  void _navigateToTab(int index) {
    setState(() {
      _previousIndex = _currentIndex;
      _currentIndex = index;
    });
  }

  List<Widget> get _tabs => [
    CompanyDashboardScreen(onNavigateToTab: _navigateToTab),
    const CompanyJobsTab(),
    const CompanyApplicationsTab(),
    const CompanyProfileTab(),
  ];

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    // Refresh jobs and applications data
    if (!mounted) return;
    await context.read<JobProvider>().fetchAllJobsFromSupabase();
    if (!mounted) return;
    await context.read<ApplicationProvider>().fetchAllApplicationsFromSupabase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    // Show loading if user data not yet loaded
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (user is! Company) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              const Text('Access denied. Companies only.'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.read<AuthProvider>().signOut(),
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          final isEntering = child.key == ValueKey<int>(_currentIndex);
          final isForward = _currentIndex > _previousIndex;
          
          final offset = Tween<Offset>(
            begin: Offset(isEntering ? (isForward ? 1.0 : -1.0) : (isForward ? -1.0 : 1.0), 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
          
          return SlideTransition(position: offset, child: child);
        },
        layoutBuilder: (currentChild, previousChildren) {
          return Stack(
            children: [
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_currentIndex),
          child: _tabs[_currentIndex],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _navigateToTab,
          backgroundColor: Colors.white,
          elevation: 0,
          indicatorColor: theme.primaryColor.withValues(alpha: 0.12),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          height: 70,
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined, color: Colors.grey.shade600),
              selectedIcon: Icon(Icons.dashboard_rounded, color: theme.primaryColor),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.work_outline_rounded, color: Colors.grey.shade600),
              selectedIcon: Icon(Icons.work_rounded, color: theme.primaryColor),
              label: 'Jobs',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline_rounded, color: Colors.grey.shade600),
              selectedIcon: Icon(Icons.people_rounded, color: theme.primaryColor),
              label: 'Applications',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded, color: Colors.grey.shade600),
              selectedIcon: Icon(Icons.person_rounded, color: theme.primaryColor),
              label: 'Profile',
            ),
          ],
        ),
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.pushNamed(context, '/company/create-job');
                if (result == true && mounted) {
                  _refreshData();
                }
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Post Job'),
              elevation: 2,
            )
          : null,
    );
  }
}
