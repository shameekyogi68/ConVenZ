import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import 'subscription_plans_page.dart';
import '../../services/location_services.dart';
import 'my_booking_screen.dart';
import '../../utils/shared_prefs.dart';
import '../../services/subscription_service.dart';
import '../../utils/blocking_helper.dart';
import 'customer_profile_screen.dart';
import 'booking/map_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import 'widgets/home_header.dart';
import 'widgets/category_grid.dart';
import 'widgets/popular_services.dart';
import '../../services/notification_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _currentBannerIndex = 0;
  final PageController _bannerController = PageController();

  // Subscription state
  Map<String, dynamic>? _userSubscription;
  bool _loadingSubscription = true;

  @override
  void initState() {
    super.initState();
    
    _checkUserBlockingStatus();
    LocationService.startLocationTracking();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.loadInitialData();
      userProvider.syncLocation();
      
      // ✅ Sync FCM token on every launch to prevent notification skips
      NotificationService.refreshAndSendToken();
    });

    _loadUserSubscription();
    
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted && _loadingSubscription) {
        setState(() => _loadingSubscription = false);
      }
    });
  }

  void _checkUserBlockingStatus() async {
    try {
      await BlockingHelper.checkUserStatusOnLaunch(context);
    } catch (e) {
      print("❌ Error checking blocking status: $e");
    }
  }

  Future<void> _loadUserSubscription() async {
    try {
      final userId = SharedPrefs.getUserId();
      print("📱 Loading subscription for userId: $userId");
      
      if (userId == null || userId.isEmpty) {
        print("⚠️ No userId found");
        setState(() => _loadingSubscription = false);
        return;
      }

      final result = await SubscriptionService.getUserSubscription(userId);
      print("📥 Subscription result: $result");
      
      if (mounted) {
        setState(() {
          if (result['success'] == true && result['data'] != null) {
            _userSubscription = result['data'];
            print("✅ Subscription loaded: ${_userSubscription?['currentPack']}");
          } else {
            print("⚠️ No active subscription found");
            _userSubscription = null;
          }
          _loadingSubscription = false;
        });
      }
    } catch (e) {
      print("❌ Subscription Load Error: $e");
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
      final planName = _userSubscription!['currentPack'] ?? 'Premium Plan';
      final expiryDate = _userSubscription!['expiryDate'];
      
      String formattedExpiry = 'Soon';
      if (expiryDate != null) {
        try {
          final expiry = DateTime.parse(expiryDate);
          formattedExpiry = '${expiry.day} ${_getMonthName(expiry.month)}, ${expiry.year}';
        } catch (e) {
          print("Date parse error: $e");
        }
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
                      "✓ ACTIVE PLAN",
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
                    "Valid until: $formattedExpiry",
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
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SubscriptionPlansPage()),
        );
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
                      "UPGRADE PLAN",
                      style: TextStyle(
                        color: Color(0xFF1F465A),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Upgrade Your Plan",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Get exclusive benefits & premium access",
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
                  "25% OFF",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "On your first home cleaning service!",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MapScreen(
                            selectedService: 'Cleaning',
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primaryTeal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text("Book Now", style: TextStyle(fontSize: 12)),
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

  Widget _buildHomeContent() {
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
            child: const TextField(
              decoration: InputDecoration(
                hintText: "Search for services...",
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                icon: Icon(Icons.search, color: AppColors.primaryTeal),
              ),
            ),
          ).animate().fade(delay: 100.ms).slideY(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOutCubic),

          const SizedBox(height: 25),
          _buildBannerCarousel(),
          const SizedBox(height: 25),

          const CategoryGrid(),
          const SizedBox(height: 25),
          
          const PopularServicesList(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyContent;
    switch (_selectedIndex) {
      case 0: bodyContent = _buildHomeContent(); break;
      case 1: bodyContent = MyBookingsScreen(); break;
      case 2: bodyContent = SubscriptionPlansPage(); break;
      case 3: bodyContent = CustomerProfileScreen(controller: PageController()); break;
      default: bodyContent = _buildHomeContent();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: bodyContent),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: AppColors.primaryTeal,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: "Bookings"),
          BottomNavigationBarItem(icon: Icon(Icons.paid), label: "Plans"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}