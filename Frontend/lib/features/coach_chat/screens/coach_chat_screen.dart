import 'dart:async';

import 'package:fit_guard_app/Core/constants/app_colors.dart';
import 'package:fit_guard_app/Core/network/api_error.dart';
import 'package:fit_guard_app/features/coach_chat/models/coach_chat_models.dart';
import 'package:fit_guard_app/features/coach_chat/services/coach_chat_service.dart';
import 'package:flutter/material.dart';

class CoachChatScreen extends StatefulWidget {
  final CoachConversation conversation;

  const CoachChatScreen({super.key, required this.conversation});

  @override
  State<CoachChatScreen> createState() => _CoachChatScreenState();
}

class _CoachChatScreenState extends State<CoachChatScreen> {
  final _service = CoachChatService();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  List<CoachMessage> _messages = [];
  Timer? _poller;
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _poller = Timer.periodic(
      const Duration(seconds: 8),
      (_) => _loadMessages(silent: true),
    );
  }

  @override
  void dispose() {
    _poller?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final messages = await _service.getMessages(widget.conversation.id);
      if (!mounted) return;
      setState(() {
        _messages = messages;
        _loading = false;
        _error = null;
      });
      _scrollToBottom();
    } catch (error) {
      if (!mounted) return;
      if (!silent) {
        setState(() {
          _loading = false;
          _error = error is ApiError ? error.message : error.toString();
        });
      }
    }
  }

  Future<void> _send() async {
    final body = _controller.text.trim();
    if (body.isEmpty || _sending) return;
    _controller.clear();
    setState(() => _sending = true);

    try {
      final sent = await _service.sendMessage(
        conversationId: widget.conversation.id,
        body: body,
      );
      if (!mounted) return;
      setState(() {
        _messages = [..._messages, sent];
        _sending = false;
      });
      _scrollToBottom();
    } catch (error) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error is ApiError ? error.message : error.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _scrollToBottom() {
    Timer(const Duration(milliseconds: 80), () {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final coach = widget.conversation.coach;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary,
              backgroundImage: coach.imageUrl == null
                  ? null
                  : NetworkImage(coach.imageUrl!),
              child: coach.imageUrl == null
                  ? Text(
                      coach.name.isEmpty ? 'C' : coach.name[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(coach.name, overflow: TextOverflow.ellipsis),
                  const Text(
                    'Coach conversation',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildBody()),
          _buildComposer(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.forum_outlined,
                color: AppColors.primary,
                size: 44,
              ),
              const SizedBox(height: 12),
              const Text(
                'Chat unavailable',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadMessages,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_messages.isEmpty) {
      return Center(
        child: Text(
          'Send the first message.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadMessages,
      color: AppColors.primary,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          return _MessageBubble(message: _messages[index]);
        },
      ),
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
                style: const TextStyle(color: AppColors.textPrimary),
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Message your coach...',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filled(
              onPressed: _sending ? null : _send,
              style: IconButton.styleFrom(backgroundColor: AppColors.primary),
              icon: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final CoachMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isMine ? AppColors.primary : AppColors.cardBackground,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMine ? 18 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 18),
          ),
          border: isMine ? null : Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.body,
              style: const TextStyle(color: AppColors.textPrimary, height: 1.4),
            ),
            const SizedBox(height: 6),
            Text(
              _time(message.createdAt),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _time(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
