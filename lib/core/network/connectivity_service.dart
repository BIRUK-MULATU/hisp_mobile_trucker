import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'network_info.dart';

/// App-wide ONLINE truth = "can we actually reach the DHIS2 server",
/// not "does the OS report a network interface". Browser/OS
/// connectivity events are unreliable (Linux Chrome often never fires
/// them) and a connected interface can still have no internet — so
/// this service probes `/system/ping` and treats ANY HTTP response as
/// online (401 included: an auth error still proves reachability).
/// Only a transport failure (timeout / connection error) means offline.
///
/// Probe triggers: startup, every [_interval], every connectivity
/// event, and manual [checkNow] (the indicator taps into this).
class ConnectivityService extends ChangeNotifier {
  ConnectivityService._() {
    _subscription = ConnectivityNetworkInfo()
        .onConnectivityChanged
        .listen((_) => checkNow());
    _timer = Timer.periodic(_interval, (_) => checkNow());
    unawaited(checkNow());
  }

  static final ConnectivityService instance = ConnectivityService._();

  static const _interval = Duration(seconds: 30);

  // Bare client on purpose: the app's ApiClient carries auth
  // interceptors (a 401 there ends the session — a ping must never
  // do that). X-Requested-With is load-bearing: without it an
  // unauthenticated DHIS2 replies 302 → plain-http login page, which
  // the browser blocks (mixed content, no CORS) and the probe would
  // read as offline. With it the server answers 401 JSON in place —
  // reachability proven.
  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
    validateStatus: (_) => true,
    headers: {'X-Requested-With': 'XMLHttpRequest'},
  ));

  StreamSubscription<bool>? _subscription;
  Timer? _timer;
  bool _checking = false;

  bool? _online;

  /// null until the first probe answers.
  bool? get online => _online;

  DateTime? lastChecked;

  Future<void> checkNow() async {
    if (_checking) return;
    _checking = true;
    try {
      await _dio.get('${ApiClient().baseUrl}/system/ping');
      _set(true);
    } on DioException {
      _set(false);
    } catch (_) {
      _set(false);
    } finally {
      lastChecked = DateTime.now();
      _checking = false;
    }
  }

  void _set(bool value) {
    if (_online == value) return;
    _online = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _timer?.cancel();
    super.dispose();
  }
}
