import 'package:fit_guard_app/Core/constants/app_colors.dart';
import 'package:fit_guard_app/features/progress/models/workout_history_entry.dart';
import 'package:fit_guard_app/features/progress/services/progress_repository.dart';
import 'package:flutter/material.dart';

enum HistoryFilter { all, strength, cardio, aiTracked }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _repo = ProgressRepository();
  HistoryFilter _filter = HistoryFilter.all;
  late Future<List<WorkoutHistoryEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.getHistory(refresh: true);
  }

  Future<void> _refresh() async {
    setState(() => _future = _repo.getHistory(refresh: true));
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        title: const Text('History'),
      ),
      body: FutureBuilder<List<WorkoutHistoryEntry>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (snapshot.hasError) {
            return _StateMessage(
              icon: Icons.error_outline,
              title: 'Could not load history',
              message: snapshot.error.toString(),
              onRetry: _refresh,
            );
          }
          final entries = _applyFilter(snapshot.data ?? const []);
          return RefreshIndicator(
            onRefresh: _refresh,
            color: AppColors.primary,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
              children: [
                _buildFilters(),
                const SizedBox(height: 16),
                if (entries.isEmpty)
                  const _EmptyHistory()
                else
                  ..._grouped(entries).entries.expand(
                    (group) => [
                      _DateHeader(label: group.key),
                      const SizedBox(height: 10),
                      ...group.value.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _HistoryCard(entry: entry),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: HistoryFilter.values.map((filter) {
          final selected = filter == _filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: selected,
              label: Text(_filterLabel(filter)),
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.cardBackground,
              side: const BorderSide(color: AppColors.border),
              labelStyle: TextStyle(
                color: selected ? Colors.white : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              ),
              onSelected: (_) => setState(() => _filter = filter),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<WorkoutHistoryEntry> _applyFilter(List<WorkoutHistoryEntry> entries) {
    return entries.where((entry) {
      switch (_filter) {
        case HistoryFilter.strength:
          return entry.type == WorkoutHistoryType.strength;
        case HistoryFilter.cardio:
          return entry.type == WorkoutHistoryType.cardio;
        case HistoryFilter.aiTracked:
          return entry.type == WorkoutHistoryType.aiTracked ||
              entry.source == WorkoutHistorySource.ai;
        case HistoryFilter.all:
          return true;
      }
    }).toList();
  }

  Map<String, List<WorkoutHistoryEntry>> _grouped(
    List<WorkoutHistoryEntry> entries,
  ) {
    final map = <String, List<WorkoutHistoryEntry>>{};
    for (final entry in entries) {
      final label = _dateLabel(entry.sessionAt);
      map.putIfAbsent(label, () => []).add(entry);
    }
    return map;
  }

  String _filterLabel(HistoryFilter filter) {
    switch (filter) {
      case HistoryFilter.all:
        return 'All';
      case HistoryFilter.strength:
        return 'Strength';
      case HistoryFilter.cardio:
        return 'Cardio';
      case HistoryFilter.aiTracked:
        return 'AI Tracked';
    }
  }
}

class _HistoryCard extends StatelessWidget {
  final WorkoutHistoryEntry entry;

  const _HistoryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final color = entry.type == WorkoutHistoryType.cardio
        ? AppColors.calories
        : entry.source == WorkoutHistorySource.ai
        ? AppColors.secondary
        : AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.exerciseName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_time(entry.sessionAt)} • ${entry.source.name.toUpperCase()}',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (!entry.synced)
                const Icon(Icons.cloud_off, color: AppColors.warning, size: 18),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Metric(label: 'Reps', value: '${entry.totalReps}'),
              _Metric(label: 'Correct', value: '${entry.correctReps}'),
              _Metric(label: 'Wrong', value: '${entry.wrongReps}'),
              _Metric(label: 'Kcal', value: '${entry.caloriesBurned}'),
            ],
          ),
          if (entry.durationSeconds > 0 || entry.mistakes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (entry.durationSeconds > 0)
                  _Pill(text: '${(entry.durationSeconds / 60).round()} min'),
                ...entry.mistakes.take(3).map((item) => _Pill(text: item)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  IconData get _icon {
    if (entry.type == WorkoutHistoryType.cardio) return Icons.directions_run;
    if (entry.source == WorkoutHistorySource.ai) return Icons.psychology_alt;
    return Icons.fitness_center;
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;

  const _Pill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: const TextStyle(color: AppColors.textSecondary)),
    );
  }
}

class _DateHeader extends StatelessWidget {
  final String label;

  const _DateHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.history, color: AppColors.textSecondary, size: 44),
          SizedBox(height: 12),
          Text(
            'No sessions yet',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'AI workouts, uploaded videos, and cardio entries will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Future<void> Function() onRetry;

  const _StateMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary, size: 46),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

String _dateLabel(DateTime value) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(value.year, value.month, value.day);
  if (date == today) return 'Today';
  if (date == today.subtract(const Duration(days: 1))) return 'Yesterday';
  return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}

String _time(DateTime value) {
  return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}
