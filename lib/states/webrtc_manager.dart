// lib/services/webrtc_manager.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:hoop/dtos/podos/calls/call_models.dart';
import 'package:hoop/states/ws/chat_sockets.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:logger/logger.dart';

class WebRTCManager with ChangeNotifier {
  static final WebRTCManager _instance = WebRTCManager._internal();
  factory WebRTCManager() => _instance;
  WebRTCManager._internal();

  // Logging
  final Logger logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: false,
    ),
  );

  // State matching your web version
  CallData? _activeCall;
  CallData? _incomingCall;
  MediaStream? _localStream;
  final Map<int, MediaStream> _remoteStreams = {};
  final Map<int, RTCPeerConnection> _peerConnections = {};
  final Map<int, RTCDataChannel> _dataChannels = {};

  bool _isAudioMuted = false;
  bool _isVideoMuted = false;
  bool _isCallActive = false;
  bool _showCallModal = false;
  String _connectionState = 'disconnected';
  String _iceConnectionState = 'disconnected';

  // Current user info
  int _currentUserId = 0;
  String _currentUserName = 'User';

  // Socket integration with your ChatWebSocketHandler
  late ChatWebSocketHandler _chatHandler;

  // ICE Servers (matching your web config)
  final List<Map<String, dynamic>> _iceServers = [
    {
      'urls': [
        'stun:ec2-18-209-65-130.compute-1.amazonaws.com:3478',
        'turn:ec2-18-209-65-130.compute-1.amazonaws.com:3478?transport=udp',
        'turn:ec2-18-209-65-130.compute-1.amazonaws.com:3478?transport=tcp',
      ],
      'username': 'webrtcuser',
      'credential': 'supersecret',
    },
  ];

  // Reconnection tracking
  final Map<int, Timer> _connectionTimers = {};
  final Map<int, int> _reconnectAttempts = {};
  final Random _random = Random();

  // Callbacks (matching your web interface)
  Function(CallData)? onIncomingCall;
  Function(CallData)? onCallStarted;
  Function(CallData)? onCallEnded;
  Function(Map<int, MediaStream>)? onRemoteStreamsUpdated;
  Function(bool)? onAudioMuted;
  Function(bool)? onVideoMuted;
  Function(String)? onError;

  // Getter methods matching your web interface
  CallData? get activeCall => _activeCall;
  CallData? get incomingCall => _incomingCall;
  MediaStream? get localStream => _localStream;
  Map<int, MediaStream> get remoteStreams => Map.from(_remoteStreams);
  bool get isAudioMuted => _isAudioMuted;
  bool get isVideoMuted => _isVideoMuted;
  bool get isCallActive => _isCallActive;
  bool get showCallModal => _showCallModal;
  String get connectionState => _connectionState;
  String get iceConnectionState => _iceConnectionState;

  // Initialize with ChatWebSocketHandler
  void initialize(
    ChatWebSocketHandler chatHandler,
    int userId,
    String userName,
  ) {
    _chatHandler = chatHandler;
    _currentUserId = userId;
    _currentUserName = userName;

    _setupWebSocketListeners();
    _initializeWebRTC();

    logger.i('🎯 WebRTC Manager initialized for user $userId');
  }

  void _setupWebSocketListeners() {
    // Listen to WebSocket events from your ChatWebSocketHandler

    // Incoming call
    _chatHandler.on('call_started', (data) {
      logger.i('📨 Incoming call via WebSocket');
      try {
        final callData = CallData.fromJson(data);
        _handleIncomingCallViaWebSocket(callData);
      } catch (e) {
        logger.e('❌ Error parsing incoming call: $e');
      }
    });

    // WebRTC signaling events
    _chatHandler.on('webrtc_offer', (data) async {
      logger.i('📨 WebRTC offer received');
      try {
        final offer = data['offer'];
        final callData = CallData.fromJson(data['callData']);
        final fromUserId = data['fromUserId'];

        await _handleRemoteOffer(
          RTCSessionDescription(offer['sdp'], offer['type']),
          callData,
          fromUserId,
        );
      } catch (e) {
        logger.e('❌ Error handling WebRTC offer: $e');
      }
    });

    _chatHandler.on('webrtc_answer', (data) async {
      logger.i('📨 WebRTC answer received');
      try {
        final answer = data['answer'];
        final fromUserId = data['fromUserId'];

        await _handleRemoteAnswer(
          RTCSessionDescription(answer['sdp'], answer['type']),
          fromUserId,
        );
      } catch (e) {
        logger.e('❌ Error handling WebRTC answer: $e');
      }
    });

    _chatHandler.on('webrtc_ice_candidate', (data) async {
      logger.i('🧊 WebRTC ICE candidate received');
      try {
        final candidate = data['candidate'];
        final fromUserId = data['fromUserId'];

        await _handleRemoteICECandidate(
          RTCIceCandidate(
            candidate['candidate'],
            candidate['sdpMid'],
            candidate['sdpMLineIndex'],
          ),
          fromUserId,
        );
      } catch (e) {
        logger.e('❌ Error handling ICE candidate: $e');
      }
    });

    // Call management events
    _chatHandler.on('call_answered', (data) {
      logger.i('📞 Call answered remotely');
      _handleCallAnswered(data);
    });

    _chatHandler.on('call_rejected', (data) {
      logger.i('📞 Call rejected remotely');
      _handleCallRejected(data);
    });

    _chatHandler.on('call_ended', (data) {
      logger.i('📞 Call ended remotely');
      _handleCallEnded(data);
    });

    _chatHandler.on('user_joined_call', (data) {
      logger.i('👋 User joined call remotely');
      _handleUserJoinedCall(data);
    });

    _chatHandler.on('user_left_call', (data) {
      logger.i('👋 User left call remotely');
      _handleUserLeftCall(data);
    });
  }

  void _initializeWebRTC() {
    // Ensure WebRTC is initialized
    if (WebRTC.platformIsDesktop) {
      // Desktop specific initialization
    }
    logger.i('🎯 WebRTC initialized for platform');
  }

  // Get user media (matching your web constraints)
  Future<MediaStream> _getUserMedia(CallType type) async {
    try {
      final Map<String, dynamic> constraints = {
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        },
        'video': type == CallType.video
            ? {
                'mandatory': {
                  'minWidth': '640',
                  'minHeight': '480',
                  'minFrameRate': '30',
                },
                'facingMode': 'user',
                'optional': [],
              }
            : false,
      };

      logger.i(
        '🎤 Getting user media for ${type == CallType.video ? 'video' : 'audio'} call',
      );
      final stream = await navigator.mediaDevices.getUserMedia(constraints);
      _localStream = stream;
      return stream;
    } catch (e) {
      logger.e('❌ Error getting user media: $e');
      rethrow;
    }
  }

  // Create peer connection (matching your web implementation)
  Future<RTCPeerConnection> _createPeerConnection(int userId) async {
    logger.i('🔗 Creating peer connection for user $userId');

    final configuration = <String, dynamic>{
      'iceServers': _iceServers,
      'iceCandidatePoolSize': 10,
      'bundlePolicy': 'max-bundle',
      'rtcpMuxPolicy': 'require',
      'iceTransportPolicy': 'all',
    };

    final pc = await createPeerConnection(configuration, {});

    // Add local tracks
    if (_localStream != null) {
      _localStream!.getTracks().forEach((track) {
        pc.addTrack(track, _localStream!);
      });
    }

    // Set up event handlers (matching your web implementation)
    pc.onTrack = (event) {
      logger.i('📥 Received track from user $userId: ${event.track.kind}');
      if (event.streams.isNotEmpty) {
        _remoteStreams[userId] = event.streams.first;
        onRemoteStreamsUpdated?.call(Map.from(_remoteStreams));
        notifyListeners();
      }
    };

    pc.onIceCandidate = (candidate) {
      if (candidate.candidate != null &&
          candidate.candidate!.isNotEmpty &&
          _activeCall != null) {
        logger.i('🧊 Sending ICE candidate to user $userId');

        // Send via WebSocket (matching your web signaling)
        _chatHandler.emit('webrtc_ice_candidate', {
          'candidate': {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          },
          'callId': _activeCall!.callId,
          'groupId': _activeCall!.groupId,
          'toUserId': userId,
          'fromUserId': _currentUserId,
        });
      }
    };

    pc.onIceConnectionState = (state) {
      logger.i('🧊 ICE connection state for user $userId: $state');
      _handleICEConnectionState(state, userId);
    };

    pc.onConnectionState = (state) {
      logger.i('🔗 Peer connection state for user $userId: $state');
      _handleConnectionState(state, userId);
    };

    // Create data channel for connectivity (matching web)
    try {
      final dataChannel = await pc.createDataChannel(
        'call-control-$userId',
        RTCDataChannelInit()
          ..ordered = true
          ..maxRetransmits = 3,
      );

      _setupDataChannel(dataChannel, userId);
      _dataChannels[userId] = dataChannel;
    } catch (e) {
      logger.e('❌ Error creating data channel: $e');
    }

    // Handle incoming data channels
    pc.onDataChannel = (channel) {
      logger.i('📡 Incoming data channel from user $userId: ${channel.label}');
      _setupDataChannel(channel, userId);
      _dataChannels[userId] = channel;
    };

    _peerConnections[userId] = pc;
    return pc;
  }

  void _setupDataChannel(RTCDataChannel channel, int userId) {
    channel.onMessage = (message) {
      _handleDataChannelMessage(message.text, userId);
    };

    channel.onDataChannelState = (state) {
      if (state == RTCDataChannelState.RTCDataChannelClosed) {
        logger.i('📡 Data channel closed with user $userId');
        _dataChannels.remove(userId);
      }
      if (state == RTCDataChannelState.RTCDataChannelOpen) {
        logger.i('📡 Data channel opened with user $userId');
      }
    };
    // channel.onError = (error) {
    //   logger.e('📡 Data channel error with user $userId: $error');
    // };
  }

  void _handleDataChannelMessage(String message, int fromUserId) {
    try {
      final data = json.decode(message);
      logger.i(
        '📨 Data channel message from user $fromUserId: ${data['type']}',
      );

      switch (data['type']) {
        case 'mute_audio':
          if (_activeCall != null) {
            final updatedParticipants = _activeCall!.participants.map((p) {
              if (p.id == fromUserId) {
                return p..isAudioMuted = data['muted'];
              }
              return p;
            }).toList();
            _activeCall = _activeCall!.copyWith(
              participants: updatedParticipants,
            );
            notifyListeners();
          }
          break;

        case 'mute_video':
          if (_activeCall != null) {
            final updatedParticipants = _activeCall!.participants.map((p) {
              if (p.id == fromUserId) {
                return p..isVideoMuted = data['muted'];
              }
              return p;
            }).toList();
            _activeCall = _activeCall!.copyWith(
              participants: updatedParticipants,
            );
            notifyListeners();
          }
          break;

        case 'ping':
          // Send pong response (matching web)
          final dc = _dataChannels[fromUserId];
          if (dc != null &&
              dc.state == RTCDataChannelState.RTCDataChannelOpen) {
            dc.send(
              RTCDataChannelMessage(
                json.encode({
                  'type': 'pong',
                  'timestamp': DateTime.now().millisecondsSinceEpoch,
                  'userId': _currentUserId,
                }),
              ),
            );
          }
          break;
      }
    } catch (e) {
      logger.e('❌ Error parsing data channel message: $e');
    }
  }

  void _handleICEConnectionState(RTCIceConnectionState state, int userId) {
    switch (state) {
      case RTCIceConnectionState.RTCIceConnectionStateConnected:
        logger.i('✅ ICE connection established with user $userId');
        _reconnectAttempts.remove(userId);
        _startConnectionMonitoring(userId);
        break;

      case RTCIceConnectionState.RTCIceConnectionStateDisconnected:
        logger.w('⚠️ ICE connection disconnected with user $userId');
        _attemptReconnection(userId);
        break;

      case RTCIceConnectionState.RTCIceConnectionStateFailed:
        logger.e('❌ ICE connection failed with user $userId');
        _handleConnectionFailure(userId);
        break;

      case RTCIceConnectionState.RTCIceConnectionStateClosed:
        logger.i('🔒 ICE connection closed with user $userId');
        _cleanupParticipant(userId);
        break;

      default:
        break;
    }
  }

  void _handleConnectionState(RTCPeerConnectionState state, int userId) {
    switch (state) {
      case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
        logger.i('✅ WebRTC connection established with user $userId');
        _isCallActive = true;
        if (_activeCall != null) {
          onCallStarted?.call(_activeCall!);
        }
        notifyListeners();
        break;

      case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
        logger.w('⚠️ Connection disconnected with user $userId');
        break;

      case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
        logger.e('❌ Connection failed with user $userId');
        _handleConnectionFailure(userId);
        break;

      case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
        logger.i('🔒 Connection closed with user $userId');
        _cleanupParticipant(userId);
        break;

      default:
        break;
    }
  }

  void _startConnectionMonitoring(int userId) {
    // Stop existing timer
    _connectionTimers[userId]?.cancel();

    // Start new monitoring timer (matching web's 3-second ping)
    final timer = Timer.periodic(Duration(seconds: 3), (timer) async {
      final pc = _peerConnections[userId];
      if (pc == null ||
          pc.iceConnectionState !=
              RTCIceConnectionState.RTCIceConnectionStateConnected) {
        timer.cancel();
        _connectionTimers.remove(userId);
        return;
      }

      // Send ping to keep connection alive (matching web)
      final dc = _dataChannels[userId];
      if (dc != null && dc.state == RTCDataChannelState.RTCDataChannelOpen) {
        try {
          dc.send(
            RTCDataChannelMessage(
              json.encode({
                'type': 'ping',
                'timestamp': DateTime.now().millisecondsSinceEpoch,
                'userId': _currentUserId,
              }),
            ),
          );
        } catch (e) {
          logger.e('❌ Error sending ping: $e');
        }
      }
    });

    _connectionTimers[userId] = timer;
  }

  void _attemptReconnection(int userId) {
    final attempts = _reconnectAttempts[userId] ?? 0;

    if (attempts < 3) {
      logger.i(
        '🔄 Attempting to restart ICE for user $userId (attempt ${attempts + 1})',
      );
      _reconnectAttempts[userId] = attempts + 1;

      Future.delayed(Duration(seconds: 2), () async {
        final pc = _peerConnections[userId];
        if (pc != null &&
            pc.iceConnectionState ==
                RTCIceConnectionState.RTCIceConnectionStateDisconnected) {
          try {
            // Create new offer with ICE restart (matching web)
            final offer = await pc.createOffer({'iceRestart': true});
            await pc.setLocalDescription(offer);

            _chatHandler.emit('webrtc_offer', {
              'offer': {'sdp': offer.sdp, 'type': offer.type},
              'callData': _activeCall!.toJson(),
              'toUserId': userId,
              'fromUserId': _currentUserId,
            });
          } catch (e) {
            logger.e('❌ Error restarting ICE: $e');
          }
        }
      });
    } else {
      logger.w('💀 Max reconnection attempts reached for user $userId');
      _cleanupParticipant(userId);
    }
  }

  void _handleConnectionFailure(int userId) {
    _connectionTimers[userId]?.cancel();
    _connectionTimers.remove(userId);

    Future.delayed(Duration(seconds: 8), () {
      final pc = _peerConnections[userId];
      if (pc != null &&
          pc.connectionState ==
              RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        _cleanupParticipant(userId);
      }
    });
  }

  // ========= PUBLIC API (matching your web interface) =========

  // Start a call (matching your web startCall method)
  Future<CallData> startCall({
    required CallType type,
    required int groupId,
    required String groupName,
  }) async {
    try {
      logger.i(
        '🚀 Starting ${type == CallType.video ? 'video' : 'audio'} call for group $groupId',
      );

      // Cleanup any existing calls
      await _cleanupAll();

      // Get user media
      final stream = await _getUserMedia(type);

      // Create call data (matching your web structure)
      final callData = CallData(
        callId:
            'call-${DateTime.now().millisecondsSinceEpoch}-${_random.nextInt(10000)}',
        groupId: groupId,
        groupName: groupName,
        initiatorId: _currentUserId.toString(),
        startedAt: DateTime.now(),
        initiatorName: '',
        initiator: _currentUserId,
        type: type,
        participants: [
          CallParticipant(
            id: _currentUserId,
            name: 'You',
            avatar: '',
            role: ParticipantRole.caller,
            isAudioMuted: false,
            isVideoMuted: type != CallType.video,
          ),
        ],
        status: CallStatus.ringing,
      );

      _activeCall = callData;
      _showCallModal = true;

      // Send via WebSocket (matching your web signaling)
      _chatHandler.emit('call_started', {
        'callData': callData.toJson(),
        'groupId': groupId,
        'fromUserId': _currentUserId,
        'invitedUsers': [], // You can populate this from group members
      });

      logger.i(
        '📞 ${type == CallType.video ? 'Video' : 'Audio'} call started - waiting for participants',
      );
      notifyListeners();

      return callData;
    } catch (e) {
      logger.e('❌ Error starting call: $e');
      await _cleanupAll();
      rethrow;
    }
  }

  // Create offer for specific user (matching web createOfferForUser)
  Future<void> _createOfferForUser(int userId) async {
    try {
      logger.i('🎯 Creating offer for user $userId');

      final pc = await _createPeerConnection(userId);

      final offer = await pc.createOffer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': _activeCall!.type == CallType.video,
      });

      await pc.setLocalDescription(offer);

      _chatHandler.emit('webrtc_offer', {
        'offer': {'sdp': offer.sdp, 'type': offer.type},
        'callData': _activeCall!.toJson(),
        'toUserId': userId,
        'fromUserId': _currentUserId,
      });

      logger.i('✅ Offer sent to user $userId');
    } catch (e) {
      logger.e('❌ Error creating offer for user $userId: $e');
      rethrow;
    }
  }

  // Handle remote offer (matching web handleRemoteOffer)
  Future<void> _handleRemoteOffer(
    RTCSessionDescription offer,
    CallData callData,
    int fromUserId,
  ) async {
    try {
      logger.i('📨 Handling remote offer from user $fromUserId');

      // Get user media
      await _getUserMedia(callData.type);

      // Create peer connection
      final pc = await _createPeerConnection(fromUserId);

      // Set remote description
      await pc.setRemoteDescription(offer);

      // Create answer
      final answer = await pc.createAnswer();
      await pc.setLocalDescription(answer);

      // Send answer
      _chatHandler.emit('webrtc_answer', {
        'answer': {'sdp': answer.sdp, 'type': answer.type},
        'callId': callData.callId,
        'groupId': callData.groupId,
        'toUserId': fromUserId,
        'fromUserId': _currentUserId,
      });

      // Update call data
      _activeCall = callData.copyWith(
        status: CallStatus.active,
        participants: [
          ...callData.participants,
          CallParticipant(
            id: _currentUserId,
            name: 'You',
            avatar: '',
            role: ParticipantRole.callee,
            isAudioMuted: false,
            isVideoMuted: callData.type != CallType.video,
          ),
        ],
      );

      _isCallActive = true;
      _showCallModal = true;
      onCallStarted?.call(_activeCall!);
      notifyListeners();

      logger.i('✅ Answer sent to user $fromUserId');
    } catch (e) {
      logger.e('❌ Error handling remote offer: $e');
      rethrow;
    }
  }

  // Handle remote answer (matching web handleRemoteAnswer)
  Future<void> _handleRemoteAnswer(
    RTCSessionDescription answer,
    int fromUserId,
  ) async {
    try {
      logger.i('📨 Handling remote answer from user $fromUserId');

      final pc = _peerConnections[fromUserId];
      if (pc != null) {
        await pc.setRemoteDescription(answer);
        logger.i('✅ Remote answer applied from user $fromUserId');
      } else {
        logger.e('❌ No peer connection found for user $fromUserId');
      }
    } catch (e) {
      logger.e('❌ Error handling remote answer: $e');
    }
  }

  // Handle remote ICE candidate (matching web handleRemoteICECandidate)
  Future<void> _handleRemoteICECandidate(
    RTCIceCandidate candidate,
    int fromUserId,
  ) async {
    try {
      logger.i('🧊 Handling remote ICE candidate from user $fromUserId');

      final pc = _peerConnections[fromUserId];
      if (pc != null) {
        await pc.addCandidate(candidate);
        logger.i('✅ ICE candidate added from user $fromUserId');
      } else {
        logger.e('❌ No peer connection found for user $fromUserId');
      }
    } catch (e) {
      logger.e('❌ Error handling ICE candidate: $e');
    }
  }

  // Handle incoming call via WebSocket (for calls initiated from web)
  void _handleIncomingCallViaWebSocket(CallData callData) {
    logger.i(
      '📨 Incoming call from WebSocket ${_activeCall == null && _incomingCall == null} ${_activeCall == null} ${_incomingCall == null}',
    );

    // Only handle if not already in a call
    if (_activeCall == null) { // && _incomingCall == null
      _incomingCall = callData;
      onIncomingCall?.call(callData);
      notifyListeners();
    }
  }

  // Answer call (matching web answerCall)
  Future<void> answerCall() async {
    if (_incomingCall == null) {
      logger.e('❌ No incoming call to answer');
      return;
    }

    try {
      logger.i('📞 Answering incoming call');

      // Send answer to server via WebSocket
      _chatHandler.emit('call_answer', {
        'callId': _incomingCall!.callId,
        'fromUserId': _currentUserId,
      });

      // The actual WebRTC connection will be established
      // when we receive the offer from the caller via WebSocket

      logger.i('✅ Call answered');
    } catch (e) {
      logger.e('❌ Error answering call: $e');
      await _cleanupAll();
    }
  }

  // Join existing call (matching web joinCall)
  Future<void> joinCall(CallData callData) async {
    try {
      logger.i('🚀 Joining existing call: ${callData.type} call');

      await _cleanupAll();

      final stream = await _getUserMedia(callData.type);
      _localStream = stream;

      _activeCall = callData.copyWith(
        status: CallStatus.active,
        participants: [
          ...callData.participants,
          CallParticipant(
            id: _currentUserId,
            name: 'You',
            avatar: '',
            role: ParticipantRole.participant,
            isAudioMuted: false,
            isVideoMuted: callData.type != CallType.video,
          ),
        ],
      );

      _showCallModal = true;

      // Notify server we're joining
      _chatHandler.emit('user_joined_call', {
        'callId': callData.callId,
        'userId': _currentUserId,
        'userName': _currentUserName,
      });

      // Create offers for existing participants
      final existingParticipants = callData.participants
          .where((p) => p.id != _currentUserId)
          .map((p) => p.id)
          .toList();

      logger.i(
        '🎯 Creating offers for ${existingParticipants.length} existing participants',
      );

      for (final participantId in existingParticipants) {
        try {
          await _createOfferForUser(participantId);
          await Future.delayed(
            Duration(milliseconds: 500),
          ); // Delay between offers
        } catch (error) {
          logger.e(
            '❌ Failed to create offer for participant $participantId: $error',
          );
        }
      }

      notifyListeners();
      logger.i('✅ Joined call successfully');
    } catch (error) {
      logger.e('❌ Error joining call: $error');
      await _cleanupAll();
      rethrow;
    }
  }

  // End call (matching web endCall)
  Future<void> endCall() async {
    logger.i('🎬 Ending call');

    if (_activeCall != null) {
      // Notify other participants
      _chatHandler.emit('user_left_call', {
        'callId': _activeCall!.callId,
        'userId': _currentUserId,
      });

      // Send call end notification
      _chatHandler.emit('call_ended', {
        'callId': _activeCall!.callId,
        'userId': _currentUserId,
        'fromUserId': _currentUserId,
      });
    }

    await _cleanupAll();
    onCallEnded?.call(
      _activeCall ??
          CallData(
            callId: '',
            groupId: 0,
            groupName: '',
            initiator: 0,
            initiatorId: '0',
            initiatorName: '',
            startedAt: DateTime.now(),
            type: CallType.audio,
            participants: [],
            status: CallStatus.ended,
          ),
    );
  }

  // Reject call (matching web rejectCall)
  Future<void> rejectCall() async {
    logger.i('❌ Rejecting call');

    if (_incomingCall != null) {
      _chatHandler.emit('call_rejected', {
        'callId': _incomingCall!.callId,
        'userId': _currentUserId,
        'fromUserId': _currentUserId,
      });
    }

    await _cleanupAll();
  }

  // Add participant (matching web addParticipant)
  Future<void> addParticipant(int userId) async {
    if (_activeCall == null) {
      logger.e('❌ No active call to add participant to');
      return;
    }

    try {
      await _createOfferForUser(userId);

      final updatedParticipants = [
        ..._activeCall!.participants,
        CallParticipant(
          id: userId,
          name: 'User $userId',
          avatar: '',
          role: ParticipantRole.participant,
          isAudioMuted: false,
          isVideoMuted: false,
        ),
      ];

      _activeCall = _activeCall!.copyWith(participants: updatedParticipants);
      notifyListeners();

      logger.i('✅ Added participant $userId to call');
    } catch (e) {
      logger.e('❌ Error adding participant $userId: $e');
    }
  }

  // Toggle audio (matching web toggleAudio)
  Future<void> toggleAudio() async {
    if (_localStream == null) return;

    final audioTracks = _localStream!.getAudioTracks();
    final newMutedState = !_isAudioMuted;

    audioTracks.forEach((track) => track.enabled = !newMutedState);
    _isAudioMuted = newMutedState;

    logger.i('🔊 Audio ${newMutedState ? 'muted' : 'unmuted'}');

    // Send mute status to all participants (matching web)
    _dataChannels.forEach((userId, dc) {
      if (dc.state == RTCDataChannelState.RTCDataChannelOpen) {
        dc.send(
          RTCDataChannelMessage(
            json.encode({
              'type': 'mute_audio',
              'muted': newMutedState,
              'userId': _currentUserId,
            }),
          ),
        );
      }
    });

    // Update call data
    if (_activeCall != null) {
      final updatedParticipants = _activeCall!.participants.map((p) {
        if (p.id == _currentUserId) {
          return p..isAudioMuted = newMutedState;
        }
        return p;
      }).toList();

      _activeCall = _activeCall!.copyWith(participants: updatedParticipants);
    }

    onAudioMuted?.call(newMutedState);
    notifyListeners();
  }

  // Toggle video (matching web toggleVideo)
  Future<void> toggleVideo() async {
    if (_localStream == null) return;

    final videoTracks = _localStream!.getVideoTracks();
    if (videoTracks.isEmpty) return;

    final newMutedState = !_isVideoMuted;
    videoTracks.forEach((track) => track.enabled = !newMutedState);
    _isVideoMuted = newMutedState;

    logger.i('📹 Video ${newMutedState ? 'muted' : 'unmuted'}');

    // Send mute status to all participants (matching web)
    _dataChannels.forEach((userId, dc) {
      if (dc.state == RTCDataChannelState.RTCDataChannelOpen) {
        dc.send(
          RTCDataChannelMessage(
            json.encode({
              'type': 'mute_video',
              'muted': newMutedState,
              'userId': _currentUserId,
            }),
          ),
        );
      }
    });

    // Update call data
    if (_activeCall != null) {
      final updatedParticipants = _activeCall!.participants.map((p) {
        if (p.id == _currentUserId) {
          return p..isVideoMuted = newMutedState;
        }
        return p;
      }).toList();

      _activeCall = _activeCall!.copyWith(participants: updatedParticipants);
    }

    onVideoMuted?.call(newMutedState);
    notifyListeners();
  }

  // Handle remote events
  void _handleCallAnswered(dynamic data) {
    logger.i('📞 Remote participant answered call');
    // Update UI if needed
  }

  void _handleCallRejected(dynamic data) {
    logger.i('📞 Remote participant rejected call');
    if (_incomingCall?.callId == data['callId']) {
      _incomingCall = null;
      notifyListeners();
    }
  }

  void _handleCallEnded(dynamic data) {
    logger.i('📞 Remote participant ended call');
    endCall();
  }

  void _handleUserJoinedCall(dynamic data) {
    final userId = data['userId'];
    final callId = data['callId'];

    logger.i('👋 User $userId joined call $callId');

    if (_activeCall != null &&
        _activeCall!.callId == callId &&
        userId != _currentUserId) {
      // Add this user to our call
      addParticipant(userId);
    }
  }

  void _handleUserLeftCall(dynamic data) {
    final userId = data['userId'];
    final callId = data['callId'];

    logger.i('👋 User $userId left call $callId');

    if (_activeCall != null && _activeCall!.callId == callId) {
      // Remove this user from our call
      _cleanupParticipant(userId);

      // Update participants list
      final updatedParticipants = _activeCall!.participants
          .where((p) => p.id != userId)
          .toList();

      _activeCall = _activeCall!.copyWith(participants: updatedParticipants);
      notifyListeners();
    }
  }

  // Cleanup participant (matching web cleanupParticipant)
  Future<void> _cleanupParticipant(int userId) async {
    logger.i('🧹 Cleaning up participant $userId');

    // Clear timers
    _connectionTimers[userId]?.cancel();
    _connectionTimers.remove(userId);
    _reconnectAttempts.remove(userId);

    // Close peer connection
    final pc = _peerConnections[userId];
    if (pc != null) {
      await pc.close();
      _peerConnections.remove(userId);
    }

    // Close data channel
    final dc = _dataChannels[userId];
    if (dc != null) {
      if (dc.state == RTCDataChannelState.RTCDataChannelOpen ||
          dc.state == RTCDataChannelState.RTCDataChannelConnecting) {
        dc.close();
      }
      _dataChannels.remove(userId);
    }

    // Remove remote stream
    final stream = _remoteStreams[userId];
    if (stream != null) {
      stream.getTracks().forEach((track) => track.stop());
      _remoteStreams.remove(userId);
      onRemoteStreamsUpdated?.call(Map.from(_remoteStreams));
    }

    // Remove from active call participants
    if (_activeCall != null) {
      final updatedParticipants = _activeCall!.participants
          .where((p) => p.id != userId)
          .toList();

      _activeCall = _activeCall!.copyWith(participants: updatedParticipants);
    }

    logger.i('✅ Participant $userId cleaned up');
    notifyListeners();
  }

  // Comprehensive cleanup (matching web cleanupAll)
  Future<void> _cleanupAll() async {
    logger.i('🧹 Starting comprehensive cleanup');

    // Cleanup all participants
    final userIds = _peerConnections.keys.toList();
    for (final userId in userIds) {
      await _cleanupParticipant(userId);
    }

    // Cleanup local stream
    if (_localStream != null) {
      _localStream!.getTracks().forEach((track) => track.stop());
      _localStream = null;
    }

    // Reset state
    _isAudioMuted = false;
    _isVideoMuted = false;
    _isCallActive = false;
    _showCallModal = false;
    _connectionState = 'disconnected';
    _iceConnectionState = 'disconnected';
    _incomingCall = null;
    _activeCall = null;

    logger.i('✅ Comprehensive cleanup completed');
    notifyListeners();
  }

  // UI control methods
  void setShowCallModal(bool value) {
    _showCallModal = value;
    notifyListeners();
  }

  void setIncomingCall(CallData? callData) {
    print("Incoming call from WebSocket?? ${callData?.toJson()}");
    if (callData != null) _handleIncomingCallViaWebSocket(callData);
    notifyListeners();
  }

  // Dispose
  Future<void> dispose() async {
    logger.i('🔴 WebRTCManager disposing');
    await _cleanupAll();
    _connectionTimers.values.forEach((timer) => timer.cancel());
    _connectionTimers.clear();
  }
}
