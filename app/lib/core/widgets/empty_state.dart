import 'package:flutter/material.dart';
import 'package:vantia/app/theme/tokens.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.message,
    super.key,
    this.icon = Icons.inventory_2_outlined,
    this.badge,
    this.action,
  });

  final String message;
  final IconData icon;

  /// Contador opcional sobre el ícono (p. ej. "0" productos).
  final String? badge;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(VantiaSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 120,
                  color: context.colors.surfaceContainerHighest,
                ),
                if (badge != null)
                  Positioned(
                    right: -8,
                    bottom: 4,
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: context.colors.primaryContainer,
                      child: Text(
                        badge!,
                        style: context.text.titleMedium?.copyWith(
                          color: context.colors.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: VantiaSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.text.bodyLarge?.copyWith(
                color: context.vColors.muted,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: VantiaSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
