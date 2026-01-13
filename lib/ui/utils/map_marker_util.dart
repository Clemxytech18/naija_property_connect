import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapMarkerUtil {
  static Future<BitmapDescriptor> createCustomMarkerBitmap(
    IconData iconData, {
    Color color = Colors.blue,
    double size = 100,
  }) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = color;
    final double radius = size / 2;

    // Draw Circle Background
    canvas.drawCircle(Offset(radius, radius), radius, paint);

    // Draw Icon
    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    textPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: size * 0.6,
        fontFamily: iconData.fontFamily,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(radius - textPainter.width / 2, radius - textPainter.height / 2),
    );

    final ui.Image image = await pictureRecorder.endRecording().toImage(
      size.toInt(),
      size.toInt(),
    );
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
  }

  static IconData getIconForType(String? type) {
    switch (type?.toLowerCase()) {
      case 'house':
      case 'apartment':
        return Icons.house;
      case 'land':
        return Icons.landscape; // or terrain
      case 'office':
      case 'commercial':
        return Icons.business;
      default:
        return Icons.location_on;
    }
  }

  static Color getColorForType(String? type) {
    switch (type?.toLowerCase()) {
      case 'house':
      case 'apartment':
        return Colors.blue;
      case 'land':
        return Colors.green;
      case 'office':
      case 'commercial':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }
}
