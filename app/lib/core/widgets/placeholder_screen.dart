import 'package:flutter/material.dart';
import 'package:vantia/core/widgets/empty_state.dart';
import 'package:vantia/l10n/l10n.dart';

/// Pantalla temporal para rutas cuya feature aún no se implementa.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    required this.title,
    required this.featureId,
    super.key,
  });

  final String title;
  final String featureId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ComingSoon(featureId: featureId),
    );
  }
}

class ComingSoon extends StatelessWidget {
  const ComingSoon({required this.featureId, super.key});

  final String featureId;

  @override
  Widget build(BuildContext context) => EmptyState(
    icon: Icons.construction_rounded,
    message: context.l10n.comingSoon(featureId),
  );
}
