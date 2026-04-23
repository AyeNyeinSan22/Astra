class ActivityRecord {
  final String title;
  final String date;
  final int points;
  final String type; // 'recycle', 'habit', 'shop'

  ActivityRecord({required this.title, required this.date, required this.points, required this.type});
}

class UserModel {
  String email;
  String password;
  String name;
  String phone;
  String gender;
  String dob;
  String age;

  // --- Point System Variables ---
  int points;
  int itemsRecycled;
  double co2SavedGrams;
  int dailyStreak;
  int level;
  double levelProgress;
  List<String> badges;
  List<ActivityRecord> activities;

  UserModel({
    required this.email,
    required this.password,
    this.name = '',
    this.phone = '',
    this.gender = '',
    this.dob = '',
    this.age = '',
    this.points = 0,
    this.itemsRecycled = 0,
    this.co2SavedGrams = 0.0,
    this.dailyStreak = 0,
    this.level = 1,
    this.levelProgress = 0.2,
    this.badges = const [],
    this.activities = const [],
  });
}

class LocalAuthBackend {
  static String? currentUserEmail;

  static final Map<String, UserModel> _usersDatabase = {};

  static Future<bool> registerUser(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (_usersDatabase.containsKey(email)) return false;

    _usersDatabase[email] = UserModel(email: email, password: password, activities: []);
    currentUserEmail = email;
    return true;
  }

  static Future<bool> loginUser(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (_usersDatabase.containsKey(email) && _usersDatabase[email]!.password == password) {
      currentUserEmail = email;
      return true;
    }
    return false;
  }

  static void logout() {
    currentUserEmail = null;
  }

  static Future<bool> resetPassword(String email, String newPassword) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (_usersDatabase.containsKey(email)) {
      _usersDatabase[email]!.password = newPassword;
      return true;
    }
    return false;
  }

  static Future<void> updateUserProfile({
    String? name,
    String? phone,
    String? gender,
    String? dob,
    String? age,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (currentUserEmail != null && _usersDatabase.containsKey(currentUserEmail)) {
      var user = _usersDatabase[currentUserEmail]!;
      if (name != null) user.name = name;
      if (phone != null) user.phone = phone;
      if (gender != null) user.gender = gender;
      if (dob != null) user.dob = dob;
      if (age != null) user.age = age;
    }
  }

  static UserModel? getCurrentUser() {
    if (currentUserEmail != null && _usersDatabase.containsKey(currentUserEmail)) {
      return _usersDatabase[currentUserEmail];
    }
    return null;
  }

  static Future<void> addImpact({
    required String title,
    required int points, 
    required double co2, 
    required int items,
    required String type,
  }) async {
    if (currentUserEmail != null && _usersDatabase.containsKey(currentUserEmail)) {
      var user = _usersDatabase[currentUserEmail]!;
      user.points += points;
      user.co2SavedGrams += co2;
      user.itemsRecycled += items;
      
      // Add to activity feed
      user.activities = [
        ActivityRecord(title: title, date: 'Just now', points: points, type: type),
        ...user.activities,
      ];
      
      user.levelProgress += (points / 300); 
      if (user.levelProgress >= 1.0) {
        user.level += 1;
        user.levelProgress -= 1.0;
        String newBadge = 'Level ${user.level} Warrior';
        if (!user.badges.contains(newBadge)) {
          user.badges = List.from(user.badges)..add(newBadge);
        }
      }
    }
  }

  static Future<bool> redeemItem({required String title, required int cost}) async {
    if (currentUserEmail != null && _usersDatabase.containsKey(currentUserEmail)) {
      var user = _usersDatabase[currentUserEmail]!;
      if (user.points >= cost) {
        user.points -= cost;
        user.activities = [
          ActivityRecord(title: 'Redeemed $title', date: 'Just now', points: -cost, type: 'shop'),
          ...user.activities,
        ];
        return true;
      }
    }
    return false;
  }

  static Future<void> simulateTrashScan({required int earnedPoints, required double earnedCo2}) async {
    await addImpact(
      title: 'Recycled Plastic Bottle',
      points: earnedPoints, 
      co2: earnedCo2, 
      items: 1,
      type: 'recycle'
    );
  }
}
