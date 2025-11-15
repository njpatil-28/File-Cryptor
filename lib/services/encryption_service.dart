import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';

class EncryptionService {
  // Generate random key for a file
  String generateFileKey() {
    final key = encrypt.Key.fromSecureRandom(32);
    return key.base64;
  }

  // Derive key from password using PBKDF2
  encrypt.Key _deriveKeyFromPassword(String password) {
    const salt = 'user_password_salt_v1';
    final bytes = utf8.encode(password + salt);

    // Hash multiple times for stronger key derivation
    var hash = sha256.convert(bytes);
    for (int i = 0; i < 1000; i++) {
      hash = sha256.convert(hash.bytes);
    }

    return encrypt.Key(Uint8List.fromList(hash.bytes));
  }

  // Encrypt a file key with user's password
  List<int> encryptFileKey(String fileKey, String password) {
    final key = _deriveKeyFromPassword(password);
    final iv = encrypt.IV.fromLength(16);
    final encrypter =
        encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));

    final encrypted = encrypter.encrypt(fileKey, iv: iv);

    // Return IV + encrypted data as bytes (not base64)
    return [...iv.bytes, ...encrypted.bytes];
  }

  // Decrypt a file key with user's password
  String decryptFileKey(List<int> encryptedKeyBytes, String password) {
    final key = _deriveKeyFromPassword(password);

    final iv = encrypt.IV(Uint8List.fromList(encryptedKeyBytes.sublist(0, 16)));
    final encryptedData = encryptedKeyBytes.sublist(16);

    final encrypter =
        encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    final decrypted = encrypter.decrypt(
      encrypt.Encrypted(Uint8List.fromList(encryptedData)),
      iv: iv,
    );

    return decrypted;
  }

  // Encrypt file and embed encrypted key inside
  Future<File> encryptFile(
      File inputFile, String password, String originalFileName) async {
    print('DEBUG ENCRYPT: Starting encryption for $originalFileName');

    // Generate random key for this file
    final fileKey = generateFileKey();
    print('DEBUG ENCRYPT: File key generated');

    // Encrypt the file with random key
    final key = encrypt.Key.fromBase64(fileKey);
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter =
        encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));

    final bytes = await inputFile.readAsBytes();
    final encryptedFileData = encrypter.encryptBytes(bytes, iv: iv);
    print('DEBUG ENCRYPT: File data encrypted');

    // Encrypt the file key with user's password (returns bytes, not base64)
    final encryptedKeyBytes = encryptFileKey(fileKey, password);
    print(
        'DEBUG ENCRYPT: File key encrypted, size: ${encryptedKeyBytes.length} bytes');

    // Store original filename for extension preservation
    final fileNameBytes = utf8.encode(originalFileName);
    final fileNameLength = fileNameBytes.length;

    // Build final structure:
    // [4 bytes: fileName length] + [fileName] + [4 bytes: key length] + [encrypted key bytes] + [16 bytes: IV] + [encrypted data]
    final fileNameLengthBytes = Uint8List(4)
      ..buffer.asByteData().setUint32(0, fileNameLength, Endian.big);
    final keyLengthBytes = Uint8List(4)
      ..buffer.asByteData().setUint32(0, encryptedKeyBytes.length, Endian.big);

    final combined = Uint8List.fromList([
      ...fileNameLengthBytes,
      ...fileNameBytes,
      ...keyLengthBytes,
      ...encryptedKeyBytes,
      ...iv.bytes,
      ...encryptedFileData.bytes,
    ]);

    print('DEBUG ENCRYPT: Final encrypted file size: ${combined.length} bytes');

    final tempDir = Directory.systemTemp;
    final encryptedFile = File(
        '${tempDir.path}/encrypted_${DateTime.now().millisecondsSinceEpoch}.enc');
    await encryptedFile.writeAsBytes(combined);

    return encryptedFile;
  }

  // Decrypt file by extracting embedded key
  Future<File> decryptFile(File encryptedFile, String password) async {
    try {
      final bytes = await encryptedFile.readAsBytes();
      print('DEBUG DECRYPT: File size: ${bytes.length} bytes');

      // Extract fileName length (first 4 bytes)
      if (bytes.length < 8) {
        throw Exception('File too small to be a valid encrypted file');
      }

      final fileNameLength = bytes.buffer.asByteData().getUint32(0, Endian.big);
      print('DEBUG DECRYPT: Filename length: $fileNameLength');
      var offset = 4;

      // Extract original fileName
      final fileNameBytes = bytes.sublist(offset, offset + fileNameLength);
      final originalFileName = utf8.decode(fileNameBytes);
      print('DEBUG DECRYPT: Original filename: $originalFileName');
      offset += fileNameLength;

      // Extract key length (next 4 bytes)
      final keyLength = bytes.buffer.asByteData().getUint32(offset, Endian.big);
      print('DEBUG DECRYPT: Encrypted key length: $keyLength');
      offset += 4;

      // Extract encrypted file key (as bytes, not string)
      final encryptedKeyBytes = bytes.sublist(offset, offset + keyLength);
      print('DEBUG DECRYPT: Encrypted key extracted');
      offset += keyLength;

      // Decrypt the file key with password
      print('DEBUG DECRYPT: Attempting to decrypt file key with password...');
      final fileKey = decryptFileKey(encryptedKeyBytes, password);
      print('DEBUG DECRYPT: File key decrypted successfully');

      // Extract IV (next 16 bytes)
      final iv =
          encrypt.IV(Uint8List.fromList(bytes.sublist(offset, offset + 16)));
      offset += 16;

      // Extract encrypted file data
      final encryptedData = bytes.sublist(offset);
      print(
          'DEBUG DECRYPT: Encrypted data size: ${encryptedData.length} bytes');

      // Decrypt file data
      final key = encrypt.Key.fromBase64(fileKey);
      final encrypter =
          encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));

      print('DEBUG DECRYPT: Attempting to decrypt file data...');
      final decrypted = encrypter.decryptBytes(
        encrypt.Encrypted(Uint8List.fromList(encryptedData)),
        iv: iv,
      );
      print(
          'DEBUG DECRYPT: File data decrypted successfully, size: ${decrypted.length} bytes');

      final tempDir = Directory.systemTemp;
      final decryptedFile = File('${tempDir.path}/$originalFileName');
      await decryptedFile.writeAsBytes(decrypted);

      print('DEBUG DECRYPT: Decrypted file saved: ${decryptedFile.path}');

      return decryptedFile;
    } catch (e) {
      print('DEBUG DECRYPT ERROR: $e');
      rethrow;
    }
  }
}
