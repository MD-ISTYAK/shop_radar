import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/social_models.dart';
import '../../services/api_service.dart';
import 'public_profile_screen.dart';
import 'dart:async';

class SearchUsersScreen extends StatefulWidget {
  const SearchUsersScreen({super.key});

  @override
  State<SearchUsersScreen> createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends State<SearchUsersScreen> {
  final _searchController = TextEditingController();
  final ApiService _apiService = ApiService();
  
  bool _isLoading = false;
  List<UserProfileModel> _results = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    final query = _searchController.text.trim();
    if (query.length < 2) {
      if (_results.isNotEmpty) setState(() => _results = []);
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.searchUsers(query);
      if (response.data['success'] == true) {
        final data = response.data['data'] as List;
        setState(() {
          _results = data.map((e) => UserProfileModel.fromJson(e)).toList();
        });
      }
    } catch (e) {
      // ignore
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Search people or accounts...',
            hintStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() => _results.clear());
              },
            ),
        ],
      ),
      body: _isLoading && _results.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _searchController.text.length < 2
              ? _buildEmptyState('Type at least 2 characters to search')
              : _results.isEmpty
                  ? _buildEmptyState('No people or accounts found')
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final user = _results[index];
                        return ListTile(
                          leading: CircleAvatar(
                            radius: 20,
                            backgroundColor: Theme.of(context).dividerColor.withAlpha(50),
                            backgroundImage: user.profilePicUrl.isNotEmpty
                                ? CachedNetworkImageProvider(user.profilePicUrl)
                                : null,
                            child: user.profilePicUrl.isEmpty
                                ? Icon(
                                    user.isShop ? Icons.store : Icons.person,
                                    color: Theme.of(context).textTheme.bodySmall?.color,
                                  )
                                : null,
                          ),
                          title: Row(
                            children: [
                              Text(user.username, style: TextStyle(fontWeight: FontWeight.w600)),
                              if (user.isShop) ...[
                                SizedBox(width: 4),
                                const Icon(Icons.verified, size: 14, color: AppColors.info),
                              ]
                            ],
                          ),
                          subtitle: Text(
                            user.bio.isNotEmpty ? user.bio : (user.isShop ? 'Shop Account' : 'User'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                             style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 13),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => PublicProfileScreen(userId: user.id)),
                            );
                          },
                        );
                      },
                    ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search, size: 64, color: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey).withAlpha(100)),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 16),
          ),
        ],
      ),
    );
  }
}






