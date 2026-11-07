import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vantia/app/router/session.dart';
import 'package:vantia/features/collaborators/domain/collaborators.dart';

import '../helpers/fakes.dart';
import '../helpers/pump_app.dart';

Future<void> _openCollaborators(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.menu));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Colaboradores'));
  await tester.pumpAndSettle();
}

void main() {
  test('Invite.effectiveStatus marca vencidos', () {
    final i = Invite(
      code: 'ABC234',
      status: InviteStatus.active,
      expiresAt: fixedNow.subtract(const Duration(minutes: 1)),
    );
    expect(i.effectiveStatus(fixedNow), InviteStatus.expired);
    expect(
      i.effectiveStatus(fixedNow.subtract(const Duration(hours: 1))),
      InviteStatus.active,
    );
  });

  testWidgets('generar, ver y revocar un código (F-30, F-31)', (tester) async {
    String? clipboard;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboard = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    final repo = FakeCollaboratorRepository();
    await tester.pumpVantiaApp(collaborators: repo);
    await _openCollaborators(tester);

    expect(
      find.text('Aún no has generado códigos de invitación'),
      findsOneWidget,
    );
    await tester.tap(find.text('Generar código de invitación'));
    await tester.pumpAndSettle();

    expect(find.text('ABC231'), findsWidgets);
    expect(find.textContaining('Vence en 48 horas'), findsOneWidget);
    await tester.tap(find.text('Copiar'));
    await tester.pumpAndSettle();
    expect(find.text('Código copiado'), findsOneWidget);
    expect(clipboard, 'ABC231');

    expect(find.text('Vigente · vence en 48 h'), findsOneWidget);
    await tester.tap(find.text('Revocar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Revocar'));
    await tester.pumpAndSettle();
    expect(find.text('Revocado'), findsOneWidget);
    expect(repo.invites.single.status, InviteStatus.revoked);
  });

  testWidgets('equipo: ventas de hoy y desactivar colaborador (F-32)', (
    tester,
  ) async {
    final repo = FakeCollaboratorRepository()
      ..members.addAll([
        const Member(
          uid: 'uid-owner',
          displayName: 'Carlos',
          role: MemberRole.owner,
          active: true,
        ),
        const Member(
          uid: 'uid-ana',
          displayName: 'Ana Pérez',
          role: MemberRole.collaborator,
          active: true,
        ),
      ]);
    final payments = FakePaymentRepository(clock: () => fixedNow)
      ..seed(
        fakePayment(
          id: 'a',
          cents: 2500,
          createdBy: 'uid-ana',
          createdByName: 'Ana',
        ),
      );
    await tester.pumpVantiaApp(collaborators: repo, payments: payments);
    await _openCollaborators(tester);

    expect(find.text('Ana Pérez'), findsOneWidget);
    expect(find.textContaining('Hoy: S/ 25.00'), findsOneWidget);
    expect(find.text('Desactivar'), findsOneWidget); // no para el dueño

    await tester.tap(find.text('Desactivar'));
    await tester.pumpAndSettle();
    expect(find.text('¿Desactivar a Ana Pérez?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Desactivar'));
    await tester.pumpAndSettle();

    expect(repo.setActiveCalls, [('uid-ana', false)]);
    expect(find.text('Reactivar'), findsOneWidget);
    expect(find.textContaining('Desactivado'), findsOneWidget);
  });
}
