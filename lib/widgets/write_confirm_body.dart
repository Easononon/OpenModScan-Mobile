import 'package:flutter/material.dart';

import '../field/write_plan.dart';
import '../l10n/l10n.dart';

class WriteConfirmBody extends StatelessWidget {
  final WritePlan plan;

  const WriteConfirmBody({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tt = Theme.of(context).textTheme;
    final lines = <(String, String)>[
      (l10n.writeConfirmEndpoint, plan.endpoint),
      (l10n.writeConfirmUnit, plan.unitId.toString()),
      (
        l10n.writeConfirmFunction,
        '${plan.functionCode.toRadixString(16).padLeft(2, '0').toUpperCase()} ${plan.functionName}',
      ),
      (l10n.writeConfirmPdu, plan.pduAddress.toString()),
      (l10n.writeConfirmReference, plan.referenceAddress.toString()),
      (
        l10n.writeConfirmOld,
        plan.oldValueKnown ? plan.knownOldValue! : l10n.writeConfirmOldUnknown,
      ),
      (l10n.writeConfirmNew, plan.newValue),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${line.$1}: ',
                    style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: line.$2, style: tt.bodyMedium),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
