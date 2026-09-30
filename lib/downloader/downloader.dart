import 'dart:async';

import 'package:moviezone/constants.dart';
import 'package:moviezone/downloader/download_db.dart';
import 'package:moviezone/downloader/download_models.dart';
import 'package:moviezone/log.dart';

const l = L('moviezone_downloader');

/// MovieZone download manager.
///
/// The previous implementation contained the legacy MovieZone HLS/audio/video
/// downloader and source resolvers. MovieZone playback is now supplied by the
/// MovieZone backend, so this class only keeps the local download-screen state
/// and database controls required by the existing UI.
class Downloader {
  static final Downloader _instance = Downloader._internal();
  static bool _initialized = false;
  static int maxDownloadLimit = 2;
  static int currentDownloadItems = 0;

  final StreamController<DownloadProgress> _progressController =
      StreamController<DownloadProgress>.broadcast();

  Downloader._internal();

  static Downloader get instance {
    if (!_initialized) {
      _instance.initialize();
      _initialized = true;
    }
    return _instance;
  }

  Stream<DownloadProgress> get progressStream => _progressController.stream;

  void initialize() {
    // No legacy source/download worker is started here.
    l.info('MovieZone download manager initialized');
  }

  Future<void> pauseDownload(String videoId) async {
    await DownloadDb.instance.updateStatus(videoId, 'download', 'paused');
    _progressController.add(DownloadProgress.status(videoId, 'paused'));
  }

  Future<void> resumeDownload(String videoId) async {
    await DownloadDb.instance.updateStatus(videoId, 'download', 'paused');
    _progressController.add(DownloadProgress.status(videoId, 'paused'));
  }

  static Future<void> deleteItem(String videoId) async {
    final db = await DownloadDb.instance.database;
    await db.delete(
      DownloadTables.downloads,
      where: 'id = ?',
      whereArgs: [videoId],
    );
    _instance._progressController.add(DownloadProgress.status(videoId, 'deleted'));
  }

  static Future<void> deleteSeries(String id) async {
    final db = await DownloadDb.instance.database;
    await db.delete(
      DownloadTables.downloads,
      where: 'id = ? OR series_id = ?',
      whereArgs: [id, id],
    );
    _instance._progressController.add(DownloadProgress.status(id, 'deleted'));
  }

  Future<void> continueDownloadAfterAppOpen() async {
    // Deliberately disabled: there is no legacy MovieZone downloader anymore.
  }

  Future<void> dispose() async {
    await _progressController.close();
  }
}
