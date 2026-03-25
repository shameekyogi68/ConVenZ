import 'package:flutter_test/flutter_test.dart';
import 'package:convenz_customer_app/providers/user_provider.dart';

void main() {
  group('UserProvider Tests', () {
    late UserProvider userProvider;

    setUp(() {
      userProvider = UserProvider();
    });

    test('Initial address is Loading address...', () {
      expect(userProvider.currentAddress, 'Loading address...');
    });

    test('Initial isLoading is true', () {
      expect(userProvider.isLoading, true);
    });

    test('loadInitialData updates loading state', () async {
      // Because we lack mock services in this isolated test, it will throw caught errors.
      // But we can verify _isLoading toggles at the end.
      await userProvider.loadInitialData();
      expect(userProvider.isLoading, false);
    });
  });
}
