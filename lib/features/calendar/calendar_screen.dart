import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nerima_gomi/core/l10n/app_strings.dart';
import 'package:nerima_gomi/data/models/schedule_models.dart';
import 'package:nerima_gomi/data/models/waste_category.dart';
import 'package:nerima_gomi/data/services/notification_service.dart';
import 'package:nerima_gomi/data/services/schedule_engine.dart';
import 'package:nerima_gomi/providers/app_providers.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _focusedMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month, 1);
    _selectedDate = ScheduleEngine.dateOnly(now);
  }

  void _changeMonth(int delta) {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + delta, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final s = state.strings;
    final theme = Theme.of(context);
    final selectedCategories = ScheduleEngine.getCategoriesForDate(
      _selectedDate,
      state.currentSchedule,
      state.holidays,
    );
    final isSelectedHoliday =
        ScheduleEngine.isHoliday(_selectedDate, state.holidays);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.calendarTitle),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await NotificationService.instance
                  .showTestNotification(state.language);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(s.testNotificationSent)),
                );
              }
            },
            icon: const Icon(Icons.notifications_active_outlined, size: 18),
            label: Text(s.testNotification),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 96),
        children: [
          // Month calendar card
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => _changeMonth(-1),
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                      Text(
                        s.formatYearMonth(_focusedMonth),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _changeMonth(1),
                        icon: const Icon(Icons.chevron_right_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Weekday headers (Sun..Sat)
                  Row(
                    children: [7, 1, 2, 3, 4, 5, 6].map((wd) {
                      final color = wd == DateTime.sunday
                          ? Colors.redAccent
                          : wd == DateTime.saturday
                              ? Colors.blueAccent
                              : theme.colorScheme.onSurfaceVariant;
                      return Expanded(
                        child: Center(
                          child: Text(
                            s.weekdayName(wd),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  _MonthGrid(
                    focusedMonth: _focusedMonth,
                    selectedDate: _selectedDate,
                    schedule: state.currentSchedule,
                    holidays: state.holidays,
                    onSelectDate: (date) => setState(() => _selectedDate = date),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Selected date detail card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.formatMonthDay(_selectedDate),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (isSelectedHoliday)
                    Text(
                      s.holidayNotice,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.tertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else if (selectedCategories.isEmpty)
                    Text(
                      s.isKo ? '수거 일정이 없습니다.' : '収集予定はありません。',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: selectedCategories.map((cat) {
                        return Chip(
                          avatar: Icon(cat.icon, color: cat.color, size: 18),
                          backgroundColor: cat.color.withValues(alpha: 0.12),
                          side: BorderSide(
                            color: cat.color.withValues(alpha: 0.35),
                          ),
                          label: Text(
                            cat.cutoffTime != null
                                ? '${cat.name(state.language)} (${s.deadlineLabel(cat.cutoffTime!)})'
                                : cat.name(state.language),
                            style: TextStyle(
                              color: cat.color,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),

          // Alarm-clock style custom alarm rules section
          Row(
            children: [
              Icon(
                Icons.alarm_rounded,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                s.alarmSettingsTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              FilledButton.tonalIcon(
                onPressed: () => _openAlarmEditor(context, s),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(s.addAlarm),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            s.localOnlyHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),

          if (state.alarmRules.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    s.noAlarmsYet,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            )
          else
            ...state.alarmRules.map((rule) {
              final catLabel = rule.categories.isEmpty
                  ? s.allCategories
                  : rule.categories
                      .map((c) => c.shortName(state.language))
                      .join(' · ');
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _openAlarmEditor(context, s, existing: rule),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      rule.formattedTime,
                                      style: theme.textTheme.headlineSmall
                                          ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: rule.enabled
                                            ? theme.colorScheme.onSurface
                                            : theme.colorScheme
                                                .onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme
                                            .colorScheme.secondaryContainer,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        s.daysBeforeLabel(rule.daysBefore),
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                          color: theme.colorScheme
                                              .onSecondaryContainer,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  catLabel,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: rule.enabled,
                            onChanged: (val) {
                              ref
                                  .read(appControllerProvider.notifier)
                                  .toggleAlarmRule(rule.id, val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Future<void> _openAlarmEditor(
    BuildContext context,
    AppStrings s, {
    AlarmRule? existing,
  }) async {
    int daysBefore = existing?.daysBefore ?? 1;
    TimeOfDay time = TimeOfDay(
      hour: existing?.hour ?? 22,
      minute: existing?.minute ?? 0,
    );
    final selectedCats = Set<WasteCategory>.from(existing?.categories ?? []);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final theme = Theme.of(ctx);
            final timeStr =
                '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

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
                      Text(
                        existing == null ? s.addAlarm : s.editAlarm,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      if (existing != null)
                        IconButton(
                          onPressed: () {
                            ref
                                .read(appControllerProvider.notifier)
                                .deleteAlarmRule(existing.id);
                            Navigator.pop(ctx);
                          },
                          icon: const Icon(Icons.delete_outline_rounded),
                          color: theme.colorScheme.error,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Time picker button (Alarm-clock style)
                  Text(
                    s.alarmTime,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: ctx,
                        initialTime: time,
                      );
                      if (picked != null) {
                        setModalState(() => time = picked);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer
                            .withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            timeStr,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.edit_rounded,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Days before selector
                  Text(
                    s.alarmTiming,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<int>(
                    segments: [
                      ButtonSegment(value: 0, label: Text(s.daysBeforeLabel(0))),
                      ButtonSegment(value: 1, label: Text(s.daysBeforeLabel(1))),
                      ButtonSegment(value: 2, label: Text(s.daysBeforeLabel(2))),
                    ],
                    selected: {daysBefore},
                    onSelectionChanged: (sel) =>
                        setModalState(() => daysBefore = sel.first),
                  ),
                  const SizedBox(height: 18),

                  // Category filter (empty = all)
                  Text(
                    s.selectCategories,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        label: Text(s.allCategories),
                        selected: selectedCats.isEmpty,
                        onSelected: (_) =>
                            setModalState(() => selectedCats.clear()),
                      ),
                      ...WasteCategory.scheduledCategories.map((cat) {
                        final isSelected = selectedCats.contains(cat);
                        return FilterChip(
                          label: Text(cat.shortName(s.lang)),
                          selected: isSelected,
                          selectedColor: cat.color.withValues(alpha: 0.2),
                          checkmarkColor: cat.color,
                          onSelected: (val) {
                            setModalState(() {
                              if (val) {
                                selectedCats.add(cat);
                              } else {
                                selectedCats.remove(cat);
                              }
                            });
                          },
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        final rule = AlarmRule(
                          id: existing?.id ??
                              'alarm_${DateTime.now().millisecondsSinceEpoch}',
                          daysBefore: daysBefore,
                          hour: time.hour,
                          minute: time.minute,
                          categories: selectedCats.toList(),
                          enabled: existing?.enabled ?? true,
                        );
                        ref
                            .read(appControllerProvider.notifier)
                            .upsertAlarmRule(rule);
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

class _MonthGrid extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime selectedDate;
  final AreaSchedule schedule;
  final HolidayConfig holidays;
  final ValueChanged<DateTime> onSelectDate;

  const _MonthGrid({
    required this.focusedMonth,
    required this.selectedDate,
    required this.schedule,
    required this.holidays,
    required this.onSelectDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = ScheduleEngine.dateOnly(DateTime.now());
    final firstDay = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final daysInMonth =
        DateTime(focusedMonth.year, focusedMonth.month + 1, 0).day;

    // Sunday = 0 .. Saturday = 6
    final leadingBlanks = firstDay.weekday % 7;
    final totalCells = ((leadingBlanks + daysInMonth + 6) ~/ 7) * 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 4,
        crossAxisSpacing: 2,
        childAspectRatio: 0.92,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        final dayNum = index - leadingBlanks + 1;
        if (dayNum < 1 || dayNum > daysInMonth) {
          return const SizedBox.shrink();
        }
        final date = DateTime(focusedMonth.year, focusedMonth.month, dayNum);
        final cats =
            ScheduleEngine.getCategoriesForDate(date, schedule, holidays);
        final isSelected = date == selectedDate;
        final isToday = date == today;

        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onSelectDate(date),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary
                  : isToday
                      ? theme.colorScheme.primaryContainer.withValues(alpha: 0.6)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$dayNum',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight:
                        (isSelected || isToday) ? FontWeight.w800 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : date.weekday == DateTime.sunday
                            ? Colors.redAccent
                            : date.weekday == DateTime.saturday
                                ? Colors.blueAccent
                                : null,
                  ),
                ),
                const SizedBox(height: 3),
                SizedBox(
                  height: 7,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: cats.take(3).map((c) {
                      return Container(
                        width: 5.5,
                        height: 5.5,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : c.color,
                          shape: BoxShape.circle,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
