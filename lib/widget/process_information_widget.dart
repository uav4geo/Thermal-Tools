import 'package:dji_thermal_tools/provider/process_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProcessInformationWidget extends ConsumerWidget {
  const ProcessInformationWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.black,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: ref.watch(processModel).processes.length,
          itemBuilder: (context, index) {
            return Container(
                color: index.isEven ? Colors.white : Colors.transparent,
                child: Text(ref.watch(processModel).processes[index],
                    style: const TextStyle(fontSize: 12)));
          },
        ),
      ),
    );
  }
}
