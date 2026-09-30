import 'dart:io';

/// Local-file player commands used only by the existing Downloads UI.
/// No remote/legacy streaming endpoints are referenced here.
class ExternalPlayer {
  ExternalPlayer._();
  static final _PlayerCommand offlineFile = _PlayerCommand._();
}

class _PlayerCommand {
  _PlayerCommand._();

  Future<void> mpv(String path) async {
    if (!Platform.isLinux && !Platform.isWindows && !Platform.isMacOS) return;
    await Process.start('mpv', ['--no-config', '--demuxer=lavf', path],
        mode: ProcessStartMode.detached);
  }

  Future<void> vlc(String path) async {
    if (!Platform.isLinux && !Platform.isWindows && !Platform.isMacOS) return;
    await Process.start('vlc', ['--fullscreen', path],
        mode: ProcessStartMode.detached);
  }

  Future<void> iina(String path) async {
    if (!Platform.isMacOS) return;
    await Process.start('iina', [path], mode: ProcessStartMode.detached);
  }

  Future<void> wmp(String path) async {
    if (!Platform.isWindows) return;
    await Process.start('wmplayer.exe', [path], mode: ProcessStartMode.detached);
  }

  Future<void> ffPlay(String path) async {
    if (!Platform.isLinux && !Platform.isWindows && !Platform.isMacOS) return;
    await Process.start('ffplay', [path], mode: ProcessStartMode.detached);
  }

  Future<void> mplayer(String path) async {
    if (!Platform.isLinux && !Platform.isWindows && !Platform.isMacOS) return;
    await Process.start('mplayer', [path], mode: ProcessStartMode.detached);
  }
}
