import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // .env khusus dev — key disemai ke secure storage saat bootstrap (lihat di.dart).
  // isOptional: true agar app tetap jalan kalau .env tidak ada (mis. rilis).
  await dotenv.load(fileName: '.env', isOptional: true);

  runApp(const ProviderScope(child: DiaApp()));
}
