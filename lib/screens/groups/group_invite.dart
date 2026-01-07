import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hoop/constants/themes.dart';
import 'package:hoop/dtos/podos/models/groups/invite.dart';
import 'package:hoop/dtos/responses/group/index.dart';
import 'package:hoop/screens/groups/group_detail_screen.dart';
import 'package:hoop/utils/helpers/formatters/hoop_formatter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';

class GroupInviteScreen extends StatefulWidget {
  final String groupId;

  const GroupInviteScreen({Key? key, required this.groupId}) : super(key: key);

  @override
  State<GroupInviteScreen> createState() => _GroupInviteScreenState();
}

class _GroupInviteScreenState extends State<GroupInviteScreen> {
  GroupDetails? _group;
  GroupInviteLink? _inviteLink;
  bool _loading = true;
  bool _qrLoading = false;
  String _customMessage = '';
  bool _copied = false;
  GlobalKey _qrKey = GlobalKey();

  // Tab state
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _loadGroupData();
  }

  Future<void> _loadGroupData() async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));

    // TODO: Replace with actual API call
    // final group = await yourApiService.getGroup(widget.groupId);
    // setState(() {
    //   _group = group;
    //   _loading = false;
    // });

    // Mock data for demonstration
    setState(() {
      _group = GroupDetails(
        id: int.tryParse(widget.groupId),
        payoutOrder: "",
        startDate: "",
        createdAt: "",
        currentUserRole: "1",
        nextPayoutDate: "",
        canInvite: true,
        members: [],
        canEdit: true,
        canStart: true,
        name: 'Family Savings Group',
        description: 'Saving together for our future goals',
        contributionAmount: 5000,
        contributionFrequency: 'weekly',
        maxMembers: 20,
        approvedMembersCount: 12,
        remainingSlots: 0,
        currency: "NGN",
        allowVideoCall: false,

        isPrivate: false,
        allowPairing: true,
        allowGroupMessaging: true,
        requireApproval: true,
      );
      _loading = false;
    });

    _initializeInviteData();
  }

  Future<void> _initializeInviteData() async {
    if (_group == null) return;

    setState(() {
      _qrLoading = true;
    });

    try {
      // Create invite link
      final inviteLink = GroupInviteLink(
        url: 'https://hoop.app/join/${_group!.id}',
        expiresAt: DateTime.now().add(const Duration(days: 30)),
        usageCount: 0,
        maxUsage:
            (_group?.maxMembers?.toInt() ?? 1) -
            (_group?.approvedMembersCount?.toInt() ?? 1),
      );

      setState(() {
        _inviteLink = inviteLink;
        _qrLoading = false;
      });
    } catch (error) {
      print('Failed to initialize invite data: $error');
      // Show error toast
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate QR code'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _qrLoading = false;
      });
    }
  }

  Future<void> _copyLink() async {
    if (_inviteLink != null) {
      await Clipboard.setData(ClipboardData(text: _inviteLink!.url));
      setState(() {
        _copied = true;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invite link copied to clipboard!'),
          backgroundColor: HoopTheme.successGreen,
        ),
      );

      // Reset copied state after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _copied = false;
          });
        }
      });
    }
  }

  Future<void> _shareInvite() async {
    if (_group == null || _inviteLink == null) return;

    final shareText = _customMessage.isNotEmpty
        ? _customMessage
        : '''Hi! I'd like to invite you to join our savings group "${_group!.name}".

We're saving together with ${_formatCurrency(_group!.contributionAmount ?? 0)} ${_group!.contributionFrequency} contributions.

Join here: ${_inviteLink!.url}''';

    final result = await Share.share(shareText);

    if (result.status == ShareResultStatus.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invitation shared successfully!'),
          backgroundColor: HoopTheme.successGreen,
        ),
      );
    }
  }

  Future<void> _downloadQRCode() async {
    try {
      final RenderRepaintBoundary boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      final directory = await getTemporaryDirectory();
      final file = File(
        '${directory.path}/join-${_group!.name?.toLowerCase().replaceAll(' ', '-')}.png',
      );
      await file.writeAsBytes(pngBytes);

      // TODO: Implement file saving/sharing
      // For now, just show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('QR code saved to ${file.path}'),
          backgroundColor: HoopTheme.successGreen,
        ),
      );
    } catch (error) {
      print('Failed to save QR code: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save QR code'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatCurrency(double amount) {
    // Format as NGN
    return '₦${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: HoopTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading group information...',
            style: TextStyle(
              color: HoopTheme.getTextSecondary(
                Theme.of(context).brightness == Brightness.dark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group,
            size: 64,
            color: HoopTheme.getTextSecondary(
              Theme.of(context).brightness == Brightness.dark,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Group Not Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: HoopTheme.getTextPrimary(
                Theme.of(context).brightness == Brightness.dark,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The group you\'re trying to invite to could not be found.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: HoopTheme.getTextSecondary(
                Theme.of(context).brightness == Brightness.dark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background,
        border: Border(
          bottom: BorderSide(color: HoopTheme.getBorderColor(isDark)),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back,
              color: HoopTheme.getTextPrimary(isDark),
            ),
            style: IconButton.styleFrom(
              backgroundColor: HoopTheme.getCategoryBackgroundColor(
                'back_button',
                isDark,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Text(
            'Invite Members',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: HoopTheme.getTextPrimary(isDark),
            ),
          ),
          const SizedBox(width: 48), // Spacer for symmetry
        ],
      ),
    );
  }

  Widget _buildGroupPreview() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final memberCount = _group!.approvedMembersCount;
    final availableSpots =
        (_group!.maxMembers?.toDouble() ?? 0) -
        (memberCount?.toDouble() ?? 0.0);

    return Container(
      decoration: BoxDecoration(
        // color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: HoopTheme.getBorderColor(isDark).withOpacity(0.1),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group Avatar
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: HoopTheme.primaryBlue,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                HoopFormatters.getInitials(_group!.name ?? ''),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _group!.name ?? '',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: HoopTheme.getTextPrimary(isDark),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _group!.description ?? '-',
                  style: TextStyle(
                    fontSize: 14,
                    color: HoopTheme.getTextSecondary(isDark),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: HoopTheme.getMutedColor(isDark),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${_formatCurrency(_group!.contributionAmount ?? 1)}/${_group!.contributionFrequency}',
                        style: TextStyle(
                          fontSize: 12,
                          color: HoopTheme.getTextSecondary(isDark),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: HoopTheme.getMutedColor(isDark),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$memberCount/${_group!.maxMembers} members',
                        style: TextStyle(
                          fontSize: 12,
                          color: HoopTheme.getTextSecondary(isDark),
                        ),
                      ),
                    ),
                    if (_group!.isPrivate ?? false)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: HoopTheme.getBorderColor(isDark),
                          ),
                        ),
                        child: Text(
                          'Private',
                          style: TextStyle(
                            fontSize: 12,
                            color: HoopTheme.getTextSecondary(isDark),
                          ),
                        ),
                      ),
                    if (_group!.requireApproval ?? false)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: HoopTheme.getBorderColor(isDark),
                          ),
                        ),
                        child: Text(
                          'Approval Required',
                          style: TextStyle(
                            fontSize: 12,
                            color: HoopTheme.getTextSecondary(isDark),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Column(
      children: [
        // Tab headers
        Container(
          decoration: BoxDecoration(
            color: HoopTheme.getMutedColor(
              Theme.of(context).brightness == Brightness.dark,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTab = 0),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: _selectedTab == 0
                          ? Theme.of(context).colorScheme.surface
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.link,
                            size: 16,
                            color: _selectedTab == 0
                                ? HoopTheme.primaryBlue
                                : HoopTheme.getTextSecondary(
                                    Theme.of(context).brightness ==
                                        Brightness.dark,
                                  ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Share Link',
                            style: TextStyle(
                              fontWeight: _selectedTab == 0
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                              color: _selectedTab == 0
                                  ? HoopTheme.primaryBlue
                                  : HoopTheme.getTextSecondary(
                                      Theme.of(context).brightness ==
                                          Brightness.dark,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTab = 1),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: _selectedTab == 1
                          ? Theme.of(context).colorScheme.surface
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.qr_code,
                            size: 16,
                            color: _selectedTab == 1
                                ? HoopTheme.primaryBlue
                                : HoopTheme.getTextSecondary(
                                    Theme.of(context).brightness ==
                                        Brightness.dark,
                                  ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'QR Code',
                            style: TextStyle(
                              fontWeight: _selectedTab == 1
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                              color: _selectedTab == 1
                                  ? HoopTheme.primaryBlue
                                  : HoopTheme.getTextSecondary(
                                      Theme.of(context).brightness ==
                                          Brightness.dark,
                                    ),
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
        ),
        const SizedBox(height: 16),

        // Tab content
        _selectedTab == 0 ? _buildLinkTab() : _buildQrCodeTab(),
      ],
    );
  }

  Widget _buildLinkTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: HoopTheme.getBorderColor(isDark).withOpacity(0.1),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Row(
            children: [
              Icon(
                Icons.link,
                size: 20,
                color: HoopTheme.getTextPrimary(isDark),
              ),
              const SizedBox(width: 8),
              Text(
                'Share Invitation',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  color: HoopTheme.getTextPrimary(isDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Invitation Link
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Invitation Link',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: HoopTheme.getTextPrimary(isDark),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: HoopTheme.getMutedColor(isDark),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: HoopTheme.getBorderColor(isDark),
                        ),
                      ),
                      child: Text(
                        _inviteLink?.url ?? 'Loading...',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'monospace',
                          color: HoopTheme.getTextPrimary(isDark),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _copyLink,
                    icon: Icon(
                      _copied ? Icons.check : Icons.copy,
                      size: 18,
                      color: _copied
                          ? HoopTheme.successGreen
                          : HoopTheme.getTextSecondary(isDark),
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: HoopTheme.getMutedColor(isDark),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
              if (_inviteLink != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Used ${_inviteLink!.usageCount} of ${_inviteLink!.maxUsage} times • '
                  'Expires ${_inviteLink!.expiresAt.day}/${_inviteLink!.expiresAt.month}/${_inviteLink!.expiresAt.year}',
                  style: TextStyle(
                    fontSize: 12,
                    color: HoopTheme.getTextSecondary(isDark),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 20),

          // Custom Message
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Custom Message (Optional)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: HoopTheme.getTextPrimary(isDark),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: HoopTheme.getMutedColor(isDark),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: HoopTheme.getBorderColor(isDark)),
                ),
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: TextEditingController(text: _customMessage),
                  onChanged: (value) => setState(() => _customMessage = value),
                  maxLines: null,
                  expands: true,
                  decoration: InputDecoration.collapsed(
                    hintText:
                        'Add a personal message...\n\n'
                        'Example: "Join our ${_group?.name} savings group! '
                        'We\'re saving together with ${_formatCurrency(_group?.contributionAmount ?? 0)} '
                        '${_group?.contributionFrequency} contributions."',
                    hintStyle: TextStyle(
                      color: HoopTheme.getTextSecondary(isDark),
                      fontSize: 14,
                    ),
                  ),
                  style: TextStyle(
                    color: HoopTheme.getTextPrimary(isDark),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Quick Share Buttons
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // WhatsApp share
                        final whatsappUrl =
                            'https://wa.me/?text=${Uri.encodeComponent(_customMessage.isNotEmpty ? _customMessage : '''Hi! I'd like to invite you to join our savings group "${_group!.name}".

We're saving together with ${_formatCurrency(_group!.contributionAmount ?? 1)} ${_group!.contributionFrequency} contributions.

Join here: ${_inviteLink!.url}''')}';
                        // TODO: Open URL
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF25D366,
                        ), // WhatsApp green
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('WhatsApp'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Telegram share
                        final telegramUrl =
                            'https://t.me/share/url?url=${Uri.encodeComponent(_inviteLink?.url ?? '')}&text=${Uri.encodeComponent(_customMessage.isNotEmpty ? _customMessage : '''Hi! I'd like to invite you to join our savings group "${_group!.name}".

We're saving together with ${_formatCurrency(_group!.contributionAmount ?? 1)} ${_group!.contributionFrequency} contributions.

Join here: ${_inviteLink!.url}''')}';
                        // TODO: Open URL
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF0088CC,
                        ), // Telegram blue
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('Telegram'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              OutlinedButton(
                onPressed: _shareInvite,
                style: OutlinedButton.styleFrom(
                  foregroundColor: HoopTheme.getTextPrimary(isDark),
                  side: BorderSide(color: HoopTheme.getBorderColor(isDark)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.share,
                      size: 16,
                      color: HoopTheme.getTextPrimary(isDark),
                    ),
                    const SizedBox(width: 8),
                    Text('Share via Device'),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Use device share for Messages, Discord, or other apps',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: HoopTheme.getTextSecondary(isDark),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQrCodeTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: HoopTheme.getBorderColor(isDark).withOpacity(0.1),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Row(
            children: [
              Icon(
                Icons.qr_code,
                size: 20,
                color: HoopTheme.getTextPrimary(isDark),
              ),
              const SizedBox(width: 8),
              Text(
                'QR Code',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  color: HoopTheme.getTextPrimary(isDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // QR Code Display
          Column(
            children: [
              if (_qrLoading)
                Container(
                  width: 192,
                  height: 192,
                  decoration: BoxDecoration(
                    color: HoopTheme.getMutedColor(isDark),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: HoopTheme.primaryBlue,
                      ),
                    ),
                  ),
                )
              else if (_inviteLink != null)
                RepaintBoundary(
                  key: _qrKey,
                  child: Container(
                    width: 192,
                    height: 192,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: HoopTheme.getBorderColor(isDark),
                        width: 2,
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: QrImageView(
                      data: _inviteLink!.url,
                      version: QrVersions.auto,
                      size: 160,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Colors.black,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Colors.black,
                      ),
                    ),
                  ),
                )
              else
                Container(
                  width: 192,
                  height: 192,
                  decoration: BoxDecoration(
                    color: HoopTheme.getMutedColor(isDark),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.qr_code,
                      size: 64,
                      color: HoopTheme.getTextSecondary(isDark),
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              if (!_qrLoading && _inviteLink != null)
                Text(
                  'Scan this QR code to join ${_group?.name}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: HoopTheme.getTextSecondary(isDark),
                  ),
                ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _inviteLink != null && !_qrLoading
                    ? _downloadQRCode
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: HoopTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.download, size: 16, color: Colors.white),
                    const SizedBox(width: 8),
                    Text('Download'),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'Perfect for printing or sharing in person',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: HoopTheme.getTextSecondary(isDark),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    if (_group == null) return const SizedBox.shrink();

    final memberCount = _group!.approvedMembersCount;
    final availableSpots =
        (_group!.maxMembers ?? 0) - (memberCount?.toDouble() ?? 0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: HoopTheme.getBorderColor(isDark).withOpacity(0.1),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text(
                  memberCount.toString(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: HoopTheme.primaryBlue,
                  ),
                ),
                Text(
                  'Current Members',
                  style: TextStyle(
                    fontSize: 14,
                    color: HoopTheme.getTextSecondary(isDark),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  availableSpots.toString(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: HoopTheme.primaryBlue,
                  ),
                ),
                Text(
                  'Spots Available',
                  style: TextStyle(
                    fontSize: 14,
                    color: HoopTheme.getTextSecondary(isDark),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildLoadingState()),
          ],
        ),
      );
    }

    if (_group == null) {
      return Scaffold(
        body: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildErrorState()),
          ],
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildGroupPreview(),
                  const SizedBox(height: 24),
                  _buildTabs(),
                  const SizedBox(height: 24),
                  _buildQuickStats(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
