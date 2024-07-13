import 'dart:collection';
import 'dart:io';

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
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

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
      body: LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth > maxResponsiveWidth) {
          return const Column(
            children: [
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
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

  String getOutputFolder(selectedFolder) {
    if (selectedFolder == "") throw "Folder not selected";
    return p.join(selectedFolder, "converted");
  }

  Future<void> _convertFile(
      Directory outDir, FileSystemEntity f, WidgetRef ref) async {
    String outFile =
        p.join(outDir.path, "${p.basenameWithoutExtension(f.path)}.tif");
    //if (_processing) {
    String outFileRaw = "";
    int width = 640;
    int height = 512;
    try {
      ref.read(processModel).addProcess("Converting ${f.path}");

      (outFileRaw, width, height) = await convertFileToRaw(f.path, outFile);
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

  Future<void> _convertFiles(BuildContext context, ref) async {
    ref.read(processInformationProvider).setProcessing(true);
    String selectedPath = ref.read(imagePathModel).path;

    Directory outDir = Directory(getOutputFolder(selectedPath));
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
/*
   
    List<Future<void>> tasks = [];

    int workers = 0;
    while (q.isNotEmpty && !_canceled) {
      tasks.add(_convertFile(outDir, q.removeFirst()).then((_) {
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

    if (_failedFiles > 0) {
      _lastError = "$_processedFiles files failed to convert: $_lastError";
    }
*/
    ref.read(processInformationProvider).setProcessing(false);
    // }
  }
}
