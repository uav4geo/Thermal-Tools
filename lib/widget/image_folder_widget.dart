import 'package:desktop_drop/desktop_drop.dart';
import 'package:dji_thermal_tools/provider/path_model.dart';
import 'package:dji_thermal_tools/provider/process_model.dart';
import 'package:dji_thermal_tools/utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ImageFolderWidget extends ConsumerWidget {
  const ImageFolderWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: DropTarget(
                    onDragEntered: (details) {
                      ref.read(imagePathModel).setDragging(true);
                    },
                    onDragExited: (details) {
                      ref.read(imagePathModel).setDragging(false);
                    },
                    onDragUpdated: (details) {
                      ref.read(imagePathModel).setDragging(true);
                    },
                    onDragDone: (DropDoneDetails details) async {
                      ref.read(imagePathModel).setDragging(false);
                      String path = details.files.first.path;

                      if (await checkIfDirectory(details.files.first.path)) {
                        _setPath(ref, path, context);
                      } else {
                        String error =
                            AppLocalizations.of(context)!.fileIsNotFolder;
                        ref.read(processModel).addProcess("$error: $path");
                      }
                    },
                    child: Container(
                      color: ref.watch(imagePathModel).dragging
                          ? Colors.blue
                          : null,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (ref.watch(imagePathModel).dragging) ...[
                            Text(AppLocalizations.of(context)!.dropHere,
                                style: const TextStyle(fontSize: 18)),
                          ],
                          const Icon(Icons.folder, size: 100),
                          Text(AppLocalizations.of(context)!.dragAndDrop,
                              style: const TextStyle(fontSize: 18)),
                          FilledButton(
                              onPressed: () async {
                                String? path = await FilePicker.platform
                                    .getDirectoryPath(
                                        dialogTitle:
                                            AppLocalizations.of(context)!
                                                .selectImageFolder);

                                if (path != null) {
                                  _setPath(ref, path, context);
                                }
                              },
                              child: Text(
                                  AppLocalizations.of(context)!.clickToSelect)),
                        ],
                      ),
                    )),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  void _setPath(WidgetRef ref, String path, BuildContext context) {
    ref.read(imagePathModel).setPath(path);
    ref.read(imagePathModel).setFromDrag(true);
    
    String message = AppLocalizations.of(context)!.selected;
    ref.read(processModel).addProcess("$message: $path");
  }
}
