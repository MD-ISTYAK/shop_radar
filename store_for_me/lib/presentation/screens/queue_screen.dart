import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../providers/token_provider.dart';
import '../widgets/common_widgets.dart';

class QueueScreen extends ConsumerStatefulWidget {
  final String shopId;
  final String shopName;
  const QueueScreen({super.key, required this.shopId, required this.shopName});

  @override
  ConsumerState<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends ConsumerState<QueueScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(tokenProvider.notifier).fetchMyToken();
      ref.read(tokenProvider.notifier).fetchQueueStatus(widget.shopId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tokenProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Queue - ${widget.shopName}')),
      body: state.isLoading
          ? const LoadingIndicator()
          : RefreshIndicator(
              onRefresh: () async {
                await ref.read(tokenProvider.notifier).fetchMyToken();
                await ref.read(tokenProvider.notifier).fetchQueueStatus(widget.shopId);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Queue Status Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: AppColors.primary.withAlpha(50), blurRadius: 20, offset: const Offset(0, 8)),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text('Currently Serving', style: TextStyle(color: Colors.white70, fontSize: 14)),
                          const SizedBox(height: 8),
                          Text(
                            '#${state.queueStatus?.currentlyServing ?? 0}',
                            style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Column(
                                children: [
                                  Text('${state.queueStatus?.waitingCount ?? 0}',
                                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                                  const Text('In Queue', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                ],
                              ),
                              Container(width: 1, height: 30, color: Colors.white30),
                              Column(
                                children: [
                                  Text('~${state.queueStatus?.estimatedWaitMinutes ?? 0} min',
                                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                                  const Text('Est. Wait', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // My Token
                    if (state.myToken != null && state.myToken!.isActive) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primary.withAlpha(40)),
                          boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8)],
                        ),
                        child: Column(
                          children: [
                            const Text('Your Token', style: TextStyle(fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            Text('#${state.myToken!.tokenNumber}',
                                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.primary)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: state.myToken!.isServing ? AppColors.success.withAlpha(20) : AppColors.warning.withAlpha(20),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                state.myToken!.isServing ? '● Now Serving' : 'Position: ${state.myToken!.positionInQueue}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: state.myToken!.isServing ? AppColors.success : AppColors.warning,
                                ),
                              ),
                            ),
                            if (state.myToken!.isWaiting) ...[
                              const SizedBox(height: 4),
                              Text('~${state.myToken!.estimatedWaitMinutes} min wait',
                                  style: Theme.of(context).textTheme.bodySmall),
                            ],
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: () async {
                                final ok = await ref.read(tokenProvider.notifier).cancelToken();
                                if (ok && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Token cancelled'), backgroundColor: AppColors.error),
                                  );
                                }
                              },
                              icon: const Icon(Icons.close, size: 18),
                              label: const Text('Cancel Token'),
                              style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      ElevatedButton.icon(
                        onPressed: () async {
                          final ok = await ref.read(tokenProvider.notifier).takeToken(widget.shopId);
                          if (ok && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Token taken!'), backgroundColor: AppColors.success),
                            );
                            ref.read(tokenProvider.notifier).fetchQueueStatus(widget.shopId);
                          }
                        },
                        icon: const Icon(Icons.confirmation_number_outlined),
                        label: const Text('Take Token'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
