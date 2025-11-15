import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class StorageService {
  // Request storage permissions
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      // Check Android version
      if (await _isAndroid13OrHigher()) {
        // Android 13+ doesn't need MANAGE_EXTERNAL_STORAGE for Downloads
        return true;
      } else {
        // Android 12 and below
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
        }

        if (status.isPermanentlyDenied) {
          await openAppSettings();
          return false;
        }

        if (status.isDenied) {
          var manageStatus = await Permission.manageExternalStorage.request();
          return manageStatus.isGranted;
        }

        return status.isGranted;
      }
    }
    return true;
  }

  Future<bool> _isAndroid13OrHigher() async {
    if (Platform.isAndroid) {
      // This is a simple check - you might need to use device_info_plus for accurate version
      return true; // Assume newer Android for now
    }
    return false;
  }

  // Save file to downloads
  Future<String> saveToDownloads(File file, String fileName) async {
    try {
      print('DEBUG STORAGE: Requesting permissions...');
      final hasPermission = await requestPermissions();

      if (!hasPermission) {
        throw Exception('Storage permission denied');
      }

      print('DEBUG STORAGE: Permission granted');

      Directory? directory;

      if (Platform.isAndroid) {
        // Try multiple paths for Android
        final possiblePaths = [
          '/storage/emulated/0/Download',
          '/storage/emulated/0/Downloads',
        ];

        for (final path in possiblePaths) {
          final dir = Directory(path);
          if (await dir.exists()) {
            directory = dir;
            break;
          }
        }

        // If Download folder not accessible, use app's external storage
        if (directory == null) {
          print(
              'DEBUG STORAGE: Download folder not accessible, using external storage');
          directory = await getExternalStorageDirectory();
          if (directory != null) {
            // Create a "Downloads" subdirectory in app's storage
            directory = Directory('${directory.path}/Downloads');
            if (!await directory.exists()) {
              await directory.create(recursive: true);
            }
          }
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('Could not access storage directory');
      }

      final savePath = '${directory.path}/$fileName';
      print('DEBUG STORAGE: Saving to: $savePath');

      final savedFile = await file.copy(savePath);
      print('DEBUG STORAGE: File saved successfully');

      return savedFile.path;
    } catch (e) {
      print('DEBUG STORAGE ERROR: $e');
      rethrow;
    }
  }

  // Get temporary directory
  Future<Directory> getTempDirectory() async {
    return await getTemporaryDirectory();
  }
}
