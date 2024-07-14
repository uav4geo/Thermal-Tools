import 'dart:collection';
import 'dart:io';

import 'package:dji_thermal_tools/provider/environment_provider.dart';
import 'package:dji_thermal_tools/utils.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:dji_thermal_tools/constants.dart';
import 'package:dji_thermal_tools/process.dart';
import 'package:dji_thermal_tools/provider/path_model.dart';
import 'package:dji_thermal_tools/provider/process_information_provider.dart';
import 'package:dji_thermal_tools/provider/process_model.dart';
import 'package:dji_thermal_tools/theme_provider.dart';
import 'package:dji_thermal_tools/themes.dart';
import 'package:dji_thermal_tools/widget/environment_widget.dart';
import 'package:dji_thermal_tools/widget/image_folder_widget.dart';
import 'package:dji_thermal_tools/widget/process_information_widget.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

class Home extends ConsumerWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Thermal Tools by UAV4GEO',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        actions: [
          Visibility(
            visible: false,
            child: Row(
              children: [
                Text(ref.watch(themeProvider).themeData == darkTheme
                    ? 'Dark Theme'
                    : 'Light Theme'),
                Switch(
                  value: ref.watch(themeProvider).themeData == darkTheme,
                  onChanged: (value) {
                    final theme = ref.read(themeProvider);
                    if (value) {
                      theme.toggleDark();
                    } else {
                      theme.toggleLight();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _convertFiles(context, ref);
        },
        tooltip: '',
        child: ref.watch(processInformationProvider).processing
            ? const CircularProgressIndicator()
            : const Icon(Icons.play_arrow),
      ),
      bottomSheet: !ref.watch(processInformationProvider).finished
          ? null
          : Container(
              margin: const EdgeInsets.only(bottom: 4.0),
              child: RichText(
                  text: TextSpan(
                      style: const TextStyle(color: Colors.black, fontSize: 15),
                      children: [
                    TextSpan(text: AppLocalizations.of(context)!.processWith),
                    TextSpan(
                      text: "webodm.net",
                      style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 15,
                          decoration: TextDecoration.underline),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () async {
                          final url = Uri.https('webodm.net');

                          if (await canLaunchUrl(url)) {
                            await launchUrl(url);
                          } else {
                            throw 'Could not launch $url';
                          }
                        },
                    ),
                  ]))),
      body: LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth > maxResponsiveWidth) {
          return const Column(
            children: [
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: ImageFolderWidget(),
                    ),
                    Expanded(
                      flex: 1,
                      child: EnvironmentWidget(),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: ProcessInformationWidget(),
              ),
            ],
          );
        } else {
          return const Column(
            children: [
              Expanded(flex: 2, child: ImageFolderWidget()),
              Expanded(
                flex: 1,
                child: ProcessInformationWidget(),
              ),
            ],
          );
        }
      }),
    );
  }

  Directory getAssetsPath() {
    Directory exePath = Directory(Platform.resolvedExecutable).parent;
    return Directory(p.join(exePath.path, "data", "flutter_assets", "assets"));
  }

  String getOutputFolder(selectedFolder, context) {
    if (selectedFolder == "") {
      throw AppLocalizations.of(context)!.folderNotSelected;
    }
    return p.join(selectedFolder, "converted");
  }

  Future<void> _convertFile(
      Directory outDir, FileSystemEntity f, WidgetRef ref) async {
    String outFile =
        p.join(outDir.path, "${p.basenameWithoutExtension(f.path)}.tif");
    if (ref.watch(processInformationProvider).processing) {
      String outFileRaw = "";
      int width = 640;
      int height = 512;
      try {
        ref.read(processModel).addProcess("Converting ${f.path}");

        EnvParams? envParams = ref.watch(environmentModel).envParams;

        (outFileRaw, width, height) =
            await convertFileToRaw(f.path, outFile, envParams);
        await convertRawToTiff(f.path, outFileRaw, width, height, outFile);
        await copyExifTags(f.path, outFile);
      } catch (e) {
        ref.read(processModel).addProcess("Error converting ${f.path}: $e");
      } finally {
        if (outFileRaw != "") {
          File f = File(outFileRaw);
          if (await f.exists()) await f.delete();
        }
      }
    }
  }

  Future<void> _convertFiles(BuildContext context, ref) async {
    ref.read(processInformationProvider).setProcessing(true);
    String selectedPath = ref.read(imagePathModel).path;

    Directory outDir = Directory(getOutputFolder(selectedPath, context));
    if (await outDir.exists()) {
      await outDir.delete(recursive: true);
    }
    await outDir.create();

    List<FileSystemEntity> files = Directory(selectedPath).listSync();

    files = files
        .where((f) =>
            f.path.toLowerCase().endsWith(".jpg") ||
            f.path.toLowerCase().endsWith(".jpeg"))
        .toList();

    var q = Queue.from(files.toList());
    if (q.isNotEmpty) {
      await _convertFile(outDir, q.removeFirst(), ref);
    }

    List<Future<void>> tasks = [];

    int workers = 0;

    while (q.isNotEmpty && ref.watch(processInformationProvider).canceled) {
      tasks.add(_convertFile(outDir, q.removeFirst(), ref).then((_) {
        workers--;
      }).catchError((_) {
        workers--;
      }));
      workers++;
      while (workers >= Platform.numberOfProcessors) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }

    await Future.wait(tasks);

    await saveLog(selectedPath, ref.watch(processModel).processes.join("\n"));

    ref.read(processInformationProvider).setProcessing(false);
  }
}
