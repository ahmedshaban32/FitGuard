import 'package:fit_guard_app/Core/constants/app_colors.dart';
import 'package:fit_guard_app/Core/network/api_error.dart';
import 'package:fit_guard_app/Core/utils/pref_helpers.dart';
import 'package:fit_guard_app/features/coach_chat/models/coach_chat_models.dart';
import 'package:fit_guard_app/features/coach_chat/screens/coach_chat_screen.dart';
import 'package:fit_guard_app/features/coach_chat/services/coach_chat_service.dart';
import 'package:flutter/material.dart';

class CoachesScreen extends StatefulWidget {
  const CoachesScreen({super.key});

  @override
  State<CoachesScreen> createState() => _CoachesScreenState();
}

class _CoachesScreenState extends State<CoachesScreen> {
  final _service = CoachChatService();
  late Future<void> _future;
  List<CoachProfile> _coaches = [];
  SubscriptionStatus _subscription = const SubscriptionStatus(isActive: false);
  String _role = 'user';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<void> _load() async {
    final role = await PrefHelper.getUserRole();
    final results = await Future.wait([
      _service.getPublicCoaches(),
      _service.getSubscription(),
    ]);
    _coaches = results[0] as List<CoachProfile>;
    _subscription = results[1] as SubscriptionStatus;
    _role = role;
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _openChat(CoachProfile coach) async {
    if (_role == 'user' &&
        (!_subscription.isActive || _subscription.coachId != coach.id)) {
      _showSubscribeSheet(coach);
      return;
    }

    try {
      final conversation = await _service.startConversation(coach.id);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CoachChatScreen(conversation: conversation),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _showError(error);
    }
  }

  Future<void> _subscribe(CoachProfile coach) async {
    final navigator = Navigator.of(context);
    try {
      await _service.subscribeToCoach(coach.id);
      navigator.pop();
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Subscribed to ${coach.name}. You can message now.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _showError(error);
    }
  }

  void _showSubscribeSheet(CoachProfile coach) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Subscribe to chat',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Messaging is available for users subscribed to this coach.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _subscribe(coach),
                icon: const Icon(Icons.workspace_premium),
                label: Text('Subscribe to ${coach.name}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(Object error) {
    final message = error is ApiError ? error.message : error.toString();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Real Coaches'),
        actions: [
          IconButton(
            icon: const Icon(Icons.forum_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ConversationsScreen()),
            ),
          ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (snapshot.hasError) {
            return _StateMessage(
              icon: Icons.cloud_off_outlined,
              title: 'Could not load coaches',
              message: snapshot.error.toString(),
              actionLabel: 'Retry',
              onAction: _refresh,
            );
          }
          if (_coaches.isEmpty) {
            return _StateMessage(
              icon: Icons.person_search,
              title: 'No coaches yet',
              message: 'Approved public coaches will appear here.',
              actionLabel: 'Refresh',
              onAction: _refresh,
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            color: AppColors.primary,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _coaches.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final coach = _coaches[index];
                final isSubscribed =
                    _subscription.isActive && _subscription.coachId == coach.id;
                return _CoachCard(
                  coach: coach,
                  isSubscribed: isSubscribed,
                  role: _role,
                  onChat: () => _openChat(coach),
                  onSubscribe: () => _subscribe(coach),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final _service = CoachChatService();
  late Future<List<CoachConversation>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getConversations();
  }

  void _reload() {
    setState(() => _future = _service.getConversations());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Coach Messages'),
      ),
      body: FutureBuilder<List<CoachConversation>>(
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
              title: 'Messages unavailable',
              message:
                  'The coach chat API is not reachable yet. Pull to retry after backend chat endpoints are enabled.',
              actionLabel: 'Retry',
              onAction: _reload,
            );
          }
          final conversations = snapshot.data ?? const [];
          if (conversations.isEmpty) {
            return _StateMessage(
              icon: Icons.forum_outlined,
              title: 'No conversations',
              message: 'Start a chat from a coach profile.',
              actionLabel: 'Browse coaches',
              onAction: () => Navigator.pop(context),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: conversations.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              return ListTile(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CoachChatScreen(conversation: conversation),
                  ),
                ),
                tileColor: AppColors.cardBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.border),
                ),
                leading: _CoachAvatar(coach: conversation.coach),
                title: Text(
                  conversation.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  conversation.lastMessage?.body ?? 'Open conversation',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                trailing: conversation.unreadCount > 0
                    ? CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.error,
                        child: Text(
                          '${conversation.unreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.chevron_right,
                        color: AppColors.textSecondary,
                      ),
              );
            },
          );
        },
      ),
    );
  }
}

class _CoachCard extends StatelessWidget {
  final CoachProfile coach;
  final bool isSubscribed;
  final String role;
  final VoidCallback onChat;
  final VoidCallback onSubscribe;

  const _CoachCard({
    required this.coach,
    required this.isSubscribed,
    required this.role,
    required this.onChat,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSubscribed ? AppColors.success : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _CoachAvatar(coach: coach, radius: 30),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coach.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: AppColors.warning,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          coach.rating.toStringAsFixed(1),
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                        if (isSubscribed) ...[
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.verified,
                            color: AppColors.success,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Subscribed',
                            style: TextStyle(
                              color: AppColors.success,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            coach.bio,
            style: TextStyle(color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: coach.specialties
                .map(
                  (item) => Chip(
                    label: Text(item),
                    labelStyle: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                    ),
                    backgroundColor: AppColors.background,
                    side: const BorderSide(color: AppColors.border),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (role == 'user' && !isSubscribed)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onSubscribe,
                    icon: const Icon(Icons.workspace_premium),
                    label: const Text('Subscribe'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.secondary,
                      side: const BorderSide(color: AppColors.secondary),
                    ),
                  ),
                ),
              if (role == 'user' && !isSubscribed) const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onChat,
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: Text(role == 'coach' ? 'Reply' : 'Chat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSubscribed || role != 'user'
                        ? AppColors.primary
                        : AppColors.border,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CoachAvatar extends StatelessWidget {
  final CoachProfile coach;
  final double radius;

  const _CoachAvatar({required this.coach, this.radius = 24});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary,
      backgroundImage: coach.imageUrl == null
          ? null
          : NetworkImage(coach.imageUrl!),
      child: coach.imageUrl == null
          ? Text(
              coach.name.isEmpty ? 'C' : coach.name[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }
}

class _StateMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _StateMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary, size: 48),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
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
              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
