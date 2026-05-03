import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fit_guard_app/Core/constants/app_colors.dart';
import 'package:fit_guard_app/presentation/screens/workouts/models/workout_models.dart';
import 'package:fit_guard_app/presentation/screens/workouts/widgets/workout_widgets.dart';
import 'live_workout_screen.dart';

enum _ActivePanel { none, upload }

class ExerciseDetailScreen extends StatefulWidget {
  final Exercise exercise;
  const ExerciseDetailScreen({super.key, required this.exercise});

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen>
    with TickerProviderStateMixin {
  _ActivePanel _activePanel = _ActivePanel.none;
  bool _tipsExpanded = false;
  final ImagePicker _picker = ImagePicker();
  File? _selectedVideo;
  bool _isUploading = false;

  // متغيرات الـ AI للـ Dashboard
  String _aiReps = "0";
  String _aiErrors = "0";
  String _aiLiveFeedback = "WAITING...";
  String _aiFeedbackMsg = "Upload a video to see real-time AI analysis";
  Uint8List? _analyzedFrame;

  // دالة الرفع واستقبال البث المباشر للتحليل (Real-Time Stream)
  Future<void> _uploadAndAnalyzeVideo() async {
    if (_selectedVideo == null) return;
    setState(() {
      _isUploading = true;
      _aiFeedbackMsg = "Initializing AI Engine... ⏳";
      _analyzedFrame = null;
      _aiReps = "0";
      _aiErrors = "0";
      _aiLiveFeedback = "STARTING...";
    });

    try {
      // ⚠️ تأكدي دايماً إن الـ IP ده هو بتاع اللابتوب بتاعك
      var uri = Uri.parse('http://192.168.1.6:8000/upload-video-stream');
      var request = http.MultipartRequest('POST', uri);
      request.files.add(
        await http.MultipartFile.fromPath('video', _selectedVideo!.path),
      );

      var response = await request.send();

      response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            (String line) {
              if (!mounted) return;
              final data = jsonDecode(line);

              if (data['status'] == 'processing') {
                setState(() {
                  _analyzedFrame = base64Decode(data['frame']);
                  _aiReps = data['reps'].toString();
                  _aiErrors = data['errors'].toString();
                  _aiLiveFeedback = data['feedback'].toString();
                  _aiFeedbackMsg = "Analyzing your form in real-time... 🔥";
                });
              } else if (data['status'] == 'done') {
                setState(() {
                  _isUploading = false;
                  _aiFeedbackMsg = "Analysis Complete! ✅";
                });
              }
            },
            onError: (e) {
              if (mounted) {
                setState(() {
                  _isUploading = false;
                  _aiFeedbackMsg = "❌ Error reading stream.";
                });
              }
            },
            onDone: () {
              if (mounted) {
                setState(() => _isUploading = false);
              }
            },
          );
    } catch (e) {
      setState(() {
        _isUploading = false;
        _aiFeedbackMsg = "❌ Connection failed. Check server.";
      });
    }
  }

  // الدالة الذكية لتحديد لون الفيدباك بناءً على الكلمة اللي جاية من الـ AI
  Color _getFeedbackColor(String feedback) {
    final text = feedback.toLowerCase();
    if (text.contains("good") || text.contains("perfect"))
      return Colors.greenAccent;
    if (text.contains("too") || text.contains("bad") || text.contains("error"))
      return Colors.redAccent;
    if (text.contains("down") || text.contains("up") || text.contains("moving"))
      return Colors.blueAccent;
    return Colors.orangeAccent; // اللون الافتراضي لأي كلمة تانية
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
                  _buildTopBar(context),
                  _buildDescriptionSection(),
                  _buildTipsSection(),
                  _buildSetTracker(),
                  _buildAIAnalysisSection(),
                  if (_activePanel == _ActivePanel.upload) _buildUploadPanel(),
                  _buildFeedbackSection(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
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
            widget.exercise.description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.list, color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.exercise.instructions,
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: GestureDetector(
        onTap: () => setState(() => _tipsExpanded = !_tipsExpanded),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.success.withOpacity(0.3)),
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
                    "Pro Tips",
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
              if (_tipsExpanded)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Column(
                    children: widget.exercise.tips
                        .map(
                          (tip) => Text(
                            "• $tip",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSetTracker() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Set Tracker",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(
              3,
              (index) => Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index == 2 ? 0 : 10),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: index == 0
                        ? AppColors.primary.withOpacity(0.2)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: index == 0 ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Set ${index + 1}",
                        style: TextStyle(
                          color: index == 0
                              ? AppColors.primary
                              : Colors.white60,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        "12-15",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
            "AI Analysis",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            "Choose how to get feedback",
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 15),
          GradientButton(
            label: "Watch Exercise Video",
            icon: Icons.play_circle_outline,
            onTap: () {},
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GradientButton(
                  label: "Upload Video",
                  icon: Icons.upload,
                  outlined: true,
                  outlineColor: AppColors.secondary,
                  onTap: () {
                    setState(
                      () => _activePanel = _activePanel == _ActivePanel.upload
                          ? _ActivePanel.none
                          : _ActivePanel.upload,
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GradientButton(
                  label: "Live Session",
                  icon: Icons.videocam,
                  outlined: true,
                  outlineColor: AppColors.success,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LiveWorkoutPage(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUploadPanel() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          GestureDetector(
            onTap: () async {
              final XFile? video = await _picker.pickVideo(
                source: ImageSource.gallery,
              );
              if (video != null) {
                setState(() => _selectedVideo = File(video.path));
              }
            },
            child: Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.secondary.withOpacity(0.5),
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
                    color: AppColors.secondary,
                    size: 40,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _selectedVideo == null
                        ? "Tap to Select Video"
                        : "Video Selected",
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
          if (_selectedVideo != null)
            Padding(
              padding: const EdgeInsets.only(top: 15),
              child: GradientButton(
                label: _isUploading ? "Analyzing..." : "Analyze My Form",
                icon: Icons.psychology,
                onTap: () {
                  if (!_isUploading) _uploadAndAnalyzeVideo();
                },
              ),
            ),
        ],
      ),
    );
  }

  // الداشبورد كـ "مراية" ذكية للـ AI
  Widget _buildFeedbackSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "AI Trainer Dashboard",
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

          // شاشة عرض الفيديو اللحظي
          if (_analyzedFrame != null)
            Container(
              width: double.infinity,
              height: 400,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.memory(
                  _analyzedFrame!,
                  gaplessPlayback: true,
                  fit: BoxFit.contain,
                ),
              ),
            ),

          // لوحة التحكم (العدادات والفيدباك)
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
                // صف العدادات
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        const Text(
                          "REPS",
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 14,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          _aiReps,
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 45,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(height: 50, width: 1, color: Colors.white24),
                    Column(
                      children: [
                        const Text(
                          "ERRORS",
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 14,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          _aiErrors,
                          style: const TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 45,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Divider(color: Colors.white24),
                ),

                // الفيدباك اللحظي (مراية للذكاء الاصطناعي)
                const Text(
                  "FEEDBACK",
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _aiLiveFeedback,
                  style: TextStyle(
                    color: _getFeedbackColor(
                      _aiLiveFeedback,
                    ), // تحديد اللون بناءً على الكلمة
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
