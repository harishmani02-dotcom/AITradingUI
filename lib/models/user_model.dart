class UserModel {
  final String id;
  final String userId;
  final String email;
  final bool subscriptionStatus;
  final DateTime? subscriptionEnd;
  final DateTime createdAt;
 
  UserModel({
    required this.id,
    required this.userId,
    required this.email,
    required this.subscriptionStatus,
    this.subscriptionEnd,
    required this.createdAt,
  });
 
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      email: json['email'] ?? '',
      subscriptionStatus: json['subscription_status'] ?? false,
      subscriptionEnd: json['subscription_end'] != null
          ? DateTime.parse(json['subscription_end'])
          : null,
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toString()
      ),
    );
  }
 
  bool get isSubscriptionActive {
    if (!subscriptionStatus) return false;
    if (subscriptionEnd == null) return true;
    return subscriptionEnd!.isAfter(DateTime.now());
  }
 
  int get daysRemaining {
    if (subscriptionEnd == null) return 0;
    return subscriptionEnd!.difference(DateTime.now()).inDays;
  }
}