import 'package:fit_guard_app/Core/network/api_error.dart';
import 'package:fit_guard_app/Core/network/api_service.dart';
import 'package:fit_guard_app/features/coach_chat/models/coach_chat_models.dart';

class CoachChatService {
  final ApiService _api;

  CoachChatService({ApiService? api}) : _api = api ?? ApiService();

  Future<List<CoachProfile>> getPublicCoaches() async {
    final response = await _api.get('/coaches/public');
    if (response is ApiError) throw response;
    final list = _listFrom(response, const ['coaches', 'data', 'items']);
    return list
        .whereType<Map>()
        .map((item) => CoachProfile.fromJson(Map<String, dynamic>.from(item)))
        .where((coach) => coach.id.isNotEmpty)
        .toList();
  }

  Future<CoachProfile> getCoach(String id) async {
    final response = await _api.get('/coaches/$id');
    if (response is ApiError) throw response;
    final map = _mapFrom(response);
    final coach = map['coach'] is Map
        ? Map<String, dynamic>.from(map['coach'] as Map)
        : map;
    return CoachProfile.fromJson(coach);
  }

  Future<SubscriptionStatus> getSubscription() async {
    final response = await _api.get('/subscriptions/me');
    if (response is ApiError) {
      if (response.statusCode == 404) {
        return const SubscriptionStatus(isActive: false);
      }
      throw response;
    }
    if (response is List && response.isNotEmpty && response.first is Map) {
      return SubscriptionStatus.fromJson(
        Map<String, dynamic>.from(response.first as Map),
      );
    }
    return SubscriptionStatus.fromJson(_mapFrom(response));
  }

  Future<void> subscribeToCoach(String coachId) async {
    final response = await _api.post('/subscriptions', {'coachId': coachId});
    if (response is ApiError) throw response;
  }

  Future<List<CoachConversation>> getConversations() async {
    final response = await _api.get('/chat/conversations');
    if (response is ApiError) throw response;
    final list = _listFrom(response, const ['conversations', 'data', 'items']);
    return list
        .whereType<Map>()
        .map(
          (item) => CoachConversation.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<CoachConversation> startConversation(String coachId) async {
    final response = await _api.post('/chat/conversations', {
      'coachId': coachId,
    });
    if (response is ApiError) throw response;
    final map = _mapFrom(response);
    final conversation = map['conversation'] is Map
        ? Map<String, dynamic>.from(map['conversation'] as Map)
        : map;
    return CoachConversation.fromJson(conversation);
  }

  Future<List<CoachMessage>> getMessages(String conversationId) async {
    final response = await _api.get(
      '/chat/conversations/$conversationId/messages',
    );
    if (response is ApiError) throw response;
    final list = _listFrom(response, const ['messages', 'data', 'items']);
    return list
        .whereType<Map>()
        .map((item) => CoachMessage.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<CoachMessage> sendMessage({
    required String conversationId,
    required String body,
  }) async {
    final response = await _api.post(
      '/chat/conversations/$conversationId/messages',
      {'message': body},
    );
    if (response is ApiError) throw response;
    final map = _mapFrom(response);
    final message = map['message'] is Map
        ? Map<String, dynamic>.from(map['message'] as Map)
        : map;
    return CoachMessage.fromJson({...message, 'isMine': true});
  }

  Map<String, dynamic> _mapFrom(dynamic response) {
    if (response is Map<String, dynamic>) return response;
    if (response is Map) return Map<String, dynamic>.from(response);
    return <String, dynamic>{};
  }

  List<dynamic> _listFrom(dynamic response, List<String> keys) {
    if (response is List) return response;
    final map = _mapFrom(response);
    for (final key in keys) {
      final value = map[key];
      if (value is List) return value;
    }
    return const [];
  }
}
