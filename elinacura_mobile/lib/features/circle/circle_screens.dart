import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/engagement_repository.dart';
import '../../core/data/local_prefs.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/ec_outcome_hero.dart';
import '../../shared/widgets/ec_page_kit.dart';
import '../../shared/widgets/ec_glass.dart';
import '../../shared/widgets/ec_widgets.dart';

class FamilyCircleScreen extends ConsumerStatefulWidget {
  const FamilyCircleScreen({super.key});

  @override
  ConsumerState<FamilyCircleScreen> createState() => _FamilyCircleScreenState();
}

class _FamilyCircleScreenState extends ConsumerState<FamilyCircleScreen> {
  FamilyCirclesData? _data;
  List<Map<String, dynamic>> _pendingInvites = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final invites = await LocalPrefs.readList('ec.circle.invites');
    try {
      final data = await ref.read(engagementRepositoryProvider).listCircles();
      if (mounted) {
        setState(() {
          _data = data;
          _pendingInvites = invites;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _data = const FamilyCirclesData();
          _pendingInvites = invites;
          _loading = false;
        });
      }
    }
  }

  Future<void> _invite() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => const _InviteDialog(),
    );
    if (result == null) return;
    final invite = {
      'id': 'inv-${DateTime.now().millisecondsSinceEpoch}',
      ...result,
    };
    setState(() => _pendingInvites = [..._pendingInvites, invite]);
    await LocalPrefs.writeList('ec.circle.invites', _pendingInvites);
  }

  @override
  Widget build(BuildContext context) {
    final circles = _data?.all ?? [];
    final memberCount =
        circles.fold<int>(0, (sum, c) => sum + c.members.length) + _pendingInvites.length;

    return EcGlassScaffold(
      appBar: const EcAppBar(title: 'Family circle'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: kEcGlassListPadding,
              children: [
                EcOutcomeHero(
                  eyebrow: 'Care network',
                  title: 'Your care circle',
                  subtitle: 'Members, guardians, roles, and privacy controls.',
                  icon: Icons.family_restroom_rounded,
                  accent: EcAccent.sky,
                  trailing: EcPill(label: '$memberCount people', tone: EcPillTone.info),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _invite,
                  icon: const Icon(Icons.person_add_rounded),
                  label: const Text('Invite member'),
                ),
                const SizedBox(height: 16),
                if (circles.isEmpty && _pendingInvites.isEmpty)
                  EcEmptyState(
                    icon: Icons.people_outline_rounded,
                    title: 'No circle yet',
                    message: 'Invite family or caregivers to coordinate care.',
                    action: TextButton(
                      onPressed: () => context.push('/connections'),
                      child: const Text('Manage connections'),
                    ),
                  ),
                ...circles.map(
                  (circle) => EcGlassEntrance(
                    index: 0,
                    child: EcCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            circle.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...circle.members.map(
                            (m) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const CircleAvatar(child: Icon(Icons.person_rounded)),
                              title: Text(m.name),
                              subtitle: Text(m.role),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_pendingInvites.isNotEmpty) ...[
                  EcSectionTitle(title: 'Pending invites'),
                  const SizedBox(height: 8),
                  ..._pendingInvites.map(
                    (inv) => EcGlassListTile(
                      icon: Icons.mail_outline_rounded,
                      title: inv['name'] as String? ?? 'Invite',
                      subtitle: inv['email'] as String? ?? '',
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                EcGlassListTile(
                  icon: Icons.photo_library_rounded,
                  title: 'Shared moments',
                  subtitle: 'Milestones and notes from your circle',
                  onTap: () => context.push('/moments'),
                ),
              ],
            ),
    );
  }
}

class _InviteDialog extends StatefulWidget {
  const _InviteDialog();

  @override
  State<_InviteDialog> createState() => _InviteDialogState();
}

class _InviteDialogState extends State<_InviteDialog> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  String _role = 'member';

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Invite to circle'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
          TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _role,
            items: const [
              DropdownMenuItem(value: 'member', child: Text('Member')),
              DropdownMenuItem(value: 'guardian', child: Text('Guardian')),
            ],
            onChanged: (v) => setState(() => _role = v ?? 'member'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (_name.text.trim().isEmpty) return;
            Navigator.pop(context, {
              'name': _name.text.trim(),
              'email': _email.text.trim(),
              'role': _role,
            });
          },
          child: const Text('Send invite'),
        ),
      ],
    );
  }
}

class MomentsScreen extends ConsumerStatefulWidget {
  const MomentsScreen({super.key});

  @override
  ConsumerState<MomentsScreen> createState() => _MomentsScreenState();
}

class _MomentsScreenState extends ConsumerState<MomentsScreen> {
  List<MomentFeedItem> _items = [];
  bool _loading = true;
  final _captionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await ref.read(engagementRepositoryProvider).getMomentsFeed();
      if (items.isEmpty) {
        final saved = await LocalPrefs.readList('ec.moments.feed');
        if (mounted) {
          setState(() {
            _items = saved
                .map(
                  (e) => MomentFeedItem(
                    id: e['id'] as String? ?? '',
                    authorName: e['author'] as String? ?? 'You',
                    caption: e['caption'] as String? ?? '',
                    kind: e['kind'] as String? ?? 'note',
                    liked: e['liked'] as bool? ?? false,
                  ),
                )
                .toList();
            _loading = false;
          });
        }
        return;
      }
      if (mounted) {
        setState(() {
          _items = items;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleLike(MomentFeedItem item) async {
    final next = !item.liked;
    setState(() {
      _items = _items
          .map(
            (m) => m.id == item.id
                ? m.copyWith(
                    liked: next,
                    reactions: m.reactions + (next ? 1 : -1),
                  )
                : m,
          )
          .toList();
    });
    try {
      await ref.read(engagementRepositoryProvider).setMomentReaction(item.id, liked: next);
    } catch (_) {}
  }

  Future<void> _compose() async {
    final caption = _captionController.text.trim();
    if (caption.isEmpty) return;
    final created = MomentFeedItem(
      id: 'local-${DateTime.now().millisecondsSinceEpoch}',
      authorName: 'You',
      caption: caption,
      kind: 'note',
    );
    setState(() => _items = [created, ..._items]);
    _captionController.clear();
    await LocalPrefs.writeList(
      'ec.moments.feed',
      _items
          .map(
            (m) => {
              'id': m.id,
              'author': m.authorName,
              'caption': m.caption,
              'kind': m.kind,
              'liked': m.liked,
            },
          )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return EcGlassScaffold(
      appBar: const EcAppBar(title: 'Moments'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: kEcGlassListPadding,
              children: [
                EcOutcomeHero(
                  eyebrow: 'Moments',
                  title: 'Shared wellness feed',
                  subtitle: 'Milestones, notes, and encouragement from your care circle.',
                  icon: Icons.auto_stories_rounded,
                  accent: EcAccent.lavender,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _captionController,
                  decoration: InputDecoration(
                    hintText: 'Share a moment…',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send_rounded),
                      onPressed: _compose,
                    ),
                  ),
                  onSubmitted: (_) => _compose(),
                ),
                const SizedBox(height: 16),
                if (_items.isEmpty)
                  const EcEmptyState(
                    icon: Icons.image_outlined,
                    title: 'No moments yet',
                    message: 'Celebrate wins and keep your circle connected.',
                  )
                else
                  ..._items.map(
                    (item) => EcGlassEntrance(
                      index: 0,
                      child: EcCard(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.authorName,
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 6),
                            Text(item.caption),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () => _toggleLike(item),
                                  icon: Icon(
                                    item.liked
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    color: item.liked ? Colors.redAccent : null,
                                  ),
                                ),
                                Text('${item.reactions}'),
                                const Spacer(),
                                EcPill(label: item.kind, tone: EcPillTone.neutral),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
