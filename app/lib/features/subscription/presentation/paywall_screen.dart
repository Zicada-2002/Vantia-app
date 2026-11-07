import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vantia/app/providers.dart';
import 'package:vantia/app/router/session.dart';
import 'package:vantia/app/theme/tokens.dart';
import 'package:vantia/core/observability/analytics.dart';
import 'package:vantia/core/widgets/error_messages.dart';
import 'package:vantia/core/widgets/v_button.dart';
import 'package:vantia/features/subscription/application/plan_providers.dart';
import 'package:vantia/features/subscription/data/subscription_service.dart';
import 'package:vantia/features/subscription/presentation/plan_card.dart';
import 'package:vantia/l10n/l10n.dart';

/// F-85: "Mejorar ahora".
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  late Future<List<SubscriptionOption>> _options;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    ref.read(analyticsProvider).log(AnalyticsEvent.paywallViewed).ignore();
    _options = _load();
  }

  Future<List<SubscriptionOption>> _load() async {
    final service = ref.read(subscriptionServiceProvider);
    final s = ref.read(sessionProvider);
    if (!service.isAvailable || s is! SessionReady) return const [];
    await service.identify(s.businessId);
    return await service.options();
  }

  Future<void> _run(Future<bool> Function() action) async {
    setState(() => _busy = true);
    final l10n = context.l10n;
    try {
      final ok = await action();
      if (!mounted) return;
      if (ok) {
        ref
            .read(analyticsProvider)
            .log(AnalyticsEvent.subscriptionStarted)
            .ignore();
        showSnack(context, l10n.paywallSuccess);
        context.pop();
      }
    } on Object {
      if (mounted) showSnack(context, l10n.errUnknown);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final service = ref.watch(subscriptionServiceProvider);
    final session = ref.watch(sessionProvider);
    final isOwner = session is SessionReady && session.isOwner;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.paywallTitle)),
      body: ListView(
        padding: const EdgeInsets.all(VantiaSpacing.page),
        children: [
          const PlanCard(),
          const SizedBox(height: VantiaSpacing.lg),
          if (!isOwner)
            Text(l10n.paywallOwnerOnly)
          else if (!service.isAvailable)
            Text(l10n.paywallUnavailable)
          else
            FutureBuilder<List<SubscriptionOption>>(
              future: _options,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Column(
                  children: [
                    for (final o in snap.data!)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: VantiaSpacing.sm,
                        ),
                        child: VButton(
                          label: '${o.title} · ${o.price}',
                          loading: _busy,
                          onPressed: () => _run(() => service.purchase(o)),
                        ),
                      ),
                    VButton(
                      variant: VButtonVariant.text,
                      label: l10n.paywallRestore,
                      onPressed: _busy ? null : () => _run(service.restore),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
