import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../auth/data/datasources/auth_remote_datasource.dart';
import '../../../auth/data/repositories/auth_repository_impl.dart';
import '../../../auth/domain/usecases/logout_usecase.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _secureStorage = SecureStorage();

  String? _username;
  String? _orgUnitName;
  String _serverUrl = ApiConstants.baseUrl;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final username = await _secureStorage.getUsername();
    final orgUnit = await _secureStorage.getPrimaryOrgUnit();
    final storedUrl = await _secureStorage.getBaseUrl();
    if (!mounted) return;
    setState(() {
      _username = username;
      _orgUnitName = orgUnit?['displayName'] as String? ??
          orgUnit?['name'] as String? ??
          orgUnit?['shortName'] as String?;
      _serverUrl = (storedUrl != null && storedUrl.isNotEmpty)
          ? storedUrl
          : ApiConstants.baseUrl;
    });
  }

  Future<void> _editServerUrl() async {
    final controller = TextEditingController(text: _serverUrl);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        ),
        title: const Row(
          children: [
            _TileIcon(icon: Icons.dns_rounded, color: AppColors.primary),
            SizedBox(width: AppDimensions.spaceMD),
            Expanded(
              child: Text('DHIS2 Server',
                  style: AppTextStyles.headingSmall),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The app will send and fetch data from this server.',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppDimensions.spaceMD),
            TextField(
              controller: controller,
              keyboardType: TextInputType.url,
              autocorrect: false,
              autofocus: true,
              style: AppTextStyles.bodyMedium,
              decoration: const InputDecoration(
                hintText: 'http://server:port/api',
                prefixIcon: Icon(Icons.link_rounded,
                    size: AppDimensions.iconMD),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();

    final url = result?.trim();
    if (url == null || url.isEmpty || url == _serverUrl) return;

    await _secureStorage.saveBaseUrl(url);
    ApiClient().updateBaseUrl(url);
    if (!mounted) return;
    setState(() => _serverUrl = url);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Server URL updated'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        ),
        title: const Row(
          children: [
            _TileIcon(icon: Icons.logout_rounded, color: AppColors.error),
            SizedBox(width: AppDimensions.spaceMD),
            Expanded(
              child:
                  Text('Log out?', style: AppTextStyles.headingSmall),
            ),
          ],
        ),
        content: const Text(
          'You will need to log in again. Data not yet synced stays on '
          'this device.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final repository = AuthRepositoryImpl(
      remoteDataSource: AuthRemoteDataSourceImpl(
        apiClient: ApiClient(),
        secureStorage: _secureStorage,
      ),
      secureStorage: _secureStorage,
    );
    await LogoutUseCase(repository).call();
    if (mounted) context.go(AppRouter.login);
  }

  String get _initials {
    final name = _username?.trim() ?? '';
    if (name.isEmpty) return '?';
    return name.length >= 2
        ? name.substring(0, 2).toUpperCase()
        : name.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Settings', style: AppTextStyles.appBarTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppDimensions.spaceXXL),
        children: [
          // ── Profile header ─────────────────────────────
          _ProfileHeader(
            initials: _initials,
            username: _username ?? 'Not logged in',
            orgUnitName: _orgUnitName ?? 'No organisation unit',
          ),

          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionHeader('Server'),
                _SettingsCard(children: [
                  _SettingsTile(
                    icon: Icons.dns_rounded,
                    color: AppColors.primary,
                    title: 'DHIS2 server URL',
                    subtitle: _serverUrl,
                    onTap: _editServerUrl,
                  ),
                ]),

                const _SectionHeader('About'),
                const _SettingsCard(children: [
                  _SettingsTile(
                    icon: Icons.verified_rounded,
                    color: AppColors.success,
                    title: 'App version',
                    subtitle:
                        '${AppConstants.appName} ${AppConstants.appVersion}',
                  ),
                ]),

                const SizedBox(height: AppDimensions.spaceXL),
                _SettingsCard(children: [
                  _SettingsTile(
                    icon: Icons.logout_rounded,
                    color: AppColors.error,
                    title: 'Log out',
                    titleColor: AppColors.error,
                    onTap: _logout,
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Profile header ─────────────────────────────────────────────
class _ProfileHeader extends StatelessWidget {
  final String initials;
  final String username;
  final String orgUnitName;

  const _ProfileHeader({
    required this.initials,
    required this.username,
    required this.orgUnitName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.spaceXL,
        AppDimensions.spaceXL,
        AppDimensions.spaceXL,
        AppDimensions.spaceXXL,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppDimensions.radiusXXL),
          bottomRight: Radius.circular(AppDimensions.radiusXXL),
        ),
      ),
      child: Row(
        children: [
          // Avatar with initials
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initials,
                style: AppTextStyles.headingMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spaceLG),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: AppTextStyles.headingSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppDimensions.spaceXS),
                Row(
                  children: [
                    const Icon(Icons.apartment_rounded,
                        color: Colors.white70,
                        size: AppDimensions.iconSM),
                    const SizedBox(width: AppDimensions.spaceXXS),
                    Flexible(
                      child: Text(
                        orgUnitName,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: Colors.white70),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section header ─────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.spaceSM,
        AppDimensions.spaceXL,
        AppDimensions.spaceSM,
        AppDimensions.spaceSM,
      ),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.labelMedium.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ── Card wrapper ───────────────────────────────────────────────
class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        // Clip so the InkWell ripple follows the rounded corners.
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
          child: Column(children: children),
        ),
      ),
    );
  }
}

// ── Tinted icon badge ──────────────────────────────────────────
class _TileIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _TileIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
      ),
      child: Icon(icon, color: color, size: AppDimensions.iconMD),
    );
  }
}

// ── Single tile ────────────────────────────────────────────────
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final Color? titleColor;
  final String? subtitle;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.color,
    required this.title,
    this.titleColor,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: color.withValues(alpha: 0.08),
      highlightColor: color.withValues(alpha: 0.04),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space,
          vertical: AppDimensions.spaceMD,
        ),
        child: Row(
          children: [
            _TileIcon(icon: icon, color: color),
            const SizedBox(width: AppDimensions.spaceMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: titleColor ?? AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (onTap != null)
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textHint,
                size: AppDimensions.iconLG,
              ),
          ],
        ),
      ),
    );
  }
}
