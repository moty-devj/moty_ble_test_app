import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:moty_test_app/dependency_injection/ble_service.dart';

import 'package:moty_test_app/dependency_injection/permission_service.dart';
import 'package:moty_test_app/page.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );

  GetIt.I.registerSingleton<PermissionService>(PermissionService());
  GetIt.I.registerSingleton<BleService>(BleService());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ble test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const PageScreen(),
    );
  }
}
