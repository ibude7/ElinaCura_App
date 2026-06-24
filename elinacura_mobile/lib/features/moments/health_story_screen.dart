import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/engagement_repository.dart';
import '../../shared/widgets/ec_glass.dart';
import '../../shared/widgets/ec_guilloche.dart';
import '../../shared/widgets/ec_page_kit.dart';
import '../../shared/widgets/ec_widgets.dart';

/// Moments → year-in-review Health Story (Rec #45).
class HealthStoryScreen extends ConsumerStatefulWidget {
  const HealthStoryScreen({super.key});

  @override
  ConsumerState<HealthStoryScreen> createState() => _HealthStoryScreenState();
}

class _HealthStoryScreenState extends ConsumerState<HealthStoryScreen> {
  @override
  Widget build(BuildContext context) {
    final moments = ref.watch(
      FutureProvider((ref) async {
        final result =
            await ref.read(engagementRepositoryProvider).getMomentsFeedResult();
        return result.valueOrNull ?? [];
      }),
    );

    return EcGlassScaffold(
      appBar: const EcAppBar(title: 'Health Story'),
      body: moments.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EcErrorState(message: '$e', onRetry: () => setState(() {})),
        data: (items) {
          return ListView(
            padding: kEcGlassListPadding,
            children: [
              EcGuillocheBackdrop(
                child: EcPageHero(
                  eyebrow: 'Your year in care',
                  title: 'Health Story',
                  subtitle:
                      'A private narrative woven from moments, doses, and vitals.',
                  icon: Icons.auto_stories_rounded,
                  accent: EcAccent.amber,
                ),
              ),
              const SizedBox(height: 20),
              if (items.isEmpty)
                const EcEmptyState(
                  icon: Icons.auto_stories_outlined,
                  title: 'Your story is just beginning',
                  message:
                      'Moments from your care journey will appear here as a year-in-review narrative.',
                )
              else
                ...items.map(
                  (m) => EcGlassListTile(
                    icon: Icons.favorite_rounded,
                    title: m.authorName,
                    subtitle: m.caption,
                    onTap: () {},
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
