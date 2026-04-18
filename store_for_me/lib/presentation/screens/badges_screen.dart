import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../providers/gamification_provider.dart';
import '../widgets/common_widgets.dart';

class BadgesScreen extends ConsumerStatefulWidget {
  const BadgesScreen({super.key});

  @override
  ConsumerState<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends ConsumerState<BadgesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(gamificationProvider.notifier).fetchBadges());
  }

  @override
  Widget build(BuildContext context) {
    final gamState = ref.watch(gamificationProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Badges & Rewards', style: TextStyle(fontWeight: FontWeight.w700))),
      body: gamState.isLoading
          ? const LoadingIndicator(message: 'Loading badges...')
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppColors.primary, AppColors.accent]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${gamState.earnedCount}/${gamState.badges.length}',
                          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        const Text('Badges Earned', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      ],
                    ),
                  ).animate().fadeIn(duration: 500.ms),

                  const SizedBox(height: 20),
                  const Text('All Badges', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 12),

                  // Badge grid
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: gamState.badges.length,
                      itemBuilder: (context, index) {
                        final badge = gamState.badges[index];
                        final emoji = AppConstants.badgeEmoji[badge.badgeName] ?? '🏅';

                        return Container(
                          decoration: BoxDecoration(
                            color: badge.earned ? AppColors.primary.withAlpha(12) : AppColors.card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: badge.earned ? AppColors.primary.withAlpha(80) : AppColors.divider,
                              width: badge.earned ? 2 : 1,
                            ),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(emoji, style: TextStyle(fontSize: 32, color: badge.earned ? null : Colors.grey)),
                              const SizedBox(height: 8),
                              Text(
                                badge.badgeName.replaceAll('_', '\n'),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: badge.earned ? AppColors.primary : AppColors.textLight,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              // Progress bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: badge.progressPercent,
                                  backgroundColor: AppColors.divider,
                                  valueColor: AlwaysStoppedAnimation(
                                    badge.earned ? AppColors.success : AppColors.primary,
                                  ),
                                  minHeight: 4,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${badge.progress}/${badge.target}',
                                style: TextStyle(fontSize: 9, color: AppColors.textLight),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: (80 * index).ms).scale(begin: const Offset(0.9, 0.9));
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
