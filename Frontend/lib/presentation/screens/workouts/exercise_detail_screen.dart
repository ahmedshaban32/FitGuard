import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fit_guard_app/Core/constants/app_colors.dart';
import 'package:fit_guard_app/Core/utils/pref_helpers.dart';
import 'package:fit_guard_app/features/progress/models/workout_history_entry.dart';
import 'package:fit_guard_app/features/progress/services/progress_repository.dart';
import 'package:fit_guard_app/presentation/screens/workouts/live_workout_screen.dart';
import 'package:fit_guard_app/presentation/screens/workouts/models/workout_models.dart';
import 'package:fit_guard_app/presentation/screens/workouts/widgets/workout_widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

const _kDefaultAiBaseUrl =
    'https://silver-space-enigma-5grvq594jr5xh46w7-8000.app.github.dev';
const _kBaseUrl = String.fromEnvironment(
  'FITGUARD_AI_BASE_URL',
  defaultValue: _kDefaultAiBaseUrl,
);
const _kUploadApiKey = String.fromEnvironment('FITGUARD_UPLOAD_API_KEY');
const _kLargeUploadWarningBytes = 25 * 1024 * 1024;
const _kMaxUploadBytes = 90 * 1024 * 1024;
const _kAnalysisReplayFrameDelay = Duration(milliseconds: 90);
const _kMaxAnalysisReplayFrames = 450;

enum _ActivePanel { none, upload }

class ExerciseDetailScreen extends StatefulWidget {
  final Exercise exercise;

  const ExerciseDetailScreen({super.key, required this.exercise});

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen>
    with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  final http.Client _httpClient = http.Client();

  _ActivePanel _activePanel = _ActivePanel.none;
  bool _tipsExpanded = false;
  XFile? _selectedVideo;
  bool _isUploading = false;
  bool _analysisComplete = false;
  int? _selectedVideoBytes;
  Timer? _analysisReplayTimer;

  int _aiReps = 0;
  int _aiErrors = 0;
  String _aiLiveFeedback = 'WAITING';
  String _aiFeedbackMsg = 'Upload a video to see AI analysis';
  Uint8List? _analyzedFrame;
  final List<_AnalyzedVideoFrame> _analyzedFrames = [];
  int _analysisReplayIndex = 0;
  bool _isReplayingAnalysis = false;
  DateTime? _analysisStartedAt;
  bool _historySaved = false;
  List<String> _lastMistakes = const [];

  @override
  void dispose() {
    _analysisReplayTimer?.cancel();
    _httpClient.close();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final video = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 30),
    );
    if (video == null) return;

    final videoSize = await video.length();
    _safeSetState(() {
      _selectedVideo = video;
      _selectedVideoBytes = videoSize;
      _analysisComplete = false;
      if (videoSize >= _kLargeUploadWarningBytes) {
        _aiLiveFeedback = 'READY';
        _aiFeedbackMsg =
            'Large video selected (${_readableBytes(videoSize)}). Analysis may take longer.';
      }
    });
  }

  Future<void> _uploadAndAnalyzeVideo() async {
    if (_isUploading) return;

    final selectedVideo = _selectedVideo;
    if (selectedVideo == null) {
      _showError('Select a valid video file before starting analysis.');
      _safeSetState(() {
        _aiLiveFeedback = 'ERROR';
        _aiFeedbackMsg = 'No video file was selected.';
      });
      return;
    }

    final backendKey = mapExerciseName(widget.exercise.name);
    if (backendKey.isEmpty) {
      _showError('This exercise is not supported by the AI backend.');
      return;
    }

    _safeSetState(() {
      _isUploading = true;
      _analysisComplete = false;
      _analyzedFrame = null;
      _analyzedFrames.clear();
      _analysisReplayIndex = 0;
      _isReplayingAnalysis = false;
      _analysisReplayTimer?.cancel();
      _aiReps = 0;
      _aiErrors = 0;
      _aiLiveFeedback = 'PROCESSING';
      _aiFeedbackMsg = 'Preparing direct upload for AI analysis...';
      _analysisStartedAt = DateTime.now();
      _historySaved = false;
      _lastMistakes = const [];
    });

    try {
      final uploadUri = _aiUri('/upload-video-stream');
      final uploadVideo = selectedVideo;
      final videoSize = await uploadVideo.length();
      if (videoSize <= 0) {
        throw const FileSystemException('Selected video is empty');
      }

      if (videoSize > _kMaxUploadBytes) {
        throw FileSystemException(
          'Video is too large (${_readableBytes(videoSize)}). Use a shorter clip under ${_readableBytes(_kMaxUploadBytes)}.',
        );
      }

      _safeSetState(() {
        _aiFeedbackMsg =
            'Uploading ${_readableBytes(videoSize)} directly to AI...';
      });

      final request = http.MultipartRequest('POST', uploadUri);
      request.headers.addAll(await _uploadHeaders());
      request.fields['exercise_name'] = backendKey;
      request.files.add(
        http.MultipartFile(
          'video',
          uploadVideo.openRead(),
          videoSize,
          filename: _videoFileName(uploadVideo),
        ),
      );
      _debugUploadRequest(
        request: request,
        backendKey: backendKey,
        videoPath: uploadVideo.path,
        videoSize: videoSize,
      );

      final streamedResponse = await request.send().timeout(
        const Duration(minutes: 10),
      );

      if (streamedResponse.statusCode < 200 ||
          streamedResponse.statusCode >= 300) {
        final body = await streamedResponse.stream.bytesToString();
        throw HttpException(_uploadFailureMessage(streamedResponse, body));
      }

      if (kDebugMode) {
        debugPrint(
          'Workout upload response: status=${streamedResponse.statusCode} '
          'contentType=${streamedResponse.headers[HttpHeaders.contentTypeHeader]}',
        );
      }

      await streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .forEach(_handleStreamLine);

      if (mounted && _isUploading) {
        _safeSetState(() {
          _isUploading = false;
          _analysisComplete = true;
          if (_analyzedFrames.length > 1) {
            _aiFeedbackMsg = 'Playing analyzed video with AI feedback.';
          } else {
            _aiLiveFeedback = 'DONE';
            _aiFeedbackMsg = 'Analysis complete.';
          }
        });
        _startAnalyzedVideoReplay();
        unawaited(_saveAiHistorySession(source: WorkoutHistorySource.ai));
      }
    } on SocketException {
      _failUpload('No network connection. Check your internet and retry.');
    } on TimeoutException {
      _failUpload('The AI analysis timed out. Please try a shorter video.');
    } on FileSystemException {
      _failUpload(
        'Could not read the selected video. Pick a shorter clip and try again.',
      );
    } catch (error) {
      _failUpload(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  String _videoFileName(XFile video) {
    if (video.name.trim().isNotEmpty) return video.name.trim();
    if (video.path.trim().isEmpty) return 'workout-video.mp4';
    return video.path.split(RegExp(r'[\\/]')).last;
  }

  Future<Map<String, String>> _uploadHeaders() async {
    final token = await PrefHelper.getToken();
    final headers = <String, String>{
      HttpHeaders.acceptHeader: 'application/x-ndjson, application/json',
      HttpHeaders.userAgentHeader: 'FitGuard-Flutter',
    };

    if (token != null && token.isNotEmpty && token != 'guest') {
      headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
    }
    if (_kUploadApiKey.isNotEmpty) {
      headers['x-api-key'] = _kUploadApiKey;
    }

    debugPrint(
      'Uploading workout video to ${_aiUri('/upload-video-stream')} '
      'with auth=${headers.containsKey(HttpHeaders.authorizationHeader)} '
      'apiKey=${headers.containsKey('x-api-key')}',
    );
    return headers;
  }

  Uri _aiUri(String path) {
    final base = _kBaseUrl.endsWith('/')
        ? _kBaseUrl.substring(0, _kBaseUrl.length - 1)
        : _kBaseUrl;
    return Uri.parse('$base$path');
  }

  void _debugUploadRequest({
    required http.MultipartRequest request,
    required String backendKey,
    required String videoPath,
    required int videoSize,
  }) {
    if (!kDebugMode) return;

    final safeHeaders = Map<String, String>.from(request.headers);
    if (safeHeaders.containsKey(HttpHeaders.authorizationHeader)) {
      safeHeaders[HttpHeaders.authorizationHeader] = '<redacted>';
    }
    if (safeHeaders.containsKey('x-api-key')) {
      safeHeaders['x-api-key'] = '<redacted>';
    }

    debugPrint('Workout upload request: ${request.method} ${request.url}');
    debugPrint('Workout upload fields: exercise_name=$backendKey');
    debugPrint(
      'Workout upload file: field=video path=$videoPath bytes=$videoSize',
    );
    debugPrint('Workout upload headers: $safeHeaders');
  }

  String _uploadFailureMessage(http.StreamedResponse response, String body) {
    final status = response.statusCode;
    final lowerBody = body.toLowerCase();
    final isCodespacesAuth =
        status == 401 && lowerBody.contains('github.com/codespaces/auth');

    if (isCodespacesAuth) {
      return 'Upload failed (401): GitHub Codespaces blocked the request before it reached FastAPI. Make port 8000 public or use a deployed/public AI backend URL.';
    }

    return 'Upload failed ($status)${body.isEmpty ? '' : ': $body'}';
  }

  void _handleStreamLine(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || !mounted) return;

    try {
      final data = jsonDecode(trimmed) as Map<String, dynamic>;
      final status = (data['status'] ?? '').toString().toLowerCase();

      if (status == 'processing') {
        _safeSetState(() {
          _applyAiData(data);
          _aiFeedbackMsg = 'Analyzing your form in real time.';
        });
      } else if (status == 'done') {
        if (_aiLiveFeedback == 'ERROR') return;
        _safeSetState(() {
          _applyAiData(data);
          _isUploading = false;
          _analysisComplete = true;
          if (_analyzedFrames.length > 1) {
            _aiFeedbackMsg = 'Playing analyzed video with AI feedback.';
          } else {
            _aiLiveFeedback = 'DONE';
            _aiFeedbackMsg = 'Analysis complete.';
          }
        });
        _startAnalyzedVideoReplay();
        unawaited(_saveAiHistorySession(source: WorkoutHistorySource.ai));
      } else if (status == 'error') {
        _failUpload(
          (data['message'] ?? data['error'] ?? 'AI analysis failed').toString(),
        );
      }
    } catch (error) {
      debugPrint('Workout stream parse error: $error');
    }
  }

  void _applyAiData(Map<String, dynamic> data) {
    _aiReps = _readCount(data['reps'], _aiReps);
    _aiErrors = _readCount(data['errors'] ?? data['improper_reps'], _aiErrors);

    final feedback = data['feedback'];
    if (feedback != null && feedback.toString().trim().isNotEmpty) {
      _aiLiveFeedback = feedback.toString().toUpperCase();
    }

    final frameB64 = data['frame']?.toString();
    if (frameB64 != null && frameB64.isNotEmpty) {
      try {
        _analyzedFrame = base64Decode(_stripDataUri(frameB64));
        _storeAnalyzedFrame(_analyzedFrame!);
      } catch (_) {
        // Keep the previous valid frame.
      }
    }

    final mistakes =
        data['mistakes'] ?? data['error_messages'] ?? data['messages'];
    _lastMistakes = _parseMistakes(mistakes);
  }

  void _storeAnalyzedFrame(Uint8List bytes) {
    _analyzedFrames.add(
      _AnalyzedVideoFrame(
        bytes: bytes,
        reps: _aiReps,
        errors: _aiErrors,
        feedback: _aiLiveFeedback,
      ),
    );

    if (_analyzedFrames.length > _kMaxAnalysisReplayFrames) {
      _analyzedFrames.removeAt(0);
    }
  }

  void _startAnalyzedVideoReplay() {
    _analysisReplayTimer?.cancel();
    if (!mounted || _analyzedFrames.length <= 1) return;

    _analysisReplayIndex = 0;
    _safeSetState(() {
      _isReplayingAnalysis = true;
      _aiFeedbackMsg = 'Playing analyzed video with AI feedback.';
    });

    _analysisReplayTimer = Timer.periodic(_kAnalysisReplayFrameDelay, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_analysisReplayIndex >= _analyzedFrames.length) {
        final lastFrame = _analyzedFrames.last;
        timer.cancel();
        _safeSetState(() {
          _isReplayingAnalysis = false;
          _analyzedFrame = lastFrame.bytes;
          _aiReps = lastFrame.reps;
          _aiErrors = lastFrame.errors;
          _aiLiveFeedback = 'DONE';
          _aiFeedbackMsg = 'Analysis complete. Tap replay to watch again.';
        });
        return;
      }

      final frame = _analyzedFrames[_analysisReplayIndex++];
      _safeSetState(() {
        _analyzedFrame = frame.bytes;
        _aiReps = frame.reps;
        _aiErrors = frame.errors;
        _aiLiveFeedback = frame.feedback;
      });
    });
  }

  List<String> _parseMistakes(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item.toString())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    if (value is String && value.trim().isNotEmpty) return [value.trim()];
    if (_aiErrors > 0) return [_aiLiveFeedback];
    return const [];
  }

  Future<void> _saveAiHistorySession({
    required WorkoutHistorySource source,
  }) async {
    if (_historySaved || (_aiReps <= 0 && _aiErrors <= 0)) return;
    _historySaved = true;
    final started = _analysisStartedAt ?? DateTime.now();
    final duration = DateTime.now().difference(started).inSeconds;
    final total = _aiReps;
    final wrong = _aiErrors.clamp(0, total).toInt();
    final correct = (total - wrong).clamp(0, total).toInt();
    final entry = WorkoutHistoryEntry(
      id: 'ai-${widget.exercise.key}-${DateTime.now().microsecondsSinceEpoch}',
      exerciseId: mapExerciseName(widget.exercise.name),
      exerciseName: widget.exercise.name,
      sessionAt: DateTime.now(),
      totalReps: total,
      correctReps: correct,
      wrongReps: wrong,
      mistakes: _lastMistakes,
      caloriesBurned: estimateCalories(
        type: WorkoutHistoryType.aiTracked,
        durationSeconds: duration,
        totalReps: total,
      ),
      durationSeconds: duration,
      type: WorkoutHistoryType.aiTracked,
      source: source,
    );
    await ProgressRepository().saveSession(entry);
  }

  String _stripDataUri(String value) {
    final comma = value.indexOf(',');
    return comma == -1 ? value : value.substring(comma + 1);
  }

  int _readCount(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is List) return value.length;
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  void _failUpload(String message) {
    _safeSetState(() {
      _isUploading = false;
      _isReplayingAnalysis = false;
      _analysisReplayTimer?.cancel();
      _analysisComplete = false;
      _aiLiveFeedback = 'ERROR';
      _aiFeedbackMsg = message;
    });
    _showError(message);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  void _resetAnalysis() {
    _safeSetState(() {
      _selectedVideo = null;
      _selectedVideoBytes = null;
      _analyzedFrame = null;
      _analyzedFrames.clear();
      _analysisReplayIndex = 0;
      _isReplayingAnalysis = false;
      _analysisReplayTimer?.cancel();
      _aiReps = 0;
      _aiErrors = 0;
      _aiLiveFeedback = 'WAITING';
      _aiFeedbackMsg = 'Upload a video to see AI analysis';
      _analysisComplete = false;
      _analysisStartedAt = null;
      _historySaved = false;
      _lastMistakes = const [];
    });
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  Color _feedbackColor(String feedback) {
    final text = feedback.toLowerCase();
    if (text.contains('correct') ||
        text.contains('good') ||
        text.contains('perfect') ||
        text.contains('done')) {
      return Colors.greenAccent;
    }
    if (text.contains('error') ||
        text.contains('wrong') ||
        text.contains('bad') ||
        text.contains('failed') ||
        text.contains('dont') ||
        text.contains('caving') ||
        text.contains('pinned') ||
        text.contains('sag')) {
      return Colors.redAccent;
    }
    if (text.contains('move') ||
        text.contains('moving') ||
        text.contains('up') ||
        text.contains('down') ||
        text.contains('processing') ||
        text.contains('range') ||
        text.contains('going')) {
      return Colors.blueAccent;
    }
    return Colors.orangeAccent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBar(),
                  _buildDescriptionSection(),
                  _buildTipsSection(),
                  _buildSetTracker(),
                  _buildAIAnalysisSection(),
                  if (_activePanel == _ActivePanel.upload) _buildUploadPanel(),
                  _buildDashboard(),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          DifficultyBadge(difficulty: widget.exercise.difficulty),
          const Icon(Icons.bookmark_border, color: Colors.white70),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.exercise.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            widget.exercise.instructions.isEmpty
                ? 'Follow the planned sets and let the AI backend analyze your movement.'
                : widget.exercise.instructions,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          if (widget.exercise.type.isNotEmpty ||
              widget.exercise.defaultWeight.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (widget.exercise.type.isNotEmpty)
                  _infoPill(widget.exercise.type.toUpperCase()),
                if (widget.exercise.defaultWeight.isNotEmpty)
                  _infoPill(widget.exercise.defaultWeight),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white60, fontSize: 11),
      ),
    );
  }

  Widget _buildTipsSection() {
    if (widget.exercise.tips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: GestureDetector(
        onTap: () => setState(() => _tipsExpanded = !_tipsExpanded),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    color: AppColors.success,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Tips',
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _tipsExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.success,
                  ),
                ],
              ),
              if (_tipsExpanded) ...[
                const SizedBox(height: 10),
                ...widget.exercise.tips.map(
                  (tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '- ',
                          style: TextStyle(color: Colors.white70),
                        ),
                        Expanded(
                          child: Text(
                            tip,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSetTracker() {
    final setCount = widget.exercise.sets <= 0 ? 1 : widget.exercise.sets;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Set Tracker',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(setCount, (index) {
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    right: index == setCount - 1 ? 0 : 10,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: index == 0
                        ? AppColors.primary.withValues(alpha: 0.2)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: index == 0 ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Set ${index + 1}',
                        style: TextStyle(
                          color: index == 0
                              ? AppColors.primary
                              : Colors.white60,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        widget.exercise.reps,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildAIAnalysisSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI Analysis',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'Choose how to get feedback',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: GradientButton(
                  label: _activePanel == _ActivePanel.upload
                      ? 'Hide Upload'
                      : 'Upload Video',
                  icon: _activePanel == _ActivePanel.upload
                      ? Icons.expand_less
                      : Icons.upload,
                  outlined: true,
                  outlineColor: AppColors.secondary,
                  onTap: () => setState(() {
                    _activePanel = _activePanel == _ActivePanel.upload
                        ? _ActivePanel.none
                        : _ActivePanel.upload;
                  }),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GradientButton(
                  label: 'Live Session',
                  icon: Icons.videocam,
                  outlined: true,
                  outlineColor: AppColors.success,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          LiveWorkoutPage(exerciseName: widget.exercise.name),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUploadPanel() {
    final fileName = _selectedVideo == null
        ? null
        : _videoFileName(_selectedVideo!);
    final fileSize = _selectedVideoBytes;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          GestureDetector(
            onTap: _isUploading ? null : _pickVideo,
            child: Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _selectedVideo != null
                      ? AppColors.success
                      : AppColors.secondary.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _selectedVideo == null
                        ? Icons.cloud_upload_outlined
                        : Icons.check_circle,
                    color: _selectedVideo != null
                        ? AppColors.success
                        : AppColors.secondary,
                    size: 40,
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Text(
                      fileName ?? 'Tap to select video',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _selectedVideo != null
                            ? AppColors.success
                            : Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (fileSize != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _readableBytes(fileSize),
                      style: TextStyle(
                        color: fileSize >= _kLargeUploadWarningBytes
                            ? AppColors.warning
                            : Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_selectedVideo != null) ...[
            const SizedBox(height: 15),
            GradientButton(
              label: _uploadButtonLabel(),
              icon: _isUploading ? Icons.hourglass_top : Icons.psychology,
              onTap: _isUploading ? null : _uploadAndAnalyzeVideo,
            ),
          ],
          if (!_isUploading && (_selectedVideo != null || _analysisComplete))
            TextButton.icon(
              onPressed: _resetAnalysis,
              icon: const Icon(Icons.refresh, color: Colors.white54, size: 16),
              label: const Text(
                'Reset',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI Trainer Dashboard',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _aiFeedbackMsg,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 15),
          _buildFramePreview(),
          if (_analyzedFrames.length > 1 &&
              !_isUploading &&
              _analysisComplete) ...[
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _isReplayingAnalysis
                    ? null
                    : _startAnalyzedVideoReplay,
                icon: Icon(
                  _isReplayingAnalysis
                      ? Icons.play_circle_filled
                      : Icons.replay_rounded,
                  size: 18,
                ),
                label: Text(
                  _isReplayingAnalysis ? 'Playing analysis' : 'Replay analysis',
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.secondary,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _counterCell('REPS', '$_aiReps', Colors.greenAccent),
                    Container(height: 50, width: 1, color: Colors.white24),
                    _counterCell('ERRORS', '$_aiErrors', Colors.redAccent),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(color: Colors.white24),
                ),
                const Text(
                  'LIVE FEEDBACK',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _aiLiveFeedback,
                    key: ValueKey(_aiLiveFeedback),
                    style: TextStyle(
                      color: _feedbackColor(_aiLiveFeedback),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFramePreview() {
    if (_analyzedFrame != null) {
      return Container(
        width: double.infinity,
        height: 360,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: (_isUploading || _isReplayingAnalysis)
                ? AppColors.primary
                : Colors.white24,
            width: (_isUploading || _isReplayingAnalysis) ? 2 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.memory(
            _analyzedFrame!,
            gaplessPlayback: true,
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    if (!_isUploading) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      height: 200,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
          SizedBox(height: 14),
          Text(
            'Processing frames...',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _counterCell(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 14,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            value,
            key: ValueKey(value),
            style: TextStyle(
              color: color,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  String _uploadButtonLabel() {
    return _isUploading ? 'Analyzing...' : 'Analyze My Form';
  }

  String _readableBytes(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '$bytes B';
  }
}

class _AnalyzedVideoFrame {
  final Uint8List bytes;
  final int reps;
  final int errors;
  final String feedback;

  const _AnalyzedVideoFrame({
    required this.bytes,
    required this.reps,
    required this.errors,
    required this.feedback,
  });
}
