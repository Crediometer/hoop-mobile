// lib/providers/group_community_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hoop/constants/strings.dart';
import 'package:hoop/dtos/responses/ApiResponse.dart';
import 'package:hoop/dtos/responses/GeneralResponse/paginated_response.dart';
import 'package:hoop/dtos/responses/SpotlightVideo.dart';
import 'package:hoop/dtos/responses/User.dart';
import 'package:hoop/dtos/responses/group/index.dart';
import 'package:hoop/services/group_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GroupCommunityProvider extends ChangeNotifier {
  // Services
  final GroupHttpService _groupService = GroupHttpService();
  late SharedPreferences _prefs;

  // User State
  User? _user;
  bool _isLoading = true;

  // Groups State
  List<Group> _groups = [];
  GroupDetails? _currentGroup;
  GroupDetailsPublic? _currentPublicGroup;
  List<GroupMember> _groupMembers = [];
  List<GroupWithScore> _communities = [];
  List<GroupContribution> _groupContributions = [];
  GroupStats? _groupStats;

  // Pagination State
  int _currentPage = 1;
  int _groupsCurrentPage = 0;
  bool _hasMore = true;
  bool _groupsHasMore = true;
  bool _isFetching = false;

  // Join Requests State
  List<GroupJoinRequest> _joinRequests = [];
  int _joinRequestsCurrentPage = 0;
  bool _joinRequestsHasMore = true;

  // Spotlight State
  List<SpotlightVideo> _spotlight = [];
  bool _isFetchingSpotlight = false;

  // Community Preferences
  CommunityPreferences? _communityPreferences;
  bool _isLoadingPreferences = false;

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  List<Group> get groups => List.unmodifiable(_groups);
  GroupDetails? get currentGroup => _currentGroup;
  GroupDetailsPublic? get currentPublicGroup => _currentPublicGroup;
  List<GroupMember> get groupMembers => List.unmodifiable(_groupMembers);
  List<GroupWithScore> get communities => List.unmodifiable(_communities);
  List<GroupContribution> get groupContributions =>
      List.unmodifiable(_groupContributions);
  GroupStats? get groupStats => _groupStats;

  int get currentPage => _currentPage;
  int get groupsCurrentPage => _groupsCurrentPage;
  bool get hasMore => _hasMore;
  bool get groupsHasMore => _groupsHasMore;
  bool get isFetching => _isFetching;

  List<GroupJoinRequest> get joinRequests => List.unmodifiable(_joinRequests);
  int get joinRequestsCurrentPage => _joinRequestsCurrentPage;
  bool get joinRequestsHasMore => _joinRequestsHasMore;

  List<SpotlightVideo> get spotlight => List.unmodifiable(_spotlight);
  bool get isFetchingSpotlight => _isFetchingSpotlight;

  CommunityPreferences? get communityPreferences => _communityPreferences;
  bool get isLoadingPreferences => _isLoadingPreferences;

  // Initialize the provider
  Future<void> initialize({required GroupHttpService groupService}) async {
    _prefs = await SharedPreferences.getInstance();
    _isLoading = false;
    notifyListeners();
  }

  // Helper Methods
  String getAvatarGradient() {
    final gradients = [
      "bg-gradient-to-br from-pink-500 to-rose-500",
      "bg-gradient-to-br from-red-500 to-orange-500",
      "bg-gradient-to-br from-amber-500 to-yellow-500",
      "bg-gradient-to-br from-lime-500 to-green-500",
      "bg-gradient-to-br from-emerald-500 to-teal-500",
      "bg-gradient-to-br from-cyan-500 to-sky-500",
      "bg-gradient-to-br from-blue-500 to-indigo-500",
      "bg-gradient-to-br from-violet-500 to-purple-500",
      "bg-gradient-to-br from-fuchsia-500 to-pink-500",
      "bg-gradient-to-br from-slate-500 to-gray-500",
      "bg-gradient-to-br from-gray-500 to-gray-600",
      "bg-gradient-to-br from-vibrant-orange to-orange-400",
      "bg-gradient-to-br from-primary-blue to-blue-600",
      "bg-gradient-to-br from-success-green to-green-500",
      "bg-gradient-to-br from-purple-500 to-pink-500",
      "bg-gradient-to-br from-red-500 to-orange-500",
      "bg-gradient-to-br from-green-500 to-emerald-600",
    ];

    final randomIndex = DateTime.now().millisecond % gradients.length;
    return gradients[randomIndex];
  }

  String getAvatarColor(String groupName) {
    final colors = ["bg-light-orange", "bg-light-blue", "bg-light-green"];
    final firstLetter = groupName.isNotEmpty ? groupName[0].toUpperCase() : "A";
    final alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    final index = alphabet.indexOf(firstLetter);
    final colorIndex = index != -1 ? index % colors.length : 0;
    return colors[colorIndex];
  }


  String getGroupStatus(String groupStatus, String memberStatus) {
    if (memberStatus == 'PENDING') return 'pending';
    if (memberStatus == 'REJECTED') return 'rejected';
    if (groupStatus == 'ACTIVE' || groupStatus == 'FORMING') return 'current';
    if (groupStatus == 'COMPLETED' || groupStatus == 'ENDED') return 'finished';
    return 'pending';
  }

  // Group Management Methods
  Future<ApiResponse<Group>> createGroup(CreateGroupRequest groupData) async {
    try {
      final response = await _groupService.createGroup(groupData);
      if (response.success && response.data != null) {
        _groups.add(response.data!);
        notifyListeners();
      }
      return response;
    } catch (error) {
      rethrow;
    }
  }

  Future<ApiResponse<GroupDetails>> getGroup(String id) async {
    try {
      final response = await _groupService.getGroup(id);
      print("response???? ${response.data}");
      if (response.success && response.data != null) {
        _currentGroup = response.data;
        notifyListeners();
      }
      return response;
    } catch (error) {
      rethrow;
    }
  }

  Future<ApiResponse<GroupDetailsPublic>> getPublicGroup(String id) async {
    try {
      final response = await _groupService.getGroupPublic(id);
      if (response.success && response.data != null) {
        _currentPublicGroup = response.data;
        notifyListeners();
      }
      return response;
    } catch (error) {
      rethrow;
    }
  }

  Future<ApiResponse<Group>> updateGroup(
    String id,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _groupService.updateGroup(id, updates);
      if (response.success && response.data != null) {
        _groups = _groups.map((g) => g.id == id ? response.data! : g).toList();
        if (_currentGroup?.id == id) {
          _currentGroup = response.data as GroupDetails?;
        }
        notifyListeners();
      }
      return response;
    } catch (error) {
      rethrow;
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> deleteGroup(String id) async {
    try {
      final response = await _groupService.deleteGroup(id);
      if (response.success) {
        _groups.removeWhere((g) => g.id == id);
        if (_currentGroup?.id == id) {
          _currentGroup = null;
        }
        notifyListeners();
      }
      return response;
    } catch (error) {
      rethrow;
    }
  }

  Future<ApiResponse<PaginatedResponse<Group>>> getMyGroup({
    int page = 0,
    int limit = 20,
    String? status,
  }) async {
    try {
      _isFetching = true;
      notifyListeners();

      final response = await _groupService.getMyGroup(
        page: page,
        limit: limit,
        tab: status,
      );

      if (response.success && response.data != null) {
        final newGroups = response.data!.content;

        if (page == 0) {
          _groups = newGroups;
        } else {
          final existingGroupIds = _groups.map((g) => g.id).toSet();
          final uniqueNewGroups = newGroups
              .where((group) => !existingGroupIds.contains(group.id))
              .toList();
          _groups.addAll(uniqueNewGroups);
        }

        _groupsHasMore = !response.data!.last;
        // todo: rework this
        // _hasMore = response.data!.hasMore ?? false;

        _currentPage = page;
      }

      return response;
    } catch (error) {
      rethrow;
    } finally {
      _isFetching = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreGroups() async {
    if (!_hasMore || _isFetching) return;
    await getMyGroup(page: _currentPage + 1, limit: 20);
  }

  void resetPagination() {
    _currentPage = 1;
    _hasMore = true;
    _groups = [];
    notifyListeners();
  }

  void resetGroupsPagination() {
    _groupsCurrentPage = 0;
    _groupsHasMore = true;
    _groups = [];
    notifyListeners();
  }

  // Spotlight Methods
  Future<ApiResponse<List<SpotlightVideo>>> getSpotlights() async {
    try {
      _isFetchingSpotlight = true;
      notifyListeners();

      final response = await _groupService.getSpotlightService();

      if (response.success && response.data != null) {
        _spotlight = response.data!;
      }

      return response;
    } catch (error) {
      rethrow;
    } finally {
      _isFetchingSpotlight = false;
      notifyListeners();
    }
  }

  // In your GroupCommunityProvider class
  Future<void> refreshSpotlights() async {
    await getSpotlights();
  }

  // Group Settings Updates
  Future<void> handleAllowGroupMessagingChange(bool value) async {
    try {
      if (_currentGroup == null) return;

      await _groupService.updateAllowGroupMessage(
        _currentGroup!.id!,
        value,
      );
      _currentGroup = GroupDetails.fromJson({
        ..._currentGroup!.toJson(),
        'allowGroupMessaging': value,
      });
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> handleAllowVideoCallChange(bool value) async {
    try {
      if (_currentGroup == null) return;

      await _groupService.updateAllowGroupVideoCall(
        _currentGroup!.id!,
        value,
      );
      _currentGroup = GroupDetails.fromJson({
        ..._currentGroup!.toJson(),
        'allowVideoCall': value,
      });
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  // Join Requests Methods
  Future<ApiResponse<List<GroupJoinRequest>>> getMyJoinRequests(
    String status, {
    int page = 0,
    int limit = 20,
  }) async {
    try {
      _isFetching = true;
      notifyListeners();

      final response = await _groupService.getMyJoinRequests(
        status: status,
        page: page,
        limit: limit,
      );

      if (response.success && response.data != null) {
        final joinRequestsData = response.data!;

        if (page == 0) {
          _joinRequests = joinRequestsData;
        } else {
          final existingRequestIds = _joinRequests.map((r) => r.id).toSet();
          final uniqueNewRequests = joinRequestsData
              .where((request) => !existingRequestIds.contains(request.id))
              .toList();
          _joinRequests.addAll(uniqueNewRequests);
        }

        // _joinRequestsHasMore = !response.data!.last;
        _joinRequestsCurrentPage = page;
      }

      return response;
    } catch (error) {
      rethrow;
    } finally {
      _isFetching = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreJoinRequests() async {
    if (!_joinRequestsHasMore || _isFetching) return;
    await getMyJoinRequests(
      "pending",
      page: _joinRequestsCurrentPage + 1,
      limit: 20,
    );
  }

  void resetJoinRequestsPagination() {
    _joinRequestsCurrentPage = 0;
    _joinRequestsHasMore = true;
    _joinRequests = [];
    notifyListeners();
  }

  Future<ApiResponse<Map<String, int>>> getMyGroupCounts() async {
    try {
      return await _groupService.getMyGroupCounts();
    } catch (error) {
      rethrow;
    }
  }

   Future<ApiResponse<List<JoinRequest>>> getGroupJoinRequests(String groupId) async {
    try {
      final response = await _groupService.getGroupJoinRequests(groupId);
      if (response.success && response.data != null) {
        // _joinRequests = response.data!.content;
        notifyListeners();
      }
      return ApiResponse<List<JoinRequest>>(
        success: response.success,
        data: response.data?.content ?? [],
        message: response.message,
      );
    } catch (error) {
      rethrow;
    }
  }

  Future<ApiResponse<Group>> finalizeGroup(
    String groupId,
    List<Map<String, dynamic>> payoutOrder,
  ) async {
    try {
      final response = await _groupService.finalizeGroup(groupId, payoutOrder);
      if (response.success) {
        // Refresh group data after finalization
        await getGroup(groupId);
      }
      return response;
    } catch (error) {
      rethrow;
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getPayoutOrderGroup(String groupId) async {
    try {
      final response = await _groupService.getPayoutOrderGroup(groupId);
      return response;
    } catch (error) {
      rethrow;
    }
  }

  // Community Groups Methods
  Future<ApiResponse<PaginatedResponse<GroupWithScore>>> getCommunityGroups({
    double? lat,
    double? lng,
    int page = 0,
    int limit = 25,
  }) async {
    try {
      final response = await _groupService.getCommunityGroups(
        lat: lat,
        lng: lng,
        page: page,
        size: limit,
      );

      if (response.success && response.data != null) {
        _communities = response.data!.content;
      } else {
        _communities = [];
      }

      return response;
    } catch (error) {
      rethrow;
    }
  }

  Future<ApiResponse<GroupMember>> joinCommunityGroup(
    String groupId, {
    int slots = 1,
  }) async {
    try {
      final response = await _groupService.joinGroup(
        groupId,
        message: null,
        slots: slots,
      );
      return response;
    } catch (error) {
      rethrow;
    }
  }

  // Group Membership Methods
  Future<ApiResponse<GroupMember>> joinGroup(
    String groupId, {
    String? message,
    int slots = 1,
  }) async {
    try {
      return await _groupService.joinGroup(
        groupId,
        message: message,
        slots: slots,
      );
    } catch (error) {
      rethrow;
    }
  }

  Future<ApiResponse<List<PayoutOrderItem>>> approveGroupRequest(
    String groupId,
    String requestId,
  ) async {
    try {
      return await _groupService.approveGroupRequest(groupId, requestId);
    } catch (error) {
      rethrow;
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> rejectGroupRequest(
    String groupId,
    String requestId,
  ) async {
    try {
      return await _groupService.rejectGroupRequest(groupId, requestId);
    } catch (error) {
      rethrow;
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> leaveGroup(String groupId) async {
    try {
      return await _groupService.leaveGroup(groupId);
    } catch (error) {
      rethrow;
    }
  }

  Future<ApiResponse<List<GroupMember>>> getGroupMembers(String groupId) async {
    try {
      final response = await _groupService.getGroupMembers(groupId);
      if (response.success && response.data != null) {
        _groupMembers = response.data!;
        notifyListeners();
      }
      return response;
    } catch (error) {
      rethrow;
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> removeMember(
    String groupId,
    String userId,
  ) async {
    try {
      return await _groupService.removeMember(groupId, userId);
    } catch (error) {
      rethrow;
    }
  }

  // Payout Order Methods
  Future<ApiResponse<List<PayoutOrderItem>>> getPayoutOrder(
    String groupId, {
    int cycleNumber = 1,
  }) async {
    try {
      return await _groupService.getPayoutOrder(
        groupId,
        cycleNumber: cycleNumber,
      );
    } catch (error) {
      rethrow;
    }
  }

  Future<ApiResponse<List<PayoutOrderItem>>> setPayoutOrder(
    String groupId,
    List<String> memberIds, {
    int cycleNumber = 1,
  }) async {
    try {
      return await _groupService.setPayoutOrder(
        groupId,
        memberIds,
        cycleNumber: cycleNumber,
      );
    } catch (error) {
      rethrow;
    }
  }

  Future<ApiResponse<List<PayoutOrderItem>>> moveInPayoutOrder(
    String groupId,
    String memberId,
    int newPosition, {
    int cycleNumber = 1,
  }) async {
    try {
      return await _groupService.moveInPayoutOrder(
        groupId,
        memberId,
        newPosition,
        cycleNumber: cycleNumber,
      );
    } catch (error) {
      rethrow;
    }
  }

  Future<ApiResponse<List<PayoutOrderItem>>> resetPayoutOrder(
    String groupId, {
    int cycleNumber = 1,
  }) async {
    try {
      return await _groupService.resetPayoutOrder(
        groupId,
        cycleNumber: cycleNumber,
      );
    } catch (error) {
      rethrow;
    }
  }

  Future<ApiResponse<Group>> startGroup(String groupId) async {
    try {
      final response = await _groupService.startGroup(groupId);
      if (response.success && response.data != null) {
        _currentGroup = response.data as GroupDetails?;
        _groups = _groups
            .map((g) => g.id == groupId ? response.data! : g)
            .toList();
        notifyListeners();
      }
      return response;
    } catch (error) {
      rethrow;
    }
  }

  // Group Contributions Methods
  Future<ApiResponse<GroupContribution>> makeContribution(
    String groupId,
    double amount,
  ) async {
    try {
      return await _groupService.makeContribution(groupId, amount);
    } catch (error) {
      rethrow;
    }
  }

  Future<ApiResponse<PaginatedResponse<GroupContribution>>>
  getGroupContributions(String groupId, {int page = 1}) async {
    try {
      final response = await _groupService.getGroupContributions(
        groupId,
        page: page,
      );
      if (response.success && response.data != null) {
        _groupContributions = response.data!.content;
        notifyListeners();
      }
      return response;
    } catch (error) {
      rethrow;
    }
  }

  // Group Invitations Methods
  Future<ApiResponse<List<GroupInvite>>> inviteToGroup(
    String groupId,
    List<Map<String, dynamic>> invites,
  ) async {
    try {
      return await _groupService.inviteToGroup(groupId, invites);
    } catch (error) {
      rethrow;
    }
  }

  Future<ApiResponse<List<GroupInvite>>> getGroupInvites(String groupId) async {
    try {
      return await _groupService.getGroupInvites(groupId);
    } catch (error) {
      rethrow;
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> respondToInvite(
    String inviteId,
    String response,
  ) async {
    try {
      return await _groupService.respondToInvite(inviteId, response);
    } catch (error) {
      rethrow;
    }
  }

  // Group Statistics Methods
  Future<ApiResponse<GroupStats>> getGroupStats(String groupId) async {
    try {
      final response = await _groupService.getGroupStats(groupId);
      if (response.success && response.data != null) {
        _groupStats = response.data;
        notifyListeners();
      }
      return response;
    } catch (error) {
      rethrow;
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getMyGroupStats() async {
    try {
      return await _groupService.getMyGroupStats();
    } catch (error) {
      rethrow;
    }
  }

  // Community Preferences Methods
  Future<void> loadCommunityPreferences() async {
    try {
      _isLoadingPreferences = true;
      notifyListeners();

      final response = await _groupService.getPreferences();
      if (response.success && response.data != null) {
        _communityPreferences = response.data;
        print("Preference otten ... ");
      }
    } catch (error) {
      print("error?? $error");
      rethrow;
    } finally {
      print("Preference otten ... ${_communityPreferences?.toJson()}");
      _isLoadingPreferences = false;
      notifyListeners();
    }
  }

  Future<void> updateCommunityPreferences(
    Map<String, dynamic> preferences,
  ) async {
    try {
      final response = await _groupService.updatePreferences(preferences);
      if (response.success && response.data != null) {
        _communityPreferences = response.data;
        notifyListeners();
      }
    } catch (error) {
      rethrow;
    }
  }

  Future<void> resetCommunityPreferences() async {
    try {
      final response = await _groupService.resetPreferences();
      if (response.success && response.data != null) {
        _communityPreferences = response.data;
        notifyListeners();
      }
    } catch (error) {
      rethrow;
    }
  }

  // Utility method to find minimum
  int min(int a, int b) => a < b ? a : b;
}
