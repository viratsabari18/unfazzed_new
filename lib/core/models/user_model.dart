class UserModel {
  final String id;
  final String name;
  final String email;
  final String profileImage;
  final double walletBalance;
  final double cashbackBalance;
  final String referralCode;
  final List<Map<String, dynamic>> loyaltyActivity;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.profileImage,
    required this.walletBalance,
    required this.cashbackBalance,
    required this.referralCode,
    required this.loyaltyActivity,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      profileImage: json['profileImage'] ?? '',

     
      walletBalance: (json['walletBalance'] ?? 0).toDouble(),
      cashbackBalance: (json['cashbackBalance'] ?? 0).toDouble(),

      referralCode: json['referralCode'] ?? '',


      loyaltyActivity: (json['loyaltyActivity'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e))
          .toList(),
    );
  }

 
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "email": email,
      "profileImage": profileImage,
      "walletBalance": walletBalance,
      "cashbackBalance": cashbackBalance,
      "referralCode": referralCode,
      "loyaltyActivity": loyaltyActivity,
    };
  }


  factory UserModel.mock() {
    return UserModel(
      id: '1',
      name: 'Himanshu',
      email: 'himanshu@zeerah.com',
      profileImage: 'lib/assets/images/worker_1.png',
      walletBalance: 200.0,
      cashbackBalance: 450.0,
      referralCode: 'SHI7K9B',
      loyaltyActivity: [
        {
          'amount': '+50 ksb',
          'desc': 'Referral Bonus',
          'date': 'Jan 12, 2026',
          'type': 'credit',
        },
        {
          'amount': '+20 ksb',
          'desc': 'Cleaning Service Booking',
          'date': 'Jan 12, 2026',
          'type': 'credit',
        },
        {
          'amount': '-100 ksb',
          'desc': 'Cashback Redeemed',
          'date': 'Jan 12, 2026',
          'type': 'debit',
        },
      ],
    );
  }
}
