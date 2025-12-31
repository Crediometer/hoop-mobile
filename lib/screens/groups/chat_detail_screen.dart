import 'package:flutter/material.dart';
import 'package:hoop/main.dart';
import 'package:hoop/screens/groups/group_detail_screen.dart';
import 'package:hoop/states/group_state.dart';
import 'package:provider/provider.dart';

class ChatDetailScreen extends StatefulWidget {
  final Map<String, dynamic> group;

  const ChatDetailScreen({super.key, required this.group});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showSend = false;
  final List<Map<String, dynamic>> _messages = [
    {
      "type": "system",
      "text": "Please welcome Elizabeth Ekundayo to the group!",
      "emoji": "👋",
      "timestamp": DateTime.now().subtract(const Duration(hours: 2)),
    },
  ];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_updateSendVisibility);
    _messageController.addListener(_updateSendVisibility);
  }

  void _updateSendVisibility() {
    setState(() {
      _showSend =
          _focusNode.hasFocus || _messageController.text.trim().isNotEmpty;
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _messages.add({
        "type": "own",
        "text": _messageController.text,
        "isOwn": true,
        "timestamp": DateTime.now(),
      });
    });

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : Colors.black;
    final textSecondary = isDark ? Colors.grey[400] : Colors.grey[600];
    final groupProvider = context.watch<GroupCommunityProvider>();
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F111A) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F111A) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: GestureDetector(
          onTap: () {
            Navigator.pushNamed(
              context,
              "/group/detail",
              arguments: {"groupId": widget.group['id'].toString()},
            );
          },
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: widget.group["color"],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    widget.group["initials"],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.group["name"],
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "No one online • Active",
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.videocam_outlined, color: textPrimary, size: 24),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // DIVIDER
          Container(
            height: 1,
            color: isDark ? Colors.white10 : Colors.grey[200],
          ),

          // MESSAGES AREA
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                // Load More Messages button
                Center(
                  child: Text(
                    "Load More Messages",
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Date separator
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "04/12/2025",
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Messages
                ..._messages.map((message) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildMessageWidget(
                      message,
                      isDark,
                      textPrimary,
                      textSecondary,
                    ),
                  );
                }).toList(),
              ],
            ),
          ),

          // DIVIDER
          Container(
            height: 1,
            color: isDark ? Colors.white10 : Colors.grey[200],
          ),

          // MESSAGE INPUT AREA
          Container(
            color: isDark ? const Color(0xFF0F111A) : Colors.white,
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 390,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A1D27) : Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _focusNode.hasFocus
                            ? const Color(0xFF6366F1) // Active border color
                            : (isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.grey[300]!),
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 0,
                    ),
                    child: Row(
                      children: [
                        // Text input
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            focusNode: _focusNode,
                            style: TextStyle(color: textPrimary, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: "Type a message",
                              hintStyle: TextStyle(
                                color: textSecondary,
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        // Microphone icon
                        GestureDetector(
                          onTap: () {},
                          child: Icon(
                            Icons.mic_none,
                            color: textSecondary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Attachment icon
                        GestureDetector(
                          onTap: () {},
                          child: Icon(
                            Icons.attach_file,
                            color: textSecondary,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_showSend) ...[
                  const SizedBox(width: 10),
                  // Send button - Dark blue/purple circular
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2D1B69),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 22,
                      ),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageWidget(
    Map<String, dynamic> message,
    bool isDark,
    Color textPrimary,
    Color? textSecondary,
  ) {
    if (message["type"] == "system") {
      return _buildSystemMessage(message, isDark, textSecondary);
    }
    return _buildMessageBubble(message, isDark, textPrimary);
  }

  Widget _buildSystemMessage(
    Map<String, dynamic> message,
    bool isDark,
    Color? textSecondary,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.grey[200]?.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message["emoji"] ?? "🎉", style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message["text"],
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    Map<String, dynamic> message,
    bool isDark,
    Color textPrimary,
  ) {
    final isOwn = message["isOwn"] ?? false;

    return Align(
      alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isOwn
              ? const Color(0xFF6366F1)
              : (isDark ? const Color(0xFF1A1D27) : Colors.grey[200]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message["text"],
          style: TextStyle(
            color: isOwn ? Colors.white : textPrimary,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
