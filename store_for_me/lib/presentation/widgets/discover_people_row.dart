import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/social_models.dart';
import '../providers/social_provider.dart';
import '../providers/auth_provider.dart';
import '../screens/public_profile_screen.dart';

class DiscoverPeopleRow extends ConsumerWidget {
  const DiscoverPeopleRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final socialState = ref.watch(socialProvider);
    final users = socialState.suggestedUsers;

    if (users.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Discover people',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 190,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Container(
                width: 140,
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                PublicProfileScreen(userId: user.id),
                          ),
                        );
                      },
                      child: CircleAvatar(
                        radius: 36,
                        backgroundColor: AppColors.shimmerBase,
                        backgroundImage: user.profilePicUrl.isNotEmpty
                            ? CachedNetworkImageProvider(user.profilePicUrl)
                            : null,
                        child: user.profilePicUrl.isEmpty
                            ? const Icon(
                                Icons.person,
                                color: AppColors.textLight,
                                size: 36,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user.username,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      user.bio.isNotEmpty ? user.bio : 'Suggested',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 30,
                      child: ElevatedButton(
                        onPressed: () async {
                          final currentUserId =
                              ref.read(authProvider).user?.id ?? '';
                          final success = await ref
                              .read(socialProvider.notifier)
                              .toggleFollow(user.id, currentUserId);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: user.isFollowing
                              ? Colors.transparent
                              : AppColors.primary,
                          foregroundColor: user.isFollowing
                              ? AppColors.textPrimary
                              : Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          side: user.isFollowing
                              ? const BorderSide(color: AppColors.divider)
                              : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Text(
                          user.isFollowing ? 'Following' : 'Follow',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
