import 'package:flutter/material.dart';
import 'package:vantia/app/theme/tokens.dart';
import 'package:vantia/l10n/l10n.dart';

/// Diálogo que pide un motivo (mín. 3 caracteres). Devuelve el texto o null.
Future<String?> showReasonDialog(
  BuildContext context, {
  required String title,
  required String label,
  required String confirm,
  String? body,
  String? hint,
}) => showDialog<String>(
  context: context,
  builder: (_) => _ReasonDialog(
    title: title,
    label: label,
    confirm: confirm,
    body: body,
    hint: hint,
  ),
);

class _ReasonDialog extends StatefulWidget {
  const _ReasonDialog({
    required this.title,
    required this.label,
    required this.confirm,
    this.body,
    this.hint,
  });

  final String title;
  final String label;
  final String confirm;
  final String? body;
  final String? hint;

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final valid = _reason.text.trim().length >= 3;
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.body != null) ...[
            Text(widget.body!),
            const SizedBox(height: VantiaSpacing.md),
          ],
          TextField(
            controller: _reason,
            autofocus: true,
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: widget.hint,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          onPressed: valid
              ? () => Navigator.pop(context, _reason.text.trim())
              : null,
          child: Text(widget.confirm),
        ),
      ],
    );
  }
}
