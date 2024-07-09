import 'package:image/image.dart';
import 'dart:typed_data';

class MyTiffEncoder extends Encoder {
  @override
  Uint8List encode(Image image, {bool singleFrame = false}) {
    final out = OutputBuffer();

    // TIFF is really just an EXIF structure (or, really, EXIF is just a TIFF
    // structure).

    final exif = ExifData();
    if (image.hasExif) {
      exif.imageIfd.copy(image.exif.imageIfd);
    }

    final type = image.numChannels == 1
        ? TiffPhotometricType.blackIsZero.index
        : image.hasPalette
            ? TiffPhotometricType.palette.index
            : TiffPhotometricType.rgb.index;

    final nc = image.numChannels;

    final ifd0 = exif.imageIfd;
    ifd0['BitsPerSample'] = image.bitsPerChannel;
    ifd0['Compression'] = TiffCompression.none;
    ifd0['ImageWidth'] = image.width;
    ifd0['ImageHeight'] = image.height;
    ifd0['PhotometricInterpretation'] = type;
    ifd0['PlanarConfiguration'] = 1;
    ifd0['RowsPerStrip'] = image.height;
    ifd0['SampleFormat'] = _getSampleFormat(image).index;
    ifd0['StripByteCounts'] = image.lengthInBytes;
    ifd0['StripOffsets'] = IfdValueUndefined.list(image.data!.toUint8List());
    
    exif.write(out);

    return out.getBytes();
  }

  TiffFormat _getSampleFormat(Image image) {
    switch (image.formatType) {
      case FormatType.uint:
        return TiffFormat.uint;
      case FormatType.int:
        return TiffFormat.int;
      case FormatType.float:
        return TiffFormat.float;
    }
  }
}