import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class Sound {
  late final AudioPlayer _player;

  Sound.loop() {
    _player = AudioPlayer();
    _player.setReleaseMode(ReleaseMode.loop);
  }

  Sound.single() {
    _player = AudioPlayer();
    _player.setReleaseMode(ReleaseMode.release);
  }

  Sound.shout(String? url) {
    _player = AudioPlayer();
    _player.setReleaseMode(ReleaseMode.release);
    cache(url).then((S) => playSource(S));
  }

  Future<void> dispose() async {
    await _player.dispose();
    log('Sound disposed');
  }

  Future<void> playSource(DeviceFileSource? source) async {
    if (source == null) {
      log('No sound source available to play');
      return;
    }
    await _player.play(source);
    log('Sound playing');
  }

  Future<void> stop() async {
    await _player.stop();
    log('Sound stopped');
  }

  Future<void> pause() async {
    await _player.pause();
    log('Sound paused');
  }

  Future<void> resume() async {
    await _player.resume();
    log('Sound resumed');
  }

  Future<DeviceFileSource?> cache(String? url) async {
    try {
      if (url == null || url.isEmpty) {
        log('Sound URL is null or empty');
        return null;
      }

      final dir = await getTemporaryDirectory();
      final hash = md5.convert(utf8.encode(url)).toString();
      final file = '${dir.path}/$hash';

      final f = File(file);
      if (await f.exists()) {
        log('Sound playing from cache');
        return DeviceFileSource(f.path);
      } else {
        log('Downloading sound from URL: $url');
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final f = await File(file).writeAsBytes(response.bodyBytes);
          log('Sound downloaded and playing');
          return DeviceFileSource(f.path);
        } else {
          log('Failed to download sound: ${response.statusCode}');
        }
      }
    } catch (e) {
      log('Error in cacheAndPlay: $e');
    }
    return null;
  }
}
