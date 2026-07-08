import 'package:logger/logger.dart';

/// One logger for the whole app. Usage:
///   log.d('detail');  log.i('info');  log.w('warn');  log.e('error');
///
/// Levels let you silence chatter without deleting lines: set
/// [Logger.level] to Level.warning in release builds.
final log = Logger(
  printer: PrettyPrinter(
    methodCount: 0, // no stack trace per line — too noisy for flow logs
    colors: true,
    printEmojis: false,
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
);
