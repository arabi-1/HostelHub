import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'data/supabase_client.dart';

import 'features/notifications/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeSupabase();
  await NotificationService.instance.initialize();

  runApp(
    const ProviderScope(
      child: HostelHubApp(),
    ),
  );
}
