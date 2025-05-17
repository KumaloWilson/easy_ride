import 'dart:io';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:easy_ride/core/values/constants.dart';
import 'package:uuid/uuid.dart';
import 'package:easy_ride/core/utils/logs.dart';

class StorageService extends GetxService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Uuid _uuid = const Uuid();

  Future<StorageService> init() async {
    return this;
  }

  Future<String?> uploadProfileImage(File file, String userId) async {
    try {
      String fileExt = path.extension(file.path);
      String fileName = '${userId}_${_uuid.v4()}$fileExt';

      await _supabase.storage
          .from(Constants.profileImagesPath)
          .upload(fileName, file);

      final imageUrl = _supabase.storage
          .from(Constants.profileImagesPath)
          .getPublicUrl(fileName);

      return imageUrl;
    } catch (e) {
      DevLogs.error('Error uploading profile image', exception: e);
      return null;
    }
  }

  Future<String?> uploadDocumentImage(File file, String userId, String documentType) async {
    try {
      String fileExt = path.extension(file.path);
      String fileName = '${userId}_${documentType}_${_uuid.v4()}$fileExt';

      await _supabase.storage
          .from(Constants.documentImagesPath)
          .upload(fileName, file);

      final imageUrl = _supabase.storage
          .from(Constants.documentImagesPath)
          .getPublicUrl(fileName);

      return imageUrl;
    } catch (e) {
      DevLogs.error('Error uploading document image', exception: e);
      return null;
    }
  }

  Future<bool> deleteFile(String bucket, String path) async {
    try {
      await _supabase.storage.from(bucket).remove([path]);
      return true;
    } catch (e) {
      DevLogs.error('Error deleting file', exception: e);
      return false;
    }
  }
}
