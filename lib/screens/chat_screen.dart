import 'package:flutter/material.dart';
import '../services/gemini_service.dart';
import '../theme/app_theme.dart';
import '../repositories/chat_repository.dart';
import '../models/chat_message_model.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _chatController = TextEditingController();
  final _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  final ChatRepository _chatRepository = ChatRepository();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  /// Load chat history dari database
  Future<void> _loadChatHistory() async {
    try {
      final messages = await _chatRepository.getAllMessages();
      setState(() {
        _messages.clear();
        for (var msg in messages) {
          _messages.add(msg.toUIMap());
        }
      });
      print('[DEBUG] Loaded ${_messages.length} messages from database');
      _scrollToBottom();
    } catch (e) {
      print('[ERROR] Error loading chat history: $e');
    }
  }

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    
    // Add user message to UI
    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isLoading = true;
    });
    
    // Save user message to database
    await _chatRepository.addMessage(ChatMessage(role: 'user', text: text));
    
    _chatController.clear();
    _scrollToBottom();
    
    // Get AI response
    final response = await GeminiService.askGemini(text);
    
    // Add AI message to UI
    setState(() {
      _messages.add({'role': 'ai', 'text': response});
      _isLoading = false;
    });
    
    // Save AI message to database
    await _chatRepository.addMessage(ChatMessage(role: 'ai', text: response));
    
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Clear all chat history from database and UI
  void _clearHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat History?'),
        content: const Text('Semua pesan chat akan dihapus dan tidak bisa dipulihkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _chatRepository.clearAllMessages();
              setState(() {
                _messages.clear();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Chat history cleared'),
                  duration: Duration(seconds: 2),
                ),
              );
              print('[DEBUG] Chat history cleared');
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.smart_toy_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Asisten Lapang.in', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                Text('Powered by Gemini AI', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w400)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 22),
            tooltip: 'Clear History',
            onPressed: _clearHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.smart_toy_rounded, size: 36, color: AppColors.primary),
                        ),
                        const SizedBox(height: 16),
                        const Text('Halo! Ada yang bisa dibantu?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        const SizedBox(height: 6),
                        const Text('Tanya seputar lapangan & olahraga', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            _quickChip('Cara booking lapangan?'),
                            _quickChip('Lapangan futsal terdekat'),
                            _quickChip('Tips olahraga rutin'),
                          ],
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return _buildBubble(msg['text']!, msg['role'] == 'user');
                    },
                  ),
          ),

          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.smart_toy_rounded, size: 16, color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 6)],
                    ),
                    child: const SizedBox(
                      width: 40,
                      height: 16,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _TypingDot(delay: 0),
                          _TypingDot(delay: 200),
                          _TypingDot(delay: 400),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Input
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 12, offset: Offset(0, -4))],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _chatController,
                      decoration: const InputDecoration(
                        hintText: 'Ketik pesan...',
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                      maxLines: null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(String text, bool isUser) {
    return Padding(
      padding: EdgeInsets.only(
        left: isUser ? 60 : 16,
        right: isUser ? 16 : 60,
        bottom: 8,
      ),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.smart_toy_rounded, size: 16, color: AppColors.primary),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: isUser ? 0 : 6)],
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: isUser ? Colors.white : AppColors.textPrimary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickChip(String text) {
    return GestureDetector(
      onTap: () {
        _chatController.text = text;
        _sendMessage();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Text(text, style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _TypingDot extends StatefulWidget {
  final int delay;
  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _anim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(color: AppColors.textSecondary, shape: BoxShape.circle),
      ),
    );
  }
}
