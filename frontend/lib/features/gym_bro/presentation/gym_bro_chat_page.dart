import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:gym_app/core/theme/app_theme.dart';
import 'package:gym_app/features/gym_bro/domain/gym_bro_match.dart';
import 'package:gym_app/services/api_client.dart';

/// GB-4: chat thread for a single Gym Bro match.
class GymBroChatPage extends StatefulWidget {
  const GymBroChatPage({super.key, required this.matchId, this.title});

  final String matchId;
  final String? title;

  @override
  State<GymBroChatPage> createState() => _GymBroChatPageState();
}

class _GymBroChatPageState extends State<GymBroChatPage> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  List<GymBroChatMessage> _messages = const [];
  String? _myUserId;
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await ApiClient.I.fetchProfile();
      final rows = await ApiClient.I.fetchGymBroMessages(widget.matchId);
      if (!mounted) return;
      setState(() {
        _myUserId = (profile['user'] as Map?)?['id']?.toString();
        _messages = rows.map(GymBroChatMessage.fromJson).toList();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.statusCode == 403
              ? 'You are not authorized to view this conversation.'
              : 'Unable to load conversation: $error';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _scrollToEnd() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  Future<void> _send() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final sent = await ApiClient.I.sendGymBroMessage(
        matchId: widget.matchId,
        text: text,
      );
      if (!mounted) return;
      setState(() {
        _messages = [..._messages, GymBroChatMessage.fromJson(sent)];
        _textController.clear();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not send message: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'Chat'),
        leading: IconButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/gym-bro/matches'),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildBody()),
            if (_error == null) _buildComposer(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 48, color: AppTheme.error),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: const Text('Try again')),
            ],
          ),
        ),
      );
    }
    if (_messages.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No messages yet. Say hi!',
            style: TextStyle(color: AppTheme.mut),
          ),
        ),
      );
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isMine = message.senderId == _myUserId;
        return Align(
          alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              color: isMine ? AppTheme.primary : AppTheme.surfaceContainer,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              message.text,
              style: TextStyle(
                color: isMine ? AppTheme.onPrimary : AppTheme.ink,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildComposer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: const InputDecoration(hintText: 'Message'),
              onSubmitted: (_) => _send(),
              textInputAction: TextInputAction.send,
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: _sending ? null : _send,
            icon: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}
