import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vantia/app/providers.dart';
import 'package:vantia/core/time/clock.dart';
import 'package:vantia/features/subscription/data/subscription_service.dart';
import 'package:vantia/features/subscription/domain/plan.dart';

final planProvider = Provider<PlanStatus>(
  (ref) => PlanStatus.of(
    ref.watch(currentBusinessProvider).value,
    ref.watch(clockProvider)(),
  ),
);

final subscriptionServiceProvider = Provider<SubscriptionService>(
  (ref) => RevenueCatSubscriptionService(),
);
