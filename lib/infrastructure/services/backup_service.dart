import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/app_database.dart';

class LocalBackupInfo {
  final String locationPath;
  final String fullFilePath;
  final DateTime? lastBackupDate;
  final String formattedSize;
  final bool fileExists;

  const LocalBackupInfo({
    required this.locationPath,
    required this.fullFilePath,
    this.lastBackupDate,
    required this.formattedSize,
    required this.fileExists,
  });

  String get formattedDate {
    if (lastBackupDate == null || !fileExists) {
      return 'No local backup yet';
    }
    return DateFormat('dd MMM yyyy, hh:mm a').format(lastBackupDate!);
  }
}

class BackupService {
  BackupService._();
  static final BackupService instance = BackupService._();

  static const String _prefCustomLocationKey = 'custom_backup_location_dir';
  static const String _prefLastBackupTimeKey = 'last_local_backup_timestamp';

  /// Get standard default Documents path
  Future<String> getDefaultBaseDirectory() async {
    try {
      if (Platform.isAndroid) {
        final extDir = Directory('/storage/emulated/0/Documents');
        if (await extDir.exists()) {
          return extDir.path;
        }
      }
      final docDir = await getApplicationDocumentsDirectory();
      return docDir.path;
    } catch (_) {
      return '/storage/emulated/0/Documents';
    }
  }

  /// Get current configured base directory (custom or default Documents)
  Future<String> getConfiguredBaseDirectory() async {
    final prefs = await SharedPreferences.getInstance();
    final custom = prefs.getString(_prefCustomLocationKey);
    if (custom != null && custom.isNotEmpty) {
      return custom;
    }
    return await getDefaultBaseDirectory();
  }

  /// Full destination file path: <base_dir>/xenobill/Database/xenobill_db.bin
  Future<String> getFullBackupFilePath([String? customBaseDir]) async {
    final base = customBaseDir ?? await getConfiguredBaseDirectory();
    final cleanBase = base.replaceAll('\\', '/').replaceAll(RegExp(r'/+$'), '');
    return '$cleanBase/xenobill/Database/xenobill_db.bin';
  }

  /// Pick custom directory from device
  Future<String?> selectCustomBackupDirectory() async {
    final selectedDirectory = await FilePickerPlatform.instance.getDirectoryPath(
      dialogTitle: 'Select Backup Folder',
    );
    if (selectedDirectory != null && selectedDirectory.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefCustomLocationKey, selectedDirectory);
      return selectedDirectory;
    }
    return null;
  }

  /// Get backup info for UI display
  Future<LocalBackupInfo> getBackupInfo() async {
    final baseDir = await getConfiguredBaseDirectory();
    final fullPath = await getFullBackupFilePath(baseDir);
    final file = File(fullPath);

    final prefs = await SharedPreferences.getInstance();
    final timeStr = prefs.getString(_prefLastBackupTimeKey);

    DateTime? lastBackupDate;
    if (timeStr != null) {
      lastBackupDate = DateTime.tryParse(timeStr);
    }

    bool fileExists = false;
    String formattedSize = '0 KB';

    if (await file.exists()) {
      fileExists = true;
      final bytes = await file.length();
      lastBackupDate ??= await file.lastModified();
      formattedSize = _formatBytes(bytes);
    }

    return LocalBackupInfo(
      locationPath: fullPath,
      fullFilePath: fullPath,
      lastBackupDate: lastBackupDate,
      formattedSize: formattedSize,
      fileExists: fileExists,
    );
  }

  /// Create local backup
  Future<LocalBackupInfo> createLocalBackup() async {
    final baseDir = await getConfiguredBaseDirectory();
    final targetFolder = Directory('${baseDir.replaceAll('\\', '/').replaceAll(RegExp(r'/+$'), '')}/xenobill/Database');
    if (!await targetFolder.exists()) {
      await targetFolder.create(recursive: true);
    }

    final fullPath = '${targetFolder.path}/xenobill_db.bin';
    final file = File(fullPath);
    final bytes = AppDatabase.instance.exportBinDatabase();
    await file.writeAsBytes(bytes, flush: true);

    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefLastBackupTimeKey, now.toIso8601String());

    return LocalBackupInfo(
      locationPath: fullPath,
      fullFilePath: fullPath,
      lastBackupDate: now,
      formattedSize: _formatBytes(bytes.length),
      fileExists: true,
    );
  }

  /// Restore from chosen local backup file or fallback path
  Future<bool> restoreFromLocalFile({String? explicitFilePath}) async {
    if (explicitFilePath != null && explicitFilePath.isNotEmpty) {
      final file = File(explicitFilePath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        return await AppDatabase.instance.importBinDatabase(bytes);
      }
      return false;
    }

    try {
      final result = await FilePickerPlatform.instance.pickFiles(
        type: FileType.any,
        dialogTitle: 'Select Xenobill Database Backup (.bin)',
      );

      if (result.isNotEmpty && result.first.path != null) {
        final filePath = result.first.path!;
        final file = File(filePath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          return await AppDatabase.instance.importBinDatabase(bytes);
        }
      }
      return false;
    } catch (e) {
      // Fallback: check if the default backup file exists
      final defaultPath = await getFullBackupFilePath();
      final defaultFile = File(defaultPath);
      if (await defaultFile.exists()) {
        final bytes = await defaultFile.readAsBytes();
        final success = await AppDatabase.instance.importBinDatabase(bytes);
        if (success) return true;
      }
      rethrow;
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 KB';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}
