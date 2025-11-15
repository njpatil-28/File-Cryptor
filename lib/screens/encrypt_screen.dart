import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../services/encryption_service.dart';
import '../services/supabase_service.dart';
import '../services/storage_service.dart';
import '../utils/theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';

class EncryptScreen extends StatefulWidget {
  const EncryptScreen({super.key});

  @override
  State<EncryptScreen> createState() => _EncryptScreenState();
}

class _EncryptScreenState extends State<EncryptScreen> {
  final _encryptionService = EncryptionService();
  final _supabaseService = SupabaseService();
  final _storageService = StorageService();
  final _passwordController = TextEditingController();
  final _metadataController = TextEditingController();

  File? _selectedFile;
  File? _encryptedFile;
  bool _isEncrypting = false;
  bool _isUploading = false;
  bool _obscurePassword = true;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();

    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _encryptedFile = null;
        _passwordController.clear();
        _metadataController.clear();
      });
    }
  }

  Future<void> _encryptFile() async {
    if (_selectedFile == null) return;

    if (_passwordController.text.isEmpty) {
      _showError('Please enter a password');
      return;
    }

    if (_passwordController.text.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }

    setState(() => _isEncrypting = true);

    try {
      // Get original filename with extension
      final originalFileName = _selectedFile!.path.split('/').last;

      // Encrypt file with password and preserve filename
      final encrypted = await _encryptionService.encryptFile(
        _selectedFile!,
        _passwordController.text,
        originalFileName,
      );

      setState(() => _encryptedFile = encrypted);

      _showSuccess('File encrypted successfully!');
    } catch (e) {
      _showError('Encryption failed: ${e.toString()}');
    } finally {
      setState(() => _isEncrypting = false);
    }
  }

  Future<void> _downloadFile() async {
    if (_encryptedFile == null) return;

    try {
      final fileName = 'encrypted_${DateTime.now().millisecondsSinceEpoch}.enc';
      await _storageService.saveToDownloads(_encryptedFile!, fileName);
      _showSuccess('File saved to Downloads!');
    } catch (e) {
      _showError('Failed to save file: ${e.toString()}');
    }
  }

  Future<void> _shareFile() async {
    if (_encryptedFile == null) return;

    try {
      await Share.shareXFiles(
        [XFile(_encryptedFile!.path)],
        text: 'Encrypted file\nPassword: ${_passwordController.text}',
      );
    } catch (e) {
      _showError('Failed to share file: ${e.toString()}');
    }
  }

  Future<void> _uploadToCloud() async {
    if (_encryptedFile == null) return;

    setState(() => _isUploading = true);

    try {
      final fileName = 'encrypted_${DateTime.now().millisecondsSinceEpoch}.enc';
      final metadata =
          _metadataController.text.isNotEmpty ? _metadataController.text : null;

      await _supabaseService.uploadEncryptedFile(
        _encryptedFile!,
        fileName,
        metadata,
      );

      _showSuccess('File uploaded to cloud!');

      // Reset form
      setState(() {
        _selectedFile = null;
        _encryptedFile = null;
        _passwordController.clear();
        _metadataController.clear();
      });
    } catch (e) {
      _showError('Upload failed: ${e.toString()}');
    } finally {
      setState(() => _isUploading = false);
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
      appBar: AppBar(title: const Text('Encrypt Files')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.mintGreen,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.lock,
                        size: 32, color: AppTheme.primary),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Secure Your Files',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Each file gets unique encryption',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            if (_selectedFile == null) ...[
              CustomButton(
                text: 'Select File to Encrypt',
                onPressed: _pickFile,
                color: AppTheme.primary,
              ),
            ] else ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.skyBlue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.insert_drive_file,
                            color: Colors.blue),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedFile!.path.split('/').last,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${(_selectedFile!.lengthSync() / 1024).toStringAsFixed(2)} KB',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _selectedFile = null;
                            _encryptedFile = null;
                            _passwordController.clear();
                            _metadataController.clear();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_encryptedFile == null) ...[
                CustomTextField(
                  controller: _passwordController,
                  label: 'Encryption Password',
                  hint: 'Enter password for this file',
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _metadataController,
                  label: 'Notes (Optional)',
                  hint: 'Add description or notes',
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Encrypt File',
                  onPressed: _encryptFile,
                  isLoading: _isEncrypting,
                  color: AppTheme.primary,
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.mintGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppTheme.primary),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'File encrypted! Remember your password to decrypt.',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  color: AppTheme.peach,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.key,
                            size: 20, color: AppTheme.secondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Password: ${_passwordController.text}',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 18),
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: _passwordController.text));
                            _showSuccess('Password copied!');
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Choose an action:',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Download',
                  onPressed: _downloadFile,
                  color: Colors.blue.shade400,
                ),
                const SizedBox(height: 12),
                CustomButton(
                  text: 'Share',
                  onPressed: _shareFile,
                  color: Colors.purple.shade400,
                ),
                const SizedBox(height: 12),
                CustomButton(
                  text: 'Upload to Cloud',
                  onPressed: _uploadToCloud,
                  isLoading: _isUploading,
                  color: Colors.orange.shade400,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _metadataController.dispose();
    super.dispose();
  }
}
