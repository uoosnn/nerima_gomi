import 'package:material_ui/material_ui.dart';
import 'package:nerima_gomi/core/l10n/app_strings.dart';

enum WasteCategory {
  burnable,
  nonBurnable,
  plastic,
  paper,
  bottleCanPet,
  oversized,
  collectionPoint;

  String get key {
    switch (this) {
      case WasteCategory.burnable:
        return 'burnable';
      case WasteCategory.nonBurnable:
        return 'non_burnable';
      case WasteCategory.plastic:
        return 'plastic';
      case WasteCategory.paper:
        return 'paper';
      case WasteCategory.bottleCanPet:
        return 'bottle_can_pet';
      case WasteCategory.oversized:
        return 'oversized';
      case WasteCategory.collectionPoint:
        return 'collection_point';
    }
  }

  static WasteCategory fromKey(String raw) {
    switch (raw) {
      case 'burnable':
        return WasteCategory.burnable;
      case 'non_burnable':
        return WasteCategory.nonBurnable;
      case 'plastic':
        return WasteCategory.plastic;
      case 'paper':
        return WasteCategory.paper;
      case 'bottle_can_pet':
        return WasteCategory.bottleCanPet;
      case 'oversized':
        return WasteCategory.oversized;
      case 'collection_point':
        return WasteCategory.collectionPoint;
      default:
        return WasteCategory.burnable;
    }
  }

  /// Categories that appear on regular weekly/monthly calendar schedules.
  bool get isScheduledCategory {
    switch (this) {
      case WasteCategory.burnable:
      case WasteCategory.nonBurnable:
      case WasteCategory.plastic:
      case WasteCategory.paper:
      case WasteCategory.bottleCanPet:
        return true;
      case WasteCategory.oversized:
      case WasteCategory.collectionPoint:
        return false;
    }
  }

  static List<WasteCategory> get scheduledCategories =>
      WasteCategory.values.where((c) => c.isScheduledCategory).toList();

  String name(AppLanguage lang) {
    final isKo = lang == AppLanguage.ko;
    switch (this) {
      case WasteCategory.burnable:
        return isKo ? '가연쓰레기' : '可燃ごみ';
      case WasteCategory.nonBurnable:
        return isKo ? '불연쓰레기' : '不燃ごみ';
      case WasteCategory.plastic:
        return isKo ? '플라스틱' : 'プラスチック';
      case WasteCategory.paper:
        return isKo ? '고지 (종이류)' : '古紙';
      case WasteCategory.bottleCanPet:
        return isKo ? '병 · 캔 · 페트병' : 'びん・缶・ペット';
      case WasteCategory.oversized:
        return isKo ? '대형쓰레기' : '粗大ごみ';
      case WasteCategory.collectionPoint:
        return isKo ? '거점회수 · 별도' : '拠点回収・対象外';
    }
  }

  String shortName(AppLanguage lang) {
    final isKo = lang == AppLanguage.ko;
    switch (this) {
      case WasteCategory.burnable:
        return isKo ? '가연' : '可燃';
      case WasteCategory.nonBurnable:
        return isKo ? '불연' : '不燃';
      case WasteCategory.plastic:
        return isKo ? '플라' : 'プラ';
      case WasteCategory.paper:
        return isKo ? '고지' : '古紙';
      case WasteCategory.bottleCanPet:
        return isKo ? '병·캔' : 'びん缶';
      case WasteCategory.oversized:
        return isKo ? '대형' : '粗大';
      case WasteCategory.collectionPoint:
        return isKo ? '거점' : '拠点';
    }
  }

  /// Nerima-ku official cutoff time: 09:00 for bottle/can/pet, 08:00 for others.
  String? get cutoffTime {
    switch (this) {
      case WasteCategory.burnable:
      case WasteCategory.nonBurnable:
      case WasteCategory.plastic:
      case WasteCategory.paper:
        return '08:00';
      case WasteCategory.bottleCanPet:
        return '09:00';
      case WasteCategory.oversized:
      case WasteCategory.collectionPoint:
        return null;
    }
  }

  Color get color {
    switch (this) {
      case WasteCategory.burnable:
        return const Color(0xFFE53935); // Vibrant Coral Red
      case WasteCategory.nonBurnable:
        return const Color(0xFF3949AB); // Indigo Blue
      case WasteCategory.plastic:
        return const Color(0xFF8E24AA); // Vivid Purple
      case WasteCategory.paper:
        return const Color(0xFFEF6C00); // Warm Orange
      case WasteCategory.bottleCanPet:
        return const Color(0xFF00897B); // Fresh Teal
      case WasteCategory.oversized:
        return const Color(0xFF546E7A); // Slate Blue Grey
      case WasteCategory.collectionPoint:
        return const Color(0xFF2E7D32); // Eco Green
    }
  }

  IconData get icon {
    switch (this) {
      case WasteCategory.burnable:
        return Icons.local_fire_department_rounded;
      case WasteCategory.nonBurnable:
        return Icons.hardware_rounded;
      case WasteCategory.plastic:
        return Icons.recycling_rounded;
      case WasteCategory.paper:
        return Icons.newspaper_rounded;
      case WasteCategory.bottleCanPet:
        return Icons.local_drink_rounded;
      case WasteCategory.oversized:
        return Icons.chair_rounded;
      case WasteCategory.collectionPoint:
        return Icons.battery_charging_full_rounded;
    }
  }
}
