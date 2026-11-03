import 'package:flutter/material.dart';
import 'package:vantia/app/theme/tokens.dart';
import 'package:vantia/features/auth/presentation/widgets/auth_scaffold.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          VantiaLogo(size: 72),
          SizedBox(height: VantiaSpacing.xl),
          SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ],
      ),
    ),
  );
}
