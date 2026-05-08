class CoachProfile {
  final String id;
  final String name;
  final String email;
  final String bio;
  final List<String> specialties;
  final String? imageUrl;
  final double rating;

  const CoachProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.bio,
    required this.specialties,
    this.imageUrl,
    this.rating = 4.8,
  });

  factory CoachProfile.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] is Map
        ? Map<String, dynamic>.from(json['profile'] as Map)
        : json;
    return CoachProfile(
      id: (json['id'] ?? json['_id'] ?? profile['id'] ?? '').toString(),
      name:
          (json['name'] ??
                  profile['name'] ??
                  json['fullName'] ??
                  'FitGuard Coach')
              .toString(),
      email: (json['email'] ?? '').toString(),
      bio: (json['bio'] ?? profile['bio'] ?? 'Certified fitness coach.')
          .toString(),
      specialties: _stringList(
        json['specialties'] ?? profile['specialties'] ?? profile['specialty'],
      ),
      imageUrl: (json['image'] ?? json['avatar'] ?? profile['image'])
          ?.toString(),
      rating: _double(json['rating'] ?? profile['rating'], 4.8),
    );
  }
}

class CoachConversation {
  final String id;
  final CoachProfile coach;
  final String? userId;
  final String title;
  final CoachMessage? lastMessage;
  final int unreadCount;
  final DateTime updatedAt;
  final bool canMessage;

  const CoachConversation({
    required this.id,
    required this.coach,
    this.userId,
    required this.title,
    this.lastMessage,
    this.unreadCount = 0,
    required this.updatedAt,
    this.canMessage = true,
  });

  factory CoachConversation.fromJson(Map<String, dynamic> json) {
    final coachSource = json['coach'] is Map
        ? Map<String, dynamic>.from(json['coach'] as Map)
        : json['participant'] is Map
        ? Map<String, dynamic>.from(json['participant'] as Map)
        : <String, dynamic>{};
    final lastMessageSource = json['lastMessage'] ?? json['last_message'];
    return CoachConversation(
      id: (json['id'] ?? json['_id'] ?? json['conversationId'] ?? '')
          .toString(),
      coach: CoachProfile.fromJson(coachSource),
      userId: (json['userId'] ?? json['user_id'])?.toString(),
      title:
          (json['title'] ??
                  coachSource['name'] ??
                  coachSource['profile']?['name'] ??
                  'Coach Chat')
              .toString(),
      lastMessage: lastMessageSource is Map
          ? CoachMessage.fromJson(Map<String, dynamic>.from(lastMessageSource))
          : null,
      unreadCount: _int(json['unreadCount'] ?? json['unread_count'], 0),
      updatedAt: _date(json['updatedAt'] ?? json['updated_at']),
      canMessage: json['canMessage'] != false && json['can_message'] != false,
    );
  }
}

class CoachMessage {
  final String id;
  final String senderId;
  final String senderRole;
  final String body;
  final DateTime createdAt;
  final bool isMine;

  const CoachMessage({
    required this.id,
    required this.senderId,
    required this.senderRole,
    required this.body,
    required this.createdAt,
    required this.isMine,
  });

  factory CoachMessage.fromJson(Map<String, dynamic> json) {
    return CoachMessage(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      senderId: (json['senderId'] ?? json['sender_id'] ?? '').toString(),
      senderRole: (json['senderRole'] ?? json['sender_role'] ?? 'user')
          .toString(),
      body: (json['body'] ?? json['message'] ?? json['content'] ?? '')
          .toString(),
      createdAt: _date(json['createdAt'] ?? json['created_at']),
      isMine: json['isMine'] == true || json['mine'] == true,
    );
  }
}

class SubscriptionStatus {
  final bool isActive;
  final String? coachId;
  final String? subscriptionId;

  const SubscriptionStatus({
    required this.isActive,
    this.coachId,
    this.subscriptionId,
  });

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    final source = json['subscription'] is Map
        ? Map<String, dynamic>.from(json['subscription'] as Map)
        : json;
    final status = (source['status'] ?? '').toString().toLowerCase();
    return SubscriptionStatus(
      isActive:
          source['isActive'] == true ||
          source['active'] == true ||
          status == 'active',
      coachId:
          (source['coachId'] ?? source['coach_id'] ?? source['coach']?['id'])
              ?.toString(),
      subscriptionId: (source['id'] ?? source['_id'])?.toString(),
    );
  }
}

List<String> _stringList(dynamic value) {
  if (value is List) return value.map((item) => item.toString()).toList();
  if (value is String && value.trim().isNotEmpty) {
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
  return const ['Strength', 'Nutrition'];
}

int _int(dynamic value, int fallback) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

double _double(dynamic value, double fallback) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

DateTime _date(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
}
