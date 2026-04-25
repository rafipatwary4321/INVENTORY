import 'dart:async';

import '../constants/app_constants.dart';

/// Runtime business scope used by services for multitenant Firestore paths.
class BusinessScope {
  BusinessScope._();

  static String _businessId = AppConstants.demoBusinessId;
  static final _broadcastController = StreamController<String>.broadcast();
  static Stream<String> get _broadcast => _broadcastController.stream;
  static final _controller = Stream<String>.multi((multi) {
    multi.add(_businessId);
    final sub = _broadcast.listen(multi.add);
    multi.onCancel = sub.cancel;
  }).asBroadcastStream();

  static String get businessId => _businessId;
  static Stream<String> get changes => _controller;

  static void setBusinessId(String id) {
    final normalized = id.trim();
    if (normalized.isEmpty) return;
    if (_businessId == normalized) return;
    _businessId = normalized;
    _broadcastController.add(_businessId);
  }
}
