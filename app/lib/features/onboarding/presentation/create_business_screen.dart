import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vantia/app/providers.dart';
import 'package:vantia/app/theme/tokens.dart';
import 'package:vantia/core/observability/analytics.dart';
import 'package:vantia/core/result/result.dart';
import 'package:vantia/core/validation/validators.dart';
import 'package:vantia/core/widgets/error_messages.dart';
import 'package:vantia/core/widgets/v_button.dart';
import 'package:vantia/core/widgets/v_text_field.dart';
import 'package:vantia/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:vantia/features/business/domain/business.dart';
import 'package:vantia/features/business/domain/peru_locations.dart';
import 'package:vantia/l10n/l10n.dart';

/// F-16: el dueño registra su negocio (inicia la prueba de 7 días).
class CreateBusinessScreen extends ConsumerStatefulWidget {
  const CreateBusinessScreen({super.key});

  @override
  ConsumerState<CreateBusinessScreen> createState() =>
      _CreateBusinessScreenState();
}

class _CreateBusinessScreenState extends ConsumerState<CreateBusinessScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _province = TextEditingController();
  String? _department;
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _province.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    final result = await ref
        .read(businessRepositoryProvider)
        .createBusiness(
          CreateBusinessInput(
            name: _name.text,
            phone: Validators.normalizePhone(_phone.text),
            department: _department!,
            province: _province.text,
          ),
        );
    if (!mounted) return;
    setState(() => _loading = false);
    switch (result) {
      case Ok():
        // El perfil se actualiza vía stream y el router lleva a Inicio.
        await ref.read(analyticsProvider).log(AnalyticsEvent.businessCreated);
      case Err(:final failure):
        if (mounted) showSnack(context, failureMessage(context.l10n, failure));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AuthScaffold(
      showBack: true,
      showLogo: false,
      title: l10n.businessTitle,
      subtitle: l10n.businessSubtitle,
      children: [
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VTextField(
                label: l10n.fieldBusinessName,
                hint: l10n.hintBusinessName,
                controller: _name,
                textInputAction: TextInputAction.next,
                validator: validatorFor(context, Validators.name),
              ),
              const SizedBox(height: VantiaSpacing.md),
              VTextField(
                label: l10n.fieldPhone,
                hint: l10n.hintPhone,
                prefixText: '+51 ',
                controller: _phone,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d ]')),
                  LengthLimitingTextInputFormatter(11),
                ],
                validator: validatorFor(context, Validators.phone),
              ),
              const SizedBox(height: VantiaSpacing.md),
              Text(
                l10n.fieldDepartment,
                style: context.text.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: VantiaSpacing.sm),
              DropdownButtonFormField<String>(
                initialValue: _department,
                isExpanded: true,
                items: [
                  for (final d in peruDepartments)
                    DropdownMenuItem(value: d, child: Text(d)),
                ],
                onChanged: (v) => setState(() {
                  _department = v;
                  if (_province.text.isEmpty && v != null) _province.text = v;
                }),
                validator: validatorFor(context, Validators.required),
              ),
              const SizedBox(height: VantiaSpacing.md),
              VTextField(
                label: l10n.fieldProvince,
                hint: l10n.hintProvince,
                controller: _province,
                textInputAction: TextInputAction.done,
                validator: validatorFor(context, Validators.required),
              ),
            ],
          ),
        ),
        const SizedBox(height: VantiaSpacing.xl),
        VButton(
          label: l10n.businessCreate,
          loading: _loading,
          onPressed: _submit,
        ),
      ],
    );
  }
}
