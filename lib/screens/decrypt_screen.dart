import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/encryption_service.dart';
import '../services/supabase_service.dart';
import '../services/storage_service.dart';
import '../models/encrypted_file.dart';
import '../utils/theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/file_card.dart';

class DecryptScreen extends StatefulWidget {
  const DecryptScreen({super.key});

  @override
  State<DecryptScreen> createState() => _DecryptScreenState();
}

class _DecryptScreenState extends State<DecryptScreen> {
  final _encryptionService = EncryptionService();
  final _supabaseService = SupabaseService();
  final _storageService = StorageService();

  List<EncryptedFile> _cloudFiles = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCloudFiles();
  }

  Future<void> _loadCloudFiles() async {
    setState(() => _isLoading = true);

    try {
      final files = await _supabaseService.getUserFiles();
      setState(() => _cloudFiles = files);
    } catch (e) {
      _showError('Failed to load files: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndDecryptFile() async {
    final result = await FilePicker.platform.pickFiles();

    if (result != null) {
      final encryptedFile = File(result.files.single.path!);

      _showPasswordDialog(
        title: 'Enter Password',
        onDecrypt: (password) async {
          // Show loading
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(),
            ),
          );

          try {
            print('DEBUG: Starting decryption from local file...');

            // Decrypt file - filename is embedded inside
            final decryptedFile = await _encryptionService.decryptFile(
              encryptedFile,
              password,
            );

            print('DEBUG: Decryption successful, now saving to downloads...');

            // Save with original filename (including extension)
            final fileName = decryptedFile.path.split('/').last;
            final savedPath = await _storageService.saveToDownloads(
              decryptedFile,
              fileName,
            );

            print('DEBUG: File saved to: $savedPath');

            // Hide loading
            if (mounted) Navigator.pop(context);

            _showSuccess(
                'File decrypted and saved to Downloads!\nFile: $fileName');
          } catch (e) {
            print('DEBUG: Decryption error: $e');

            // Hide loading
            if (mounted) Navigator.pop(context);

            _showError('Decryption failed. Wrong password or corrupted file.');
          }
        },
      );
    }
  }

  Future<void> _decryptCloudFile(EncryptedFile file) async {
    _showPasswordDialog(
      title: 'Enter Password',
      metadata: file.metadata,
      onDecrypt: (password) async {
        // Show loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        try {
          print('DEBUG: Downloading file from cloud...');

          // Download encrypted file
          final bytes = await _supabaseService.downloadFile(file.filePath);
          final tempDir = await _storageService.getTempDirectory();
          final tempFile = File('${tempDir.path}/temp_encrypted.enc');
          await tempFile.writeAsBytes(bytes);

          print('DEBUG: Download complete, starting decryption...');

          // Decrypt file - filename is embedded inside
          final decryptedFile = await _encryptionService.decryptFile(
            tempFile,
            password,
          );

          print('DEBUG: Decryption successful, now saving to downloads...');

          // Save with original filename (including extension)
          final fileName = decryptedFile.path.split('/').last;
          await _storageService.saveToDownloads(
            decryptedFile,
            fileName,
          );

          print('DEBUG: File saved successfully');

          // Hide loading
          if (mounted) Navigator.pop(context);

          _showSuccess(
              'File decrypted and saved to Downloads!\nFile: $fileName');
        } catch (e) {
          print('DEBUG: Error during cloud decryption: $e');

          // Hide loading
          if (mounted) Navigator.pop(context);

          _showError('Decryption failed. Wrong password or error occurred.');
        }
      },
    );
  }

  void _showPasswordDialog({
    required String title,
    required Function(String) onDecrypt,
    String? metadata,
  }) {
    final passwordController = TextEditingController();
    bool obscurePassword = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (metadata != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.skyBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          metadata,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Enter password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setDialogState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (passwordController.text.isNotEmpty) {
                  Navigator.pop(context);
                  onDecrypt(passwordController.text);
                }
              },
              child: const Text('Decrypt'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteCloudFile(EncryptedFile file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: const Text('Are you sure you want to delete this file?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _supabaseService.deleteFile(file.filePath, file.id);
        _loadCloudFiles();
        _showSuccess('File deleted');
      } catch (e) {
        _showError('Failed to delete file');
      }
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.primary),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade400),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Decrypt Files'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCloudFiles,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomButton(
              text: 'Pick File from Device',
              onPressed: _pickAndDecryptFile,
              color: Colors.blue.shade400,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                const Text(
                  'Your Cloud Files',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_cloudFiles.isEmpty && !_isLoading)
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    Icon(Icons.cloud_off,
                        size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(
                      'No files in cloud',
                      style:
                          TextStyle(fontSize: 16, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _cloudFiles.length,
                itemBuilder: (context, index) {
                  final file = _cloudFiles[index];
                  return FileCard(
                    file: file,
                    onTap: () => _decryptCloudFile(file),
                    onDelete: () => _deleteCloudFile(file),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
