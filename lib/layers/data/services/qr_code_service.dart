import 'package:impostor_ar/core/constants.dart';

class QrCodeService {
  static String generateRoomUrl(String roomCode) {
    return '${AppConstants.baseUrl}/$roomCode';
  }

  static String? extractRoomCodeFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.host.contains('impostor-ar.web.app')) {
        final pathSegments = uri.pathSegments;
        if (pathSegments.isNotEmpty) {
          return pathSegments.last.toUpperCase();
        }
      }
    } catch (e) {
      return null;
    }
    return null;
  }
}
