// lib/screens/call_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:hoop/dtos/podos/calls/call_models.dart';
import 'package:hoop/states/webrtc_manager.dart';

class CallScreen extends StatefulWidget {
  final CallData callData;
  final WebRTCManager webrtcManager;

  const CallScreen({
    Key? key,
    required this.callData,
    required this.webrtcManager,
  }) : super(key: key);

  @override
  _CallScreenState createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final Map<int, RTCVideoRenderer> _remoteRenderers = {};
  RTCVideoRenderer? _localRenderer;
  Timer? _callTimer;
  int _callDuration = 0;
  bool _isSpeakerEnabled = false;
  bool _isBluetoothEnabled = false;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _initializeRenderers();
    _startCallTimer();
    _setupCallbacks();
  }

  Future<void> _initializeRenderers() async {
    // Initialize local renderer
    _localRenderer = RTCVideoRenderer();
    await _localRenderer!.initialize();
    
    // Set local stream if available
    final localStream = widget.webrtcManager.localStream;
    if (localStream != null) {
      _localRenderer!.srcObject = localStream;
    }

    // Initialize remote renderers for existing participants
    final remoteStreams = widget.webrtcManager.remoteStreams;
    for (final userId in remoteStreams.keys) {
      await _addRemoteRenderer(userId, remoteStreams[userId]!);
    }

    setState(() {});
  }

  Future<void> _addRemoteRenderer(int userId, MediaStream stream) async {
    final renderer = RTCVideoRenderer();
    await renderer.initialize();
    renderer.srcObject = stream;
    _remoteRenderers[userId] = renderer;
    setState(() {});
  }

  void _removeRemoteRenderer(int userId) {
    final renderer = _remoteRenderers[userId];
    if (renderer != null) {
      renderer.dispose();
      _remoteRenderers.remove(userId);
      setState(() {});
    }
  }

  void _setupCallbacks() {
    widget.webrtcManager.onRemoteStreamsUpdated =
        (Map<int, MediaStream> streams) {
      // Add new streams
      streams.forEach((userId, stream) {
        if (!_remoteRenderers.containsKey(userId)) {
          _addRemoteRenderer(userId, stream);
        }
      });

      // Remove old streams
      _remoteRenderers.keys.toList().forEach((userId) {
        if (!streams.containsKey(userId)) {
          _removeRemoteRenderer(userId);
        }
      });
    };
  }

  void _startCallTimer() {
    _callTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _callDuration++;
      });
    });
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _localRenderer?.dispose();
    _remoteRenderers.values.forEach((renderer) => renderer.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isVideoCall = widget.callData.type == CallType.video;
    final remoteStreams = widget.webrtcManager.remoteStreams;
    final participants = widget.callData.participants;
    final isAudioMuted = widget.webrtcManager.isAudioMuted;
    final isVideoMuted = widget.webrtcManager.isVideoMuted;
    final isCallActive = widget.webrtcManager.isCallActive;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Background gradient
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black,
                      Colors.grey[900]!,
                    ],
                  ),
                ),
              ),
            ),

            // Main content
            Column(
              children: [
                // Top bar with call info
                _buildTopBar(),
                
                // Video grid or caller info
                Expanded(
                  child: isVideoCall && remoteStreams.isNotEmpty
                      ? _buildVideoGrid(remoteStreams, participants)
                      : _buildAudioCallView(participants),
                ),
                
                // Call controls
                _buildCallControls(
                  isVideoCall: isVideoCall,
                  isAudioMuted: isAudioMuted,
                  isVideoMuted: isVideoMuted,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  widget.callData.groupName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person,
                      size: 14,
                      color: Colors.green,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '${widget.callData.participants.length} participants',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white30,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      _formatDuration(_callDuration),
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // More options
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.white),
            onPressed: _showMoreOptions,
          ),
        ],
      ),
    );
  }

  Widget _buildVideoGrid(Map<int, MediaStream> remoteStreams, List<CallParticipant> participants) {
    final participantIds = remoteStreams.keys.toList();
    final totalParticipants = participantIds.length + 1; // +1 for local view

    if (totalParticipants == 1) {
      // Only local view
      return Center(
        child: Container(
          width: 120,
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: _localRenderer != null
                ? RTCVideoView(
                    _localRenderer!,
                    mirror: true,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  )
                : Center(
                    child: Icon(Icons.person, size: 40, color: Colors.white),
                  ),
          ),
        ),
      );
    }

    if (totalParticipants == 2) {
      // One remote participant - full screen
      final remoteId = participantIds.first;
      return Stack(
        children: [
          // Remote video (full screen)
          Container(
            color: Colors.black,
            child: _remoteRenderers[remoteId] != null
                ? RTCVideoView(
                    _remoteRenderers[remoteId]!,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  )
                : Center(
                    child: _buildParticipantAvatar(
                      participants.firstWhere((p) => p.id == remoteId),
                      size: 100,
                    ),
                  ),
          ),
          
          // Local preview (picture-in-picture)
          Positioned(
            bottom: 100,
            right: 20,
            child: Container(
              width: 100,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _localRenderer != null
                    ? RTCVideoView(
                        _localRenderer!,
                        mirror: true,
                        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      )
                    : Center(
                        child: Icon(Icons.person, size: 30, color: Colors.white),
                      ),
              ),
            ),
          ),
        ],
      );
    }

    // 3+ participants - grid view
    final gridParticipants = [
      if (_localRenderer != null) {'type': 'local', 'renderer': _localRenderer},
      ...participantIds.map((id) => {
            'type': 'remote',
            'id': id,
            'renderer': _remoteRenderers[id],
            'participant': participants.firstWhere((p) => p.id == id, orElse: () => CallParticipant(
                  id: id,
                  name: 'User $id',
                  avatar: '',
                  role: ParticipantRole.participant,
                )),
          }),
    ];

    return GridView.builder(
      padding: EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.75,
      ),
      itemCount: gridParticipants.length,
      itemBuilder: (context, index) {
        final participant = gridParticipants[index];
        final isLocal = participant['type'] == 'local';
        final renderer = participant['renderer'] as RTCVideoRenderer?;
        final callParticipant = participant['participant'] as CallParticipant?;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[900],
            border: Border.all(
              color: isLocal ? Colors.blue : Colors.transparent,
              width: 2,
            ),
          ),
          child: Stack(
            children: [
              // Video or avatar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: renderer != null
                    ? RTCVideoView(
                        renderer,
                        mirror: isLocal,
                        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      )
                    : Center(
                        child: _buildParticipantAvatar(
                          callParticipant ?? CallParticipant(
                            id: isLocal ? 0 : -1,
                            name: isLocal ? 'You' : 'User',
                            avatar: '',
                            role: ParticipantRole.participant,
                          ),
                          size: 40,
                        ),
                      ),
              ),
              
              // Participant info overlay
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      if (callParticipant?.isAudioMuted ?? false)
                        Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(Icons.mic_off, size: 12, color: Colors.white),
                        ),
                      Text(
                        callParticipant?.name ?? (isLocal ? 'You' : 'User'),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Connection indicator
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAudioCallView(List<CallParticipant> participants) {
    final currentUser = participants.firstWhere(
      (p) => p.id == widget.webrtcManager.activeCall?.initiator,
      orElse: () => participants.isNotEmpty ? participants.first : CallParticipant(
        id: 0,
        name: 'Unknown',
        avatar: '',
        role: ParticipantRole.caller,
      ),
    );

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Caller avatar
          _buildParticipantAvatar(currentUser, size: 120),
          
          SizedBox(height: 24),
          
          // Caller name
          Text(
            currentUser.name,
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          SizedBox(height: 8),
          
          // Call status
          Text(
            widget.webrtcManager.isCallActive ? 'Connected' : 'Connecting...',
            style: TextStyle(
              color: Colors.green,
              fontSize: 16,
            ),
          ),
          
          SizedBox(height: 40),
          
          // Participants list
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Text(
                  'Participants (${participants.length})',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 12),
                LimitedBox(
                  maxHeight: 120,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: participants.length,
                    itemBuilder: (context, index) {
                      final participant = participants[index];
                      return ListTile(
                        leading: _buildParticipantAvatar(participant, size: 36),
                        title: Text(
                          participant.name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (participant.isAudioMuted)
                              Icon(Icons.mic_off, size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Icon(
                              Icons.circle,
                              size: 10,
                              color: Colors.green,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantAvatar(CallParticipant participant, {double size = 60}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade700,
            Colors.purple.shade500,
          ],
        ),
      ),
      child: Center(
        child: Text(
          participant.name.isNotEmpty ? participant.name[0].toUpperCase() : '?',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCallControls({
    required bool isVideoCall,
    required bool isAudioMuted,
    required bool isVideoMuted,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.95),
            Colors.black.withOpacity(0.8),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        children: [
          // Quick actions row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Speaker toggle
              _buildControlButton(
                icon: _isSpeakerEnabled ? Icons.volume_up : Icons.volume_down,
                label: 'Speaker',
                isActive: _isSpeakerEnabled,
                onPressed: _toggleSpeaker,
              ),
              
              // Bluetooth toggle
              _buildControlButton(
                icon: Icons.bluetooth,
                label: 'Bluetooth',
                isActive: _isBluetoothEnabled,
                onPressed: _toggleBluetooth,
              ),
              
              // Record toggle
              _buildControlButton(
                icon: _isRecording ? Icons.stop : Icons.fiber_manual_record,
                label: 'Record',
                isActive: _isRecording,
                activeColor: Colors.red,
                onPressed: _toggleRecording,
              ),
              
              // More options
              _buildControlButton(
                icon: Icons.more_horiz,
                label: 'More',
                onPressed: _showMoreOptions,
              ),
            ],
          ),
          
          SizedBox(height: 20),
          
          // Main controls row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Mute audio
              _buildMainControlButton(
                icon: isAudioMuted ? Icons.mic_off : Icons.mic,
                label: isAudioMuted ? 'Unmute' : 'Mute',
                backgroundColor: isAudioMuted ? Colors.red : Colors.white24,
                onPressed: widget.webrtcManager.toggleAudio,
              ),
              
              // Toggle video (only for video calls)
              if (isVideoCall)
                _buildMainControlButton(
                  icon: isVideoMuted ? Icons.videocam_off : Icons.videocam,
                  label: isVideoMuted ? 'Video On' : 'Video Off',
                  backgroundColor: isVideoMuted ? Colors.red : Colors.white24,
                  onPressed: widget.webrtcManager.toggleVideo,
                ),
              
              // End call
              _buildMainControlButton(
                icon: Icons.call_end,
                label: 'End',
                backgroundColor: Colors.red,
                isLarge: true,
                onPressed: () {
                  widget.webrtcManager.endCall();
                  Navigator.pop(context);
                },
              ),
              
              // Flip camera (only for video calls)
              if (isVideoCall)
                _buildMainControlButton(
                  icon: Icons.flip_camera_ios,
                  label: 'Flip',
                  backgroundColor: Colors.white24,
                  onPressed: _flipCamera,
                ),
              
              // Add participant
              _buildMainControlButton(
                icon: Icons.person_add,
                label: 'Add',
                backgroundColor: Colors.white24,
                onPressed: _addParticipant,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isActive = false,
    Color activeColor = Colors.blue,
  }) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? activeColor.withOpacity(0.2) : Colors.white10,
            border: Border.all(
              color: isActive ? activeColor : Colors.transparent,
              width: 2,
            ),
          ),
          child: IconButton(
            icon: Icon(icon, size: 24, color: isActive ? activeColor : Colors.white),
            onPressed: onPressed,
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isActive ? activeColor : Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildMainControlButton({
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required VoidCallback onPressed,
    bool isLarge = false,
  }) {
    return Column(
      children: [
        Container(
          width: isLarge ? 70 : 60,
          height: isLarge ? 70 : 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: backgroundColor,
            boxShadow: [
              BoxShadow(
                color: backgroundColor.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              icon,
              size: isLarge ? 32 : 24,
              color: Colors.white,
            ),
            onPressed: onPressed,
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // Control methods
  void _toggleSpeaker() {
    setState(() {
      _isSpeakerEnabled = !_isSpeakerEnabled;
      // TODO: Implement speaker toggle functionality
    });
  }

  void _toggleBluetooth() {
    setState(() {
      _isBluetoothEnabled = !_isBluetoothEnabled;
      // TODO: Implement Bluetooth audio routing
    });
  }

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
      // TODO: Implement call recording
      if (_isRecording) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Call recording started'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Call recording stopped'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    });
  }

  void _flipCamera() {
    // TODO: Implement camera flipping
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Camera flipped'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _addParticipant() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Participant'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Enter user ID',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement adding participant by ID
                Navigator.pop(context);
              },
              child: Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.people, color: Colors.white),
              title: Text('View Participants', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showParticipantsList();
              },
            ),
            Divider(color: Colors.white30),
            ListTile(
              leading: Icon(Icons.share, color: Colors.white),
              title: Text('Share Call Link', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _shareCallLink();
              },
            ),
            Divider(color: Colors.white30),
            ListTile(
              leading: Icon(Icons.settings, color: Colors.white),
              title: Text('Call Settings', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showCallSettings();
              },
            ),
            Divider(color: Colors.white30),
            ListTile(
              leading: Icon(Icons.help, color: Colors.white),
              title: Text('Help', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showHelp();
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showParticipantsList() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Participants (${widget.callData.participants.length})'),
        content: Container(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: widget.callData.participants.length,
            itemBuilder: (context, index) {
              final participant = widget.callData.participants[index];
              return ListTile(
                leading: _buildParticipantAvatar(participant, size: 40),
                title: Text(participant.name),
                subtitle: Text(participant.role.toString().split('.').last),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (participant.isAudioMuted)
                      Icon(Icons.mic_off, color: Colors.red, size: 16),
                    if (participant.isVideoMuted)
                      Icon(Icons.videocam_off, color: Colors.red, size: 16),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _shareCallLink() {
    // TODO: Generate and share call link
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Call link copied to clipboard'),
      ),
    );
  }

  void _showCallSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Call Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: Text('Noise Cancellation'),
              value: true,
              onChanged: (value) {},
            ),
            SwitchListTile(
              title: Text('Echo Cancellation'),
              value: true,
              onChanged: (value) {},
            ),
            SwitchListTile(
              title: Text('Auto Gain Control'),
              value: true,
              onChanged: (value) {},
            ),
            Divider(),
            ListTile(
              title: Text('Audio Quality'),
              subtitle: Text('High'),
              onTap: () {},
            ),
            ListTile(
              title: Text('Video Quality'),
              subtitle: Text('720p'),
              onTap: () {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Call Help'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Tap mute/unmute to control microphone'),
            SizedBox(height: 8),
            Text('• Tap video on/off to control camera'),
            SizedBox(height: 8),
            Text('• Add participants using the + button'),
            SizedBox(height: 8),
            Text('• Use speaker/bluetooth for audio routing'),
            SizedBox(height: 8),
            Text('• Recording saves to local storage'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it'),
          ),
        ],
      ),
    );
  }
}