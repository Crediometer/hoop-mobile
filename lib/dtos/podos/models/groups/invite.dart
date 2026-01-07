import 'dart:convert';

import 'package:flutter/material.dart';

class GroupInviteLink {
  final String url;
  final DateTime expiresAt;
  final int usageCount;
  final int maxUsage;

  GroupInviteLink({
    required this.url,
    required this.expiresAt,
    required this.usageCount,
    required this.maxUsage,
  });

  Map<String, dynamic> toJson() => {
    'url': url,
    'expiresAt': expiresAt.toIso8601String(),
    'usageCount': usageCount,
    'maxUsage': maxUsage,
  };

  factory GroupInviteLink.fromJson(Map<String, dynamic> json) {
    return GroupInviteLink(
      url: json['url'],
      expiresAt: DateTime.parse(json['expiresAt']),
      usageCount: json['usageCount'],
      maxUsage: json['maxUsage'],
    );
  }
}

class ShareOption {
  final String name;
  final String url;
  final Color color;

  const ShareOption({
    required this.name,
    required this.url,
    required this.color,
  });
}