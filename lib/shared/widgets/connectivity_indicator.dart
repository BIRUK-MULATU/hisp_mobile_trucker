import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/network/connectivity_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Small connection pill for app bars, DHIS2-style but unobtrusive:
/// a green/red wifi dot that expands to say "Online"/"Offline" for a
/// few seconds whenever the state changes, then collapses back to the
/// icon. Tapping it re-checks the server right now and shows the
/// label again. Driven by [ConnectivityService] (real server
/// reachability, not just the network interface).
class ConnectivityIndicator extends StatefulWidget {
  const ConnectivityIndicator({super.key});

  /// How long the expanded label stays before collapsing to the dot.
  static const labelDuration = Duration(seconds: 5);

  @override
  State<ConnectivityIndicator> createState() => _ConnectivityIndicatorState();
}

class _ConnectivityIndicatorState extends State<ConnectivityIndicator> {
  bool? _online;
  bool _expanded = false;
  Timer? _collapseTimer;

  @override
  void initState() {
    super.initState();
    _online = ConnectivityService.instance.online;
    if (_online != null) _showLabel();
    ConnectivityService.instance.addListener(_onChanged);
  }

  @override
  void dispose() {
    ConnectivityService.instance.removeListener(_onChanged);
    _collapseTimer?.cancel();
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) return;
    setState(() => _online = ConnectivityService.instance.online);
    _showLabel();
  }

  void _showLabel() {
    _collapseTimer?.cancel();
    setState(() => _expanded = true);
    _collapseTimer = Timer(ConnectivityIndicator.labelDuration, () {
      if (mounted) setState(() => _expanded = false);
    });
  }

  void _onTap() {
    unawaited(ConnectivityService.instance.checkNow());
    _showLabel();
  }

  @override
  Widget build(BuildContext context) {
    final online = _online;
    if (online == null) return const SizedBox.shrink();

    final color = online ? AppColors.success : AppColors.error;
    // On narrow phones the expanded label yields to the app bar's
    // other actions — cap it so nothing overflows.
    final maxLabelWidth = MediaQuery.of(context).size.width * 0.3;

    return Center(
      child: Tooltip(
        message: online
            ? 'Connected to the server'
            : 'No server connection — changes are saved on this device',
        child: InkWell(
          onTap: _onTap,
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            height: 26,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white70, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  online ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                  size: 14,
                  color: Colors.white,
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  child: _expanded
                      ? Container(
                          constraints:
                              BoxConstraints(maxWidth: maxLabelWidth),
                          padding: const EdgeInsets.only(left: 4, right: 2),
                          child: Text(
                            online ? 'Online' : 'Offline',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
