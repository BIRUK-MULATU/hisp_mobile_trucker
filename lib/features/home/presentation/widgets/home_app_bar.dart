import 'package:flutter/material.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/theme/app_dimensions.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onMenuTap;
  final VoidCallback? onSyncTap;
  final VoidCallback? onListViewTap;
  final VoidCallback? onSearchTap;
  final ValueChanged<String>? onSearchChanged;
  final bool isSyncing;
  final bool filtersShown;
  final bool searchActive;

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
  });

  @override
  Size get preferredSize => const Size.fromHeight(AppDimensions.appBarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.menu_rounded,
          color: Colors.white,
          size: AppDimensions.iconLG,
        ),
        onPressed: onMenuTap,
        tooltip: 'Open menu',
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
                  hintText: 'Search datasets...',
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
        // ── Search Button ──────────────────────
        IconButton(
          icon: Icon(
            searchActive ? Icons.close_rounded : Icons.search_rounded,
            color: Colors.white,
            size: AppDimensions.iconLG,
          ),
          onPressed: onSearchTap,
          tooltip: searchActive ? 'Close search' : 'Search datasets',
        ),

        // ── Sync Button (hidden while searching) ─
        if (!searchActive)
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

        // ── List View Button (hidden while searching) ─
        if (!searchActive)
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
