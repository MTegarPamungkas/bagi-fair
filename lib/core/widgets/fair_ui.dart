/// Shared Bagi Fair UI kit.
///
/// The kit is deliberately split into small files (one concern each) so a page
/// can be understood without scrolling through a thousand lines of widgets:
///
/// * [FairBackground] – the paper canvas
/// * [FairCard], [PerforatedDivider] – surfaces and receipt rules
/// * [PageHeader], [SectionHeader] – page and section titles
/// * [LoadingState], [EmptyState], [ErrorState] – the three required states
/// * [Pill], [StampBadge], [MetaPair] – chips and stamps
/// * [AmountText], [LedgerRow] – money rendering
/// * [AvatarCircle], [AvatarStack] – people
/// * [GroupTypeIcon], [SyncChip], [MetricTile], [InfoRow], [SheetHeader]
///
/// Importing this one barrel keeps feature code tidy while the implementation
/// stays modular.
library;

export 'package:bagi_fair/core/widgets/avatars.dart';
export 'package:bagi_fair/core/widgets/brand_mark.dart';
export 'package:bagi_fair/core/widgets/chips.dart';
export 'package:bagi_fair/core/widgets/fair_background.dart';
export 'package:bagi_fair/core/widgets/group_type_icon.dart';
export 'package:bagi_fair/core/widgets/info_tiles.dart';
export 'package:bagi_fair/core/widgets/money_text.dart';
export 'package:bagi_fair/core/widgets/page_header.dart';
export 'package:bagi_fair/core/widgets/paper_card.dart';
export 'package:bagi_fair/core/widgets/sheet_header.dart';
export 'package:bagi_fair/core/widgets/state_views.dart';
export 'package:bagi_fair/core/widgets/sync_chip.dart';
