// import 'dart:typed_data';

// import 'package:camera/camera.dart';
// // import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

// Future<InputImage> convertCameraImageToBitmap(CameraImage image) async {
//   try {
//     // Convert YUV420 to RGBA
//     if (image.format.group == ImageFormatGroup.yuv420) {
//       final yPlane = image.planes[0];
//       final uPlane = image.planes[1];
//       final vPlane = image.planes[2];
      
//       // Create RGBA buffer
//       final rgbaBytes = Uint8List(image.width * image.height * 4);
      
//       // Simple YUV to RGB conversion (for demo purposes)
//       // In production, use a proper YUV to RGB conversion
//       int rgbaIndex = 0;
//       for (int y = 0; y < image.height; y++) {
//         for (int x = 0; x < image.width; x++) {
//           final yIndex = y * yPlane.bytesPerRow + x;
//           final uvIndex = (y ~/ 2) * uPlane.bytesPerRow + (x ~/ 2) * 2;
          
//           final yValue = yPlane.bytes[yIndex];
//           final uValue = uPlane.bytes[uvIndex];
//           final vValue = vPlane.bytes[uvIndex];
          
//           // Convert YUV to RGB
//           final r = yValue + 1.402 * (vValue - 128);
//           final g = yValue - 0.344 * (uValue - 128) - 0.714 * (vValue - 128);
//           final b = yValue + 1.772 * (uValue - 128);
          
//           rgbaBytes[rgbaIndex++] = r.clamp(0, 255).toInt();
//           rgbaBytes[rgbaIndex++] = g.clamp(0, 255).toInt();
//           rgbaBytes[rgbaIndex++] = b.clamp(0, 255).toInt();
//           rgbaBytes[rgbaIndex++] = 255; // Alpha
//         }
//       }
      
//       return InputImage.fromBitmap(
//         bitmap: rgbaBytes,
//         width: image.width,
//         height: image.height,
//         rotation: 90, // Front camera rotation
//       );
//     }
    
//     // For iOS BGRA format
//     final plane = image.planes[0];
//     return InputImage.fromBitmap(
//       bitmap: plane.bytes,
//       width: image.width,
//       height: image.height,
//       rotation: 90,
//     );
//   } catch (e) {
//     print('Error converting to bitmap: $e');
//     rethrow;
//   }
// }




import 'dart:convert';
import 'dart:typed_data';

String? uint8ListToBase64(Uint8List? imageBytes) {
  if (imageBytes == null) return null;
  return base64Encode(imageBytes);
}