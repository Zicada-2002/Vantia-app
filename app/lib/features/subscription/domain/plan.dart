import 'package:flutter/foundation.dart';
import 'package:vantia/features/business/domain/business.dart';

enum PlanTier { free, trial, pro }

/// Estado del plan del negocio (F-84).
@immutable
class PlanStatus {
  const PlanStatus({required this.tier, this.trialDaysLeft = 0});

  factory PlanStatus.of(Business? b, DateTime now) {
    if (b == null) return const PlanStatus(tier: PlanTier.free);
    final end = b.trialEndsAt;
    if (b.planTier == 'pro') return const PlanStatus(tier: PlanTier.pro);
    if (b.planTier == 'trial' && end != null && end.isAfter(now)) {
      final days = (end.difference(now).inMinutes / (24 * 60)).ceil();
      return PlanStatus(
        tier: PlanTier.trial,
        trialDaysLeft: days.clamp(0, 365),
      );
    }
    return const PlanStatus(tier: PlanTier.free);
  }

  final PlanTier tier;
  final int trialDaysLeft;

  /// Funciones Pro activas (pagado o prueba vigente).
  bool get isPro => tier != PlanTier.free;
}

/// Límite de colaboradores en el plan Free.
const freeCollaboratorLimit = 1;
