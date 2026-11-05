import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_exception.dart';

abstract class CameraService {
  /// Returns the captured selfie bytes, or null when the user cancels.
  Future<Uint8List?> captureSelfie({
    int imageQuality = 60,
    CameraDevice preferredCameraDevice = CameraDevice.front,
  });
}

class CameraServiceImpl implements CameraService {
  final ImagePicker _picker;

  CameraServiceImpl({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  @override
  Future<Uint8List?> captureSelfie({
    int imageQuality = 60,
    CameraDevice preferredCameraDevice = CameraDevice.front,
  }) async {
    final XFile? shot;
    try {
      shot = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: preferredCameraDevice,
        imageQuality: imageQuality,
      );
    } on PlatformException catch (e) {
      if (e.code == 'camera_access_denied' || e.code == 'photo_access_denied') {
        throw const ApiException(
          code: 'CAMERA_PERMISSION_DENIED',
          message: 'Cần quyền camera để chụp ảnh chấm công. Hãy bật trong Cài đặt.',
          statusCode: 403,
        );
      }
      return null;
    } catch (_) {
      return null;
    }

    if (shot == null) return null;

    // Read bytes rather than handing the path to MultipartFile.fromFile: on web
    // the picked file is a blob: URL and fromFile throws UnsupportedError.
    try {
      return await shot.readAsBytes();
    } catch (_) {
      return null;
    }
  }
}
