import 'dart:io';

import 'package:fit_guard_app/Core/constants/app_colors.dart';
import 'package:fit_guard_app/Core/network/api_error.dart';
import 'package:fit_guard_app/features/food_scanner/models/food_scan_result.dart';
import 'package:fit_guard_app/features/food_scanner/services/food_scanner_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class FoodScannerScreen extends StatefulWidget {
  const FoodScannerScreen({super.key});

  @override
  State<FoodScannerScreen> createState() => _FoodScannerScreenState();
}

class _FoodScannerScreenState extends State<FoodScannerScreen>
    with SingleTickerProviderStateMixin {
  final _picker = ImagePicker();
  final _service = FoodScannerService();
  late final AnimationController _scanController;
  File? _image;
  FoodScanResult? _result;
  bool _scanning = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 82,
      maxWidth: 1600,
    );
    if (picked == null) return;
    setState(() {
      _image = File(picked.path);
      _result = null;
      _error = null;
    });
    await _scan();
  }

  Future<void> _scan() async {
    final image = _image;
    if (image == null) return;
    setState(() {
      _scanning = true;
      _error = null;
    });
    _scanController.repeat(reverse: true);
    try {
      final result = await _service.scanFood(image);
      if (!mounted) return;
      setState(() {
        _result = result;
        _scanning = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is ApiError ? error.message : error.toString();
        _scanning = false;
      });
    } finally {
      _scanController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Scan Food'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            _buildHero(),
            const SizedBox(height: 18),
            _buildImagePanel(),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _scanning
                        ? null
                        : () => _pick(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Upload'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.secondary,
                      side: const BorderSide(color: AppColors.secondary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _scanning
                        ? null
                        : () => _pick(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Camera'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
            if (_image != null) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _scanning ? null : _scan,
                icon: const Icon(Icons.refresh),
                label: const Text('Analyze again'),
              ),
            ],
            const SizedBox(height: 20),
            if (_scanning) _buildScanning(),
            if (_error != null) _buildError(),
            if (_result != null) _ResultCard(result: _result!),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00D9A0), Color(0xFF00D9FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.document_scanner_outlined, color: Colors.white, size: 34),
          SizedBox(height: 14),
          Text(
            'AI Food Scanner',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Take a photo and estimate calories, protein, carbs, fats, and serving size.',
            style: TextStyle(color: Colors.white, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePanel() {
    return AspectRatio(
      aspectRatio: 1.15,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: _image == null
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.fastfood_outlined,
                      color: AppColors.textSecondary,
                      size: 48,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Choose a food photo',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(_image!, fit: BoxFit.cover),
                  if (_scanning)
                    AnimatedBuilder(
                      animation: _scanController,
                      builder: (_, __) {
                        return Align(
                          alignment: Alignment(
                            0,
                            -1 + _scanController.value * 2,
                          ),
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.secondary.withValues(
                                    alpha: 0.7,
                                  ),
                                  blurRadius: 18,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildScanning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: AppColors.secondary,
              strokeWidth: 2,
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'Analyzing nutrition estimate...',
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(
                color: AppColors.textPrimary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final FoodScanResult result;

  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  result.foodName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            result.servingEstimate,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: 'Calories',
                  value: '${result.calories}',
                  color: AppColors.calories,
                ),
              ),
              Expanded(
                child: _Metric(
                  label: 'Protein',
                  value: '${result.protein.toStringAsFixed(1)}g',
                  color: AppColors.protein,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: 'Carbs',
                  value: '${result.carbs.toStringAsFixed(1)}g',
                  color: AppColors.carbs,
                ),
              ),
              Expanded(
                child: _Metric(
                  label: 'Fats',
                  value: '${result.fats.toStringAsFixed(1)}g',
                  color: AppColors.fats,
                ),
              ),
            ],
          ),
          if (result.notes.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...result.notes.map(
              (note) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '• $note',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Metric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
