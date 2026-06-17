class ApiConstants {
  ApiConstants._();

  // ── DHIS2 Endpoints ────────────────────────────────────────
  static const String baseUrl = 'http://localhost:8090/api';
  static const String loginEndpoint = '/me';
  static const String meEndpoint = '/me';
  static const String programsEndpoint = '/programs';
  static const String dataElementsEndpoint = '/dataElements';
  static const String eventsEndpoint = '/events';
  static const String trackedEntityEndpoint = '/trackedEntityInstances';

  // ── Timeouts (milliseconds) ────────────────────────────────
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;
  static const int sendTimeout = 30000;

  // ── API Version ────────────────────────────────────────────
  static const String apiVersion = '40';

  // ── Headers ────────────────────────────────────────────────
  static const String contentType = 'application/json';
  static const String accept = 'application/json';
}
