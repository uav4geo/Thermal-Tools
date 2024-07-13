import 'package:dji_thermal_tools/provider/environment_provider.dart';
import 'package:dji_thermal_tools/widget/environment_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EnvironmentWidget extends ConsumerWidget {
  const EnvironmentWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          SwitchListTile(
              title: const Text('Override Defaults'),
              value: ref.watch(environmentModel).overrideDefaults,
              onChanged: (bool value) {
                ref.read(environmentModel).setOverrideDefaults(value);
                ref.read(environmentModel).reset();
              }),
          if (ref.watch(environmentModel).overrideDefaults) ...[
            const EnvironmentForm(),
          ]
        ],
      ),
    );
  }
}
