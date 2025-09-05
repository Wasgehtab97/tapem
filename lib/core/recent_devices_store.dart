import 'package:shared_preferences/shared_preferences.dart';

class RecentDevicesStore {
  static String _key(String gymId) => 'recentDevices/\$gymId';

  static Future<void> record(String gymId, String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key(gymId)) ?? <String>[];
    list.remove(deviceId);
    list.insert(0, deviceId);
    await prefs.setStringList(_key(gymId), list);
  }

  static Future<List<String>> getOrder(String gymId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key(gymId)) ?? <String>[];
  }
}
