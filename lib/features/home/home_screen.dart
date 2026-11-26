import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nerima_gomi/core/l10n/app_strings.dart';
import 'package:nerima_gomi/data/models/waste_category.dart';
import 'package:nerima_gomi/data/services/schedule_engine.dart';
import 'package:nerima_gomi/providers/app_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final PageController _nerimaruController = PageController(viewportFraction: 0.92);
  int _nerimaruPage = 0;

  @override
  void dispose() {
    _nerimaruController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final s = state.strings;
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = ScheduleEngine.dateOnly(now);
    final tomorrow = today.add(const Duration(days: 1));

    final todayCategories = ScheduleEngine.getCategoriesForDate(
      today,
      state.currentSchedule,
      state.holidays,
    );
    final tomorrowCategories = ScheduleEngine.getCategoriesForDate(
      tomorrow,
      state.currentSchedule,
      state.holidays,
    );

    // Before 09:00 emphasize today; from 09:00 onward emphasize tomorrow
    final emphasizeToday = now.hour < 9;
    final nextNonBurnable = ScheduleEngine.findNextCollection(
      today,
      state.currentSchedule,
      state.holidays,
      category: WasteCategory.nonBurnable,
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.eco_rounded,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.appTitle),
                Text(
                  state.currentSchedule.displayName(state.language),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SegmentedButton<AppLanguage>(
              showSelectedIcon: false,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
              segments: const [
                ButtonSegment(value: AppLanguage.ko, label: Text('한')),
                ButtonSegment(value: AppLanguage.ja, label: Text('日')),
              ],
              selected: {state.language},
              onSelectionChanged: (selection) {
                ref
                    .read(appControllerProvider.notifier)
                    .setLanguage(selection.first);
              },
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          // Primary hero card (Today before 9 AM, Tomorrow after 9 AM)
          _DayHeroCard(
            badgeLabel: emphasizeToday ? s.today : s.tomorrow,
            dateText: s.formatMonthDay(emphasizeToday ? today : tomorrow),
            categories: emphasizeToday ? todayCategories : tomorrowCategories,
            isHoliday: ScheduleEngine.isHoliday(
              emphasizeToday ? today : tomorrow,
              state.holidays,
            ),
            isPrimary: true,
            strings: s,
          ),
          const SizedBox(height: 12),

          // Secondary compact card (the other day)
          _DayHeroCard(
            badgeLabel: emphasizeToday ? s.tomorrow : s.today,
            dateText: s.formatMonthDay(emphasizeToday ? tomorrow : today),
            categories: emphasizeToday ? tomorrowCategories : todayCategories,
            isHoliday: ScheduleEngine.isHoliday(
              emphasizeToday ? tomorrow : today,
              state.holidays,
            ),
            isPrimary: false,
            strings: s,
          ),
          const SizedBox(height: 18),

          // Weekly 7-day strip + Next Non-Burnable D-Day
          Row(
            children: [
              Text(
                s.thisWeek,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (nextNonBurnable != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: WasteCategory.nonBurnable.color
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        WasteCategory.nonBurnable.icon,
                        size: 14,
                        color: WasteCategory.nonBurnable.color,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${s.upcomingNonBurnable} ${s.dDayLabel(nextNonBurnable.daysFromBase)}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: WasteCategory.nonBurnable.color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _WeeklyStripCard(
            today: today,
            schedule: state.currentSchedule,
            holidays: state.holidays,
            strings: s,
          ),
          const SizedBox(height: 22),

          // Nerimaru Character Carousel (fills lower space cleanly without clutter)
          Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                s.nerimaruGallery,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _NerimaruCarousel(
            controller: _nerimaruController,
            images: state.nerimaruImages,
            currentPage: _nerimaruPage,
            onPageChanged: (index) => setState(() => _nerimaruPage = index),
            strings: s,
          ),
        ],
      ),
    );
  }
}

class _DayHeroCard extends StatelessWidget {
  final String badgeLabel;
  final String dateText;
  final List<WasteCategory> categories;
  final bool isHoliday;
  final bool isPrimary;
  final AppStrings strings;

  const _DayHeroCard({
    required this.badgeLabel,
    required this.dateText,
    required this.categories,
    required this.isHoliday,
    required this.isPrimary,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final leadColor = categories.isNotEmpty
        ? categories.first.color
        : theme.colorScheme.primary;

    return Card(
      color: isPrimary
          ? Color.alphaBlend(
              leadColor.withValues(alpha: 0.08),
              theme.cardTheme.color ?? theme.colorScheme.surface,
            )
          : null,
      child: Padding(
        padding: EdgeInsets.all(isPrimary ? 18 : 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPrimary
                        ? leadColor
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badgeLabel,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: isPrimary
                          ? Colors.white
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  dateText,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            SizedBox(height: isPrimary ? 14 : 10),
            if (isHoliday)
              Row(
                children: [
                  Icon(
                    Icons.celebration_rounded,
                    color: theme.colorScheme.tertiary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    strings.holidayNotice,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            else if (categories.isEmpty)
              Row(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    color: theme.colorScheme.primary,
                    size: isPrimary ? 24 : 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    badgeLabel == strings.today
                        ? strings.noCollectionToday
                        : strings.noCollectionTomorrow,
                    style: (isPrimary
                            ? theme.textTheme.titleMedium
                            : theme.textTheme.bodyMedium)
                        ?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              )
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: categories.map((cat) {
                  return Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isPrimary ? 14 : 11,
                      vertical: isPrimary ? 10 : 7,
                    ),
                    decoration: BoxDecoration(
                      color: cat.color.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: cat.color.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          cat.icon,
                          color: cat.color,
                          size: isPrimary ? 22 : 18,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cat.name(strings.lang),
                              style: (isPrimary
                                      ? theme.textTheme.titleMedium
                                      : theme.textTheme.bodyMedium)
                                  ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: cat.color,
                              ),
                            ),
                            if (cat.cutoffTime != null)
                              Text(
                                strings.deadlineLabel(cat.cutoffTime!),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyStripCard extends StatelessWidget {
  final DateTime today;
  final dynamic schedule;
  final dynamic holidays;
  final AppStrings strings;

  const _WeeklyStripCard({
    required this.today,
    required this.schedule,
    required this.holidays,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(7, (i) {
            final day = today.add(Duration(days: i));
            final cats = ScheduleEngine.getCategoriesForDate(
              day,
              schedule,
              holidays,
            );
            final isToday = i == 0;
            return Container(
              width: 42,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isToday
                    ? theme.colorScheme.primaryContainer.withValues(alpha: 0.75)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Text(
                    strings.weekdayName(day.weekday),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isToday
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${day.day}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isToday ? theme.colorScheme.primary : null,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 10,
                    child: cats.isEmpty
                        ? Center(
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.outlineVariant,
                                shape: BoxShape.circle,
                              ),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: cats.take(3).map((c) {
                              return Container(
                                width: 7,
                                height: 7,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 1.2),
                                decoration: BoxDecoration(
                                  color: c.color,
                                  shape: BoxShape.circle,
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NerimaruCarousel extends StatelessWidget {
  final PageController controller;
  final List<String> images;
  final int currentPage;
  final ValueChanged<int> onPageChanged;
  final AppStrings strings;

  const _NerimaruCarousel({
    required this.controller,
    required this.images,
    required this.currentPage,
    required this.onPageChanged,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImages = images.isNotEmpty;
    final slideCount = hasImages ? images.length : 3;

    final placeholderThemes = [
      (
        const [Color(0xFF1B8A5A), Color(0xFF43A047)],
        Icons.pets_rounded,
        strings.isKo ? '네리마루와 함께 깔끔한 분리배출!' : 'ねり丸といっしょに楽しく分別！',
        strings.nerimaruPlaceholderSub,
      ),
      (
        const [Color(0xFF00897B), Color(0xFF26A69A)],
        Icons.local_drink_rounded,
        strings.isKo ? '병·캔·페트병은 아침 9시까지!' : 'びん・缶・ペットボトルは朝9時まで！',
        strings.isKo
            ? '다른 쓰레기는 아침 8시까지 배출해주세요'
            : 'その他の資源・ごみは朝8時までです',
      ),
      (
        const [Color(0xFFEF6C00), Color(0xFFFFA726)],
        Icons.recycling_rounded,
        strings.isKo ? '네리마루 사진 추가 가능' : 'ねり丸フォトを追加できます',
        strings.nerimaruPlaceholderSub,
      ),
    ];

    return Column(
      children: [
        SizedBox(
          height: 168,
          child: PageView.builder(
            controller: controller,
            itemCount: slideCount,
            onPageChanged: onPageChanged,
            itemBuilder: (context, index) {
              if (hasImages) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          images[index],
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          right: 10,
                          bottom: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'ねり丸 ${index + 1}/$slideCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final card = placeholderThemes[index % placeholderThemes.length];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: card.$1,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          card.$2,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'ねり丸 · NERIMARU',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              card.$3,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              card.$4,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(slideCount, (i) {
            final active = i == currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 20 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: active
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }
}
