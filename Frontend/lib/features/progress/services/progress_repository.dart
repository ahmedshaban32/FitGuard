import 'dart:convert';

import 'package:fit_guard_app/Core/network/api_error.dart';
import 'package:fit_guard_app/Core/network/api_service.dart';
import 'package:fit_guard_app/features/progress/models/workout_history_entry.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProgressRepository {
  static const _historyKey = 'workout_history_entries_v1';
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);
  final ApiService _api;

  ProgressRepository({ApiService? api}) : _api = api ?? ApiService();

  Future<List<WorkoutHistoryEntry>> getHistory({bool refresh = false}) async {
    final local = await _readLocal();
    if (!refresh) return local;

    try {
      final response = await _api.get('/progress/me');
      if (response is ApiError) throw response;
      final remote = _parseRemoteHistory(response);
      if (remote.isNotEmpty) {
        final merged = _merge(remote, local);
        await _writeLocal(merged);
        return merged;
      }
    } catch (_) {
      // Local cache remains the source of truth when backend progress is offline.
    }
    return local;
  }

  Future<ProgressSummary> getSummary({bool refresh = false}) async {
    final history = await getHistory(refresh: refresh);
    return ProgressSummary.fromEntries(history);
  }

  Future<void> saveSession(WorkoutHistoryEntry entry) async {
    final local = await _readLocal();
    final merged = _merge([entry], local);
    await _writeLocal(merged);
    _notifyChanged();

    try {
      final response = await _api.post(
        '/progress/sessions',
        entry.toBackendJson(),
      );
      if (response is ApiError) throw response;
      final synced = entry.copyWith(synced: true);
      await _writeLocal(_merge([synced], await _readLocal()));
      _notifyChanged();
    } catch (_) {
      // Keep unsynced local entry; dashboard/history still update immediately.
    }
  }

  static void _notifyChanged() {
    revision.value = revision.value + 1;
  }

  Future<void> syncPending() async {
    final history = await _readLocal();
    for (final entry in history.where((item) => !item.synced)) {
      await saveSession(entry);
    }
  }

  Future<List<WorkoutHistoryEntry>> _readLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map(
            (item) =>
                WorkoutHistoryEntry.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList()
        ..sort((a, b) => b.sessionAt.compareTo(a.sessionAt));
    } catch (_) {
      return const [];
    }
  }

  Future<void> _writeLocal(List<WorkoutHistoryEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final sorted = [...entries]
      ..sort((a, b) => b.sessionAt.compareTo(a.sessionAt));
    await prefs.setString(
      _historyKey,
      jsonEncode(sorted.map((item) => item.toJson()).toList()),
    );
  }

  List<WorkoutHistoryEntry> _parseRemoteHistory(dynamic response) {
    final list = response is List
        ? response
        : response is Map
        ? (response['sessions'] ??
              response['history'] ??
              response['data'] ??
              const [])
        : const [];
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map(
          (item) => WorkoutHistoryEntry.fromJson({
            ...Map<String, dynamic>.from(item),
            'synced': true,
          }),
        )
        .toList();
  }

  List<WorkoutHistoryEntry> _merge(
    List<WorkoutHistoryEntry> incoming,
    List<WorkoutHistoryEntry> existing,
  ) {
    final byId = <String, WorkoutHistoryEntry>{};
    for (final item in existing) {
      byId[item.id] = item;
    }
    for (final item in incoming) {
      final current = byId[item.id];
      byId[item.id] = current == null || item.synced ? item : current;
    }
    return byId.values.toList()
      ..sort((a, b) => b.sessionAt.compareTo(a.sessionAt));
  }
}
