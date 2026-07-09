import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// One logger for the whole app. Usage:
///   log.d('detail');  log.i('info');  log.w('warn');  log.e('error');
///
/// Release builds only surface warnings and errors — request/response
/// detail must not reach a field device's logcat.
final log = Logger(
  level: kReleaseMode ? Level.warning : Level.debug,
  printer: PrettyPrinter(
    methodCount: 0, // no stack trace per line — too noisy for flow logs
    colors: true,
    printEmojis: false,
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
);
