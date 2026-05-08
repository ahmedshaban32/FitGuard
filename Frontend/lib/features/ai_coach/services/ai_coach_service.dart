import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fit_guard_app/Core/network/api_error.dart';
import 'package:fit_guard_app/Core/network/api_service.dart';
import 'package:fit_guard_app/features/ai_coach/models/ai_chat_message.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AiCoachService {
  final ApiService _api;
  final http.Client _client;

  AiCoachService({ApiService? api, http.Client? client})
    : _api = api ?? ApiService(),
      _client = client ?? http.Client();

  bool get _allowInsecureDirectCohere {
    if (kReleaseMode) return false;
    const dartDefineValue = String.fromEnvironment('ALLOW_INSECURE_CLIENT_AI');
    final dotenvValue = dotenv.maybeGet('ALLOW_INSECURE_CLIENT_AI') ?? '';
    return dartDefineValue.toLowerCase() == 'true' ||
        dotenvValue.toLowerCase() == 'true';
  }

  String get _cohereApiKey {
    const dartDefineValue = String.fromEnvironment('COHERE_API_KEY');
    if (dartDefineValue.isNotEmpty) return dartDefineValue;
    return dotenv.maybeGet('COHERE_API_KEY') ?? '';
  }

  String get _cohereModel {
    const dartDefineValue = String.fromEnvironment(
      'COHERE_MODEL',
      defaultValue: '',
    );
    if (dartDefineValue.isNotEmpty) return dartDefineValue;
    return dotenv.maybeGet('COHERE_MODEL') ?? 'command-a-03-2025';
  }

  Future<String> sendMessage({
    required String message,
    required List<AiChatMessage> history,
  }) async {
    try {
      final endpoint =
          dotenv.maybeGet('AI_COACH_PROXY_ENDPOINT')?.trim().isNotEmpty == true
          ? dotenv.get('AI_COACH_PROXY_ENDPOINT')
          : '/ai/coach/chat';
      final response = await _api.post(endpoint, {
        'message': message,
        'history': history.map((item) => item.toApiJson()).toList(),
      });
      if (response is ApiError) throw response;
      final text = _extractText(response);
      if (text.isNotEmpty) return text;
      throw ApiError(message: 'AI coach returned an empty response.');
    } catch (error) {
      if (_shouldTryDirectCohere(error)) {
        return _sendDirectCohere(message: message, history: history);
      }
      if (error is ApiError && error.statusCode == 404) {
        throw ApiError(
          message:
              'AI Coach proxy is not available yet. Add a backend endpoint at /api/ai/coach/chat that calls Cohere securely.',
          statusCode: 404,
        );
      }
      rethrow;
    }
  }

  bool _shouldTryDirectCohere(Object error) {
    if (!_allowInsecureDirectCohere || _cohereApiKey.isEmpty) return false;
    return error is ApiError &&
        (error.statusCode == null ||
            error.statusCode == 404 ||
            error.statusCode == 501);
  }

  Future<String> _sendDirectCohere({
    required String message,
    required List<AiChatMessage> history,
  }) async {
    if (kReleaseMode) {
      throw ApiError(
        message: 'Direct AI calls are disabled in release builds.',
      );
    }

    final messages = history
        .take(12)
        .map(
          (item) => {
            'role': item.isUser ? 'user' : 'assistant',
            'content': item.text,
          },
        )
        .toList();
    messages.add({'role': 'user', 'content': message});

    final response = await _client
        .post(
          Uri.parse('https://api.cohere.ai/v2/chat'),
          headers: {
            HttpHeaders.authorizationHeader: 'Bearer $_cohereApiKey',
            HttpHeaders.contentTypeHeader: 'application/json',
            HttpHeaders.acceptHeader: 'application/json',
          },
          body: jsonEncode({
            'model': _cohereModel,
            'messages': [
              {
                'role': 'system',
                'content':
                    'You are FitGuard AI Coach, a concise certified fitness and nutrition assistant. Give practical, safe, non-medical guidance. Encourage professional care for injuries, chest pain, eating disorders, pregnancy, or medical conditions.',
              },
              ...messages,
            ],
            'temperature': 0.35,
          }),
        )
        .timeout(const Duration(seconds: 35));

    final decoded = _decode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiError(
        message: _extractText(decoded).isNotEmpty
            ? _extractText(decoded)
            : 'Cohere request failed (${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }
    final text = _extractText(decoded);
    if (text.isEmpty) {
      throw ApiError(message: 'Cohere returned an empty response.');
    }
    return text;
  }

  String _extractText(dynamic response) {
    if (response is Map) {
      for (final key in ['reply', 'response', 'text', 'message', 'content']) {
        final value = response[key];
        if (value is String && value.trim().isNotEmpty) return value.trim();
      }
      final data = response['data'];
      if (data is Map) return _extractText(data);
      final message = response['message'];
      if (message is Map) return _extractText(message);
      final content = response['content'];
      if (content is List && content.isNotEmpty) {
        for (final item in content) {
          final text = _extractText(item);
          if (text.isNotEmpty) return text;
        }
      }
      final generations = response['generations'];
      if (generations is List && generations.isNotEmpty) {
        return _extractText(generations.first);
      }
    }
    return '';
  }

  Map<String, dynamic> _decode(String body) {
    final decoded = jsonDecode(body);
    return decoded is Map<String, dynamic>
        ? decoded
        : Map<String, dynamic>.from(decoded as Map);
  }

  void close() => _client.close();
}
