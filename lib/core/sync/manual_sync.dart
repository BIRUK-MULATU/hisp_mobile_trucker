import 'package:flutter/foundation.dart';

import '../auth/app_session.dart';
import '../data/completeness.dart';
import '../data/data_value_store.dart';
import '../network/connectivity_service.dart';
import 'drift_sync_manager.dart';

/// What a user-triggered sync ended as — one message per outcome so
/// every sync button in the app (home, report period) tells the same
/// story.
enum ManualSyncOutcome { offline, nothingToSync, uploaded, partial, failed }

class ManualSyncResult {
  final ManualSyncOutcome outcome;

  /// Pending entries (values + completions) before the push.
  final int pendingBefore;

  /// Entries still pending after the push (partial failures).
  final int remaining;

  /// Device-only drafts — reported when there is nothing to push so
  /// "everything synced" doesn't read as "nothing left on this phone".
  final int drafts;

  const ManualSyncResult(
    this.outcome, {
    this.pendingBefore = 0,
    this.remaining = 0,
    this.drafts = 0,
  });

  /// True when the push ran — lists showing sync state should reload.
  bool get pushedAnything =>
      outcome == ManualSyncOutcome.uploaded ||
      outcome == ManualSyncOutcome.partial;

  String get message {
    String entries(int n) => '$n ${n == 1 ? 'entry' : 'entries'}';
    switch (outcome) {
      case ManualSyncOutcome.offline:
        return pendingBefore > 0
            ? 'No internet connection — ${entries(pendingBefore)} will '
                'upload automatically when you are back online.'
            : 'No internet connection.';
      case ManualSyncOutcome.nothingToSync:
        return drafts > 0
            ? 'Everything is synced. $drafts draft '
                '${drafts == 1 ? 'value stays' : 'values stay'} on this '
                'device until the data set is completed.'
            : 'Everything is already synced.';
      case ManualSyncOutcome.uploaded:
        return 'Sync complete — ${entries(pendingBefore)} uploaded.';
      case ManualSyncOutcome.partial:
        return '$remaining of $pendingBefore entries could not be '
            'uploaded and will retry later.';
      case ManualSyncOutcome.failed:
        return 'Sync failed — your entries are safe on this device and '
            'will retry automatically.';
    }
  }
}

/// The one manual "sync now": count pending work, probe connectivity
/// fresh (the cached flag can be up to 30s stale), push everything
/// pending, then best-effort metadata refresh. [onPushStart] fires
/// only when an upload actually begins — drive the button spinner
/// from it.
Future<ManualSyncResult> runManualSync({VoidCallback? onPushStart}) async {
  final session = AppSession.instance;
  if (!session.isLoggedIn) return const ManualSyncResult(ManualSyncOutcome.failed);

  final db = session.service.db;
  final store = DataValueStore(db);
  final pendingValues = await store.pendingCount();
  final pendingCompletions = (await CompletenessStore(db).pending()).length;
  final pendingTotal = pendingValues + pendingCompletions;

  await ConnectivityService.instance.checkNow();
  final online = ConnectivityService.instance.online ?? false;
  if (!online) {
    return ManualSyncResult(ManualSyncOutcome.offline,
        pendingBefore: pendingTotal, remaining: pendingTotal);
  }
  if (pendingTotal == 0) {
    return ManualSyncResult(ManualSyncOutcome.nothingToSync,
        drafts: await store.draftCount());
  }

  onPushStart?.call();
  try {
    await DriftSyncManager.instance.pushPending();
    // Refresh metadata too, but a metadata hiccup must not mask a
    // successful upload.
    try {
      await DriftSyncManager.instance.pullLatest();
    } catch (e) {
      debugPrint('metadata refresh after sync failed: $e');
    }
    final remaining = await store.pendingCount() +
        (await CompletenessStore(db).pending()).length;
    return ManualSyncResult(
      remaining == 0 ? ManualSyncOutcome.uploaded : ManualSyncOutcome.partial,
      pendingBefore: pendingTotal,
      remaining: remaining,
    );
  } catch (e) {
    debugPrint('manual sync failed: $e');
    return ManualSyncResult(ManualSyncOutcome.failed,
        pendingBefore: pendingTotal, remaining: pendingTotal);
  }
}
