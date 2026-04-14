import '../utils/shared_prefs.dart';
import 'api_service.dart';

class ProfileService {
  static Future<Map<String, dynamic>> getProfile() async {
    final String? userId = SharedPrefs.getUserId();
    if (userId == null) {
      return {'success': false, 'message': 'User ID not found'};
    }
    return ApiService.get('/user/profile/$userId');
  }

  static Future<Map<String, dynamic>> updateProfile({required String name}) async {
    final String? userId = SharedPrefs.getUserId();
    if (userId == null) {
      return {'success': false, 'message': 'User ID not found'};
    }

    final Map<String, dynamic> res = await ApiService.post('/user/profile/$userId', {'name': name});

    if (res['success'] == true && res['data'] != null) {
      final data = res['data'] as Map<String, dynamic>?;
      final updatedName = data?['name'] as String?;
      if (updatedName != null) {
        await SharedPrefs.saveUserName(updatedName);
      }
    }
    return res;
  }
}
