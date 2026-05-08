import 'dart:async';
import 'dart:io';

import 'package:fit_guard_app/Core/constants/app_colors.dart';
import 'package:fit_guard_app/Core/network/api_error.dart';
import 'package:fit_guard_app/presentation/screens/nutriton/data/nutrition_service.dart';
import 'package:fit_guard_app/presentation/screens/profile/data/profile_repo.dart';
import 'package:flutter/material.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  final ProfileRepo _profileRepo = ProfileRepo();
  final NutritionService _nutritionService = NutritionService();

  bool _loading = true;
  bool _refreshing = false;
  String? _error;
  ProfileModel? _profile;
  NutritionPlan? _plan;

  @override
  void initState() {
    super.initState();
    _loadNutritionPlan();
  }

  @override
  void dispose() {
    _nutritionService.close();
    super.dispose();
  }

  Future<void> _loadNutritionPlan({bool refresh = false}) async {
    if (refresh) {
      setState(() => _refreshing = true);
    } else {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final profile = await _profileRepo.getProfile();
      final plan = await _nutritionService.generatePlan(profile);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _plan = plan;
        _error = null;
      });
    } on SocketException {
      _setError('No internet connection. Check your network and retry.');
    } on TimeoutException {
      _setError('Nutrition AI took too long to respond. Try again.');
    } catch (error) {
      _setError(_messageFor(error));
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _refreshing = false;
        });
      }
    }
  }

  void _setError(String message) {
    if (!mounted) return;
    setState(() => _error = message);
  }

  String _messageFor(Object error) {
    if (error is ApiError) return error.message;
    return error.toString().replaceFirst('Exception: ', '');
  }

  Future<void> _openRecipe(NutritionMeal meal) async {
    final goal = _profile?.goal ?? 'Maintain';
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _RecipeSheet(
        meal: meal,
        goal: goal,
        nutritionService: _nutritionService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => _loadNutritionPlan(refresh: true),
          child: _body(),
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 220),
          Center(child: CircularProgressIndicator(color: AppColors.primary)),
          SizedBox(height: 14),
          Center(
            child: Text(
              'Generating your nutrition plan...',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      );
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          _Header(onRefresh: () => _loadNutritionPlan(refresh: true)),
          const SizedBox(height: 28),
          _ErrorCard(message: _error!, onRetry: _loadNutritionPlan),
        ],
      );
    }

    final plan = _plan;
    if (plan == null || !plan.hasMeals) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          _Header(onRefresh: () => _loadNutritionPlan(refresh: true)),
          const SizedBox(height: 28),
          const _EmptyCard(),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
      children: [
        _Header(onRefresh: () => _loadNutritionPlan(refresh: true)),
        if (_refreshing) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(color: AppColors.primary),
        ],
        const SizedBox(height: 20),
        _DailyGoalCard(plan: plan),
        const SizedBox(height: 18),
        _NotesCard(plan: plan),
        const SizedBox(height: 24),
        ...plan.meals.entries.expand(
          (entry) => [
            _MealSectionHeader(title: entry.key),
            const SizedBox(height: 12),
            if (entry.value.isEmpty)
              const _SmallMutedCard(text: 'No meals returned for this section.')
            else
              ...entry.value.map(
                (meal) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _MealCard(
                    meal: meal,
                    onRecipe: () => _openRecipe(meal),
                  ),
                ),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onRefresh;

  const _Header({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nutrition',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Synced profile • ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        IconButton(
          tooltip: 'Regenerate',
          icon: const Icon(Icons.refresh),
          color: AppColors.textSecondary,
          onPressed: onRefresh,
        ),
      ],
    );
  }
}

class _DailyGoalCard extends StatelessWidget {
  final NutritionPlan plan;

  const _DailyGoalCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DAILY TARGET',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                plan.calories == 0 ? '--' : '${plan.calories}',
                style: const TextStyle(
                  fontSize: 46,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  height: 1,
                ),
              ),
              const SizedBox(width: 6),
              const Padding(
                padding: EdgeInsets.only(bottom: 5),
                child: Text(
                  'kcal',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ...plan.macros.entries.map(
                (entry) => _MacroChip(label: entry.key, value: entry.value),
              ),
              if (plan.waterIntake.trim().isNotEmpty)
                _MacroChip(label: 'Water', value: plan.waterIntake),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  final NutritionPlan plan;

  const _NotesCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    if (plan.notes.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, color: AppColors.success, size: 20),
              SizedBox(width: 8),
              Text(
                'AI Notes',
                style: TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...plan.notes.map(
            (note) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '- $note',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final String value;

  const _MacroChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        '${_title(label)}: $value',
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MealSectionHeader extends StatelessWidget {
  final String title;

  const _MealSectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  final NutritionMeal meal;
  final VoidCallback onRecipe;

  const _MealCard({required this.meal, required this.onRecipe});

  @override
  Widget build(BuildContext context) {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.restaurant_menu, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.nameEn,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (meal.nameAr != meal.nameEn)
                      Text(
                        meal.nameAr,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      meal.portion,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (meal.calories > 0)
                Text(
                  '${meal.calories} kcal',
                  style: const TextStyle(
                    color: AppColors.warning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          if (meal.macros.isNotEmpty || meal.note.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...meal.macros.entries.map(
                  (entry) => _MiniPill(label: entry.key, value: entry.value),
                ),
                if (meal.note.trim().isNotEmpty)
                  _MiniPill(label: 'Note', value: meal.note),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onRecipe,
              icon: const Icon(Icons.menu_book_outlined, size: 18),
              label: const Text('View Recipe'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final String label;
  final String value;

  const _MiniPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '${_title(label)} $value',
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
    );
  }
}

class _RecipeSheet extends StatefulWidget {
  final NutritionMeal meal;
  final String goal;
  final NutritionService nutritionService;

  const _RecipeSheet({
    required this.meal,
    required this.goal,
    required this.nutritionService,
  });

  @override
  State<_RecipeSheet> createState() => _RecipeSheetState();
}

class _RecipeSheetState extends State<_RecipeSheet> {
  bool _loading = true;
  String? _error;
  RecipeDetails? _recipe;

  @override
  void initState() {
    super.initState();
    _loadRecipe();
  }

  Future<void> _loadRecipe() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final recipe = await widget.nutritionService.getRecipe(
        meal: widget.meal,
        goal: widget.goal,
      );
      if (!mounted) return;
      setState(() => _recipe = recipe);
    } on TimeoutException {
      _setError('Recipe AI took too long. Please retry.');
    } catch (error) {
      _setError(error is ApiError ? error.message : error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _setError(String message) {
    if (!mounted) return;
    setState(() => _error = message);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      minChildSize: 0.45,
      maxChildSize: 0.94,
      builder: (_, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.all(22),
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            widget.meal.nameEn,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.meal.portion,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (_error != null)
            _ErrorCard(message: _error!, onRetry: _loadRecipe)
          else if (_recipe != null)
            _RecipeContent(recipe: _recipe!),
        ],
      ),
    );
  }
}

class _RecipeContent extends StatelessWidget {
  final RecipeDetails recipe;

  const _RecipeContent({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (recipe.calories > 0 || recipe.nutritionValues.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (recipe.calories > 0)
                _MacroChip(label: 'Calories', value: '${recipe.calories} kcal'),
              ...recipe.nutritionValues.entries.map(
                (entry) => _MacroChip(label: entry.key, value: entry.value),
              ),
            ],
          ),
        const SizedBox(height: 20),
        _RecipeList(title: 'Ingredients', items: recipe.ingredients),
        const SizedBox(height: 20),
        _RecipeList(title: 'Preparation', items: recipe.steps, numbered: true),
      ],
    );
  }
}

class _RecipeList extends StatelessWidget {
  final String title;
  final List<String> items;
  final bool numbered;

  const _RecipeList({
    required this.title,
    required this.items,
    this.numbered = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        if (items.isEmpty)
          const Text(
            'No details returned.',
            style: TextStyle(color: AppColors.textSecondary),
          )
        else
          ...items.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                numbered
                    ? '${entry.key + 1}. ${entry.value}'
                    : '- ${entry.value}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.36)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.error),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(color: AppColors.textPrimary, height: 1.4),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

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
          Icon(Icons.restaurant_menu, color: AppColors.textSecondary, size: 42),
          SizedBox(height: 12),
          Text(
            'No nutrition plan yet.',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Pull to refresh and FitGuard will generate one from your saved profile.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _SmallMutedCard extends StatelessWidget {
  final String text;

  const _SmallMutedCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(text, style: const TextStyle(color: AppColors.textSecondary)),
    );
  }
}

String _title(String value) {
  return value
      .replaceAll('_', ' ')
      .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
      .trim()
      .split(' ')
      .where((word) => word.isNotEmpty)
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}
