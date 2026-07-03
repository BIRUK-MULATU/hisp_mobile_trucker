import 'package:flutter/material.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/theme/app_dimensions.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onMenuTap;
  final VoidCallback? onSyncTap;
  final VoidCallback? onListViewTap;
  final bool isSyncing;
  final bool filtersShown;

  const HomeAppBar({
    super.key,
    this.onMenuTap,
    this.onSyncTap,
    this.onListViewTap,
    this.isSyncing = false,
    this.filtersShown = false,
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
      title: Text(
        'Home',
        style: AppTextStyles.appBarTitle,
      ),
      centerTitle: false,
      actions: [
        // ── Sync Button ────────────────────────
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

        // ── List View Button ───────────────────
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
