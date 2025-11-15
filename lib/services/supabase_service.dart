import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/encrypted_file.dart';
import '../utils/constants.dart';

class SupabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Authentication
  Future<AuthResponse> signUp(String email, String password) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signIn(String email, String password) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  User? get currentUser => _supabase.auth.currentUser;

  // File Upload (no encrypted key needed - it's embedded in file)
  Future<String> uploadEncryptedFile(
    File file,
    String fileName,
    String? metadata,
  ) async {
    final userId = currentUser!.id;
    final filePath = '$userId/$fileName';

    await _supabase.storage
        .from(AppConstants.encryptedFilesBucket)
        .upload(filePath, file);

    // Store metadata in database
    await _supabase.from('encrypted_files').insert({
      'user_id': userId,
      'file_name': fileName,
      'file_path': filePath,
      'uploaded_at': DateTime.now().toIso8601String(),
      'metadata': metadata,
    });

    return filePath;
  }

  // Fetch user's encrypted files
  Future<List<EncryptedFile>> getUserFiles() async {
    final userId = currentUser!.id;

    final response = await _supabase
        .from('encrypted_files')
        .select()
        .eq('user_id', userId)
        .order('uploaded_at', ascending: false);

    return (response as List)
        .map((json) => EncryptedFile.fromJson(json))
        .toList();
  }

  // Download file
  Future<List<int>> downloadFile(String filePath) async {
    return await _supabase.storage
        .from(AppConstants.encryptedFilesBucket)
        .download(filePath);
  }

  // Delete file
  Future<void> deleteFile(String filePath, String fileId) async {
    await _supabase.storage
        .from(AppConstants.encryptedFilesBucket)
        .remove([filePath]);

    await _supabase.from('encrypted_files').delete().eq('id', fileId);
  }
}
