import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import 'public_profile_screen.dart';

class UserNetworkScreen extends ConsumerStatefulWidget {
  final String userId;
  final int initialIndex;
  const UserNetworkScreen({super.key, required this.userId, this.initialIndex = 0});

  @override
  ConsumerState<UserNetworkScreen> createState() => _UserNetworkScreenState();
}

class _UserNetworkScreenState extends ConsumerState<UserNetworkScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _api = ApiService();
  
  List<dynamic> _followers = [];
  List<dynamic> _following = [];
  List<dynamic> _friends = [];
  
  bool _isLoadingFollowers = false;
  bool _isLoadingFollowing = false;
  bool _isLoadingFriends = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialIndex);
    _fetchData();
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _fetchData();
      }
    });
  }

  void _fetchData() {
    if (_tabController.index == 0 && _followers.isEmpty) _fetchFollowers();
    if (_tabController.index == 1 && _friends.isEmpty) _fetchFriends();
    if (_tabController.index == 2 && _following.isEmpty) _fetchFollowing();
  }

  Future<void> _fetchFollowers() async {
    setState(() => _isLoadingFollowers = true);
    try {
      final response = await _api.getFollowers(widget.userId);
      if (response.data['success'] == true) {
        setState(() => _followers = response.data['data']);
      }
    } catch (_) {}
    setState(() => _isLoadingFollowers = false);
  }

  Future<void> _fetchFollowing() async {
    setState(() => _isLoadingFollowing = true);
    try {
      final response = await _api.getFollowing(widget.userId);
      if (response.data['success'] == true) {
        setState(() => _following = response.data['data']);
      }
    } catch (_) {}
    setState(() => _isLoadingFollowing = false);
  }

  Future<void> _fetchFriends() async {
    setState(() => _isLoadingFriends = true);
    try {
      final response = await _api.getFriends(widget.userId);
      if (response.data['success'] == true) {
        setState(() => _friends = response.data['data']);
      }
    } catch (_) {}
    setState(() => _isLoadingFriends = false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Followers'),
            Tab(text: 'Friends'),
            Tab(text: 'Following'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUserList(_followers, _isLoadingFollowers, 'No followers yet'),
          _buildUserList(_friends, _isLoadingFriends, 'No friends yet'),
          _buildUserList(_following, _isLoadingFollowing, 'Not following anyone'),
        ],
      ),
    );
  }

  Widget _buildUserList(List<dynamic> users, bool isLoading, String emptyMsg) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (users.isEmpty) return Center(child: Text(emptyMsg, style: const TextStyle(color: Colors.grey)));

    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final avatar = user['avatar'] ?? user['profilePic'] ?? '';
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: avatar.isNotEmpty ? CachedNetworkImageProvider(avatar) : null,
            child: avatar.isEmpty ? const Icon(Icons.person) : null,
          ),
          title: Text(user['name'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('@${user['username'] ?? 'username'}'),
          trailing: ElevatedButton(
            onPressed: () {
              // TODO: Implement Message or Toggle Follow
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              foregroundColor: AppColors.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Profile'),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PublicProfileScreen(userId: user['_id'])),
            );
          },
        );
      },
    );
  }
}
