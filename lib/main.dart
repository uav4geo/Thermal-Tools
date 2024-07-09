import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image/image.dart' as im;
import 'tiff_encoder.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DJI Thermal Tools',
      theme: ThemeData(
        colorScheme: ColorScheme.highContrastLight(),
        useMaterial3: true,
      ),
      home: const HomePage(title: 'DJI Thermal Tools by UAV4GEO'),
    );
  }
}

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
  int _processedFiles = 0;
  int _failedFiles = 0;
  String _lastError = "";

  Future<void> _selectFolder(BuildContext context) async{
    String? path = await FilePicker.platform.getDirectoryPath(dialogTitle: "Select Images Folder");
    if (path != null){
      List<FileSystemEntity> files = Directory(path).listSync();
      setState(() {
        _selectedFiles = files.where((f) => f.path.toLowerCase().endsWith(".jpg") || f.path.toLowerCase().endsWith(".jpeg")).toList();
        _selectedFolder = path;
        _lastError = "";
      });
    }
  }

  Directory getAssetsPath(){
    Directory exePath = Directory(Platform.resolvedExecutable).parent;
    return Directory(p.join(exePath.path, "data", "flutter_assets", "assets"));
  }

  String getOutputFolder(){
    if (_selectedFolder == "") throw "Folder not selected";
    return p.join(_selectedFolder, "converted");
  }

  String getExifToolPath(){
    return p.join(getAssetsPath().path, "exiftool.exe");
  }

  String getXmpConfigPath(){
    return p.join(getAssetsPath().path, "xmp.config");
  }

  String getDjiToolPath(){
    return p.join(getAssetsPath().path, "dji_tools", "dji_irp.exe");
  }

  Future<String> convertFileToRaw(String inFile, String outFile) async{
    String outFileRaw = "$outFile.raw";
    final process = await Process.run(getDjiToolPath(), [
      "-a", "measure", "--measurefmt", "float32", "-s", inFile, "-o", "$outFile.raw"
    ]);
    if (process.exitCode != 0){
      throw process.stdout.toString();
    }

    return outFileRaw;
  }

  Future<void> copyExifTags(String exifFile, String targetFile) async{
    var process = await Process.run(getExifToolPath(), [
      "-config", getXmpConfigPath(), "-xmp:Camera:BandName=LWIR", "-tagsfromfile", exifFile, targetFile, "-overwrite_original_in_place",
    ]);
    if (process.exitCode != 0){
      throw process.stderr.toString();
    }
  }

  Future<void> convertRawToTiff(String exifFile, String rawFile, String outFile) async{
    // final exifImg = im.decodeImage(await File(exifFile).readAsBytes())!;
    final rawBytes = await File(rawFile).readAsBytes();
    
    // TODO: read image width/height from output
    const int width = 640;
    const int height = 512;

    final img = im.Image(width: width, height: height, format: im.Format.float32, numChannels: 1, withPalette: false);//, exif: exifImg.exif);
    final inData = Float32List.view(rawBytes.buffer, 0, width * height);
    final outData = Float32List.view(img.data!.buffer, 0, width * height);
    var byteData = ByteData(4);
    for (int i = 0; i < width * height; i++){
      byteData.setFloat32(0, inData[i], Endian.little);
      outData[i] = byteData.getFloat32(0);
    }

    final outBytes = MyTiffEncoder().encode(img, singleFrame: true);
    await File(outFile).writeAsBytes(outBytes, flush: true);
  }

  Future<void> _convertFiles(BuildContext context) async{
    setState((){
      _processing = true;
      _processedFiles = 0;
      _failedFiles = 0;
      _lastError = "";
    });

    Directory outDir = Directory(getOutputFolder());
    if (await outDir.exists()){
      await outDir.delete(recursive: true);
    }
    await outDir.create();

    for (FileSystemEntity f in _selectedFiles){
      String outFile = p.join(outDir.path, "${p.basenameWithoutExtension(f.path)}.tif");

      if (_processing){
        String outFileRaw = "";
        try{
          outFileRaw = await convertFileToRaw(f.path, outFile);
          await convertRawToTiff(f.path, outFileRaw, outFile);
          await copyExifTags(f.path, outFile);
        }catch(e){
          print(e);
          setState((){ 
            _failedFiles++; 
            _lastError = e.toString();
          });
        }finally{
          if (outFileRaw != ""){
            File f = File(outFileRaw);
            if (await f.exists()) await f.delete();
          }
        }
      }

      setState((){ _processedFiles++; });
    }

    if (_failedFiles > 0){
      _lastError = "${_processedFiles} files failed to convert: ${_lastError}";
    }

    setState((){
      _processing = false;
    });
  }

  Future<void> _cancelProcessing(BuildContext context) async{
    setState((){
      _processing = false;
      _processedFiles = 0;
    });
  }

  Future<void> _openConvertedFolder(BuildContext context) async{
     launchUrl(Uri.parse("file:///${getOutputFolder()}"));

    setState((){
      _processedFiles = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> controls;
    final finished = _selectedFolder != "" && !_processing && _processedFiles > 0;

    if (_processing){
      controls = <Widget>[Container(
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
          child: Text('Cancel'),
        )];
    }else if (finished){
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
    }else{
      var button = _selectedFolder != "" ? OutlinedButton(
          onPressed: _selectedFiles.isEmpty ? null : () => _convertFiles(context),
          child: Text('Process ${_selectedFiles.length} Files'),
        ) : Container();
      
      controls = <Widget>[
        Container(
          margin: const EdgeInsets.only(bottom: 4.0),
          child: OutlinedButton(
            onPressed:  () => _selectFolder(context),
            child: const Text('Select Images Folder'),
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

    if (_lastError != ""){
      controls += [Container(
          margin: const EdgeInsets.all(16.0),
          child: Text.rich(TextSpan(
            children: <InlineSpan>[
              const WidgetSpan(child: Icon(Icons.warning_rounded)),
              TextSpan(text: _lastError),
            ]
          ),
        ))];
    }
    
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: controls,
        ),
      ),
      bottomSheet: !finished ? null : Container( 
        margin: const EdgeInsets.only(bottom: 4.0),
        child: RichText(text: TextSpan(
          style: const TextStyle(color: Colors.black, fontSize: 15),
          children: [
            const TextSpan(text: "Process these images with "),
            TextSpan(text: "webodm.net",
            style: const TextStyle(color: Colors.blue, fontSize: 15, decoration: TextDecoration.underline),
            recognizer: TapGestureRecognizer()
                    ..onTap = () async {
                      const url = 'https://webodm.net';
                      if (await canLaunch(url)) {
                        await launch(url);
                      } else {
                        throw 'Could not launch $url';
                      }
                    },),
          ]
        ))
      ),
    );
  }
}
