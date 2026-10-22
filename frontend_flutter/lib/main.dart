import 'package:flutter/material.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'services/system_api.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(SystemApp(api: SystemApi(baseUrl: AppConfig.apiBaseUrl)));
}
