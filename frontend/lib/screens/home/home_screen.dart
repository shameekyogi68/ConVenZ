import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../providers/user_provider.dart';
import '../../services/location_services.dart';
import '../../services/notification_service.dart';
import '../../services/subscription_service.dart';
import '../../utils/blocking_helper.dart';
import '../../utils/shared_prefs.dart';
import 'customer_profile_screen.dart';
import 'my_booking_screen.dart';
import 'subscription_plans_page.dart';
import 'widgets/category_grid.dart';
import 'widgets/home_header.dart';
import 'widgets/popular_services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.initialTab = 0});
  /// Optional initial tab index forwarded from notification deep links.
  final int initialTab;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedIndex;
  int _currentBannerIndex = 0;
  final PageController _bannerController = PageController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // All bookable service names — used for live search filtering
  static const List<Map<String, dynamic>> _allServices = [
    {'name': 'Cleaning',     'icon': Icons.cleaning_services},
    {'name': 'Plumbing',     'icon': Icons.plumbing},
    {'name': 'Electrician',  'icon': Icons.electrical_services},
    {'name': 'Painting',     'icon': Icons.format_paint},
    {'name': 'Moving',       'icon': Icons.local_shipping},
    {'name': 'AC Repair',    'icon': Icons.ac_unit},
    {'name': 'Sofa Cleaning','icon': Icons.chair},
    {'name': 'Car Wash',     'icon': Icons.local_car_wash},
  ];

  // Subscription state
  Map<String, dynamic>? _userSubscription;
  bool _loadingSubscription = true;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab.clamp(0, 3);

    _checkUserBlockingStatus();
    LocationService.startLocationTracking();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final UserProvider userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.loadInitialData();
      userProvider.syncLocation();
      
      // ✅ Sync FCM token on every launch to prevent notification skips
      NotificationService.refreshAndSendToken();
    });

    _loadUserSubscription();
    
    Future<void>.delayed(const Duration(seconds: 3), () {
      if (mounted && _loadingSubscription) {
        setState(() => _loadingSubscription = false);
      }
    });
  }

  @override
  void dispose() {
    _bannerController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkUserBlockingStatus() async {
    try {
      await BlockingHelper.checkUserStatusOnLaunch(context);
    } catch (_) {}
  }

  Future<void> _loadUserSubscription() async {
    try {
      final String? userId = SharedPrefs.getUserId();
      if (userId == null || userId.isEmpty) {
        setState(() => _loadingSubscription = false);
        return;
      }

      final Map<String, dynamic> result = await SubscriptionService.getUserSubscription(userId);
      if (mounted) {
        setState(() {
          if (result['success'] == true && result['data'] != null) {
            _userSubscription = result['data'] as Map<String, dynamic>?;
          } else {
            _userSubscription = null;
          }
          _loadingSubscription = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingSubscription = false;
          _userSubscription = null;
        });
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // ... (Rest of your UI code: _buildBannerCarousel, _buildHomeContent, build method) ...
  // Insert your UI code here exactly as it was in the previous file

  Widget _buildBannerCarousel() {
    final List<Widget> banners = [
      _buildActivePlanBanner(),
      _buildPromoBanner(),
    ];
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _bannerController,
            itemCount: banners.length,
            onPageChanged: (index) {
              setState(() {
                _currentBannerIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return banners[index];
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(banners.length, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 8,
              width: _currentBannerIndex == index ? 24 : 8,
              decoration: BoxDecoration(
                color: _currentBannerIndex == index
                    ? AppColors.primaryTeal
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildActivePlanBanner() {
    // If loading AND we don't have any cached data, show loading state briefly
    // But default to upgrade banner if it takes too long
    if (_loadingSubscription && _userSubscription == null) {
      // Show loading for max 5 seconds, then show upgrade banner
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1B3D50), Color(0xFF2C6E80)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: const Color(0xFF2C6E80).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
          ],
        ),
        child: const SizedBox(
          height: 120,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.accentMint),
          ),
        ),
      );
    }

    // If user has active subscription, show subscription details
    if (_userSubscription != null && _userSubscription!['status'] == 'Active') {
      final String planName = (_userSubscription!['currentPack'] as String?) ?? 'Premium Plan';
      final expiryDate = _userSubscription!['expiryDate'] as String?;
      
      var formattedExpiry = 'Soon';
      if (expiryDate != null) {
        try {
          final DateTime expiry = DateTime.parse(expiryDate);
          formattedExpiry = '${expiry.day} ${_getMonthName(expiry.month)}, ${expiry.year}';
        } catch (_) {}
      }

      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1B3D50), Color(0xFF2C6E80)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: const Color(0xFF2C6E80).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accentMint,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '✓ ACTIVE PLAN',
                      style: TextStyle(
                        color: Color(0xFF1F465A),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    planName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Valid until: $formattedExpiry',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified, color: AppColors.accentMint, size: 40),
            ),
          ],
        ),
      );
    }

    // If user has NO active subscription, show upgrade prompt
    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = 2);
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1B3D50), Color(0xFF2C6E80)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: const Color(0xFF2C6E80).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accentMint,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'UPGRADE PLAN',
                      style: TextStyle(
                        color: Color(0xFF1F465A),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Upgrade Your Plan',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Get exclusive benefits & premium access',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.card_giftcard, color: AppColors.accentMint, size: 40),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return month > 0 && month <= 12 ? months[month - 1] : '';
  }

  Widget _buildPromoBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryTeal, Color(0xFF3DD5A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppColors.accentMint.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '25% OFF',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'On your first home cleaning service!',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    onPressed: () {
                      context.push('/map', extra: {'selectedService': 'Cleaning'});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primaryTeal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('Book Now', style: TextStyle(fontSize: 12)),
                  ),
                )
              ],
            ),
          ),
          const Icon(Icons.cleaning_services, color: Colors.white24, size: 80),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final String query = _searchQuery.toLowerCase();
    final List<Map<String, dynamic>> matches = _allServices
        .where((s) => (s['name'] as String).toLowerCase().contains(query))
        .toList();

    if (matches.isEmpty) {
      return Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.search_off, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('No services found for "$_searchQuery"',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${matches.length} result${matches.length == 1 ? '' : 's'}',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
        const SizedBox(height: 12),
        ...matches.map((service) => ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(service['icon'] as IconData,
                    color: AppColors.primaryTeal, size: 22),
              ),
              title: Text(service['name'] as String,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              subtitle: const Text('Tap to book',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
              onTap: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
                context.push('/map', extra: {'selectedService': service['name']});
              },
            )),
      ],
    );
  }

  Widget _buildHomeContent() {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: _buildHomeScrollContent(),
    );
  }

  Widget _buildHomeScrollContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HomeHeader(),
          const SizedBox(height: 25),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: AppColors.primaryTeal.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8))
              ],
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value.trim()),
              decoration: InputDecoration(
                hintText: 'Search for services...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                icon: const Icon(Icons.search, color: AppColors.primaryTeal),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
            ),
          ).animate().fade(delay: 100.ms).slideY(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOutCubic),

          const SizedBox(height: 25),

          if (_searchQuery.isEmpty) ...[
            _buildBannerCarousel(),
            const SizedBox(height: 25),
            const CategoryGrid(),
            const SizedBox(height: 25),
            const PopularServicesList(),
          ] else
            _buildSearchResults(),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.background,
      // IndexedStack keeps all tabs alive — scroll position and state are preserved
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildHomeContent(),
            const MyBookingsScreen(),
            const SubscriptionPlansPage(),
            const CustomerProfileScreen(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: AppColors.primaryTeal,
          unselectedItemColor: const Color(0xFFADB5BD),
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.2),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, size: 24),
              activeIcon: Icon(Icons.home_rounded, size: 26),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined, size: 22),
              activeIcon: Icon(Icons.calendar_today_rounded, size: 24),
              label: 'Bookings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.workspace_premium_outlined, size: 24),
              activeIcon: Icon(Icons.workspace_premium_rounded, size: 26),
              label: 'Plans',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded, size: 24),
              activeIcon: Icon(Icons.person_rounded, size: 26),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
