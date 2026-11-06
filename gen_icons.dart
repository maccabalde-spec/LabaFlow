import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

// Minimal PNG encoder — no external deps
Uint8List makePng(int size) {
  // PNG signature
  final sig = Uint8List.fromList([137,80,78,71,13,10,26,10]);

  Uint8List chunk(List<int> type, List<int> data) {
    final len = ByteData(4)..setUint32(0, data.length, Endian.big);
    final combined = [...type, ...data];
    var crc = 0xFFFFFFFF;
    for (final b in combined) {
      crc ^= b;
      for (var i = 0; i < 8; i++) {
        crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xEDB88320 : crc >> 1;
      }
    }
    crc ^= 0xFFFFFFFF;
    final crcBytes = ByteData(4)..setUint32(0, crc, Endian.big);
    return Uint8List.fromList([...len.buffer.asUint8List(), ...combined, ...crcBytes.buffer.asUint8List()]);
  }

  // IHDR
  final ihdrData = ByteData(13);
  ihdrData.setUint32(0, size, Endian.big);
  ihdrData.setUint32(4, size, Endian.big);
  ihdrData.setUint8(8, 8);  // bit depth
  ihdrData.setUint8(9, 2);  // RGB
  final ihdr = chunk([73,72,68,82], ihdrData.buffer.asUint8List());

  // Raw image data
  final raw = <int>[];
  final r = size ~/ 2;
  for (var y = 0; y < size; y++) {
    raw.add(0); // filter byte
    for (var x = 0; x < size; x++) {
      final cx = x - size ~/ 2;
      final cy = y - size ~/ 2;
      if (cx * cx + cy * cy <= (r - 2) * (r - 2)) {
        raw.addAll([2, 132, 199]); // #0284c7 blue
      } else {
        raw.addAll([255, 255, 255]); // white
      }
    }
  }
  final compressed = zlib.encode(raw);
  final idat = chunk([73,68,65,84], compressed);
  final iend = chunk([73,69,78,68], []);

  return Uint8List.fromList([...sig, ...ihdr, ...idat, ...iend]);
}

void main() {
  final base = r'c:\Users\chrst\Desktop\LabaFlow\flutter_mobile\android\app\src\main\res';
  final sizes = {
    'mipmap-mdpi':    48,
    'mipmap-hdpi':    72,
    'mipmap-xhdpi':   96,
    'mipmap-xxhdpi':  144,
    'mipmap-xxxhdpi': 192,
  };
  for (final entry in sizes.entries) {
    final path = '$base\\${entry.key}\\ic_launcher.png';
    File(path).writeAsBytesSync(makePng(entry.value));
    print('Created ${entry.key}/ic_launcher.png (${entry.value}x${entry.value})');
  }
  print('All icons generated!');
}
