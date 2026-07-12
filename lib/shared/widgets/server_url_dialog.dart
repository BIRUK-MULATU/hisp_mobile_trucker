import 'package:flutter/material.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/connectivity_service.dart';
import '../../core/storage/secure_storage.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_text_styles.dart';

/// Normalize what a user types into a DHIS2 API base URL, or return
/// null when it cannot be one. Accepts bare hosts ("hmis.moh.gov.et"),
/// adds https:// and the /api suffix, strips trailing slashes.
String? normalizeServerUrl(String input) {
  var url = input.trim();
  if (url.isEmpty) return null;
  if (!url.startsWith('http://') && !url.startsWith('https://')) {
    url = 'https://$url';
  }
  while (url.endsWith('/')) {
    url = url.substring(0, url.length - 1);
  }
  final uri = Uri.tryParse(url);
  if (uri == null || uri.host.isEmpty) return null;
  if (!url.endsWith('/api')) url = '$url/api';
  return url;
}

/// Server-URL editor shared by Settings and the login page. Persists
/// the choice, points the ApiClient at it, and re-probes reachability.
/// Returns the saved URL, or null when the user cancelled.
Future<String?> showServerUrlDialog(BuildContext context) async {
  final stored = await SecureStorage().getBaseUrl();
  final current =
      (stored == null || stored.isEmpty) ? ApiConstants.baseUrl : stored;
  if (!context.mounted) return null;

  final result = await showDialog<String>(
    context: context,
    builder: (_) => _ServerUrlDialog(initialUrl: current),
  );

  if (result == null || result == current) return null;

  await SecureStorage().saveBaseUrl(result);
  ApiClient().updateBaseUrl(result);
  // The online pill must reflect the NEW server right away.
  await ConnectivityService.instance.checkNow();
  return result;
}

/// Owns the text controller so it is disposed when the dialog truly
/// unmounts (after the close animation) — disposing it right after
/// showDialog returns kills it while the field is still animating out.
class _ServerUrlDialog extends StatefulWidget {
  const _ServerUrlDialog({required this.initialUrl});

  final String initialUrl;

  @override
  State<_ServerUrlDialog> createState() => _ServerUrlDialogState();
}

class _ServerUrlDialogState extends State<_ServerUrlDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialUrl);
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final url = normalizeServerUrl(_controller.text);
    if (url == null) {
      setState(() => _errorText = 'Enter a valid server address');
    } else {
      Navigator.pop(context, url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
      ),
      title: const Text('DHIS2 Server', style: AppTextStyles.headingSmall),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'The app will send and fetch data from this server. '
            'Changing it requires logging in again.',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppDimensions.spaceMD),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.url,
            autocorrect: false,
            autofocus: true,
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: 'https://server/api',
              errorText: _errorText,
              prefixIcon:
                  const Icon(Icons.link_rounded, size: AppDimensions.iconMD),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
