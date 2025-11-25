import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class Sound {
  late final AudioPlayer _player;

  Sound.cacheLoop(String? url) {
    _player = AudioPlayer();
    _player.setReleaseMode(ReleaseMode.loop);
    cacheAndPlay(url);
  }

  Sound.cacheSingle(String? url) {
    _player = AudioPlayer();
    _player.setReleaseMode(ReleaseMode.release);
    cacheAndPlay(url);
  }

  void dispose() {
    _player.dispose();
    log('Sound disposed');
  }

  void stop() {
    _player.stop();
    log('Sound stopped');
  }

  void pause() {
    _player.pause();
    log('Sound paused');
  }

  void resume() {
    _player.resume();
    log('Sound resumed');
  }

  Future<void> cacheAndPlay(String? url) async {
    try {
      if (url == null || url.isEmpty) {
        log('Sound URL is null or empty');
        return;
      }

      final dir = await getTemporaryDirectory();
      final hash = md5.convert(utf8.encode(url)).toString();
      final file = '${dir.path}/$hash';

      final f = File(file);
      if (await f.exists()) {
        log('Sound playing from cache');
        _player.play(DeviceFileSource(f.path));
      } else {
        log('Downloading sound from URL: $url');
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final f = await File(file).writeAsBytes(response.bodyBytes);
          log('Sound downloaded and playing');
          _player.play(DeviceFileSource(f.path));
        } else {
          log('Failed to download sound: ${response.statusCode}');
        }
      }
    } catch (e) {
      log('Error in cacheAndPlay: $e');
    }
  }
}
