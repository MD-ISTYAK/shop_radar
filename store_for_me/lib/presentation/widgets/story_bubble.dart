import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/social_models.dart';
import '../../core/theme/app_theme.dart';
import 'premium_widgets.dart';

class StoryBubble extends StatelessWidget {
  final StoryGroupModel? group;
  final String? imageUrl;
  final String? name;
  final bool isAddStory;
  final bool isVerified;
  final bool hasUnseenStories;
  final VoidCallback onTap;

  const StoryBubble({
    super.key,
    this.group,
    this.imageUrl,
    this.name,
    this.isAddStory = false,
    this.isVerified = false,
    this.hasUnseenStories = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayImageUrl = isAddStory ? imageUrl : (group?.stories.isNotEmpty == true ? group!.stories.first.mediaUrl : imageUrl);
    final displayName = isAddStory ? 'Your story' : (group?.username ?? name ?? 'User');
    final displayVerified = group?.userId != null ? false : isVerified; 
    final displayHasUnseen = group?.hasUnseenStories ?? hasUnseenStories;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: displayHasUnseen
                    ? const LinearGradient(
                        colors: [AppColors.primary, AppColors.accent, AppColors.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [AppColors.textLight.withOpacity(0.2), AppColors.textLight.withOpacity(0.2)],
                      ),
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  children: [
                    PremiumAvatar(imageUrl: displayImageUrl, size: 62, hasBorder: false),
                    if (displayVerified)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.verified, color: AppColors.primary, size: 16),
                        ),
                      ),
                    if (isAddStory)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                          child: const Icon(Icons.add, color: Colors.white, size: 18),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 70,
              child: Text(
                displayName,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}






