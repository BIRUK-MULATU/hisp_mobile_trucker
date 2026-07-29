import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/widgets/connectivity_indicator.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onMenuTap;
  final VoidCallback? onSyncTap;
  final VoidCallback? onListViewTap;
  final VoidCallback? onSearchTap;
  final ValueChanged<String>? onSearchChanged;
  final bool isSyncing;
  final bool filtersShown;
  final bool searchActive;
  final String searchHint;

  /// Filters only apply to the Capture workflow, so the button is
  /// hidden while the Visualization mode is active.
  final bool showFilterButton;

  /// App-tour showcase anchors (see home_page.dart) — always visible
  /// regardless of mode, unlike the filter button, so they're safe
  /// targets for the auto-triggered first-run tour.
  final GlobalKey? menuShowcaseKey;
  final GlobalKey? searchShowcaseKey;
  final GlobalKey? syncShowcaseKey;

  const HomeAppBar({
    super.key,
    this.onMenuTap,
    this.onSyncTap,
    this.onListViewTap,
    this.onSearchTap,
    this.onSearchChanged,
    this.isSyncing = false,
    this.filtersShown = false,
    this.searchActive = false,
    this.searchHint = 'Search...',
    this.showFilterButton = true,
    this.menuShowcaseKey,
    this.searchShowcaseKey,
    this.syncShowcaseKey,
  });

  @override
  Size get preferredSize => const Size.fromHeight(AppDimensions.appBarHeight);

  /// Wraps [child] in a Showcase when [key] is given (the app-tour
  /// path); otherwise returns it untouched — callers that don't pass
  /// showcase keys (tests, or any future reuse of this bar) get plain
  /// icons with no behavior change.
  Widget _showcase(
    GlobalKey? key,
    String title,
    String description,
    Widget child,
  ) {
    if (key == null) return child;
    return Showcase(
      key: key,
      title: title,
      description: description,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 0,
      leading: _showcase(
        menuShowcaseKey,
        'Menu',
        'Open the menu to reach Settings, About, or Log out.',
        IconButton(
          icon: const Icon(
            Icons.menu_rounded,
            color: Colors.white,
            size: AppDimensions.iconLG,
          ),
          onPressed: onMenuTap,
          tooltip: 'Open menu',
        ),
      ),
      titleSpacing: searchActive ? 0 : null,
      title: searchActive
          ? Container(
              height: 40,
              margin: const EdgeInsets.only(right: AppDimensions.spaceSM),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                autofocus: true,
                onChanged: onSearchChanged,
                cursorColor: AppColors.primary,
                textAlignVertical: TextAlignVertical.center,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: Colors.black87,
                ),
                decoration: InputDecoration(
                  // The global theme fills inputs with a grey
                  // rectangle — disable it so the rounded white
                  // pill container shows through.
                  filled: false,
                  isDense: true,
                  hintText: searchHint,
                  hintStyle: AppTextStyles.bodyLarge.copyWith(
                    color: Colors.black38,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.primary,
                    size: AppDimensions.iconLG,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.space,
                    vertical: 10,
                  ),
                ),
              ),
            )
          : const Text(
              'Home',
              style: AppTextStyles.appBarTitle,
            ),
      centerTitle: false,
      actions: [
        // ── Online/offline pill ────────────────
        if (!searchActive) const ConnectivityIndicator(),

        // ── Search Button ──────────────────────
        _showcase(
          searchShowcaseKey,
          'Search',
          'Search organisation units in Capture, or your saved charts '
              'in Visualization.',
          IconButton(
            icon: Icon(
              searchActive ? Icons.close_rounded : Icons.search_rounded,
              color: Colors.white,
              size: AppDimensions.iconLG,
            ),
            onPressed: onSearchTap,
            tooltip: searchActive ? 'Close search' : 'Search',
          ),
        ),

        // ── Sync Button (hidden while searching) ─
        if (!searchActive)
          _showcase(
            syncShowcaseKey,
            'Sync',
            'Push any offline changes to the server and pull the '
                'latest data.',
            IconButton(
              icon: isSyncing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                        semanticsLabel: 'Syncing',
                      ),
                    )
                  : const Icon(
                      Icons.sync_rounded,
                      color: Colors.white,
                      size: AppDimensions.iconLG,
                    ),
              onPressed: isSyncing ? null : onSyncTap,
              tooltip: 'Sync all',
            ),
          ),

        // ── Filter Button (Capture mode only, hidden while searching) ─
        if (!searchActive && showFilterButton)
          IconButton(
            icon: const Icon(
              Icons.format_list_bulleted_rounded,
              color: Colors.white,
              size: AppDimensions.iconLG,
            ),
            onPressed: onListViewTap,
            tooltip: filtersShown ? 'Hide filters' : 'Show filters',
          ),

        const SizedBox(width: AppDimensions.spaceXS),
      ],
    );
  }
}
