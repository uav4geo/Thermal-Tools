import 'dart:io';
import 'package:dji_thermal_tools/tiff_encoder.dart';
import 'package:image/image.dart' as im;
import 'package:path/path.dart' as p;
import 'dart:typed_data';

Future<(String, int, int)> convertFileToRaw(String inFile, String outFile,
    EnvParams? envParams) async {
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
  if (envParams != null) {
    params += [
      "--distance",
      envParams.distance.toString(),
      "--humidity",
      envParams.humidity.toString(),
      "--emissivity",
      envParams.emissivity.toString(),
      "--ambient",
      envParams.ambient.toString(),
      "--reflection",
      envParams.reflection.toString(),
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

String getDjiToolPath() {
  if (Platform.isLinux) {
    return p.join(getAssetsPath().path, "linux", "dji_tools", "dji_irp.sh");
  } else {
    // Windows
    return p.join(getAssetsPath().path, "windows", "dji_tools", "dji_irp.exe");
  }
}

Directory getAssetsPath() {
  Directory exePath = Directory(Platform.resolvedExecutable).parent;
  return Directory(p.join(exePath.path, "data", "flutter_assets", "assets"));
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

String getOutputFolder(String selectedPath) {
  if (selectedPath == "") throw "Folder not selected";
  return p.join(selectedPath, "converted");
}

class EnvParams {
  double distance = 1.0;
  double humidity = 50.0;
  double emissivity = 0.95;
  double ambient = 20.0;
  double reflection = 20.0;

  EnvParams(
      {required this.distance,
      required this.humidity,
      required this.emissivity,
      required this.ambient,
      required this.reflection});
}
