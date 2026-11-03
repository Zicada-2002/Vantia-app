import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vantia/app/providers.dart';
import 'package:vantia/app/router/routes.dart';
import 'package:vantia/app/router/session.dart';
import 'package:vantia/app/shell/app_drawer.dart';
import 'package:vantia/app/theme/tokens.dart';
import 'package:vantia/core/widgets/offline_banner.dart';
import 'package:vantia/features/products/application/product_providers.dart';
import 'package:vantia/l10n/l10n.dart';

/// Shell principal: menú lateral, AppBar por pestaña, barra inferior con
/// 4 pestañas y el FAB central "Registrar pago".
class HomeShell extends StatelessWidget {
  const HomeShell({required this.shell, super.key});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final titles = [
      l10n.titleHome,
      l10n.titlePayments,
      l10n.titleProducts,
      l10n.titleReports,
    ];
    final index = shell.currentIndex;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(titles[index]),
        actions: [
          if (index == 0) const _AvatarButton(),
          if (index == 2) const _ProductsMenu(),
          const SizedBox(width: VantiaSpacing.sm),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: shell),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox.square(
        dimension: 72,
        child: FloatingActionButton(
          tooltip: l10n.fabNewPayment,
          onPressed: () => context.push(Routes.newPayment),
          child: const Icon(Icons.add_rounded, size: 36),
        ),
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: index,
        onSelected: (i) => shell.goBranch(i, initialLocation: i == index),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.currentIndex, required this.onSelected});

  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = [
      (Icons.home_outlined, Icons.home_rounded, l10n.navHome),
      (Icons.payments_outlined, Icons.payments_rounded, l10n.navPayments),
      (
        Icons.shopping_bag_outlined,
        Icons.shopping_bag_rounded,
        l10n.navProducts,
      ),
      (Icons.bar_chart_outlined, Icons.bar_chart_rounded, l10n.navReports),
    ];

    Widget item(int i) {
      final (icon, selectedIcon, label) = items[i];
      final selected = i == currentIndex;
      final color = selected ? context.colors.primary : context.vColors.muted;
      return Expanded(
        child: Semantics(
          selected: selected,
          button: true,
          label: label,
          child: InkWell(
            onTap: () => onSelected(i),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? context.colors.surfaceContainerHigh
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(VantiaRadius.pill),
                  ),
                  child: Icon(selected ? selectedIcon : icon, color: color),
                ),
                const SizedBox(height: 4),
                ExcludeSemantics(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.labelMedium?.copyWith(color: color),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return BottomAppBar(
      color: context.colors.surfaceContainerLow,
      height: 80,
      padding: EdgeInsets.zero,
      child: Row(
        children: [
          item(0),
          item(1),
          const SizedBox(width: 88),
          item(2),
          item(3),
        ],
      ),
    );
  }
}

class _AvatarButton extends ConsumerWidget {
  const _AvatarButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initials = ref.watch(currentBusinessProvider).value?.initials ?? '';
    return IconButton(
      tooltip: context.l10n.titleUser,
      onPressed: () => context.push(Routes.user),
      icon: CircleAvatar(
        backgroundColor: context.colors.primaryContainer,
        child: Text(
          initials,
          style: context.text.labelLarge?.copyWith(
            color: context.colors.onPrimaryContainer,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ProductsMenu extends ConsumerWidget {
  const _ProductsMenu();

  Future<void> _scan(BuildContext context, WidgetRef ref) async {
    final code = await ref.read(barcodeScannerProvider)(context);
    if (code == null || !context.mounted) return;
    final s = ref.read(sessionProvider) as SessionReady;
    final existing = await ref
        .read(productRepositoryProvider)
        .findByBarcode(s.businessId, code);
    if (!context.mounted) return;
    await context.push(
      existing != null
          ? Routes.productEdit(existing.id)
          : Routes.productNewWithBarcode(code),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final s = ref.watch(sessionProvider);
    if (s is! SessionReady || !s.isOwner) return const SizedBox.shrink();
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'barcode',
          child: ListTile(
            leading: const Icon(Icons.qr_code_scanner_rounded),
            title: Text(l10n.productsMenuBarcode),
          ),
        ),
        PopupMenuItem(
          value: 'manual',
          child: ListTile(
            leading: const Icon(Icons.shopping_bag_rounded),
            title: Text(l10n.productsMenuNoBarcode),
          ),
        ),
      ],
      onSelected: (v) => v == 'barcode'
          ? _scan(context, ref)
          : context.push(Routes.productNew),
    );
  }
}
