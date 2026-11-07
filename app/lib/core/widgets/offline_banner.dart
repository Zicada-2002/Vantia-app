import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vantia/app/theme/tokens.dart';
import 'package:vantia/features/payments/application/payment_providers.dart';
import 'package:vantia/l10n/l10n.dart';

/// F-27: banner global cuando no hay conexión.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline = ref.watch(offlineProvider).value ?? false;
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: offline
          ? Material(
              color: context.vColors.warning.withValues(alpha: 0.18),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: VantiaSpacing.md,
                  vertical: VantiaSpacing.sm,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.wifi_off_rounded,
                      color: context.vColors.warning,
                    ),
                    const SizedBox(width: VantiaSpacing.sm),
                    Expanded(child: Text(context.l10n.offlineBanner)),
                  ],
                ),
              ),
            )
          : const SizedBox(width: double.infinity),
    );
  }
}
