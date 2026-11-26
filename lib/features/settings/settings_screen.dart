import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nerima_gomi/core/constants/nerima_links.dart';
import 'package:nerima_gomi/core/l10n/app_strings.dart';
import 'package:nerima_gomi/data/models/schedule_models.dart';
import 'package:nerima_gomi/data/models/waste_category.dart';
import 'package:nerima_gomi/providers/app_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _launchExternalUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open $url')),
      );
    }
  }

  Future<void> _callPhone(BuildContext context, String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    final ok = await launchUrl(uri);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not dial $phone')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final s = state.strings;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.settingsTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // 1. My Area & Custom Schedule Section (Option B)
          _SectionHeader(
            icon: Icons.location_on_rounded,
            title: s.myAreaSection,
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: Text(
                    state.currentSchedule.displayName(state.language),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(s.selectAreaPreset),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (state.currentSchedule.isCustom)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.tertiaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            s.customScheduleBadge,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onTertiaryContainer,
                            ),
                          ),
                        ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                  onTap: () => _showPresetPicker(context, ref, state),
                ),
                const Divider(height: 1),
                ...WasteCategory.scheduledCategories.map((cat) {
                  final rule = state.currentSchedule.rules[cat] ??
                      const CollectionRule.none();
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: cat.color.withValues(alpha: 0.14),
                      child: Icon(cat.icon, size: 17, color: cat.color),
                    ),
                    title: Text(
                      cat.name(state.language),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(rule.describe(s)),
                    trailing: const Icon(Icons.edit_outlined, size: 18),
                    onTap: () => _showRuleEditor(context, ref, s, cat, rule),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // 2. Official Web Pages (External Browser)
          _SectionHeader(
            icon: Icons.open_in_browser_rounded,
            title: s.officialWebSection,
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                for (var i = 0; i < NerimaOfficialResources.webLinks.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  Builder(
                    builder: (_) {
                      final link = NerimaOfficialResources.webLinks[i];
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.public_rounded,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          s.isKo ? link.titleKo : link.titleJa,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          s.isKo ? link.subtitleKo : link.subtitleJa,
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                        onTap: () => _launchExternalUrl(context, link.url),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 22),

          // 3. Official Department Phone Numbers (One-Tap Dial)
          _SectionHeader(
            icon: Icons.call_rounded,
            title: s.officialPhoneSection,
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                for (var i = 0;
                    i < NerimaOfficialResources.phoneContacts.length;
                    i++) ...[
                  if (i > 0) const Divider(height: 1),
                  Builder(
                    builder: (_) {
                      final contact = NerimaOfficialResources.phoneContacts[i];
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.phone_rounded,
                            color: theme.colorScheme.secondary,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          s.isKo ? contact.titleKo : contact.titleJa,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              contact.phone,
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              s.isKo ? contact.subtitleKo : contact.subtitleJa,
                              style: const TextStyle(fontSize: 11.5),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: IconButton.filledTonal(
                          onPressed: () => _callPhone(context, contact.phone),
                          icon: const Icon(Icons.call_rounded, size: 18),
                        ),
                        onTap: () => _callPhone(context, contact.phone),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 22),

          // 4. App Preferences (Language & Theme)
          _SectionHeader(
            icon: Icons.tune_rounded,
            title: s.appPreferencesSection,
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.languageLabel,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<AppLanguage>(
                      segments: const [
                        ButtonSegment(
                          value: AppLanguage.ko,
                          label: Text('한국어'),
                        ),
                        ButtonSegment(
                          value: AppLanguage.ja,
                          label: Text('日本語'),
                        ),
                      ],
                      selected: {state.language},
                      onSelectionChanged: (sel) {
                        ref
                            .read(appControllerProvider.notifier)
                            .setLanguage(sel.first);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    s.themeLabel,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ThemeMode>(
                      segments: [
                        ButtonSegment(
                          value: ThemeMode.system,
                          label: Text(s.themeSystem),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text(s.themeLight),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text(s.themeDark),
                        ),
                      ],
                      selected: {state.themeMode},
                      onSelectionChanged: (sel) {
                        ref
                            .read(appControllerProvider.notifier)
                            .setThemeMode(sel.first);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPresetPicker(
    BuildContext context,
    WidgetRef ref,
    AppState state,
  ) {
    final s = state.strings;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                s.selectAreaPreset,
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            ...state.areaPresets.map((preset) {
              final selected = preset.id == state.currentSchedule.id &&
                  !state.currentSchedule.isCustom;
              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                selected: selected,
                title: Text(
                  preset.displayName(state.language),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  state.language == AppLanguage.ko
                      ? preset.nameJa
                      : preset.nameKo,
                ),
                trailing: selected
                    ? const Icon(Icons.check_circle_rounded)
                    : null,
                onTap: () {
                  ref
                      .read(appControllerProvider.notifier)
                      .selectAreaPreset(preset);
                  Navigator.pop(ctx);
                },
              );
            }),
          ],
        );
      },
    );
  }

  Future<void> _showRuleEditor(
    BuildContext context,
    WidgetRef ref,
    AppStrings s,
    WasteCategory category,
    CollectionRule current,
  ) async {
    RuleType type = current.type;
    final weekdays = Set<int>.from(current.weekdays);
    int nthWeekday = current.weekday;
    final weeks = Set<int>.from(current.weeks);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final theme = Theme.of(ctx);
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                4,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(category.icon, color: category.color),
                      const SizedBox(width: 10),
                      Text(
                        category.name(s.lang),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<RuleType>(
                      segments: [
                        ButtonSegment(
                          value: RuleType.weekly,
                          label: Text(s.ruleTypeWeekly),
                        ),
                        ButtonSegment(
                          value: RuleType.nthWeekday,
                          label: Text(s.ruleTypeNthWeekday),
                        ),
                        ButtonSegment(
                          value: RuleType.none,
                          label: Text(s.ruleTypeNone),
                        ),
                      ],
                      selected: {type},
                      onSelectionChanged: (sel) =>
                          setModalState(() => type = sel.first),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (type == RuleType.weekly) ...[
                    Text(
                      s.selectWeekdays,
                      style: theme.textTheme.labelLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(7, (i) {
                        final wd = i + 1;
                        return FilterChip(
                          label: Text(s.weekdayName(wd)),
                          selected: weekdays.contains(wd),
                          onSelected: (val) {
                            setModalState(() {
                              if (val) {
                                weekdays.add(wd);
                              } else {
                                weekdays.remove(wd);
                              }
                            });
                          },
                        );
                      }),
                    ),
                  ] else if (type == RuleType.nthWeekday) ...[
                    Text(
                      s.selectWeeks,
                      style: theme.textTheme.labelLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [1, 2, 3, 4, 5].map((w) {
                        return FilterChip(
                          label: Text(s.nthWeekLabel(w)),
                          selected: weeks.contains(w),
                          onSelected: (val) {
                            setModalState(() {
                              if (val) {
                                weeks.add(w);
                              } else {
                                weeks.remove(w);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      s.selectWeekdays,
                      style: theme.textTheme.labelLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(7, (i) {
                        final wd = i + 1;
                        return ChoiceChip(
                          label: Text(s.weekdayName(wd)),
                          selected: nthWeekday == wd,
                          onSelected: (_) =>
                              setModalState(() => nthWeekday = wd),
                        );
                      }),
                    ),
                  ],
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        final CollectionRule nextRule = switch (type) {
                          RuleType.none => const CollectionRule.none(),
                          RuleType.weekly =>
                            CollectionRule.weekly(weekdays.toList()..sort()),
                          RuleType.nthWeekday => CollectionRule.nthWeekday(
                              weekday: nthWeekday,
                              weeks: weeks.toList()..sort(),
                            ),
                        };
                        ref
                            .read(appControllerProvider.notifier)
                            .updateCustomRule(category, nextRule);
                        Navigator.pop(ctx);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(s.save),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
