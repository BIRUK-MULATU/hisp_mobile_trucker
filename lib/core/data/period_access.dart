import '../database/app_database.dart';
import '../utils/app_logger.dart';

/// Pure domain rule: is a period open for data entry in this data set?
/// Consulted by the UI BEFORE allowing edits — the store itself stays
/// mechanical, and the DHIS2 server re-enforces expiry at import with
/// its own clock, so this gate protects the USER from entering data
/// that would bounce, not the server (which protects itself).
///
/// Tamper resistance: "now" is a HIGH-WATER MARK — the latest time this
/// app has ever observed (persisted in syncInfo, reset to server time
/// at each sync). Setting the device clock BACKWARDS therefore never
/// reopens a closed period: effectiveNow cannot decrease. Forward
/// tampering only closes periods early (fail-closed) and heals at the
/// next server contact.
class PeriodAccess {
  PeriodAccess(this._db);

  static const _hwmKey = 'clockHighWaterMark';
  static const _tamperKey = 'clockTamperedAt';

  /// Small slack so legitimate NTP corrections never false-flag.
  static const _backwardsTolerance = Duration(minutes: 2);

  final AppDatabase _db;
  DateTime? _hwmCache;

  /// Call at every session start (login, app resume). Compares now
  /// against the last seen local time; a backwards jump beyond the
  /// tolerance sets a PERSISTENT tamper flag. Returns true if the
  /// clock is currently flagged as tampered.
  ///
  /// The flag's purpose is visibility: the high-water mark already
  /// prevents expired periods from reopening, but the flag lets the UI
  /// refuse/warn on back-data entry explicitly — no silent fake
  /// "entered on time" narrative.
  Future<bool> checkAtSessionStart() async {
    final now = DateTime.now();
    final hwm = await _highWaterMark();
    if (hwm != null && now.isBefore(hwm.subtract(_backwardsTolerance))) {
      log.w('CLOCK TAMPER: now=${now.toIso8601String()} is before last '
          'seen ${hwm.toIso8601String()} — flag set');
      await _db.setSyncInfo(_tamperKey, hwm.toIso8601String());
      return true;
    }
    await _persist(now);
    return isClockTampered();
  }

  /// Is the persistent tamper flag set? UI contract: when true, show a
  /// clear error and refuse entry into past periods; entry into the
  /// CURRENT open period may continue (the data itself is fine — only
  /// backdating claims are suspect). Cleared by server contact.
  Future<bool> isClockTampered() async {
    final raw = await _db.getSyncInfo(_tamperKey);
    return raw != null && raw.isNotEmpty;
  }

  /// Reset the mark to authoritative server time (call at each sync /
  /// online login). Heals forward-tamper pollution AND clears the
  /// tamper flag — server time re-establishes truth.
  Future<void> anchorToServer(DateTime serverTime) async {
    await _persist(serverTime, force: true);
    await _db.setSyncInfo(_tamperKey, ''); // '' == cleared
  }

  /// The app's monotonic notion of now. Call sites: period gating only —
  /// data value lastModified stamps use plain DateTime.now() (v2 adds
  /// the server offset there).
  Future<DateTime> effectiveNow() async {
    final now = DateTime.now();
    final hwm = await _highWaterMark();
    if (hwm != null && hwm.isAfter(now)) {
      return hwm; // clock behind last observed: never go backwards
    }
    await _persist(now);
    return now;
  }

  /// Is [periodStart]..[periodEnd] open for entry in a data set with
  /// [expiryDays] and [openFuturePeriods] (period lengths ahead of the
  /// current one that may be entered)?
  ///
  /// - CLOSED when effectiveNow > periodEnd + expiryDays
  ///   (expiryDays == 0 means "never expires" in DHIS2).
  /// - CLOSED when the period starts beyond the allowed future window:
  ///   [periodsAhead] is how many period-lengths the candidate lies
  ///   after the current period (0 = current), computed by the caller
  ///   from the period sequence.
  Future<PeriodStatus> statusOf({
    required DateTime periodStart,
    required DateTime periodEnd,
    required int expiryDays,
    required int openFuturePeriods,
    required int periodsAhead,
  }) async {
    final now = await effectiveNow();

    if (periodsAhead > 0 && periodsAhead > openFuturePeriods) {
      return PeriodStatus.notYetOpen;
    }
    if (expiryDays > 0) {
      final deadline = periodEnd.add(Duration(days: expiryDays));
      if (now.isAfter(deadline)) return PeriodStatus.expired;
    }
    return PeriodStatus.open;
  }

  Future<bool> isOpen({
    required DateTime periodStart,
    required DateTime periodEnd,
    required int expiryDays,
    required int openFuturePeriods,
    required int periodsAhead,
  }) async =>
      await statusOf(
        periodStart: periodStart,
        periodEnd: periodEnd,
        expiryDays: expiryDays,
        openFuturePeriods: openFuturePeriods,
        periodsAhead: periodsAhead,
      ) ==
      PeriodStatus.open;

  // ── internals ──

  Future<DateTime?> _highWaterMark() async {
    if (_hwmCache != null) return _hwmCache;
    final raw = await _db.getSyncInfo(_hwmKey);
    _hwmCache = raw == null ? null : DateTime.tryParse(raw);
    return _hwmCache;
  }

  Future<void> _persist(DateTime t, {bool force = false}) async {
    final current = await _highWaterMark();
    if (force || current == null || t.isAfter(current)) {
      _hwmCache = t;
      await _db.setSyncInfo(_hwmKey, t.toIso8601String());
    }
  }
}

enum PeriodStatus { open, expired, notYetOpen }
