import 'dart:io';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:path/path.dart' as path;

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  // Default key for encryption (in a real app, this should be securely generated and stored)
  static const String _defaultKey = 'pocketrecorder123pocketrecorder123'; // 32 bytes for AES-256

  // Encrypt a file
  Future<String?> encryptFile(String filePath) async {
    try {
      // Read the file
      final file = File(filePath);
      final Uint8List fileBytes = await file.readAsBytes();

      // Create key and encrypter
      final key = Key.fromUtf8(_defaultKey);
      final encrypter = Encrypter(AES(key));

      // Encrypt the file data
      final encrypted = encrypter.encryptBytes(fileBytes);

      // Create encrypted file path
      final String dir = path.dirname(filePath);
      final String fileName = path.basenameWithoutExtension(filePath);
      final String extension = path.extension(filePath);
      final String encryptedFilePath = path.join(dir, '${fileName}_encrypted$extension');

      // Write encrypted data to new file
      final encryptedFile = File(encryptedFilePath);
      await encryptedFile.writeAsBytes(encrypted.bytes);

      // Delete original file
      await file.delete();

      return encryptedFilePath;
    } catch (e) {
      print('Error encrypting file: $e');
      return null;
    }
  }

  // Decrypt a file
  Future<String?> decryptFile(String encryptedFilePath) async {
    try {
      // Read the encrypted file
      final file = File(encryptedFilePath);
      final Uint8List encryptedBytes = await file.readAsBytes();

      // Create key and encrypter
      final key = Key.fromUtf8(_defaultKey);
      final encrypter = Encrypter(AES(key));

      // Create IV (in a real app, this should be randomly generated and stored with the file)
      final iv = IV.fromLength(16);

      // Decrypt the file data
      final encrypted = Encrypted(encryptedBytes);
      final decryptedBytes = encrypter.decryptBytes(encrypted, iv: iv);

      // Create decrypted file path
      final String dir = path.dirname(encryptedFilePath);
      final String fileName = path.basenameWithoutExtension(encryptedFilePath);
      final String extension = path.extension(encryptedFilePath);
      final String decryptedFilePath = path.join(dir, '${fileName}_decrypted$extension');

      // Write decrypted data to new file
      final decryptedFile = File(decryptedFilePath);
      await decryptedFile.writeAsBytes(decryptedBytes);

      // Delete encrypted file
      await file.delete();

      return decryptedFilePath;
    } catch (e) {
      print('Error decrypting file: $e');
      return null;
    }
  }

  // Generate a secure key (for future implementation)
  String generateSecureKey() {
    // In a real implementation, you would generate a truly random key
    // and securely store it using Flutter's secure storage mechanisms
    return _defaultKey;
  }
}