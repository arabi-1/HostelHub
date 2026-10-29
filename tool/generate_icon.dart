import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final image = img.Image(width: 1024, height: 1024);

  final teal = img.ColorRgba8(15, 118, 110, 255);       // #0F766E
  final white = img.ColorRgba8(255, 255, 255, 255);    // White
  final gold = img.ColorRgba8(201, 146, 46, 255);      // #C9922E
  final softWhite = img.ColorRgba8(235, 245, 243, 255); // Soft white

  // Fill background with deep teal
  img.fill(image, color: teal);

  // Helper for filled rounded rect
  void fillRRect(int x1, int y1, int x2, int y2, int radius, img.Color color) {
    if (x2 <= x1 || y2 <= y1) return;
    img.fillRect(image, x1: x1 + radius, y1: y1, x2: x2 - radius, y2: y2, color: color);
    img.fillRect(image, x1: x1, y1: y1 + radius, x2: x2, y2: y2 - radius, color: color);
    img.fillCircle(image, x: x1 + radius, y: y1 + radius, radius: radius, color: color);
    img.fillCircle(image, x: x2 - radius, y: y1 + radius, radius: radius, color: color);
    img.fillCircle(image, x: x1 + radius, y: y2 - radius, radius: radius, color: color);
    img.fillCircle(image, x: x2 - radius, y: y2 - radius, radius: radius, color: color);
  }

  // Left vertical post of 'H' (Bed headboard)
  fillRRect(240, 200, 360, 824, 48, white);

  // Right vertical post of 'H' (Bed footboard)
  fillRRect(664, 280, 784, 824, 48, white);

  // Bed Mattress / crossbar connecting the H
  fillRRect(320, 520, 704, 630, 28, white);

  // Bed Pillow on the left side
  fillRRect(370, 440, 500, 520, 24, softWhite);

  // Gold accent blanket runner on the bed
  fillRRect(520, 545, 660, 575, 10, gold);

  // Elegant gold finial on the left headboard top
  img.fillCircle(image, x: 300, y: 200, radius: 24, color: gold);

  final pngBytes = img.encodePng(image);
  Directory('assets/icon').createSync(recursive: true);
  File('assets/icon/app_icon.png').writeAsBytesSync(pngBytes);
  print('Generated assets/icon/app_icon.png (${pngBytes.length} bytes)');
}
