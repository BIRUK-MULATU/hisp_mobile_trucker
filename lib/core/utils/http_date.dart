import 'package:intl/intl.dart';

/// Web-safe replacement for dart:io's HttpDate.parse (dart:io is not
/// available on web). Parses the RFC-1123 dates servers send in the
/// HTTP Date header (e.g. "Tue, 08 Jul 2026 13:05:00 GMT") as UTC.
/// Throws FormatException on malformed input — callers already guard.
DateTime parseHttpDate(String value) =>
    DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'", 'en_US')
        .parseUtc(value.trim());
