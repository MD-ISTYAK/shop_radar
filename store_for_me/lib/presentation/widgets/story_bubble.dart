import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/social_models.dart';

class StoryBubble extends StatelessWidget {
  final StoryGroupModel group;
  final bool isAddStory;
  final VoidCallback onTap;

  const StoryBubble({
    super.key,
    required this.group,
    this.isAddStory = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isAddStory
                    ? null
                    : group.hasUnseenStories
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFF58529),
                              Color(0xFFDD2A7B),
                              Color(0xFF8134AF),
                              Color(0xFF515BD4),
                            ],
                          )
                        : const LinearGradient(
                            colors: [Color(0xFFD1D5DB), Color(0xFFD1D5DB)],
                          ),
                border: isAddStory
                    ? Border.all(color: AppColors.divider, width: 2)
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.card,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: isAddStory
                      ? CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.primary.withAlpha(20),
                          child: const Icon(Icons.add, color: AppColors.primary, size: 28),
                        )
                      : CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.shimmerBase,
                          backgroundImage: group.displayProfilePic.isNotEmpty
                              ? CachedNetworkImageProvider(group.displayProfilePic)
                              : null,
                          child: group.displayProfilePic.isEmpty
                              ? const Icon(Icons.person, size: 24, color: AppColors.textLight)
                              : null,
                        ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 72,
              child: Text(
                isAddStory ? 'Your story' : group.username,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: isAddStory ? AppColors.textSecondary : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
