import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hoop/constants/themes.dart';
import 'package:hoop/dtos/podos/chats/messages.dart';
import 'package:hoop/states/auth_state.dart';
import 'package:hoop/states/ws/chat_sockets.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:smart_overlay_menu/smart_overlay_menu.dart';

class ChatDetailScreen extends StatefulWidget {
  final Map<String, dynamic> group;

  const ChatDetailScreen({super.key, required this.group});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final _random = Random();
  bool _showSend = false;
  Message? _replyingTo;
  Message? _editingMessage;
  bool _isRecording = false;
  List<File> _attachedFiles = [];
  SmartOverlayMenuController smartOverlayMenuController =
      SmartOverlayMenuController();
  final ScrollController _scrollController = ScrollController();
  final _reactionKeys = <String, GlobalKey>{};

  // Typing state
  Timer? _typingDebounceTimer;
  bool _isTypingActive = false;

  String? userId;
  late ChatWebSocketHandler _chatHandler;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_updateSendVisibility);
    _messageController.addListener(_updateSendVisibility);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  void _initializeChat() {
    final authProvider = context.read<AuthProvider>();
    userId = authProvider.user?.id.toString();
    _chatHandler = context.read<ChatWebSocketHandler>();

    // Join the group chat
    if (widget.group['id'] != null) {
      final groupId = num.tryParse(widget.group['id'].toString());
      if (groupId != null) {
        _chatHandler.joinGroup(groupId);
        // Load messages for this group
        _chatHandler.getMessages();
      }
    }

    setState(() {});
  }

  void _updateSendVisibility() {
    if (_showSend !=
        (_focusNode.hasFocus || _messageController.text.trim().isNotEmpty)) {
      setState(() {
        _showSend =
            _focusNode.hasFocus || _messageController.text.trim().isNotEmpty;
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _reactionKeys.clear();

    // Clean up typing state
    _typingDebounceTimer?.cancel();
    if (_isTypingActive) {
      _sendTypingStop();
    }

    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty && _attachedFiles.isEmpty) {
      return;
    }

    if (_editingMessage != null) {
      _editMessage();
    } else if (_replyingTo != null) {
      _sendReplyMessage();
    } else {
      _sendNewMessage();
    }

    _messageController.clear();
    setState(() => _attachedFiles.clear());
  }

  void _sendNewMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty && _attachedFiles.isEmpty) return;

    final groupId = widget.group['id'];
    if (groupId == null) return;

    final tempId =
        'temp-${DateTime.now().millisecondsSinceEpoch}-${_random.nextInt(1 << 32).toRadixString(36)}';

    debugPrint('📤 Sending message to group $groupId: $content');

    _chatHandler.sendTextMessage(
      int.parse(groupId.toString()),
      content,
      tempId,
    );

    // Stop typing when message is sent
    if (_isTypingActive) {
      _sendTypingStop();
    }

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        0,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _sendReplyMessage() {
    if (_replyingTo == null) return;

    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final groupId = widget.group['id'];
    if (groupId == null) return;

    final tempId =
        'temp-${DateTime.now().millisecondsSinceEpoch}-${_random.nextInt(1 << 32).toRadixString(36)}';

    _chatHandler.sendMessage(
      SendMessageParams(
        groupId: int.parse(groupId.toString()),
        message: content,
        messageType: 'TEXT',
        tempId: tempId,
        replyTo: {
          'messageId': _replyingTo!.id,
          'content': _replyingTo!.content,
          'sender': _replyingTo!.sender,
          'senderName': _replyingTo!.senderName,
        },
      ),
    );

    setState(() => _replyingTo = null);

    // Stop typing when message is sent
    if (_isTypingActive) {
      _sendTypingStop();
    }
  }

  void _editMessage() {
    if (_editingMessage == null) return;

    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final groupId = widget.group['id'];
    if (groupId == null) return;

    _chatHandler.editMessage(
      _editingMessage!.id,
      num.parse(groupId.toString()),
      content,
    );

    setState(() => _editingMessage = null);

    // Stop typing when message is sent
    if (_isTypingActive) {
      _sendTypingStop();
    }
  }

  // Typing event handlers
  void _handleTyping() {
    // Debounce typing events
    _typingDebounceTimer?.cancel();
    _typingDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (!_isTypingActive && _messageController.text.isNotEmpty) {
        _sendTypingStart();
      }
      _typingDebounceTimer = null;
    });
  }

  void _handleStopTyping() {
    if (_isTypingActive) {
      _sendTypingStop();
    }
  }

  void _sendTypingStart() {
    final groupId = widget.group['id'];
    if (groupId == null) return;

    _chatHandler.startTyping(groupId.toString());
    _isTypingActive = true;
  }

  void _sendTypingStop() {
    final groupId = widget.group['id'];
    if (groupId == null) return;

    _chatHandler.stopTyping(groupId.toString());
    _isTypingActive = false;
  }

  void _onReply(Message message) {
    setState(() {
      _replyingTo = message;
      _focusNode.requestFocus();
    });
  }

  void _onCopy(Message message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
  }

  void _onEdit(Message message) {
    setState(() {
      _editingMessage = message;
      _messageController.text = message.content;
      _focusNode.requestFocus();
    });
  }

  void _onDeleteForMe(Message message) {
    final groupId = widget.group['id'];
    if (groupId == null) return;

    _chatHandler.deleteMessage(message.id, num.parse(groupId.toString()));

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Message deleted')));
  }

  void _onMessageInfo(Message message) {
    // Implementation for message info
  }

  void _onSaveDownload(Message message) {
    if (message.attachments != null && message.attachments!.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Downloading attachment...')),
      );
    }
  }

  void _onReact(Message message, String emoji) {
    final groupId = widget.group['id'];
    if (groupId == null) return;

    debugPrint('Reacted with $emoji to message: ${message.id}');
    _chatHandler.addReaction(message.id, emoji, groupId.toString());
  }

  void _cancelReply() => setState(() => _replyingTo = null);
  void _cancelEdit() {
    setState(() {
      _editingMessage = null;
      _messageController.clear();
    });
  }

  Future<void> _pickFile() async {
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Photo & Video'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? file = await picker.pickImage(
                  source: ImageSource.gallery,
                );
                if (file != null) {
                  setState(() => _attachedFiles.add(File(file.path)));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: const Text('Document'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Document picker coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? file = await picker.pickImage(
                  source: ImageSource.camera,
                );
                if (file != null) {
                  setState(() => _attachedFiles.add(File(file.path)));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _removeFile(File file) => setState(() => _attachedFiles.remove(file));
  void _startRecording() => setState(() => _isRecording = true);
  void _stopRecording() {
    setState(() => _isRecording = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Voice message sent')));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : Colors.black;
    final textSecondary = isDark ? Colors.grey[400] : Colors.grey[600];

    return Consumer<ChatWebSocketHandler>(
      builder: (context, handler, child) {
        final onlineCount = handler.getOnlineCountForGroup(widget.group['id']);
        final messages = _getMessagesForGroup(handler.messages.value);
        final typingUsers = handler.getTypingUsers(widget.group['id'] ?? 0);

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
              onTap: () => Navigator.pushNamed(
                context,
                "/group/detail",
                arguments: {"groupId": widget.group['id'].toString()},
              ),
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
                          typingUsers.isNotEmpty
                              ? '${typingUsers.first.userName} is typing'
                              : onlineCount > 0
                              ? "$onlineCount online • Active"
                              : "No one online • Active",
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
                icon: Icon(Iconsax.call, color: textPrimary, size: 24),
                onPressed: () async {
                  final callData = await handler.startWebRTCCall(
                    context,
                    type: 'video',
                    groupId: int.parse(widget.group['id'].toString()),
                    groupName: widget.group["name"],
                  );
                },
              ),
              IconButton(
                icon: Icon(Iconsax.video, color: textPrimary, size: 24),
                onPressed: () async {
                  final callData = await handler.startWebRTCCall(
                    context,
                    type: 'video',
                    groupId: int.parse(widget.group['id'].toString()),
                    groupName: widget.group["name"],
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: GestureDetector(
            onTap: () {
              if (_replyingTo != null) _cancelReply();
              if (_editingMessage != null) _cancelEdit();
              FocusScope.of(context).unfocus();
            },
            child: Column(
              children: [
                if (typingUsers.isNotEmpty)
                  // Typing indicator
                  _buildTypingIndicator(typingUsers),
                if (_replyingTo != null || _editingMessage != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: isDark ? const Color(0xFF1A1D27) : Colors.grey[100],
                    child: Row(
                      children: [
                        Icon(
                          _editingMessage != null ? Icons.edit : Icons.reply,
                          color: HoopTheme.primaryBlue,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _editingMessage != null
                                    ? 'Editing'
                                    : 'Replying to',
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _editingMessage?.content ??
                                    _replyingTo?.content ??
                                    '',
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: textSecondary,
                            size: 20,
                          ),
                          onPressed: () => _editingMessage != null
                              ? _cancelEdit()
                              : _cancelReply(),
                        ),
                      ],
                    ),
                  ),
                Container(
                  height: 1,
                  color: isDark ? Colors.white10 : Colors.grey[200],
                ),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    reverse: true,
                    itemCount: messages.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return const Column(
                          children: [
                            Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  "Today",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      final message = messages[messages.length - index];

                      if (message.messageType?.toLowerCase() == 'system') {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.grey[200]?.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              message.content,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }

                      final messageKey = _reactionKeys.putIfAbsent(
                        message.id.toString(),
                        () => GlobalKey(),
                      );
                      return Padding(
                        key: messageKey,
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SmartOverlayMenu(
                          topWidgetAlignment: message.isFromUser(userId ?? '')
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          bottomWidgetAlignment:
                              message.isFromUser(userId ?? '')
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          repositionAnimationDuration: Duration(
                            microseconds: 1,
                          ),
                          repositionAnimationCurve: Curves.easeInOut,
                          controller: smartOverlayMenuController,
                          topWidget: _buildReactionOverlay(message),
                          openWithTap: true,
                          bottomWidget: _buildMessageMenu(message),
                          child: _MessageBubble(
                            message: message,
                            userId: userId ?? '',
                            isDark: isDark,
                            textPrimary: textPrimary,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_attachedFiles.isNotEmpty)
                  Container(
                    height: 100,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: isDark ? const Color(0xFF1A1D27) : Colors.grey[50],
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _attachedFiles.length,
                      itemBuilder: (context, index) {
                        final file = _attachedFiles[index];
                        return Stack(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: isDark
                                    ? Colors.white10
                                    : Colors.grey[200],
                              ),
                              child: const Icon(
                                Icons.insert_drive_file,
                                size: 40,
                                color: Colors.grey,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removeFile(file),
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                Container(
                  height: 1,
                  color: isDark ? Colors.white10 : Colors.grey[200],
                ),
                Container(
                  color: isDark ? const Color(0xFF0F111A) : Colors.white,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Iconsax.add_circle,
                          color: textSecondary,
                          size: 28,
                        ),
                        onPressed: _pickFile,
                      ),
                      const SizedBox(width: 4),
                      if (!_isRecording)
                        IconButton(
                          icon: Icon(
                            Iconsax.microphone,
                            color: textSecondary,
                            size: 28,
                          ),
                          onPressed: _startRecording,
                        ),
                      if (_isRecording)
                        IconButton(
                          icon: Icon(
                            Iconsax.stop_circle,
                            color: Colors.red,
                            size: 28,
                          ),
                          onPressed: _stopRecording,
                        ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1A1D27)
                                : Colors.grey[50],
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: _focusNode.hasFocus
                                  ? HoopTheme.primaryBlue
                                  : (isDark
                                        ? Colors.white.withOpacity(0.05)
                                        : Colors.grey[300]!),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 16),
                                  child: TextField(
                                    controller: _messageController,
                                    focusNode: _focusNode,
                                    style: TextStyle(
                                      color: textPrimary,
                                      fontSize: 16,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: _editingMessage != null
                                          ? "Edit message..."
                                          : "Type a message",
                                      hintStyle: TextStyle(
                                        color: textSecondary,
                                        fontSize: 16,
                                      ),
                                      border: InputBorder.none,
                                    ),
                                    onSubmitted: (_) => _sendMessage(),
                                    onChanged: (text) {
                                      if (text.isNotEmpty) {
                                        // Send typing start event
                                        _handleTyping();
                                      } else {
                                        // Send typing stop event
                                        _handleStopTyping();
                                      }
                                    },
                                  ),
                                ),
                              ),
                              if (_showSend || _attachedFiles.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.all(4),
                                  child: InkWell(
                                    onTap: _sendMessage,
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF2D1B69),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Iconsax.send_1,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Typing indicator widget
  Widget _buildTypingIndicator(List<TypingUser> typingUsers) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : Colors.black;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1D27) : Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Typing dots
              _TypingDots(
                color: isDark ? Colors.grey[400]! : Colors.grey[600]!,
              ),
              const SizedBox(width: 8),
              // Typing text with user count bubble
              _buildTypingTextWithBubble(typingUsers, isDark, textPrimary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypingTextWithBubble(
    List<TypingUser> typingUsers,
    bool isDark,
    Color textPrimary,
  ) {
    if (typingUsers.isEmpty) return const SizedBox.shrink();

    if (typingUsers.length <= 2) {
      // Show names directly for 1-2 users
      return Text(
        _getTypingText(typingUsers),
        style: TextStyle(
          color: isDark ? Colors.grey[300] : Colors.grey[700],
          fontSize: 14,
        ),
      );
    } else {
      // For 3+ users, show "2 more" bubble
      return Row(
        children: [
          // First two names
          Text(
            '${typingUsers[0].userName}, ${typingUsers[1].userName} ',
            style: TextStyle(
              color: isDark ? Colors.grey[300] : Colors.grey[700],
              fontSize: 14,
            ),
          ),
          // "and X more" bubble
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: HoopTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: HoopTheme.primaryBlue.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              'and ${typingUsers.length - 2} more',
              style: TextStyle(
                color: HoopTheme.primaryBlue,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // "are typing" text
          Text(
            ' are typing...',
            style: TextStyle(
              color: isDark ? Colors.grey[300] : Colors.grey[700],
              fontSize: 14,
            ),
          ),
        ],
      );
    }
  }

  String _getTypingText(List<TypingUser> typingUsers) {
    if (typingUsers.isEmpty) return '';

    final names = typingUsers.map((user) => user.userName).toList();

    if (names.length == 1) {
      return '${names[0]} is typing...';
    } else if (names.length == 2) {
      return '${names[0]} and ${names[1]} are typing...';
    } else {
      // This is handled by _buildTypingTextWithBubble
      return 'Multiple people are typing...';
    }
  }

  Widget _buildReactionOverlay(Message message) {
    const quickReactions = ['👍', '❤️', '😮', '😂', '😢', '🙏', '⨁'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2A2D3A)
            : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: quickReactions
            .map(
              (emoji) => GestureDetector(
                onTap: () {
                  // Handle reaction
                  _onReact(message, emoji);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(emoji, style: const TextStyle(fontSize: 24)),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildMessageMenu(Message message) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1D27)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      width: 200,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMenuTile(
            icon: CupertinoIcons.reply,
            label: 'Reply',
            onTap: () => _onReply(message),
          ),
          _buildMenuTile(
            icon: CupertinoIcons.doc_on_doc,
            label: 'Copy',
            onTap: () => _onCopy(message),
          ),
          if (message.isFromUser(userId ?? ''))
            _buildMenuTile(
              icon: CupertinoIcons.pencil,
              label: 'Edit',
              onTap: () => _onEdit(message),
            ),
          _buildMenuTile(
            icon: CupertinoIcons.heart,
            label: 'React',
            onTap: () {
              // Show emoji picker
            },
          ),
          if (message.attachments != null && message.attachments!.isNotEmpty)
            _buildMenuTile(
              icon: CupertinoIcons.arrow_down_circle,
              label: 'Save/Download',
              onTap: () => _onSaveDownload(message),
            ),
          if (message.isFromUser(userId ?? '')) ...[
            _buildMenuTile(
              icon: CupertinoIcons.info_circle,
              label: 'Message Info',
              onTap: () => _onMessageInfo(message),
            ),
            _buildMenuTile(
              icon: CupertinoIcons.delete,
              label: 'Delete for me',
              isDestructive: true,
              onTap: () => _onDeleteForMe(message),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isDestructive
                    ? Colors.red
                    : (isDark ? Colors.grey[300] : Colors.grey[700]),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: isDestructive
                      ? Colors.red
                      : (isDark ? Colors.grey[300] : Colors.grey[700]),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Message> _getMessagesForGroup(List<MessageGroup> messages) {
    try {
      return messages
          .firstWhere(
            (msg) => msg.groupId.toString() == widget.group['id'].toString(),
          )
          .messages
          .toList();
    } catch (e) {
      return [];
    }
  }
}

// Typing dots animation widget
class _TypingDots extends StatefulWidget {
  final Color color;

  const _TypingDots({required this.color});

  @override
  _TypingDotsState createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _dotAnimations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();

    _dotAnimations = [
      Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.0, 0.2, curve: Curves.easeInOut),
        ),
      ),
      Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.2, 0.4, curve: Curves.easeInOut),
        ),
      ),
      Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.4, 0.6, curve: Curves.easeInOut),
        ),
      ),
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Opacity(
                opacity: _dotAnimations[index].value,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

// Message bubble widget
class _MessageBubble extends StatelessWidget {
  final Message message;
  final String userId;
  final bool isDark;
  final Color textPrimary;

  const _MessageBubble({
    required this.message,
    required this.userId,
    required this.isDark,
    required this.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final isOwn = message.isFromUser(userId);
    final hasAttachments =
        message.attachments != null && message.attachments!.isNotEmpty;

    return Align(
      alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        margin: EdgeInsets.only(
          bottom: 8,
          left: isOwn ? MediaQuery.of(context).size.width * 0.2 : 0,
          right: isOwn ? 0 : MediaQuery.of(context).size.width * 0.2,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isOwn
              ? HoopTheme.primaryBlue
              : (isDark ? const Color(0xFF1A1D27) : Colors.grey[200]),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isOwn
                ? const Radius.circular(20)
                : const Radius.circular(4),
            bottomRight: isOwn
                ? const Radius.circular(4)
                : const Radius.circular(20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasAttachments)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(
                      _getAttachmentIcon(message.messageType ?? 'text'),
                      size: 16,
                      color: isOwn
                          ? Colors.white70
                          : textPrimary.withOpacity(0.7),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${message.attachments?.length} attachment${message.attachments!.length > 1 ? 's' : ''}',
                      style: TextStyle(
                        color: isOwn
                            ? Colors.white70
                            : textPrimary.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              message.content,
              style: TextStyle(
                color: isOwn ? Colors.white : textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.edited == true)
                  Text(
                    'edited • ',
                    style: TextStyle(
                      color: isOwn
                          ? Colors.white70
                          : textPrimary.withOpacity(0.5),
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                if (message.createdAt != null)
                  Text(
                    _formatTime(message.createdAt!),
                    style: TextStyle(
                      color: isOwn
                          ? Colors.white70
                          : textPrimary.withOpacity(0.5),
                      fontSize: 11,
                    ),
                  ),
                if (isOwn && message.status != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      _getStatusIcon(message.status!),
                      size: 11,
                      color: _getStatusColor(message.status!, isOwn),
                    ),
                  ),
              ],
            ),
            if (message.reactions != null && message.reactions!.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 6),
                child: Wrap(
                  spacing: 4,
                  runSpacing: 2,
                  children: message.reactions!.map((reaction) {
                    if (reaction is Map) {
                      final emoji = reaction['emoji']?.toString() ?? '👍';
                      final count = reaction['count']?.toString() ?? '1';
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.15)
                              : Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$emoji $count',
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    }
                    return const SizedBox();
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Helper functions
IconData _getAttachmentIcon(String type) {
  switch (type.toLowerCase()) {
    case 'image':
      return Icons.image;
    case 'video':
      return Icons.videocam;
    case 'audio':
      return Icons.audiotrack;
    case 'file':
      return Icons.insert_drive_file;
    default:
      return Icons.attachment;
  }
}

String _formatTime(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = DateTime(now.year, now.month, now.day - 1);
  final messageDate = DateTime(date.year, date.month, date.day);

  if (messageDate == today) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  } else if (messageDate == yesterday) {
    return 'Yesterday ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  } else {
    return '${date.day}/${date.month} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

IconData _getStatusIcon(String status) {
  switch (status.toLowerCase()) {
    case 'sent':
      return Icons.check;
    case 'delivered':
      return Icons.done_all;
    case 'read':
      return Icons.done_all;
    case 'edited':
      return Icons.edit;
    case 'deleted':
      return Icons.delete;
    default:
      return Icons.access_time;
  }
}

Color _getStatusColor(String status, bool isOwn) {
  if (!isOwn) return Colors.transparent;

  switch (status.toLowerCase()) {
    case 'read':
      return Colors.blue;
    case 'delivered':
      return Colors.grey;
    case 'sent':
      return Colors.grey.withOpacity(0.5);
    case 'edited':
      return Colors.orange;
    case 'deleted':
      return Colors.red;
    default:
      return Colors.grey;
  }
}

class _FullEmojiBottomSheet extends StatefulWidget {
  final Message message;
  final Function(String) onReact;

  const _FullEmojiBottomSheet({required this.message, required this.onReact});

  @override
  State<_FullEmojiBottomSheet> createState() => _FullEmojiBottomSheetState();
}

class _FullEmojiBottomSheetState extends State<_FullEmojiBottomSheet> {
  String _searchQuery = '';
  final _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  // Emoji categories with their emojis
  final Map<String, List<String>> emojiCategories = {
    'Frequently Used': [
      '👍',
      '❤️',
      '😮',
      '😂',
      '😢',
      '🙏',
      '🔥',
      '👏',
      '🎉',
      '😊',
    ],
    'Smileys & People': [
      '😀',
      '😃',
      '😄',
      '😁',
      '😆',
      '😅',
      '😂',
      '🤣',
      '😊',
      '😇',
      '🙂',
      '🙃',
      '😉',
      '😌',
      '😍',
      '🥰',
      '😘',
      '😗',
      '😙',
      '😚',
      '😋',
      '😛',
      '😝',
      '😜',
      '🤪',
      '🤨',
      '🧐',
      '🤓',
      '😎',
      '🤩',
      '🥳',
      '😏',
      '😒',
      '😞',
      '😔',
      '😟',
      '😕',
      '🙁',
      '☹️',
      '😣',
      '😖',
      '😫',
      '😩',
      '🥺',
      '😢',
      '😭',
      '😤',
      '😠',
      '😡',
      '🤬',
      '🤯',
      '😳',
      '🥵',
      '🥶',
      '😱',
      '😨',
      '😰',
      '😥',
      '😓',
    ],
    'Gestures': [
      '👋',
      '🤚',
      '🖐️',
      '✋',
      '🖖',
      '👌',
      '🤌',
      '🤏',
      '✌️',
      '🤞',
      '🤟',
      '🤘',
      '🤙',
      '👈',
      '👉',
      '👆',
      '👇',
      '☝️',
      '👍',
      '👎',
      '✊',
      '👊',
      '🤛',
      '🤜',
      '👏',
      '🙌',
      '👐',
      '🤲',
      '🤝',
      '🙏',
    ],
    'Hearts': [
      '❤️',
      '🧡',
      '💛',
      '💚',
      '💙',
      '💜',
      '🖤',
      '🤍',
      '🤎',
      '💔',
      '❣️',
      '💕',
      '💞',
      '💓',
      '💗',
      '💖',
      '💘',
      '💝',
      '💟',
    ],
    'Nature': [
      '🐶',
      '🐱',
      '🐭',
      '🐹',
      '🐰',
      '🦊',
      '🐻',
      '🐼',
      '🐨',
      '🐯',
      '🦁',
      '🐮',
      '🐷',
      '🐸',
      '🐵',
      '🙈',
      '🙉',
      '🙊',
      '🐒',
      '🐔',
      '🐧',
      '🐦',
      '🐤',
      '🐣',
      '🐥',
      '🦆',
      '🦅',
      '🦉',
      '🦇',
      '🐺',
      '🐗',
      '🐴',
      '🦄',
      '🐝',
      '🐛',
      '🦋',
      '🐌',
      '🐞',
      '🐜',
      '🦟',
      '🦗',
      '🕷️',
      '🕸️',
      '🐢',
      '🐍',
      '🦎',
      '🦖',
      '🦕',
      '🐙',
      '🦑',
      '🦐',
      '🦞',
      '🦀',
      '🐡',
      '🐠',
      '🐟',
      '🐬',
      '🐳',
      '🐋',
      '🦈',
      '🐊',
      '🐅',
      '🐆',
      '🦓',
      '🦍',
      '🦧',
      '🐘',
      '🦛',
      '🦏',
      '🐪',
      '🐫',
      '🦒',
      '🦘',
      '🦬',
      '🐃',
      '🐂',
      '🐄',
      '🐎',
      '🐖',
      '🐏',
      '🐑',
      '🦙',
      '🐐',
      '🦌',
      '🐕',
      '🐩',
      '🦮',
      '🐕‍🦺',
      '🐈',
      '🐈‍⬛',
      '🪶',
      '🐓',
      '🦃',
      '🦤',
      '🦚',
      '🦜',
      '🦢',
      '🦩',
      '🕊️',
      '🐇',
      '🦝',
      '🦨',
      '🦡',
      '🦫',
      '🦦',
      '🦥',
      '🐁',
      '🐀',
      '🐿️',
      '🦔',
      '🐾',
    ],
    'Objects': [
      '⌚',
      '📱',
      '📲',
      '💻',
      '⌨️',
      '🖥️',
      '🖨️',
      '🖱️',
      '🖲️',
      '🎧',
      '🎤',
      '🎥',
      '📷',
      '🎙️',
      '📺',
      '📻',
      '📟',
      '📠',
      '🔋',
      '🔌',
      '💡',
      '🔦',
      '🕯️',
      '🧯',
      '🛢️',
      '💸',
      '💵',
      '💴',
      '💶',
      '💷',
      '💰',
      '💳',
      '💎',
      '⚖️',
      '🛠️',
      '🔧',
      '🔨',
      '⚒️',
      '🛡️',
      '🔩',
      '⚙️',
      '🔗',
      '⛓️',
      '🧰',
      '🧲',
      '🔫',
      '💣',
      '🧨',
      '🪓',
      '🔪',
      '🗡️',
      '⚔️',
      '🛡️',
      '🚬',
      '⚰️',
      '⚱️',
      '🏺',
      '🔮',
      '📿',
      '💈',
      '⚗️',
      '🔭',
      '🔬',
      '🕳️',
      '🩹',
      '🩺',
      '💊',
      '💉',
      '🩸',
      '🧬',
      '🦠',
      '🧫',
      '🧪',
      '🌡️',
      '🧹',
      '🧺',
      '🧻',
      '🚽',
      '🚰',
      '🚿',
      '🛁',
      '🧼',
      '🪒',
      '🧽',
      '🧴',
      '🛎️',
      '🔑',
      '🗝️',
      '🚪',
      '🪑',
      '🛋️',
      '🛏️',
      '🛌',
      '🧸',
      '🖼️',
      '🛍️',
      '🛒',
      '🎁',
      '🎈',
      '🎏',
      '🎀',
      '🎊',
      '🎉',
      '🎎',
      '🏮',
      '🎐',
      '🧧',
      '✉️',
      '📩',
      '📨',
      '📧',
      '💌',
      '📥',
      '📤',
      '📦',
      '🏷️',
      '📪',
      '📫',
      '📬',
      '📭',
      '📮',
      '📯',
      '📜',
      '📃',
      '📄',
      '📑',
      '🧾',
      '📊',
      '📈',
      '📉',
      '🗒️',
      '🗓️',
      '📆',
      '📅',
      '🗑️',
      '📇',
      '🗃️',
      '🗳️',
      '🗄️',
      '📋',
      '📁',
      '📂',
      '🗂️',
      '🗞️',
      '📰',
      '📓',
      '📔',
      '📒',
      '📕',
      '📗',
      '📘',
      '📙',
      '📚',
      '📖',
      '🔖',
      '🧷',
      '🔗',
      '📎',
      '🖇️',
      '📏',
      '📐',
      '✂️',
      '🗃️',
      '🗄️',
      '🗑️',
    ],
    'Symbols': [
      '❤️',
      '🧡',
      '💛',
      '💚',
      '💙',
      '💜',
      '🖤',
      '🤍',
      '🤎',
      '💔',
      '❣️',
      '💕',
      '💞',
      '💓',
      '💗',
      '💖',
      '💘',
      '💝',
      '💟',
      '☮️',
      '✝️',
      '☪️',
      '🕉️',
      '☸️',
      '✡️',
      '🔯',
      '🕎',
      '☯️',
      '☦️',
      '🛐',
      '⛎',
      '♈',
      '♉',
      '♊',
      '♋',
      '♌',
      '♍',
      '♎',
      '♏',
      '♐',
      '♑',
      '♒',
      '♓',
      '🆔',
      '⚛️',
      '🉑',
      '☢️',
      '☣️',
      '📴',
      '📳',
      '🈶',
      '🈚',
      '🈸',
      '🈺',
      '🈷️',
      '✴️',
      '🆚',
      '💮',
      '🉐',
      '㊙️',
      '㊗️',
      '🈴',
      '🈵',
      '🈹',
      '🈲',
      '🅰️',
      '🅱️',
      '🆎',
      '🆑',
      '🅾️',
      '🆘',
      '❌',
      '⭕',
      '🛑',
      '⛔',
      '📛',
      '🚫',
      '💯',
      '💢',
      '♨️',
      '🚷',
      '🚯',
      '🚳',
      '🚱',
      '🔞',
      '📵',
      '🚭',
      '❗',
      '❕',
      '❓',
      '❔',
      '‼️',
      '⁉️',
      '🔅',
      '🔆',
      '〽️',
      '⚠️',
      '🚸',
      '🔱',
      '⚜️',
      '🔰',
      '♻️',
      '✅',
      '🈯',
      '💹',
      '❇️',
      '✳️',
      '❎',
      '🌐',
      '💠',
      'Ⓜ️',
      '🌀',
      '💤',
      '🏧',
      '🚾',
      '♿',
      '🅿️',
      '🈳',
      '🈂️',
      '🛂',
      '🛃',
      '🛄',
      '🛅',
      '🚹',
      '🚺',
      '🚼',
      '⚧️',
      '🚻',
      '🚮',
      '🎦',
      '📶',
      '🈁',
      '🔣',
      'ℹ️',
      '🔤',
      '🔡',
      '🔠',
      '🆖',
      '🆗',
      '🆙',
      '🆒',
      '🆕',
      '🆓',
      '0️⃣',
      '1️⃣',
      '2️⃣',
      '3️⃣',
      '4️⃣',
      '5️⃣',
      '6️⃣',
      '7️⃣',
      '8️⃣',
      '9️⃣',
      '🔟',
      '🔢',
      '#️⃣',
      '*️⃣',
      '⏏️',
      '▶️',
      '⏸️',
      '⏯️',
      '⏹️',
      '⏺️',
      '⏭️',
      '⏮️',
      '⏩',
      '⏪',
      '⏫',
      '⏬',
      '◀️',
      '🔼',
      '🔽',
      '➡️',
      '⬅️',
      '⬆️',
      '⬇️',
      '↗️',
      '↘️',
      '↙️',
      '↖️',
      '↕️',
      '↔️',
      '↪️',
      '↩️',
      '⤴️',
      '⤵️',
      '🔀',
      '🔁',
      '🔂',
      '🔄',
      '🔃',
      '🎵',
      '🎶',
      '➕',
      '➖',
      '➗',
      '✖️',
      '♾️',
      '💲',
      '💱',
      '™️',
      '©️',
      '®️',
      '〰️',
      '➰',
      '➿',
      '🔚',
      '🔙',
      '🔛',
      '🔝',
      '🔜',
    ],
  };

  List<String> get _filteredEmojis {
    if (_searchQuery.isEmpty) {
      return [];
    }

    final query = _searchQuery.toLowerCase();
    final allEmojis = emojiCategories.values.expand((list) => list).toList();

    return allEmojis.where((emoji) {
      return emoji.contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColor = isDark ? const Color(0xFF1A1D27) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final hintColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: themeColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white10 : Colors.grey.shade200,
                ),
              ),
            ),
            child: Column(
              children: [
                // Message preview
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.message, size: 20, color: hintColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.message.content.length > 50
                              ? '${widget.message.content.substring(0, 50)}...'
                              : widget.message.content,
                          style: TextStyle(color: textColor, fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Search bar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: hintColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search emojis...',
                            hintStyle: TextStyle(color: hintColor),
                            border: InputBorder.none,
                          ),
                          style: TextStyle(color: textColor),
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        IconButton(
                          icon: Icon(Icons.clear, color: hintColor, size: 20),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                              _searchController.clear();
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Emoji grid
          Expanded(
            child: _searchQuery.isEmpty
                ? _buildCategoryView(isDark, textColor, hintColor)
                : _buildSearchView(isDark, textColor),
          ),
          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white10 : Colors.grey.shade200,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: textColor)),
                ),
                Text(
                  'React to message',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(width: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryView(bool isDark, Color textColor, Color? hintColor) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: emojiCategories.length,
      itemBuilder: (context, index) {
        final category = emojiCategories.keys.toList()[index];
        final emojis = emojiCategories.values.toList()[index];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 12, top: index > 0 ? 16 : 0),
              child: Text(
                category,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: hintColor,
                ),
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: emojis.map((emoji) {
                return GestureDetector(
                  onTap: () => widget.onReact(emoji),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: isDark ? Colors.white10 : Colors.grey[100],
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 24)),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchView(bool isDark, Color textColor) {
    if (_filteredEmojis.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_emotions_outlined,
              size: 60,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No emojis found',
              style: TextStyle(fontSize: 16, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _filteredEmojis.length,
      itemBuilder: (context, index) {
        final emoji = _filteredEmojis[index];
        return GestureDetector(
          onTap: () => widget.onReact(emoji),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isDark ? Colors.white10 : Colors.grey[100],
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
          ),
        );
      },
    );
  }
}

// class _MessageBubble extends StatelessWidget {
//   final Message message;
//   final String userId;
//   final bool isDark;
//   final Color textPrimary;

//   const _MessageBubble({
//     required this.message,
//     required this.userId,
//     required this.isDark,
//     required this.textPrimary,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final isOwn = message.isFromUser(userId);
//     final hasAttachments =
//         message.attachments != null && message.attachments!.isNotEmpty;

//     return Align(
//       alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
//       child: Container(
//         constraints: BoxConstraints(
//           maxWidth: MediaQuery.of(context).size.width * 0.8,
//         ),
//         margin: EdgeInsets.only(
//           bottom: 8,
//           left: isOwn ? MediaQuery.of(context).size.width * 0.2 : 0,
//           right: isOwn ? 0 : MediaQuery.of(context).size.width * 0.2,
//         ),
//         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//         decoration: BoxDecoration(
//           color: isOwn
//               ? HoopTheme.primaryBlue
//               : (isDark ? const Color(0xFF1A1D27) : Colors.grey[200]),
//           borderRadius: BorderRadius.only(
//             topLeft: const Radius.circular(20),
//             topRight: const Radius.circular(20),
//             bottomLeft: isOwn
//                 ? const Radius.circular(20)
//                 : const Radius.circular(4),
//             bottomRight: isOwn
//                 ? const Radius.circular(4)
//                 : const Radius.circular(20),
//           ),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             if (hasAttachments)
//               Container(
//                 margin: const EdgeInsets.only(bottom: 6),
//                 child: Row(
//                   children: [
//                     Icon(
//                       _getAttachmentIcon(message.messageType ?? 'text'),
//                       size: 16,
//                       color: isOwn
//                           ? Colors.white70
//                           : textPrimary.withOpacity(0.7),
//                     ),
//                     const SizedBox(width: 6),
//                     Text(
//                       '${message.attachments?.length} attachment${message.attachments!.length > 1 ? 's' : ''}',
//                       style: TextStyle(
//                         color: isOwn
//                             ? Colors.white70
//                             : textPrimary.withOpacity(0.7),
//                         fontSize: 12,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             Text(
//               message.content,
//               style: TextStyle(
//                 color: isOwn ? Colors.white : textPrimary,
//                 fontSize: 16,
//                 fontWeight: FontWeight.w400,
//               ),
//             ),
//             const SizedBox(height: 6),
//             Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 if (message.edited == true)
//                   Text(
//                     'edited • ',
//                     style: TextStyle(
//                       color: isOwn
//                           ? Colors.white70
//                           : textPrimary.withOpacity(0.5),
//                       fontSize: 11,
//                       fontStyle: FontStyle.italic,
//                     ),
//                   ),
//                 if (message.createdAt != null)
//                   Text(
//                     _formatTime(message.createdAt!),
//                     style: TextStyle(
//                       color: isOwn
//                           ? Colors.white70
//                           : textPrimary.withOpacity(0.5),
//                       fontSize: 11,
//                     ),
//                   ),
//                 if (isOwn && message.status != null)
//                   Padding(
//                     padding: const EdgeInsets.only(left: 4),
//                     child: Icon(
//                       _getStatusIcon(message.status!),
//                       size: 11,
//                       color: _getStatusColor(message.status!, isOwn),
//                     ),
//                   ),
//               ],
//             ),
//             if (message.reactions != null && message.reactions!.isNotEmpty)
//               Container(
//                 margin: const EdgeInsets.only(top: 6),
//                 child: Wrap(
//                   spacing: 4,
//                   runSpacing: 2,
//                   children: message.reactions!.map((reaction) {
//                     if (reaction is Map) {
//                       final emoji = reaction['emoji']?.toString() ?? '👍';
//                       final count = reaction['count']?.toString() ?? '1';
//                       return Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 6,
//                           vertical: 3,
//                         ),
//                         decoration: BoxDecoration(
//                           color: isDark
//                               ? Colors.white.withOpacity(0.15)
//                               : Colors.white.withOpacity(0.9),
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Text(
//                           '$emoji $count',
//                           style: const TextStyle(fontSize: 12),
//                         ),
//                       );
//                     }
//                     return const SizedBox();
//                   }).toList(),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }

class _MessageInfoSheet extends StatelessWidget {
  final Message message;

  const _MessageInfoSheet({required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1D27) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Message Info',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          _InfoRow(label: 'Sender', value: message.senderName ?? 'Unknown'),
          if (message.createdAt != null)
            _InfoRow(label: 'Sent', value: _formatDateTime(message.createdAt!)),
          if (message.editedAt != null)
            _InfoRow(
              label: 'Edited',
              value: _formatDateTime(message.editedAt!),
            ),
          if (message.messageType != null)
            _InfoRow(label: 'Type', value: message.messageType!.toUpperCase()),
          if (message.status != null)
            _InfoRow(label: 'Status', value: message.status!.toUpperCase()),

          // Show read by users
          if (message.readBy != null && message.readBy!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Read by',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            ..._buildReadByList(message.readBy!, isDark),
          ],

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  List<Widget> _buildReadByList(List<dynamic> readBy, bool isDark) {
    return readBy.map((reader) {
      if (reader is Map) {
        final userName =
            reader['userName']?.toString() ??
            reader['name']?.toString() ??
            'User';
        final readAt = reader['readAt'];
        String timeStr = '';

        if (readAt != null) {
          try {
            final readTime = DateTime.parse(readAt.toString());
            timeStr = _formatTime(readTime);
          } catch (e) {
            timeStr = 'Unknown time';
          }
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: HoopTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 14,
                      ),
                    ),
                    if (timeStr.isNotEmpty)
                      Text(
                        timeStr,
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
      return const SizedBox();
    }).toList();
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDateTime(DateTime date) {
  return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

// IconData _getAttachmentIcon(String type) {
//   switch (type.toLowerCase()) {
//     case 'image':
//       return Icons.image;
//     case 'video':
//       return Icons.videocam;
//     case 'audio':
//       return Icons.audiotrack;
//     case 'file':
//       return Icons.insert_drive_file;
//     default:
//       return Icons.attachment;
//   }
// }

// String _formatTime(DateTime date) {
//   final now = DateTime.now();
//   final today = DateTime(now.year, now.month, now.day);
//   final yesterday = DateTime(now.year, now.month, now.day - 1);
//   final messageDate = DateTime(date.year, date.month, date.day);

//   if (messageDate == today) {
//     return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
//   } else if (messageDate == yesterday) {
//     return 'Yesterday ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
//   } else {
//     return '${date.day}/${date.month} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
//   }
// }

// IconData _getStatusIcon(String status) {
//   switch (status.toLowerCase()) {
//     case 'sent':
//       return Icons.check;
//     case 'delivered':
//       return Icons.done_all;
//     case 'read':
//       return Icons.done_all;
//     case 'edited':
//       return Icons.edit;
//     case 'deleted':
//       return Icons.delete;
//     default:
//       return Icons.access_time;
//   }
// }

// Color _getStatusColor(String status, bool isOwn) {
//   if (!isOwn) return Colors.transparent;

//   switch (status.toLowerCase()) {
//     case 'read':
//       return Colors.blue;
//     case 'delivered':
//       return Colors.grey;
//     case 'sent':
//       return Colors.grey.withOpacity(0.5);
//     case 'edited':
//       return Colors.orange;
//     case 'deleted':
//       return Colors.red;
//     default:
//       return Colors.grey;
//   }
// }
