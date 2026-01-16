// lib/providers/group_community_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hoop/dtos/responses/ApiResponse.dart';
import 'package:hoop/dtos/responses/GeneralResponse/paginated_response.dart';
import 'package:hoop/dtos/responses/SpotlightVideo.dart';
import 'package:hoop/dtos/responses/User.dart';
import 'package:hoop/dtos/responses/group/group_join_request.dart';
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

  // Groups State with caching
  final Map<String, List<Group>> _cachedGroups = {
    'active': [],
    'completed': [],
  };
  final Map<String, bool> _segmentLoaded = {
    'active': false,
    'completed': false,
  };
  final Map<String, bool> _segmentLoading = {
    'active': false,
    'completed': false,
  };
  
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

  // Join Requests State with caching
  final Map<String, List<GroupJoinRequest>> _cachedJoinRequests = {
    'pending': [],
    'rejected': [],
  };
  final Map<String, bool> _requestsLoaded = {
    'pending': false,
    'rejected': false,
  };
  final Map<String, bool> _requestsLoading = {
    'pending': false,
    'rejected': false,
  };
  
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

  // Cache-aware getters
  List<Group> get activeGroups => List.unmodifiable(_cachedGroups['active'] ?? []);
  List<Group> get completedGroups => List.unmodifiable(_cachedGroups['completed'] ?? []);
  List<GroupJoinRequest> get pendingRequests => List.unmodifiable(_cachedJoinRequests['pending'] ?? []);
  List<GroupJoinRequest> get rejectedRequests => List.unmodifiable(_cachedJoinRequests['rejected'] ?? []);
  
  bool isSegmentLoading(String status) => _segmentLoading[status] ?? false;
  bool isSegmentLoaded(String status) => _segmentLoaded[status] ?? false;
  bool isRequestsLoading(String status) => _requestsLoading[status] ?? false;
  bool isRequestsLoaded(String status) => _requestsLoaded[status] ?? false;
  
  GroupDetails? get currentGroup => _currentGroup;
  GroupDetailsPublic? get currentPublicGroup => _currentPublicGroup;
  List<GroupMember> get groupMembers => List.unmodifiable(_groupMembers);
  List<GroupWithScore> get communities => List.unmodifiable(_communities);
  List<GroupContribution> get groupContributions => List.unmodifiable(_groupContributions);
  GroupStats? get groupStats => _groupStats;

  int get currentPage => _currentPage;
  int get groupsCurrentPage => _groupsCurrentPage;
  bool get hasMore => _hasMore;
  bool get groupsHasMore => _groupsHasMore;
  bool get isFetching => _isFetching;

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

  // Cache clearing methods
  void clearGroupCache(String? status) {
    if (status == null) {
      _cachedGroups.clear();
      _segmentLoaded.clear();
      _segmentLoading.clear();
    } else {
      _cachedGroups[status] = [];
      _segmentLoaded[status] = false;
      _segmentLoading[status] = false;
    }
    notifyListeners();
  }

  void clearJoinRequestsCache(String? status) {
    if (status == null) {
      _cachedJoinRequests.clear();
      _requestsLoaded.clear();
      _requestsLoading.clear();
    } else {
      _cachedJoinRequests[status] = [];
      _requestsLoaded[status] = false;
      _requestsLoading[status] = false;
    }
    notifyListeners();
  }

  void clearAllCache() {
    clearGroupCache(null);
    clearJoinRequestsCache(null);
    _groupMembers.clear();
    _groupContributions.clear();
    _groupStats = null;
    notifyListeners();
  }

  // Group Management Methods
  Future<ApiResponse<Group>> createGroup(Map<String, dynamic> groupData) async {
    try {
      final response = await _groupService.createGroup(groupData);
      if (response.success && response.data != null) {
        // Add to cache if it's an active group
        if (response.data!.status == 'ACTIVE' || response.data!.status == 'FORMING') {
          _cachedGroups['active']?.insert(0, response.data!);
        }
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

  Future<ApiResponse<GroupDetailsPublic>> getPublicGroup(int id) async {
    print("id..... $id");
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
        // Update in cache
        for (final status in ['active', 'completed']) {
          if (_cachedGroups.containsKey(status)) {
            final index = _cachedGroups[status]!.indexWhere((g) => g.id == id);
            if (index != -1) {
              _cachedGroups[status]![index] = response.data!;
            }
          }
        }
        
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
        // Remove from cache
        for (final status in ['active', 'completed']) {
          if (_cachedGroups.containsKey(status)) {
            _cachedGroups[status]!.removeWhere((g) => g.id == id);
          }
        }
        
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

  // Enhanced getMyGroup with caching
  Future<ApiResponse<PaginatedResponse<Group>>> getMyGroup({
    int page = 0,
    int limit = 20,
    String? status = 'active',
    bool forceRefresh = false,
  }) async {
    try {
      final cacheKey = status ?? 'active';
      
      // Return cached data if available and not forcing refresh
      if (page == 0 && 
          _segmentLoaded[cacheKey] == true && 
          !forceRefresh && 
          !_segmentLoading[cacheKey]! &&
          _cachedGroups[cacheKey]!.isNotEmpty) {
        return ApiResponse(
          success: true,
          data: PaginatedResponse(
            content: _cachedGroups[cacheKey]!,
            page: 0,
            size: limit,
            totalElements: _cachedGroups[cacheKey]!.length,
            totalPages: 1,
            last: true,
          ),
          message: 'Loaded from cache',
        );
      }

      _isFetching = true;
      if (page == 0) {
        _segmentLoading[cacheKey] = true;
      }
      notifyListeners();

      final response = await _groupService.getMyGroup(
        page: page,
        limit: limit,
        tab: status,
      );

      if (response.success && response.data != null) {
        final newGroups = response.data!.content;

        if (page == 0) {
          // Replace cache on first page
          _cachedGroups[cacheKey] = newGroups;
          _segmentLoaded[cacheKey] = true;
          _segmentLoading[cacheKey] = false;
        } else {
          // Append to cache for pagination
          final existingGroupIds = _cachedGroups[cacheKey]!.map((g) => g.id).toSet();
          final uniqueNewGroups = newGroups
              .where((group) => !existingGroupIds.contains(group.id))
              .toList();
          _cachedGroups[cacheKey]!.addAll(uniqueNewGroups);
        }

        _groupsHasMore = !response.data!.last;
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

  Future<void> loadMoreGroups({String? status = 'active'}) async {
    if (!_hasMore || _isFetching) return;
    await getMyGroup(page: _currentPage + 1, limit: 20, status: status);
  }

  void resetGroupsPagination() {
    _groupsCurrentPage = 0;
    _groupsHasMore = true;
    _cachedGroups.forEach((key, value) => value.clear());
    _segmentLoaded.forEach((key, value) => _segmentLoaded[key] = false);
    notifyListeners();
  }

  // Spotlight Methods
  Future<ApiResponse<List<SpotlightVideo>>> getSpotlights({bool forceRefresh = false}) async {
    try {
      if (_spotlight.isNotEmpty && !forceRefresh) {
        return ApiResponse(
          success: true,
          data: _spotlight,
          message: 'Loaded from cache',
        );
      }

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

  Future<void> refreshSpotlights() async {
    await getSpotlights(forceRefresh: true);
  }

  // Enhanced join requests with caching
  Future<ApiResponse<List<GroupJoinRequest>>> getMyJoinRequests(
    String status, {
    int page = 0,
    int limit = 20,
    bool forceRefresh = false,
  }) async {
    try {
      final cacheKey = status.toLowerCase();
      
      // Return cached data if available
      if (page == 0 && 
          _requestsLoaded[cacheKey] == true && 
          !forceRefresh && 
          !_requestsLoading[cacheKey]! &&
          _cachedJoinRequests[cacheKey]!.isNotEmpty) {
        return ApiResponse(
          success: true,
          data: _cachedJoinRequests[cacheKey]!,
          message: 'Loaded from cache',
        );
      }

      _isFetching = true;
      if (page == 0) {
        _requestsLoading[cacheKey] = true;
      }
      notifyListeners();

      final response = await _groupService.getMyJoinRequests(
        status: status,
        page: page,
        limit: limit,
      );

      if (response.success && response.data != null) {
        final joinRequestsData = response.data!;

        if (page == 0) {
          _cachedJoinRequests[cacheKey] = joinRequestsData;
          _requestsLoaded[cacheKey] = true;
          _requestsLoading[cacheKey] = false;
        } else {
          final existingRequestIds = _cachedJoinRequests[cacheKey]!.map((r) => r.id).toSet();
          final uniqueNewRequests = joinRequestsData
              .where((request) => !existingRequestIds.contains(request.id))
              .toList();
          _cachedJoinRequests[cacheKey]!.addAll(uniqueNewRequests);
        }

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

  Future<void> loadMoreJoinRequests(String status) async {
    if (!_joinRequestsHasMore || _isFetching) return;
    await getMyJoinRequests(
      status,
      page: _joinRequestsCurrentPage + 1,
      limit: 20,
    );
  }

  void resetJoinRequestsPagination() {
    _joinRequestsCurrentPage = 0;
    _joinRequestsHasMore = true;
    _cachedJoinRequests.forEach((key, value) => value.clear());
    _requestsLoaded.forEach((key, value) => _requestsLoaded[key] = false);
    notifyListeners();
  }

  // Other existing methods remain the same...
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
        // Clear cache since group status changed
        clearGroupCache(null);
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
      // Clear cache since group membership changed
      clearGroupCache('active');
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
      final response = await _groupService.joinGroup(
        groupId,
        message: message,
        slots: slots,
      );
      // Clear cache since group membership changed
      clearGroupCache('active');
      return response;
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
      final response = await _groupService.leaveGroup(groupId);
      if (response.success) {
        // Clear cache since group membership changed
        clearGroupCache(null);
      }
      return response;
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
        // Update cache
        clearGroupCache(null);
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