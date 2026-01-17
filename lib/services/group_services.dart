// lib/services/group_http_service.dart
import 'package:hoop/constants/strings.dart';
import 'package:hoop/dtos/podos/tokens/token_manager.dart';
import 'package:hoop/dtos/responses/ApiResponse.dart';
import 'package:hoop/dtos/responses/GeneralResponse/paginated_response.dart';
import 'package:hoop/dtos/responses/SpotlightVideo.dart';
import 'package:hoop/dtos/responses/group/group_join_request.dart';
import 'package:hoop/dtos/responses/group/index.dart';
import 'package:hoop/screens/groups/create_group.dart';
import 'package:hoop/services/base_http.dart';

// Create group request model

class GroupHttpService extends BaseHttpService {
  GroupHttpService() : super(baseUrl: BASE_URL);

  // ========== GROUP MANAGEMENT ==========

  // Get groups with pagination
  Future<ApiResponse<PaginatedResponse<Group>>> getGroups({
    int page = 1,
    int limit = 20,
  }) async {
    return getTyped<PaginatedResponse<Group>>(
      'groups',
      queryParameters: {'page': page, 'limit': limit},
      fromJson: (json) => PaginatedResponse<Group>.fromJson(
        json,
        (item) => Group.fromJson(item),
      ),
    );
  }

  // Get group details
  Future<ApiResponse<GroupDetails>> getGroup(String id) async {
    return getTyped<GroupDetails>(
      'groups/$id',
      fromJson: (json) => GroupDetails.fromJson(json),
    );
  }

  // Get public group details
  Future<ApiResponse<GroupDetailsPublic>> getGroupPublic(int id) async {
    return getTyped<GroupDetailsPublic>(
      'groups/public/$id',
      fromJson: (json) => GroupDetailsPublic.fromJson(json),
    );
  }

  // Create group
  Future<ApiResponse<Group>> createGroup(Map<String, dynamic> groupData) async {
    print("groupData?? $groupData");
    return postTyped<Group>(
      'groups/create',
      body: groupData,
      fromJson: (json) => Group.fromJson(json),
    );
  }

  // Get my groups
  Future<ApiResponse<PaginatedResponse<Group>>> getMyGroup({
    int page = 0,
    int limit = 20,
    String? tab,
  }) async {
    final params = {'page': page, 'size': limit, if (tab != null) 'tab': tab};

    return getTyped<PaginatedResponse<Group>>(
      'groups/my-groups',
      queryParameters: params,
      fromJson: (json) => PaginatedResponse<Group>.fromJson(
        json,
        (item) => Group.fromJson(item),
      ),
    );
  }

  // Get my group counts
  Future<ApiResponse<Map<String, int>>> getMyGroupCounts() async {
    return getTyped<Map<String, int>>(
      'groups/my-groups/counts',
      fromJson: (json) => {
        'current': json['current'] ?? 0,
        'finished': json['finished'] ?? 0,
        'pending': json['pending'] ?? 0,
        'rejected': json['rejected'] ?? 0,
      },
    );
  }

  // Get spotlight videos
  Future<ApiResponse<List<SpotlightVideo>>> getSpotlightService() async {
    return getTyped<List<SpotlightVideo>>(
      'spotlight',
      fromJson: (json) {
        if (json is List) {
          return json.map((item) => SpotlightVideo.fromJson(item)).toList();
        }
        return [];
      },
    );
  }

  // Update group
  Future<ApiResponse<Group>> updateGroup(
    String id,
    Map<String, dynamic> updates,
  ) async {
    return patchTyped<Group>(
      'groups/$id',
      body: updates,
      fromJson: (json) => Group.fromJson(json),
    );
  }

  // Delete group
  Future<ApiResponse<Map<String, dynamic>>> deleteGroup(String id) async {
    return deleteTyped<Map<String, dynamic>>(
      'groups/$id',
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  // Start group
  Future<ApiResponse<Group>> startGroup(String id) async {
    return postTyped<Group>(
      'groups/$id/start',
      fromJson: (json) => Group.fromJson(json),
    );
  }

  // Finalize group
  Future<ApiResponse<Group>> finalizeGroup(
    String id,
    List<Map<String, dynamic>> payoutOrder,
  ) async {
    return postTyped<Group>(
      'payout-order/group/$id/finalize',
      body: {'payoutOrder': payoutOrder},
      fromJson: (json) => Group.fromJson(json),
    );
  }

  // Update allow group message
  Future<ApiResponse<Group>> updateAllowGroupMessage(
    int groupId,
    bool value,
  ) async {
    return patchTyped<Group>(
      'groups/$groupId/allow-message',
      body: {'value': value},
      fromJson: (json) => Group.fromJson(json),
    );
  }

  // Update allow group video call
  Future<ApiResponse<Group>> updateAllowGroupVideoCall(
    int groupId,
    bool value,
  ) async {
    return patchTyped<Group>(
      'groups/$groupId/allow-video-call',
      body: {'value': value},
      fromJson: (json) => Group.fromJson(json),
    );
  }

  // ========== COMMUNITY PREFERENCES ==========

  // Get preferences
  Future<ApiResponse<CommunityPreferences>> getPreferences() async {
    return getTyped<CommunityPreferences>(
      'community/preferences',
      fromJson: (json) => CommunityPreferences.fromJson(json),
    );
  }

  // Update preferences
  Future<ApiResponse<CommunityPreferences>> updatePreferences(
    Map<String, dynamic> preferences,
  ) async {
    return putTyped<CommunityPreferences>(
      'community/preferences',
      body: preferences,
      fromJson: (json) => CommunityPreferences.fromJson(json),
    );
  }

  // Reset preferences
  Future<ApiResponse<CommunityPreferences>> resetPreferences() async {
    return postTyped<CommunityPreferences>(
      'community/preferences/reset',
      fromJson: (json) => CommunityPreferences.fromJson(json),
    );
  }

  // Check preferences exist
  Future<ApiResponse<bool>> checkPreferencesExist() async {
    return getTyped<bool>(
      'community/preferences/exists',
      fromJson: (json) => json as bool,
    );
  }

  // ========== COMMUNITY GROUPS ==========

  // Get personalized groups
  Future<ApiResponse<PaginatedResponse<GroupWithScore>>> getPersonalizedGroups({
    double? lat,
    double? lng,
    int page = 0,
    int size = 10,
  }) async {
    final params = {
      'page': page,
      'size': size,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
    };

    return getTyped<PaginatedResponse<GroupWithScore>>(
      'community/groups',
      queryParameters: params,
      fromJson: (json) => PaginatedResponse<GroupWithScore>.fromJson(
        json,
        (item) => GroupWithScore.fromJson(item),
      ),
    );
  }

  // Get community groups
  Future<ApiResponse<PaginatedResponse<GroupWithScore>>> getCommunityGroups({
    double? lat,
    double? lng,
    int page = 0,
    int size = 10,
  }) async {
    final params = {
      'page': page,
      'size': size,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
    };

    return getTyped<PaginatedResponse<GroupWithScore>>(
      'community/groups',
      queryParameters: params,
      fromJson: (json) => PaginatedResponse<GroupWithScore>.fromJson(
        json,
        (item) => GroupWithScore.fromJson(item),
      ),
      requiresAuth: true
    );
  }

  // ========== GROUP MEMBERSHIP ==========

  // Join group
  Future<ApiResponse<GroupMember>> joinGroup(
    String groupId, {
    String? message,
    int slots = 1,
  }) async {
    print("'groups/$groupId/join'?? $message, $slots");
    return postTyped<GroupMember>(
      'groups/$groupId/join',
      body: {'message': message, 'slots': slots},
      fromJson: (json) => GroupMember.fromJson(json),
    );
  }

  // Leave group
  Future<ApiResponse<Map<String, dynamic>>> leaveGroup(String groupId) async {
    return deleteTyped<Map<String, dynamic>>(
      'groups/$groupId/leave',
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  // Get group members
  Future<ApiResponse<List<GroupMember>>> getGroupMembers(String groupId) async {
    return getTyped<List<GroupMember>>(
      'groups/$groupId/members',
      fromJson: (json) {
        if (json is List) {
          return json.map((item) => GroupMember.fromJson(item)).toList();
        }
        return [];
      },
    );
  }

  // Remove member
  Future<ApiResponse<Map<String, dynamic>>> removeMember(
    String groupId,
    String userId,
  ) async {
    return deleteTyped<Map<String, dynamic>>(
      'groups/$groupId/members/$userId',
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  // ========== PAYOUT ORDER MANAGEMENT ==========

  // Get payout order
  Future<ApiResponse<List<PayoutOrderItem>>> getPayoutOrder(
    String groupId, {
    int cycleNumber = 1,
  }) async {
    return getTyped<List<PayoutOrderItem>>(
      'groups/$groupId/payout-order',
      queryParameters: {'cycleNumber': cycleNumber},
      fromJson: (json) {
        if (json is List) {
          return json.map((item) => PayoutOrderItem.fromJson(item)).toList();
        }
        return [];
      },
    );
  }

  // Get payout order group
  Future<ApiResponse<Map<String, dynamic>>> getPayoutOrderGroup(
    String groupId,
  ) async {
    return getTyped<Map<String, dynamic>>(
      'payout-order/group/$groupId',
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  // Set payout order
  Future<ApiResponse<List<PayoutOrderItem>>> setPayoutOrder(
    String groupId,
    List<String> memberIds, {
    int cycleNumber = 1,
  }) async {
    return postTyped<List<PayoutOrderItem>>(
      'groups/$groupId/payout-order',
      body: {'memberIds': memberIds, 'cycleNumber': cycleNumber},
      fromJson: (json) {
        if (json is List) {
          return json.map((item) => PayoutOrderItem.fromJson(item)).toList();
        }
        return [];
      },
    );
  }

  // Move in payout order
  Future<ApiResponse<List<PayoutOrderItem>>> moveInPayoutOrder(
    String groupId,
    String memberId,
    int newPosition, {
    int cycleNumber = 1,
  }) async {
    return patchTyped<List<PayoutOrderItem>>(
      'groups/$groupId/payout-order/$memberId/position',
      body: {'newPosition': newPosition, 'cycleNumber': cycleNumber},
      fromJson: (json) {
        if (json is List) {
          return json.map((item) => PayoutOrderItem.fromJson(item)).toList();
        }
        return [];
      },
    );
  }

  // Reset payout order
  Future<ApiResponse<List<PayoutOrderItem>>> resetPayoutOrder(
    String groupId, {
    int cycleNumber = 1,
  }) async {
    return postTyped<List<PayoutOrderItem>>(
      'groups/$groupId/payout-order/reset',
      body: {'cycleNumber': cycleNumber},
      fromJson: (json) {
        if (json is List) {
          return json.map((item) => PayoutOrderItem.fromJson(item)).toList();
        }
        return [];
      },
    );
  }

  // ========== GROUP JOIN REQUESTS ==========

  // Approve group request
  Future<ApiResponse<List<PayoutOrderItem>>> approveGroupRequest(
    String groupId,
    String requestId,
  ) async {
    return postTyped<List<PayoutOrderItem>>(
      'groups/$groupId/join-requests/$requestId/approve',
      fromJson: (json) {
        if (json is List) {
          return json.map((item) => PayoutOrderItem.fromJson(item)).toList();
        }
        return [];
      },
    );
  }

  // Reject group request
  Future<ApiResponse<Map<String, dynamic>>> rejectGroupRequest(
    String groupId,
    String requestId,
  ) async {
    return postTyped<Map<String, dynamic>>(
      'groups/$groupId/join-requests/$requestId/reject',
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  // Get my join requests
  Future<ApiResponse<List<GroupJoinRequest>>> getMyJoinRequests({
    required String status,
    int? page,
    int? limit,
  }) async {
    final params = {
      'status': status,
      if (page != null) 'page': page,
      if (limit != null) 'size': limit,
    };

    return getTyped<List<GroupJoinRequest>>(
      'groups/my-join-requests',
      queryParameters: params,
      fromJson: (json) => json.map(
        
        (item) => GroupJoinRequest.fromJson(item),
      ),
    );
  }

  // Get group join requests
  Future<ApiResponse<PaginatedResponse<JoinRequest>>> getGroupJoinRequests(
    String groupId, {
    int? page,
    int? limit,
  }) async {
    final params = {
      if (page != null) 'page': page,
      if (limit != null) 'size': limit,
    };

    return getTyped<PaginatedResponse<JoinRequest>>(
      'groups/$groupId/join-requests',
      queryParameters: params,
      fromJson: (json) => PaginatedResponse<JoinRequest>.fromJson(
        json,
        (item) => JoinRequest.fromJson(item),
      ),
    );
  }

  // ========== GROUP CONTRIBUTIONS ==========

  // Make contribution
  Future<ApiResponse<GroupContribution>> makeContribution(
    String groupId,
    double amount,
  ) async {
    return postTyped<GroupContribution>(
      'groups/$groupId/contribute',
      body: {'amount': amount},
      fromJson: (json) => GroupContribution.fromJson(json),
    );
  }

  // Get group contributions
  Future<ApiResponse<PaginatedResponse<GroupContribution>>>
  getGroupContributions(String groupId, {int page = 1}) async {
    return getTyped<PaginatedResponse<GroupContribution>>(
      'groups/$groupId/contributions',
      queryParameters: {'page': page},
      fromJson: (json) => PaginatedResponse<GroupContribution>.fromJson(
        json,
        (item) => GroupContribution.fromJson(item),
      ),
    );
  }

  // ========== GROUP INVITATIONS ==========

  // Invite to group
  Future<ApiResponse<List<GroupInvite>>> inviteToGroup(
    String groupId,
    List<Map<String, dynamic>> invites,
  ) async {
    return postTyped<List<GroupInvite>>(
      'groups/$groupId/invite',
      body: {'invites': invites},
      fromJson: (json) {
        if (json is List) {
          return json.map((item) => GroupInvite.fromJson(item)).toList();
        }
        return [];
      },
    );
  }

  // Get group invites
  Future<ApiResponse<List<GroupInvite>>> getGroupInvites(String groupId) async {
    return getTyped<List<GroupInvite>>(
      'groups/$groupId/invites',
      fromJson: (json) {
        if (json is List) {
          return json.map((item) => GroupInvite.fromJson(item)).toList();
        }
        return [];
      },
    );
  }

  // Respond to invite
  Future<ApiResponse<Map<String, dynamic>>> respondToInvite(
    String inviteId,
    String response,
  ) async {
    return postTyped<Map<String, dynamic>>(
      'groups/invites/$inviteId/respond',
      body: {'response': response},
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  // ========== GROUP STATISTICS ==========

  // Get group stats
  Future<ApiResponse<GroupStats>> getGroupStats(String groupId) async {
    return getTyped<GroupStats>(
      'groups/$groupId/stats',
      fromJson: (json) => GroupStats.fromJson(json),
    );
  }

  // Get my group stats
  Future<ApiResponse<Map<String, dynamic>>> getMyGroupStats() async {
    return getTyped<Map<String, dynamic>>(
      'groups/my/stats',
      fromJson: (json) => {
        'totalGroups': json['totalGroups'] ?? 0,
        'activeGroups': json['activeGroups'] ?? 0,
        'totalContributed': (json['totalContributed'] ?? 0).toDouble(),
        'completedGroups': json['completedGroups'] ?? 0,
      },
    );
  }
}

// Singleton instance
GroupHttpService? _groupServiceInstance;

GroupHttpService getGroupService({required String baseUrl}) {
  _groupServiceInstance ??= GroupHttpService();
  return _groupServiceInstance!;
}
