import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/security/app_lock_service.dart';
import 'core/theme/app_theme.dart';
import 'services/session_manager.dart';
import 'ui/screens/mpin_lock_screen.dart';
import 'ui/screens/mpin_setup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Edge-to-edge transparent system bars with light icons for modern mobile UI
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  final isMpinSet = await AppLockService.instance.isMpinSet();

  runApp(PocketOpsApp(isMpinSet: isMpinSet));
}

class PocketOpsApp extends StatelessWidget {
  final bool isMpinSet;

  const PocketOpsApp({super.key, this.isMpinSet = false});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SessionManager()),
      ],
      child: MaterialApp(
        title: 'PocketOps',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: isMpinSet ? const MpinLockScreen() : const MpinSetupScreen(),
      ),
    );
  }
}
