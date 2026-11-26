import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nerima_gomi/data/models/schedule_models.dart';
import 'package:nerima_gomi/data/models/waste_category.dart';
import 'package:nerima_gomi/data/services/schedule_engine.dart';
import 'package:nerima_gomi/providers/app_providers.dart';

class DictionaryScreen extends ConsumerStatefulWidget {
  const DictionaryScreen({super.key});

  @override
  ConsumerState<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends ConsumerState<DictionaryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  WasteCategory? _selectedCategory;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final s = state.strings;
    final theme = Theme.of(context);

    final filtered = ScheduleEngine.searchItems(
      state.wasteItems,
      query: _query,
      categoryFilter: _selectedCategory,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(s.dictionaryTitle),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: s.searchHint,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close_rounded),
                      )
                    : null,
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(s.filterAll),
                    selected: _selectedCategory == null,
                    onSelected: (_) => setState(() => _selectedCategory = null),
                  ),
                ),
                ...WasteCategory.values.map((cat) {
                  final selected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      avatar: Icon(
                        cat.icon,
                        size: 16,
                        color: selected ? cat.color : theme.colorScheme.onSurfaceVariant,
                      ),
                      label: Text(cat.shortName(state.language)),
                      selected: selected,
                      selectedColor: cat.color.withValues(alpha: 0.18),
                      checkmarkColor: cat.color,
                      onSelected: (_) {
                        setState(() {
                          _selectedCategory = selected ? null : cat;
                        });
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 48,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            s.noSearchResults,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return Card(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => _showItemDetail(context, item, state),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: item.category.color
                                        .withValues(alpha: 0.13),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    item.category.icon,
                                    color: item.category.color,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.primaryName(state.language),
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item.secondaryName(state.language),
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: item.category.color
                                        .withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    item.category.shortName(state.language),
                                    style: TextStyle(
                                      color: item.category.color,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showItemDetail(
    BuildContext context,
    WasteItem item,
    AppState state,
  ) {
    final s = state.strings;
    final nextInfo = item.category.isScheduledCategory
        ? ScheduleEngine.findNextCollection(
            DateTime.now(),
            state.currentSchedule,
            state.holidays,
            category: item.category,
          )
        : null;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: item.category.color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      item.category.icon,
                      color: item.category.color,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.primaryName(state.language),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          item.secondaryName(state.language),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: item.category.color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  item.category.cutoffTime != null
                      ? '${item.category.name(state.language)} · ${s.deadlineLabel(item.category.cutoffTime!)}'
                      : item.category.name(state.language),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                s.disposalTip,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.note(state.language),
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
              if (nextInfo != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer
                        .withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.event_available_rounded,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${s.nextScheduledForItem}: ${s.formatMonthDay(nextInfo.date)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      Text(
                        s.dDayLabel(nextInfo.daysFromBase),
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
