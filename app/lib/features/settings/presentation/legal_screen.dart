import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vantia/app/theme/tokens.dart';

/// Términos y privacidad empaquetados en la app (F-83).
class LegalScreen extends StatelessWidget {
  const LegalScreen({required this.title, required this.asset, super.key});

  final String title;
  final String asset;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: FutureBuilder<String>(
      future: rootBundle.loadString(asset),
      builder: (context, snap) => snap.hasData
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(VantiaSpacing.page),
              child: SelectableText(snap.data!, style: context.text.bodyLarge),
            )
          : const Center(child: CircularProgressIndicator()),
    ),
  );
}
