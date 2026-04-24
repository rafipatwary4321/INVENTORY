import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_settings.dart';
import '../services/settings_service.dart';

/// Business name + currency from `settings/business`.
class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._service) {
    _sub = _service.settingsStream().listen((s) {
      _settings = s;
      notifyListeners();
    });
  }

  final SettingsService _service;
  StreamSubscription<AppSettings>? _sub;

  AppSettings _settings = AppSettings(businessName: 'My Business', currency: 'BDT');
  AppSettings get settings => _settings;

  Future<void> save(AppSettings s) => _service.save(s);

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
