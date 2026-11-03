import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vantia/app/providers.dart';
import 'package:vantia/app/router/session.dart';
import 'package:vantia/app/theme/tokens.dart';
import 'package:vantia/core/money/money.dart';
import 'package:vantia/core/observability/analytics.dart';
import 'package:vantia/core/widgets/empty_state.dart';
import 'package:vantia/core/widgets/money_text.dart';
import 'package:vantia/core/widgets/v_card.dart';
import 'package:vantia/features/reports/application/report_providers.dart';
import 'package:vantia/features/reports/domain/report.dart';
import 'package:vantia/l10n/l10n.dart';

/// M5: reportes Semana / Mes / Año (F-51 … F-53).
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  ReportPeriod _period = ReportPeriod.week;

  @override
  void initState() {
    super.initState();
    _log();
  }

  void _log() => ref.read(analyticsProvider).log(AnalyticsEvent.reportViewed, {
    'period': _period.name,
  }).ignore();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final session = ref.watch(sessionProvider);
    if (session is SessionReady && !session.isOwner) {
      return EmptyState(
        icon: Icons.lock_outline_rounded,
        message: l10n.reportOwnerOnly,
      );
    }
    final report = ref.watch(reportProvider(_period));
    final r = report.value;
    final periodTitle = switch (_period) {
      ReportPeriod.week => l10n.reportThisWeek,
      ReportPeriod.month => l10n.reportThisMonth,
      ReportPeriod.year => l10n.reportThisYear,
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        VantiaSpacing.page,
        VantiaSpacing.sm,
        VantiaSpacing.page,
        VantiaSpacing.bottomSafe,
      ),
      children: [
        SegmentedButton<ReportPeriod>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
              value: ReportPeriod.week,
              label: Text(l10n.reportWeek),
            ),
            ButtonSegment(
              value: ReportPeriod.month,
              label: Text(l10n.reportMonth),
            ),
            ButtonSegment(
              value: ReportPeriod.year,
              label: Text(l10n.reportYear),
            ),
          ],
          selected: {_period},
          onSelectionChanged: (s) {
            setState(() => _period = s.first);
            _log();
          },
        ),
        const SizedBox(height: VantiaSpacing.md),
        VCard(
          highlight: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(periodTitle),
              MoneyText(
                r?.total ?? const Money.zero(),
                style: context.text.headlineLarge?.copyWith(
                  color: context.vColors.onHighlight,
                ),
              ),
              if (r?.changePercent case final pct?)
                Text(
                  l10n.reportVsPrevious(
                    '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(0)} %',
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: VantiaSpacing.md),
        if (r == null)
          const Padding(
            padding: EdgeInsets.all(VantiaSpacing.xl),
            child: Center(child: CircularProgressIndicator()),
          )
        else ...[
          VCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.reportIncome, style: context.text.titleMedium),
                const SizedBox(height: VantiaSpacing.md),
                SizedBox(height: 220, child: _BarChart(report: r)),
              ],
            ),
          ),
          const SizedBox(height: VantiaSpacing.md),
          Row(
            children: [
              _Kpi(
                icon: Icons.attach_money_rounded,
                color: context.vColors.warning,
                label: l10n.reportCash,
                value: '${r.cashCount}',
              ),
              const SizedBox(width: VantiaSpacing.sm),
              _Kpi(
                icon: Icons.credit_card_rounded,
                color: context.colors.primary,
                label: l10n.reportDigital,
                value: '${r.digitalCount}',
              ),
              const SizedBox(width: VantiaSpacing.sm),
              _Kpi(
                icon: Icons.trending_up_rounded,
                color: context.vColors.success,
                label: l10n.reportBest,
                value: r.best?.label ?? '—',
              ),
            ],
          ),
          const SizedBox(height: VantiaSpacing.md),
          VCard(
            child: Row(
              children: [
                Expanded(child: Text(l10n.reportAvgTicket)),
                MoneyText(r.averageTicket, style: context.text.titleMedium),
              ],
            ),
          ),
          const SizedBox(height: VantiaSpacing.md),
          _MethodsCard(report: r),
        ],
      ],
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
    child: VCard(
      padding: const EdgeInsets.symmetric(
        vertical: VantiaSpacing.md,
        horizontal: 8,
      ),
      radius: VantiaRadius.md,
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: VantiaSpacing.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label, style: context.text.labelMedium),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: context.text.titleMedium),
          ),
        ],
      ),
    ),
  );
}

class _BarChart extends StatelessWidget {
  const _BarChart({required this.report});

  final Report report;

  @override
  Widget build(BuildContext context) {
    final values = [for (final b in report.buckets) b.total.cents / 100];
    final max = values.fold<double>(0, (a, b) => b > a ? b : a);
    final barColor = context.colors.primary;
    final muted = context.vColors.muted;
    return Semantics(
      label: [
        for (final b in report.buckets) '${b.label}: ${b.total.format()}',
      ].join(', '),
      child: ExcludeSemantics(
        child: BarChart(
          BarChartData(
            maxY: max == 0 ? 10 : max * 1.15,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                  report.buckets[group.x].total.format(),
                  TextStyle(color: context.colors.onSurface),
                ),
              ),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (v, meta) => Text(
                    v == meta.max ? '' : v.toStringAsFixed(0),
                    style: TextStyle(color: muted, fontSize: 10),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) => Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      report.buckets[v.toInt()].label,
                      style: TextStyle(color: muted, fontSize: 11),
                    ),
                  ),
                ),
              ),
            ),
            barGroups: [
              for (var i = 0; i < values.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: values[i],
                      color: barColor,
                      width: report.period == ReportPeriod.year ? 12 : 22,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MethodsCard extends StatelessWidget {
  const _MethodsCard({required this.report});

  final Report report;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final shares = report.methodShares;
    return VCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.reportMethods, style: context.text.titleMedium),
          const SizedBox(height: VantiaSpacing.md),
          if (shares.isEmpty)
            Text(
              l10n.reportNoData,
              style: TextStyle(color: context.vColors.muted),
            )
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(VantiaRadius.pill),
              child: SizedBox(
                height: 14,
                child: Row(
                  children: [
                    for (final (m, v, _) in shares)
                      Expanded(
                        flex: v.cents.clamp(1, 1 << 31),
                        child: ColoredBox(color: m.color),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: VantiaSpacing.md),
            for (final (m, v, pct) in shares)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    CircleAvatar(radius: 6, backgroundColor: m.color),
                    const SizedBox(width: VantiaSpacing.sm),
                    Expanded(child: Text(m.label)),
                    MoneyText(v),
                    const SizedBox(width: VantiaSpacing.sm),
                    SizedBox(
                      width: 48,
                      child: Text(
                        '${pct.toStringAsFixed(0)} %',
                        textAlign: TextAlign.end,
                        style: TextStyle(color: context.vColors.muted),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
