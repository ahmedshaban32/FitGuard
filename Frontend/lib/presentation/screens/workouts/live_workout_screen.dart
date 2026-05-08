import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:fit_guard_app/Core/constants/app_colors.dart';
import 'package:fit_guard_app/features/progress/models/workout_history_entry.dart';
import 'package:fit_guard_app/features/progress/services/progress_repository.dart';
import 'package:fit_guard_app/presentation/screens/workouts/models/workout_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

const _kBaseUrl =
    'https://silver-space-enigma-5grvq594jr5xh46w7-8000.app.github.dev';
const _kWsUrl =
    'wss://silver-space-enigma-5grvq594jr5xh46w7-8000.app.github.dev/ws/live-workout';
const _kLiveFrameInterval = Duration(milliseconds: 550);
const _kLiveFrameMaxWidth = 360;
const _kLiveFrameJpegQuality = 55;

class LiveWorkoutPage extends StatefulWidget {
  final String exerciseName;

  const LiveWorkoutPage({super.key, required this.exerciseName});

  @override
  State<LiveWorkoutPage> createState() => _LiveWorkoutPageState();
}

class _LiveWorkoutPageState extends State<LiveWorkoutPage>
    with WidgetsBindingObserver {
  CameraController? _camera;
  bool _cameraReady = false;
  bool _isFrontCamera = true;
  String? _cameraError;

  WebSocket? _ws;
  StreamSubscription<dynamic>? _wsSub;
  bool _wsConnected = false;
  bool _useHttpFallback = false;

  final http.Client _httpClient = http.Client();
  Timer? _frameTimer;
  bool _sessionActive = false;
  bool _sendingFrame = false;

  int _reps = 0;
  int _errors = 0;
  String _feedback = 'Get into position';
  Uint8List? _processedFrame;
  DateTime? _sessionStartedAt;
  bool _historySaved = false;

  String get _backendKey => mapExerciseName(widget.exerciseName);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _stopSession();
    } else if (state == AppLifecycleState.resumed && !_cameraReady) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopSession(disposeCamera: true);
    _httpClient.close();
    super.dispose();
  }

  Future<void> _initCamera() async {
    _safeSetState(() {
      _cameraReady = false;
      _cameraError = null;
    });

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _safeSetState(() => _cameraError = 'No camera found on this device.');
        return;
      }

      final desiredLens = _isFrontCamera
          ? CameraLensDirection.front
          : CameraLensDirection.back;
      final description = cameras.firstWhere(
        (camera) => camera.lensDirection == desiredLens,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        description,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize().timeout(const Duration(seconds: 12));

      if (!mounted) {
        await controller.dispose();
        return;
      }

      _safeSetState(() {
        _camera = controller;
        _cameraReady = true;
      });
    } catch (error) {
      _safeSetState(() => _cameraError = 'Camera error: $error');
    }
  }

  Future<void> _flipCamera() async {
    if (_sessionActive) return;
    _safeSetState(() => _cameraReady = false);
    await _camera?.dispose();
    _camera = null;
    _isFrontCamera = !_isFrontCamera;
    await _initCamera();
  }

  Future<void> _startSession() async {
    if (_sessionActive || !_cameraReady || _camera == null) return;
    if (!_camera!.value.isInitialized) return;

    _safeSetState(() {
      _sessionActive = true;
      _reps = 0;
      _errors = 0;
      _feedback = 'Connecting to AI';
      _processedFrame = null;
      _useHttpFallback = false;
      _wsConnected = false;
      _sessionStartedAt = DateTime.now();
      _historySaved = false;
    });

    await _connectWebSocket();
    _startFrameLoop();
  }

  void _stopSession({bool disposeCamera = false}) {
    if (_sessionActive) {
      unawaited(_saveLiveHistorySession());
    }
    _frameTimer?.cancel();
    _frameTimer = null;
    _wsSub?.cancel();
    _wsSub = null;

    try {
      _ws?.close(WebSocketStatus.goingAway);
    } catch (_) {}
    _ws = null;

    if (disposeCamera) {
      _camera?.dispose();
      _camera = null;
      _cameraReady = false;
    }

    if (mounted) {
      setState(() {
        _sessionActive = false;
        _wsConnected = false;
        _sendingFrame = false;
        if (!disposeCamera) _feedback = 'Session ended';
      });
    }
  }

  Future<void> _saveLiveHistorySession() async {
    if (_historySaved || (_reps <= 0 && _errors <= 0)) return;
    _historySaved = true;
    final started = _sessionStartedAt ?? DateTime.now();
    final duration = DateTime.now().difference(started).inSeconds;
    final total = _reps;
    final wrong = _errors.clamp(0, total).toInt();
    final correct = (total - wrong).clamp(0, total).toInt();
    final entry = WorkoutHistoryEntry(
      id: 'live-$_backendKey-${DateTime.now().microsecondsSinceEpoch}',
      exerciseId: _backendKey,
      exerciseName: widget.exerciseName,
      sessionAt: DateTime.now(),
      totalReps: total,
      correctReps: correct,
      wrongReps: wrong,
      mistakes: wrong > 0 ? [_feedback] : const [],
      caloriesBurned: estimateCalories(
        type: WorkoutHistoryType.aiTracked,
        durationSeconds: duration,
        totalReps: total,
      ),
      durationSeconds: duration,
      type: WorkoutHistoryType.aiTracked,
      source: WorkoutHistorySource.ai,
    );
    await ProgressRepository().saveSession(entry);
  }

  Future<void> _connectWebSocket() async {
    try {
      final socket = await WebSocket.connect(
        _kWsUrl,
      ).timeout(const Duration(seconds: 8));
      _ws = socket;
      _wsSub = socket.listen(
        _onWsMessage,
        onError: (_) => _enableHttpFallback('WebSocket failed. Using HTTP.'),
        onDone: () => _enableHttpFallback('WebSocket closed. Using HTTP.'),
        cancelOnError: false,
      );

      _safeSetState(() {
        _wsConnected = true;
        _useHttpFallback = false;
        _feedback = 'AI connected';
      });
    } catch (_) {
      _enableHttpFallback('Using HTTP mode');
    }
  }

  void _enableHttpFallback(String message) {
    if (!mounted || !_sessionActive) return;
    _safeSetState(() {
      _wsConnected = false;
      _useHttpFallback = true;
      _feedback = message;
    });
  }

  void _onWsMessage(dynamic message) {
    try {
      final data = jsonDecode(message.toString()) as Map<String, dynamic>;
      _applyAiData(data);
    } catch (error) {
      debugPrint('Live workout WS parse error: $error');
    }
  }

  void _startFrameLoop() {
    _frameTimer?.cancel();
    _frameTimer = Timer.periodic(
      _kLiveFrameInterval,
      (_) => _captureAndSendFrame(),
    );
  }

  Future<void> _captureAndSendFrame() async {
    if (_sendingFrame || !_sessionActive) return;
    final camera = _camera;
    if (camera == null ||
        !camera.value.isInitialized ||
        camera.value.isTakingPicture) {
      return;
    }

    _sendingFrame = true;
    try {
      final image = await camera.takePicture().timeout(
        const Duration(seconds: 3),
      );
      final bytes = await image.readAsBytes();
      final optimizedBytes = await compute(_optimizeLiveFrameBytes, bytes);
      final base64Image = base64Encode(optimizedBytes);

      final payload = jsonEncode({
        'image': base64Image,
        'exercise_name': _backendKey,
      });

      if (_wsConnected && _ws != null) {
        _ws!.add(payload);
      } else {
        _useHttpFallback = true;
        await _sendHttpFrame(base64Image);
      }
    } on TimeoutException {
      _safeSetState(() => _feedback = 'Camera timeout. Retrying.');
    } catch (error) {
      debugPrint('Live workout frame error: $error');
    } finally {
      _sendingFrame = false;
    }
  }

  Future<void> _sendHttpFrame(String base64Image) async {
    try {
      final response = await _httpClient
          .post(
            Uri.parse('$_kBaseUrl/process-frame'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'image': base64Image,
              'exercise_name': _backendKey,
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _applyAiData(data);
      } else {
        _safeSetState(
          () => _feedback = 'AI server error ${response.statusCode}',
        );
      }
    } on SocketException {
      _safeSetState(() => _feedback = 'No connection. Retrying.');
    } on TimeoutException {
      _safeSetState(() => _feedback = 'AI timeout. Retrying.');
    } catch (error) {
      debugPrint('Live workout HTTP error: $error');
    }
  }

  void _applyAiData(Map<String, dynamic> data) {
    if (!mounted) return;
    Uint8List? frame;
    final frameB64 = data['frame']?.toString();
    if (frameB64 != null && frameB64.isNotEmpty) {
      try {
        frame = base64Decode(_stripDataUri(frameB64));
      } catch (_) {}
    }

    _safeSetState(() {
      _reps = _readCount(data['reps'], _reps);
      _errors = _readCount(data['errors'] ?? data['improper_reps'], _errors);
      final feedback = data['feedback'];
      if (feedback != null && feedback.toString().trim().isNotEmpty) {
        _feedback = feedback.toString().toUpperCase();
      }
      if (frame != null) _processedFrame = frame;
    });
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

  Color _colorForFeedback(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('correct') ||
        lower.contains('good') ||
        lower.contains('perfect')) {
      return Colors.greenAccent;
    }
    if (lower.contains('error') ||
        lower.contains('wrong') ||
        lower.contains('bad') ||
        lower.contains('failed') ||
        lower.contains('dont') ||
        lower.contains('caving') ||
        lower.contains('pinned') ||
        lower.contains('sag')) {
      return Colors.redAccent;
    }
    if (lower.contains('move') ||
        lower.contains('moving') ||
        lower.contains('up') ||
        lower.contains('down') ||
        lower.contains('range') ||
        lower.contains('going')) {
      return Colors.blueAccent;
    }
    return Colors.orangeAccent;
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _cameraError != null
            ? _buildError()
            : !_cameraReady
            ? _buildLoading()
            : _buildMain(),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 14),
          Text('Starting camera...', style: TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off, color: Colors.redAccent, size: 48),
            const SizedBox(height: 14),
            Text(
              _cameraError ?? 'Camera unavailable',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _initCamera,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMain() {
    return Stack(
      children: [
        Positioned.fill(child: _buildCameraView()),
        _buildTopBar(),
        _buildStatusBadge(),
        Positioned(
          bottom: 20,
          left: 16,
          right: 16,
          child: Column(
            children: [
              _buildCounters(),
              const SizedBox(height: 12),
              _buildFeedbackBanner(),
              const SizedBox(height: 16),
              _buildControlButton(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCameraView() {
    if (_processedFrame != null && _sessionActive) {
      return Image.memory(
        _processedFrame!,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
    }
    final camera = _camera;
    if (camera == null || !camera.value.isInitialized) {
      return const ColoredBox(color: Colors.black);
    }
    return CameraPreview(camera);
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black.withValues(alpha: 0.75), Colors.transparent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Row(
          children: [
            _circleButton(
              Icons.arrow_back_ios_new,
              onTap: () {
                _stopSession();
                Navigator.pop(context);
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.exerciseName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _circleButton(
              Icons.flip_camera_ios_rounded,
              disabled: _sessionActive,
              onTap: _flipCamera,
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleButton(
    IconData icon, {
    VoidCallback? onTap,
    bool disabled = false,
  }) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: const BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: disabled ? Colors.white24 : Colors.white,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    final String label;
    final Color dot;
    if (!_sessionActive) {
      label = 'READY';
      dot = Colors.white24;
    } else if (_wsConnected) {
      label = 'AI LIVE WS';
      dot = Colors.greenAccent;
    } else if (_useHttpFallback) {
      label = 'AI LIVE HTTP';
      dot = Colors.orangeAccent;
    } else {
      label = 'CONNECTING';
      dot = Colors.orangeAccent;
    }

    return Positioned(
      top: 60,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _counterCell('REPS', '$_reps', Colors.greenAccent),
          Container(height: 40, width: 1, color: Colors.white24),
          _counterCell('ERRORS', '$_errors', Colors.redAccent),
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
            fontSize: 12,
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
              fontSize: 40,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackBanner() {
    final color = _colorForFeedback(_feedback);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Text(
          _feedback,
          key: ValueKey(_feedback),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton() {
    return GestureDetector(
      onTap: _sessionActive ? _stopSession : _startSession,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: _sessionActive ? Colors.redAccent : AppColors.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (_sessionActive ? Colors.redAccent : AppColors.primary)
                  .withValues(alpha: 0.45),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _sessionActive ? Icons.stop_rounded : Icons.fiber_manual_record,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              _sessionActive ? 'Stop Session' : 'Start Session',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Uint8List _optimizeLiveFrameBytes(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return bytes;

  final resized = decoded.width > _kLiveFrameMaxWidth
      ? img.copyResize(decoded, width: _kLiveFrameMaxWidth)
      : decoded;

  return Uint8List.fromList(
    img.encodeJpg(resized, quality: _kLiveFrameJpegQuality),
  );
}
