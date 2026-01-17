// lib/models/call_models.dart
import 'package:flutter/foundation.dart';

enum CallType { audio, video }

enum CallStatus { ringing, active, ended, missed, rejected }

enum ParticipantRole { caller, callee, participant }

class CallParticipant {
  final int id;
  final String? avatar;
  final String name;
  final ParticipantRole? role;
  bool? isAudioMuted;
  bool? isVideoMuted;
  final int? socketId;

  CallParticipant({
    required this.id,
    required this.name,
    required this.avatar,
    required this.role,
    this.isAudioMuted = false,
    this.isVideoMuted = false,
    this.socketId,
  });

  factory CallParticipant.fromJson(Map<String, dynamic> json) {
    return CallParticipant(
      id: json['id'] ?? json['userId'],
      name: json['name'] ?? json['userName'] ?? '',
      avatar: json['avatar'] ?? '',
      role: json['role'] != null
          ? ParticipantRole.values.firstWhere(
              (e) => e.toString().split('.').last == json['role'],
              orElse: () => ParticipantRole.participant,
            )
          : ParticipantRole.participant,
      isAudioMuted: json['isAudioMuted'] ?? false,
      isVideoMuted: json['isVideoMuted'] ?? false,
      socketId: json['socketId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'role': role.toString().split('.').last,
      'isAudioMuted': isAudioMuted,
      'isVideoMuted': isVideoMuted,
      'socketId': socketId,
    };
  }
}

class CallData {
  final String callId;
  final int groupId;
  final String? groupName;
  final int initiator;
  final String initiatorId;
  final String initiatorName;
  final CallType type;
  final List<CallParticipant> participants;
  CallStatus status;
  final DateTime startedAt;

  CallData({
    required this.callId,
    required this.groupId,
    required this.groupName,
    required this.initiator,
    required this.initiatorId,
    required this.initiatorName,
    required this.type,
    required this.startedAt,
    required this.participants,
    this.status = CallStatus.ringing,
  });

  factory CallData.fromJson(Map<String, dynamic> json) {
    debugPrint("CallData JSON: $json");

    return CallData(
      callId: json['callId'],
      groupId: json['groupId'],
      groupName: json['groupName'] ?? 'Test Group',
      initiator: json['initiator'],
      initiatorId: (json['initiatorId'] ?? json['initiator'] ?? '').toString(),
      initiatorName: json['initiatorName'] ?? json['userName'] ?? '',
      type: CallType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => CallType.audio,
      ),
      participants: (json['participants'] as List<dynamic>? ?? [])
          .map((p) => CallParticipant.fromJson(p))
          .toList(),
      status: CallStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => CallStatus.ringing,
      ),
      startedAt: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'callId': callId,
      'groupId': groupId,
      'groupName': groupName,
      'initiator': initiator,
      'initiatorId': initiatorId,
      'initiatorName': initiatorName,
      'type': type.toString().split('.').last,
      'participants': participants.map((p) => p.toJson()).toList(),
      'status': status.toString().split('.').last,
      'timestamp': startedAt.toIso8601String(),
    };
  }
}

// Extension for copyWith
extension CallDataCopyWith on CallData {
  CallData copyWith({
    String? callId,
    int? groupId,
    String? groupName,
    int? initiator,
    String? initiatorId,
    String? initiatorName,
    CallType? type,
    List<CallParticipant>? participants,
    CallStatus? status,
    DateTime? startedAt,
  }) {
    return CallData(
      callId: callId ?? this.callId,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      initiator: initiator ?? this.initiator,
      initiatorId: initiatorId ?? this.initiatorId,
      initiatorName: initiatorName ?? this.initiatorName,
      type: type ?? this.type,
      participants: participants ?? this.participants,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
    );
  }
}
