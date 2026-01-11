// lib/services/callkit_integration.dart
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:hoop/dtos/podos/calls/call_models.dart';
import 'package:hoop/states/webrtc_manager.dart';
import 'package:uuid/uuid.dart';

class CallKitIntegration {
  static final CallKitIntegration _instance = CallKitIntegration._internal();
  factory CallKitIntegration() => _instance;
  CallKitIntegration._internal();

  final WebRTCManager _webrtcManager = WebRTCManager();
  String? _activeCallKitId;

  // Initialize
  Future<void> initialize(WebRTCManager webrtcManager) async {
    // Setup CallKit event listeners
    await _setupCallKit();

    // Setup WebRTC callbacks
    webrtcManager.onIncomingCall = handleIncomingCallFromWebRTC;
    webrtcManager.onCallStarted = _handleCallStartedFromWebRTC;
    webrtcManager.onCallEnded = _handleCallEndedFromWebRTC;
  }

  Future<void> _setupCallKit() async {
    FlutterCallkitIncoming.onEvent.listen((CallEvent? event) {
      switch (event?.event) {
        case Event.actionCallIncoming:
          print('📞 CallKit: Incoming call');
          _handleCallKitCallStart(event!.body!);
          break;
        case Event.actionCallAccept:
          print('📞 CallKit: Call accepted');
          _handleCallKitCallAccept(event!.body!);
          break;
        case Event.actionCallDecline:
          print('📞 CallKit: Call declined');
          _handleCallKitCallDecline(event!.body!);
          break;
        case Event.actionCallEnded:
          print('📞 CallKit: Call ended');
          _handleCallKitCallEnded(event!.body!);
          break;
        case Event.actionCallTimeout:
          print('📞 CallKit: Call timeout');
          _handleCallKitCallTimeout(event!.body!);
          break;
        default:
          break;
      }
    });
  }

  // Handle incoming call from WebRTC
  Future<void> handleIncomingCallFromWebRTC(CallData callData) async {
    print('📞 Handling incoming call from WebRTC: ${callData.callId}');

    final Uuid _uuid = Uuid();
    final params = CallKitParams(
      id: _uuid.v4(),
      nameCaller: callData.initiatorName,
      appName: 'Hoop Africa',
      avatar:
          'https://png.pngtree.com/png-clipart/20230927/original/pngtree-man-avatar-image-for-profile-png-image_13001877.png',
      handle: '+1 (555) 123-4567',
      type: callData.type == CallType.video ? 1 : 0,
      duration: 45000,
      textAccept: 'Hooper',
      textDecline: 'Decline',
      // textMissedCall: 'Missed call',
      // textCallback: 'Call back',
      callingNotification: NotificationParams(
        callbackText: 'Call Hoop Back',
        count: 1,

        isShowCallback: true,
        subtitle: 'Test Calling...',
        showNotification: true,
      ),
      extra: <String, dynamic>{
        'userId': 'test_user_123',
        'callType':  callData.type == CallType.video ? 'video' : 'voice',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      ios: IOSParams(
        iconName: 'CallKitLogo',
        handleType: 'generic',
        supportsVideo: true,
        maximumCallGroups: 2,
        maximumCallsPerCallGroup: 1,
        audioSessionMode: 'default',
        audioSessionActive: true,
        audioSessionPreferredSampleRate: 44100.0,
        audioSessionPreferredIOBufferDuration: 0.005,
        supportsDTMF: true,
        supportsHolding: true,
        supportsGrouping: false,
        supportsUngrouping: false,
        ringtonePath: 'system_ringtone_default',
      ),
      android: AndroidParams(
        isCustomNotification: true,
        isShowLogo: true,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#7C3AED',
        backgroundUrl:
            'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=500',
        actionColor: '#10B981',
        incomingCallNotificationChannelName: 'Incoming Calls',
        missedCallNotificationChannelName: 'Missed Calls',
      ),
      missedCallNotification: NotificationParams(
        showNotification: true,
        isShowCallback: true,
        subtitle: 'Missed call from Test',
        callbackText: 'Call back',
      ),
    );

    // final params = CallKitParams(
    //   id: callData.callId,
    //   nameCaller: callData.participants
    //       .firstWhere((p) => p.id == callData.initiator)
    //       .name,
    //   appName: 'Hoop Africa',
    //   // avatar: '',
    //   handle: 'Group: ${callData.groupName ?? 'Test'}',
    //   type: callData.type == CallType.video ? 1 : 0,
    //   duration: 45000,
    //   textAccept: 'Hooper',
    //   callingNotification: NotificationParams(
    //     callbackText: 'Call back',
    //     showNotification: true,
    //     isShowCallback: true,
    //   ),
    //   missedCallNotification: NotificationParams(
    //     callbackText: 'Missed Call',
    //     isShowCallback: true,
    //     showNotification: true,
    //   ),

    //   textDecline: 'Decline',
    //   // textMissedCall: 'Missed call',
    //   // textCallback: 'Call back',
    //   extra: <String, dynamic>{
    //     'callData': callData.toJson(),
    //     'callType': callData.type == CallType.video ? 'video' : 'audio',
    //     'groupId': callData.groupId,
    //     'initiator': callData.initiator,
    //   },
    //   ios: IOSParams(
    //     iconName: 'CallKitLogo',
    //     handleType: 'generic',
    //     supportsVideo: callData.type == CallType.video,
    //     maximumCallGroups: 2,
    //     maximumCallsPerCallGroup: 1,
    //     audioSessionMode: 'default',
    //     audioSessionActive: true,
    //     audioSessionPreferredSampleRate: 44100.0,
    //     configureAudioSession: true,
    //     audioSessionPreferredIOBufferDuration: 0.005,
    //     supportsDTMF: true,
    //     supportsHolding: true,
    //     supportsGrouping: true,
    //     supportsUngrouping: true,
    //     // ringtonePath: 'system_ringtone_default',
    //   ),
    //   android: AndroidParams(
    //     isCustomNotification: true,
    //     isShowLogo: true,
    //     // textColor: HoopTheme.primaryBlue.toString(),
    //     // isShowCallback: true,
    //     // isShowMissedCallNotification: true,
    //     ringtonePath: 'system_ringtone_default',
    //     backgroundColor: '#7C3AED',
    //     backgroundUrl: '',
    //     actionColor: '#10B981',
    //     incomingCallNotificationChannelName: 'Incoming Calls',
    //     missedCallNotificationChannelName: 'Missed Calls',
    //   ),
    // );

    await FlutterCallkitIncoming.showCallkitIncoming(params);
    _activeCallKitId = callData.callId;
  }

  // Handle call start from WebRTC
  Future<void> _handleCallStartedFromWebRTC(CallData callData) async {
    print('📞 Call started via WebRTC: ${callData.callId}');
    // Update CallKit UI if needed for outgoing calls
    if (_activeCallKitId == null) {
      // Show outgoing call UI
      final params = CallKitParams(
        id: callData.callId,
        nameCaller: 'You',
        appName: 'Hoop Calls',
        avatar: '',
        handle: 'Group: ${callData.groupName}',
        type: callData.type == CallType.video ? 1 : 0,
        extra: <String, dynamic>{
          'callData': callData.toJson(),
          'callType': callData.type == CallType.video ? 'video' : 'audio',
          'groupId': callData.groupId,
          'initiator': callData.initiator,
        },
        ios: IOSParams(
          iconName: 'CallKitLogo',
          handleType: 'generic',
          supportsVideo: callData.type == CallType.video,
          maximumCallGroups: 2,
          maximumCallsPerCallGroup: 1,
          audioSessionMode: 'default',
          audioSessionActive: true,
          audioSessionPreferredSampleRate: 44100.0,
          audioSessionPreferredIOBufferDuration: 0.005,
          supportsDTMF: false,
          supportsHolding: false,
          supportsGrouping: false,
          supportsUngrouping: false,
        ),
      );

      await FlutterCallkitIncoming.startCall(params);
      _activeCallKitId = callData.callId;
    }
  }

  // Handle call end from WebRTC
  Future<void> _handleCallEndedFromWebRTC(CallData callData) async {
    print('📞 Call ended via WebRTC: ${callData.callId}');
    if (_activeCallKitId == callData.callId) {
      await FlutterCallkitIncoming.endCall(callData.callId);
      _activeCallKitId = null;
    }
  }

  // Handle CallKit events
  Future<void> _handleCallKitCallStart(Map<String, dynamic> body) async {
    final callId = body['id'];
    final extra = body['extra'] as Map<String, dynamic>?;

    if (extra != null && extra.containsKey('callData')) {
      final callDataJson = extra['callData'] as Map<String, dynamic>;
      final callData = CallData.fromJson(callDataJson);
      print('📞 CallKit: Starting WebRTC call ${callData.callId}');

      // The WebRTC manager should already have received this via WebSocket
    }
  }

  Future<void> _handleCallKitCallAccept(Map<String, dynamic> body) async {
    final callId = body['id'];
    print('📞 CallKit: Accepting call $callId');

    // Answer the WebRTC call
    _webrtcManager.answerCall();
  }

  Future<void> _handleCallKitCallDecline(Map<String, dynamic> body) async {
    final callId = body['id'];
    print('📞 CallKit: Declining call $callId');

    // Reject the WebRTC call
    _webrtcManager.rejectCall();

    // End CallKit call
    await FlutterCallkitIncoming.endCall(callId);
    _activeCallKitId = null;
  }

  Future<void> _handleCallKitCallEnded(Map<String, dynamic> body) async {
    final callId = body['id'];
    print('📞 CallKit: Call ended $callId');

    // End WebRTC call
    _webrtcManager.endCall();
    _activeCallKitId = null;
  }

  Future<void> _handleCallKitCallTimeout(Map<String, dynamic> body) async {
    final callId = body['id'];
    print('📞 CallKit: Call timeout $callId');

    // Cleanup WebRTC
    _webrtcManager.endCall();
    _activeCallKitId = null;
  }

  // Cleanup
  Future<void> dispose() async {
    await FlutterCallkitIncoming.endAllCalls();
  }
}
