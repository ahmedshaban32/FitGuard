import 'dart:async';

import 'package:fit_guard_app/Core/constants/app_colors.dart';
import 'package:fit_guard_app/Core/network/api_error.dart';
import 'package:fit_guard_app/features/ai_coach/models/ai_chat_message.dart';
import 'package:fit_guard_app/features/ai_coach/services/ai_coach_service.dart';
import 'package:flutter/material.dart';

class AiCoachChatScreen extends StatefulWidget {
  const AiCoachChatScreen({super.key});

  @override
  State<AiCoachChatScreen> createState() => _AiCoachChatScreenState();
}

class _AiCoachChatScreenState extends State<AiCoachChatScreen> {
  final _service = AiCoachService();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <AiChatMessage>[];
  bool _isTyping = false;

  final _suggestions = const [
    'Ask me about workouts',
    'How many calories should I eat?',
    'Best exercises for chest?',
    'Create meal suggestions',
    'Recovery tips for sore legs',
  ];

  @override
  void dispose() {
    _service.close();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send([String? text]) async {
    final message = (text ?? _controller.text).trim();
    if (message.isEmpty || _isTyping) return;

    _controller.clear();
    final userMessage = AiChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      role: AiChatRole.user,
      text: message,
      createdAt: DateTime.now(),
      status: AiChatStatus.sent,
    );
    setState(() {
      _messages.add(userMessage);
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      final reply = await _service.sendMessage(
        message: message,
        history: _messages.where((item) => item.id != userMessage.id).toList(),
      );
      if (!mounted) return;
      setState(() {
        _messages.add(
          AiChatMessage(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            role: AiChatRole.assistant,
            text: reply,
            createdAt: DateTime.now(),
          ),
        );
        _isTyping = false;
      });
    } catch (error) {
      if (!mounted) return;
      final errorMessage = error is ApiError ? error.message : error.toString();
      setState(() {
        final index = _messages.indexWhere((item) => item.id == userMessage.id);
        if (index != -1) {
          _messages[index] = _messages[index].copyWith(
            status: AiChatStatus.failed,
          );
        }
        _messages.add(
          AiChatMessage(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            role: AiChatRole.assistant,
            text: errorMessage,
            createdAt: DateTime.now(),
            status: AiChatStatus.failed,
          ),
        );
        _isTyping = false;
      });
    }
    _scrollToBottom();
  }

  void _retry(AiChatMessage message) {
    setState(() {
      _messages.removeWhere(
        (item) => item.status == AiChatStatus.failed && !item.isUser,
      );
    });
    _send(message.text);
  }

  void _scrollToBottom() {
    Timer(const Duration(milliseconds: 80), () {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        titleSpacing: 0,
        title: const Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.psychology_alt, color: Colors.white),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Coach', style: TextStyle(fontSize: 18)),
                Text(
                  'Fitness, nutrition, recovery',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildWelcome()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isTyping && index == _messages.length) {
                        return const _TypingBubble();
                      }
                      final message = _messages[index];
                      return _MessageBubble(
                        message: message,
                        onRetry:
                            message.isUser &&
                                message.status == AiChatStatus.failed
                            ? () => _retry(message)
                            : null,
                      );
                    },
                  ),
          ),
          _buildComposer(),
        ],
      ),
    );
  }

  Widget _buildWelcome() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.auto_awesome, color: Colors.white, size: 34),
              SizedBox(height: 14),
              Text(
                'Your FitGuard AI Coach',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Ask about workouts, macros, meal ideas, soreness, motivation, or how to adjust today’s training.',
                style: TextStyle(color: Colors.white, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _suggestions
              .map(
                (item) => ActionChip(
                  backgroundColor: AppColors.cardBackground,
                  side: const BorderSide(color: AppColors.border),
                  label: Text(
                    item,
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  onPressed: () => _send(item),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildComposer() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 4,
                style: const TextStyle(color: AppColors.textPrimary),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: 'Ask your coach...',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            DecoratedBox(
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white),
                onPressed: _isTyping ? null : () => _send(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final AiChatMessage message;
  final VoidCallback? onRetry;

  const _MessageBubble({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final bg = isUser ? AppColors.primary : AppColors.cardBackground;
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;

    return Align(
      alignment: alignment,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          border: isUser ? null : Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _time(message.createdAt),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.58),
                    fontSize: 10,
                  ),
                ),
                if (onRetry != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onRetry,
                    child: const Text(
                      'Retry',
                      style: TextStyle(
                        color: AppColors.warning,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _time(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, __) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                final phase = (_controller.value + index * 0.2) % 1;
                return Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(
                      alpha: 0.35 + (phase < 0.5 ? phase : 1 - phase),
                    ),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}
