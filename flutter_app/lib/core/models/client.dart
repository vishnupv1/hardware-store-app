class Client {
  final String id;
  final String email;
  final String companyName;
  final ContactPerson contactPerson;
  final Address? address;
  final BusinessInfo? businessInfo;
  final Subscription subscription;
  final Settings settings;
  final bool isActive;
  final bool isLocked;
  final DateTime? lastLogin;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String role;

  Client({
    required this.id,
    required this.email,
    required this.companyName,
    required this.contactPerson,
    this.address,
    this.businessInfo,
    required this.subscription,
    required this.settings,
    required this.isActive,
    required this.isLocked,
    this.lastLogin,
    required this.createdAt,
    required this.updatedAt,
    required this.role,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['_id'] ?? json['id'],
      email: json['email'],
      companyName: json['companyName'],
      contactPerson: ContactPerson.fromJson(json['contactPerson']),
      address: json['address'] != null ? Address.fromJson(json['address']) : null,
      businessInfo: json['businessInfo'] != null ? BusinessInfo.fromJson(json['businessInfo']) : null,
      subscription: Subscription.fromJson(json['subscription']),
      settings: Settings.fromJson(json['settings']),
      isActive: json['isActive'] ?? true,
      isLocked: json['isLocked'] ?? false,
      lastLogin: json['lastLogin'] != null 
          ? DateTime.parse(json['lastLogin']) 
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      role: json['role'] ?? 'client',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'companyName': companyName,
      'contactPerson': contactPerson.toJson(),
      'address': address?.toJson(),
      'businessInfo': businessInfo?.toJson(),
      'subscription': subscription.toJson(),
      'settings': settings.toJson(),
      'isActive': isActive,
      'isLocked': isLocked,
      'lastLogin': lastLogin?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'role': role,
    };
  }

  String get displayName => companyName.isNotEmpty ? companyName : contactPerson.fullName;
  String get contactFullName => contactPerson.fullName;
  String get fullName => contactPerson.fullName; // For compatibility with User model

  @override
  String toString() {
    return 'Client(id: $id, email: $email, company: $companyName, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Client && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class ContactPerson {
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String? position;

  ContactPerson({
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.position,
  });

  factory ContactPerson.fromJson(Map<String, dynamic> json) {
    return ContactPerson(
      firstName: json['firstName'],
      lastName: json['lastName'],
      phoneNumber: json['phoneNumber'],
      position: json['position'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'position': position,
    };
  }

  String get fullName => '$firstName $lastName';
}

class Address {
  final String? street;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? country;

  Address({
    this.street,
    this.city,
    this.state,
    this.zipCode,
    this.country,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      street: json['street'],
      city: json['city'],
      state: json['state'],
      zipCode: json['zipCode'],
      country: json['country'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'country': country,
    };
  }

  String get fullAddress {
    final parts = [street, city, state, zipCode, country].where((part) => part != null && part.isNotEmpty).toList();
    return parts.join(', ');
  }
}

class BusinessInfo {
  final String? industry;
  final String? companySize;
  final String? website;
  final String? taxId;

  BusinessInfo({
    this.industry,
    this.companySize,
    this.website,
    this.taxId,
  });

  factory BusinessInfo.fromJson(Map<String, dynamic> json) {
    return BusinessInfo(
      industry: json['industry'],
      companySize: json['companySize'],
      website: json['website'],
      taxId: json['taxId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'industry': industry,
      'companySize': companySize,
      'website': website,
      'taxId': taxId,
    };
  }
}

class Subscription {
  final String plan;
  final String status;
  final DateTime startDate;
  final DateTime? endDate;
  final List<String> features;

  Subscription({
    required this.plan,
    required this.status,
    required this.startDate,
    this.endDate,
    required this.features,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      plan: json['plan'],
      status: json['status'],
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      features: List<String>.from(json['features'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'plan': plan,
      'status': status,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'features': features,
    };
  }

  bool get isActive => status == 'active' && (endDate == null || endDate!.isAfter(DateTime.now()));
}

class Settings {
  final String timezone;
  final String currency;
  final String language;
  final NotificationSettings notifications;

  Settings({
    required this.timezone,
    required this.currency,
    required this.language,
    required this.notifications,
  });

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      timezone: json['timezone'] ?? 'UTC',
      currency: json['currency'] ?? 'INR',
      language: json['language'] ?? 'en',
      notifications: NotificationSettings.fromJson(json['notifications'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timezone': timezone,
      'currency': currency,
      'language': language,
      'notifications': notifications.toJson(),
    };
  }
}

class NotificationSettings {
  final bool email;
  final bool push;
  final bool sms;

  NotificationSettings({
    required this.email,
    required this.push,
    required this.sms,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      email: json['email'] ?? true,
      push: json['push'] ?? true,
      sms: json['sms'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'push': push,
      'sms': sms,
    };
  }
}
