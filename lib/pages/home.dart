import 'dart:io';

import 'package:dji_thermal_tools/input_slider/input_slider.dart';
import 'package:dji_thermal_tools/input_slider/input_slider_form.dart';
import 'package:dji_thermal_tools/tiff_encoder.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:collection';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image/image.dart' as im;

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _selectedFolder = "";
  List<FileSystemEntity> _selectedFiles = [];
  bool _processing = false;
  bool _canceled = false;
  int _processedFiles = 0;
  int _failedFiles = 0;
  String _lastError = "";
  bool _overrideEnvParams = false;
  double _paramDistance = 5.0; // meters
  double _paramHumidity = 70.0; // %
  double _paramEmissivity = 1.0; // factor
  double _paramAmbient = 25.0; // Celsius
  double _paramReflection = 23.0; // Celsius

  Future<void> _selectFolder(BuildContext context) async {
    String? path = await FilePicker.platform.getDirectoryPath(
        dialogTitle: AppLocalizations.of(context)!.selectImageFolder);
    if (path != null) {
      List<FileSystemEntity> files = Directory(path).listSync();
      setState(() {
        _selectedFiles = files
            .where((f) =>
                f.path.toLowerCase().endsWith(".jpg") ||
                f.path.toLowerCase().endsWith(".jpeg"))
            .toList();
        _selectedFolder = path;
        _lastError = "";
      });
    }
  }

  Directory getAssetsPath() {
    Directory exePath = Directory(Platform.resolvedExecutable).parent;
    return Directory(p.join(exePath.path, "data", "flutter_assets", "assets"));
  }

  String getOutputFolder() {
    if (_selectedFolder == "") throw "Folder not selected";
    return p.join(_selectedFolder, "converted");
  }

  String getExifToolPath() {
    if (Platform.isLinux) {
      return p.join(getAssetsPath().path, "linux", "exiftool", "exiftool");
    } else {
      return p.join(getAssetsPath().path, "windows", "exiftool.exe");
    }
  }

  String getXmpConfigPath() {
    return p.join(getAssetsPath().path, "xmp.config");
  }

  String getDjiToolPath() {
    if (Platform.isLinux) {
      return p.join(getAssetsPath().path, "linux", "dji_tools", "dji_irp.sh");
    } else {
      // Windows
      return p.join(
          getAssetsPath().path, "windows", "dji_tools", "dji_irp.exe");
    }
  }

  Future<(String, int, int)> convertFileToRaw(
      String inFile, String outFile) async {
    String outFileRaw = "$outFile.raw";
    List<String> params = [
      "-a",
      "measure",
      "--measurefmt",
      "float32",
      "-s",
      inFile,
      "-o",
      "$outFile.raw"
    ];
    if (_overrideEnvParams) {
      params += [
        "--distance",
        _paramDistance.toString(),
        "--humidity",
        _paramHumidity.toString(),
        "--emissivity",
        _paramEmissivity.toString(),
        "--ambient",
        _paramAmbient.toString(),
        "--reflection",
        _paramReflection.toString(),
      ];
    }
    final process = await Process.run(getDjiToolPath(), params);

    String out = "${process.stdout.toString()}\n${process.stderr.toString()}";
    if (process.exitCode != 0) {
      throw out;
    }

    int width = 640;
    int height = 512;

    RegExp regExp = RegExp(r'width\s*:\s*(\d+)');
    RegExpMatch? match = regExp.firstMatch(out);
    if (match != null) {
      width = int.parse(match.group(1)!);
    }

    regExp = RegExp(r'height\s*:\s*(\d+)');
    match = regExp.firstMatch(out);
    if (match != null) {
      height = int.parse(match.group(1)!);
    }

    return (outFileRaw, width, height);
  }

  Future<void> copyExifTags(String exifFile, String targetFile) async {
    var process = await Process.run(getExifToolPath(), [
      "-config",
      getXmpConfigPath(),
      "-xmp:Camera:BandName=LWIR",
      "-tagsfromfile",
      exifFile,
      targetFile,
      "-overwrite_original_in_place",
    ]);
    if (process.exitCode != 0) {
      throw process.stderr.toString();
    }
  }

  Future<void> convertRawToTiff(String exifFile, String rawFile, int width,
      int height, String outFile) async {
    // final exifImg = im.decodeImage(await File(exifFile).readAsBytes())!;
    final rawBytes = await File(rawFile).readAsBytes();

    final img = im.Image(
        width: width,
        height: height,
        format: im.Format.float32,
        numChannels: 1,
        withPalette: false); //, exif: exifImg.exif);
    final inData = Float32List.view(rawBytes.buffer, 0, width * height);
    final outData = Float32List.view(img.data!.buffer, 0, width * height);
    var byteData = ByteData(4);
    for (int i = 0; i < width * height; i++) {
      byteData.setFloat32(0, inData[i], Endian.little);
      outData[i] = byteData.getFloat32(0);
    }

    final outBytes = MyTiffEncoder().encode(img, singleFrame: true);
    await File(outFile).writeAsBytes(outBytes, flush: true);
  }

  Future<void> _convertFile(Directory outDir, FileSystemEntity f) async {
    String outFile =
        p.join(outDir.path, "${p.basenameWithoutExtension(f.path)}.tif");
    if (_processing) {
      String outFileRaw = "";
      int width = 640;
      int height = 512;
      try {
        (outFileRaw, width, height) = await convertFileToRaw(f.path, outFile);
        await convertRawToTiff(f.path, outFileRaw, width, height, outFile);
        await copyExifTags(f.path, outFile);
      } catch (e) {
        setState(() {
          _failedFiles++;
          _lastError = e.toString();
        });
      } finally {
        if (outFileRaw != "") {
          File f = File(outFileRaw);
          if (await f.exists()) await f.delete();
        }
      }
      setState(() {
        _processedFiles++;
      });
    }
  }

  Future<void> _convertFiles(BuildContext context) async {
    setState(() {
      _processing = true;
      _canceled = false;
      _processedFiles = 0;
      _failedFiles = 0;
      _lastError = "";
    });

    Directory outDir = Directory(getOutputFolder());
    if (await outDir.exists()) {
      await outDir.delete(recursive: true);
    }
    await outDir.create();

    var q = Queue.from(_selectedFiles.toList());

    // Process the first one synchronously to allow exiftool to self-extract without
    // race conditions...
    if (q.isNotEmpty) {
      await _convertFile(outDir, q.removeFirst());
    }

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

    setState(() {
      _processing = false;
    });
  }

  Future<void> _cancelProcessing(BuildContext context) async {
    setState(() {
      _processing = false;
      _processedFiles = 0;
      _canceled = true;
    });
  }

  Future<void> _openConvertedFolder(BuildContext context) async {
    launchUrl(Uri.parse("file:///${getOutputFolder()}"));

    setState(() {
      _processedFiles = 0;
    });
  }

  Future<String?> _showEnvironmentalParams(BuildContext context) {
    return showDialog<String>(
        context: context,
        builder: (BuildContext context) => StatefulBuilder(
              builder: (BuildContext context, setState) => Dialog.fullscreen(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Container(
                        margin: const EdgeInsets.only(top: 16, bottom: 16),
                        child:
                            Column(mainAxisSize: MainAxisSize.max, children: [
                          SwitchListTile(
                              title: const Text('Override Defaults'),
                              value: _overrideEnvParams,
                              onChanged: (bool value) {
                                setState(() {
                                  _overrideEnvParams = value;
                                });
                              }),
                          const SizedBox(height: 16),
                          _overrideEnvParams
                              ? Container(
                                  margin: const EdgeInsets.only(
                                      left: 16, right: 16),
                                  child: InputSliderForm(
                                      leadingWeight: 18,
                                      sliderWeight: 20,
                                      filled: true,
                                      vertical: false,
                                      children: [
                                        InputSlider(
                                          onChange: (value) {
                                            setState(() {
                                              _paramDistance = value;
                                            });
                                          },
                                          min: 1.0,
                                          max: 25.0,
                                          decimalPlaces: 0,
                                          defaultValue: _paramDistance,
                                          leading: const Text("Distance (m):"),
                                        ),
                                        InputSlider(
                                          onChange: (value) {
                                            setState(() {
                                              _paramHumidity = value;
                                            });
                                          },
                                          min: 20.0,
                                          max: 100.0,
                                          decimalPlaces: 0,
                                          defaultValue: _paramHumidity,
                                          leading: const Text("Humidity (%):"),
                                        ),
                                        InputSlider(
                                          onChange: (value) {
                                            setState(() {
                                              _paramEmissivity = value;
                                            });
                                          },
                                          min: 0.10,
                                          max: 1.00,
                                          decimalPlaces: 2,
                                          defaultValue: _paramEmissivity,
                                          leading: const Text("Emissivity:"),
                                        ),
                                        InputSlider(
                                          onChange: (value) {
                                            setState(() {
                                              _paramAmbient = value;
                                            });
                                          },
                                          min: -40.0,
                                          max: 80.0,
                                          decimalPlaces: 1,
                                          defaultValue: _paramAmbient,
                                          leading: const Text(
                                              "Ambient Temperature (°C):"),
                                        ),
                                        InputSlider(
                                          onChange: (value) {
                                            setState(() {
                                              _paramReflection = value;
                                            });
                                          },
                                          min: -40.0,
                                          max: 500.0,
                                          decimalPlaces: 1,
                                          defaultValue: _paramReflection,
                                          leading: const Text(
                                              "Reflected Temperature (°C):"),
                                        )
                                      ]))
                              : Container(),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('Save'),
                          ),
                        ])),
                  ],
                ),
              ),
            ));
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> controls;
    final finished = !_canceled &&
        _selectedFolder != "" &&
        !_processing &&
        _processedFiles > 0;

    if (_processing) {
      controls = <Widget>[
        Container(
            margin: const EdgeInsets.all(4.0),
            child: LinearProgressIndicator(
              value: _processedFiles / _selectedFiles.length,
              semanticsLabel: 'Processed files',
            )),
        Container(
          margin: const EdgeInsets.only(bottom: 16.0),
          child: Text(
            "Processed ${_processedFiles} / ${_selectedFiles.length}",
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        OutlinedButton(
          onPressed: () => _cancelProcessing(context),
          child: const Text('Cancel'),
        )
      ];
    } else if (finished) {
      controls = <Widget>[
        Container(
          margin: const EdgeInsets.only(bottom: 32.0),
          child: Text(
            "Conversion Completed!",
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 4.0),
          child: OutlinedButton(
            onPressed: () => _openConvertedFolder(context),
            child: const Text('Open Results Folder'),
          ),
        ),
      ];
    } else {
      var button = _selectedFolder != ""
          ? Column(children: [
              Container(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  child: OutlinedButton(
                    child: const Text('Set Environment Params'),
                    onPressed: () => _showEnvironmentalParams(context),
                  )),
              FilledButton(
                onPressed: _selectedFiles.isEmpty
                    ? null
                    : () => _convertFiles(context),
                child: Text('Process ${_selectedFiles.length} Files'),
              )
            ])
          : Container();

      controls = <Widget>[
        Container(
          margin: const EdgeInsets.only(bottom: 4.0),
          child: OutlinedButton(
            onPressed: () => _selectFolder(context),
            child: Text(AppLocalizations.of(context)!.selectImageFolder),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 32.0),
          child: Text(
            _selectedFolder,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        button
      ];
    }

    if (_lastError != "") {
      controls += [
        Container(
            margin: const EdgeInsets.all(16.0),
            child: Text.rich(
              TextSpan(children: <InlineSpan>[
                const WidgetSpan(child: Icon(Icons.warning_rounded)),
                TextSpan(text: _lastError),
              ]),
            ))
      ];
    }

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: controls,
        ),
      ),
      bottomSheet: !finished
          ? null
          : Container(
              margin: const EdgeInsets.only(bottom: 4.0),
              child: RichText(
                  text: TextSpan(
                      style: const TextStyle(color: Colors.black, fontSize: 15),
                      children: [
                    const TextSpan(text: "Process these images with "),
                    TextSpan(
                      text: "webodm.net",
                      style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 15,
                          decoration: TextDecoration.underline),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () async {
                          const url = 'https://webodm.net';
                          if (await canLaunch(url)) {
                            await launch(url);
                          } else {
                            throw 'Could not launch $url';
                          }
                        },
                    ),
                  ]))),
    );
  }
}
