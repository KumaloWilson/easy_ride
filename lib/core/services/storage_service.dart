import 'dart:io';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:easy_ride/core/values/constants.dart';
import 'package:uuid/uuid.dart';

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
      
      final response = await _supabase.storage
          .from(Constants.profileImagesPath)
          .upload(fileName, file);
      
      final imageUrl = _supabase.storage
          .from(Constants.profileImagesPath)
          .getPublicUrl(fileName);
      
      return imageUrl;
    } catch (e) {
      print('Error uploading profile image: $e');
      return null;
    }
  }

  Future<String?> uploadDocumentImage({required File file, required String userId, required String documentType}) async {
    try {
      String fileExt = path.extension(file.path);
      String fileName = '${userId}_${documentType}_${_uuid.v4()}$fileExt';

      // Determine the storage path based on documentType
      String storagePath;
      switch (documentType) {
        case 'profile':
          storagePath = Constants.profileImagesPath;
          break;
        case 'driver':
          storagePath = Constants.driverDocumentsPath;
          break;
        case 'chat':
          storagePath = Constants.chatAttachmentsPath;
          break;
        case 'report':
          storagePath = Constants.chatAttachmentsPath;
          break;
        default:
        // Fallback to driver documents if type doesn't match any known types
          storagePath = Constants.driverDocumentsPath;
      }

      final response = await _supabase.storage
          .from(storagePath)
          .upload(fileName, file);

      final imageUrl = _supabase.storage
          .from(storagePath)
          .getPublicUrl(fileName);

      return imageUrl;
    } catch (e) {
      print('Error uploading document image: $e');
      return null;
    }
  }
  
  Future<bool> deleteFile(String bucket, String path) async {
    try {
      await _supabase.storage.from(bucket).remove([path]);
      return true;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }
}
