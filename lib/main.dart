import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';

import 'branding.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'providers/app_state.dart';
import 'theme/app_theme.dart';

void main() {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  runApp(const PassForgeApp());
}

class PassForgeApp extends StatelessWidget {
  const PassForgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      lazy: false,
      create: (_) => AppState()..init(),
      child: Consumer<AppState>(
        builder: (context, state, _) {
          return MaterialApp(
            title: AppBranding.name,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            builder: (context, child) {
              final mq = MediaQuery.of(context);
              return MediaQuery(
                data: mq.copyWith(
                  textScaler: TextScaler.linear(state.textScale),
                ),
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: const _BootGate(),
          );
        },
      ),
    );
  }
}

class _BootGate extends StatefulWidget {
  const _BootGate();

  @override
  State<_BootGate> createState() => _BootGateState();
}

class _BootGateState extends State<_BootGate> {
  bool _splashRemoved = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    if (state.ready && !_splashRemoved) {
      _splashRemoved = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FlutterNativeSplash.remove();
      });
    }

    if (state.bootError != null) {
      FlutterNativeSplash.remove();
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Failed to load Philippine question banks:\n${state.bootError}'),
          ),
        ),
      );
    }
    if (!state.ready) {
      return const Scaffold(
        body: SizedBox.shrink(),
      );
    }
    if (!state.hasSeenGuide) {
      return const OnboardingScreen();
    }
    return const HomeScreen();
  }
}
